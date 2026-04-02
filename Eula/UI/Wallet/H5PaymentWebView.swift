import SwiftUI
import UIKit
import WebKit

struct H5PaymentSheet: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                H5PaymentWebView(url: url, isLoading: $isLoading)
                    .ignoresSafeArea(edges: .bottom)

                if isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Web Recharge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct H5PaymentWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    private static func bridgeNames() -> [String] {
        let baseNames = [
            "iosPay",
            "nativePay",
            "appPay",
            "pay",
            "iap",
            "purchase",
            "messageHandler",
            "iosBridge",
            "nativeBridge",
            "recharge",
            "payHandler"
        ]
        let configuredName = AppConfig.h5PaymentCallPay.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !configuredName.isEmpty else {
            return baseNames
        }
        return Array(NSOrderedSet(array: baseNames + [configuredName])) as? [String] ?? (baseNames + [configuredName])
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let bridgeNames = H5PaymentWebView.bridgeNames()
        bridgeNames.forEach { configuration.userContentController.add(context.coordinator, name: $0) }
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.attach(webView: webView)
        context.coordinator.log("bridge handlers registered: \(bridgeNames.joined(separator: ", "))")
        let requestURL = normalizedURL(from: url)
        if requestURL != url {
            context.coordinator.log("webview normalized initial url from \(url.absoluteString) to \(requestURL.absoluteString)")
        }
        webView.load(URLRequest(url: requestURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let requestURL = normalizedURL(from: url)
        if webView.url != requestURL {
            if requestURL != url {
                context.coordinator.log("webview normalized updated url from \(url.absoluteString) to \(requestURL.absoluteString)")
            }
            webView.load(URLRequest(url: requestURL))
        }
    }

    private func normalizedURL(from url: URL) -> URL {
        let absoluteString = url.absoluteString.replacingOccurrences(of: "??", with: "?")
        return URL(string: absoluteString) ?? url
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        bridgeNames().forEach { webView.configuration.userContentController.removeScriptMessageHandler(forName: $0) }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        @Binding private var isLoading: Bool
        private weak var webView: WKWebView?

        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }

        func attach(webView: WKWebView) {
            self.webView = webView
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            log("webview started loading: \(webView.url?.absoluteString ?? "<pending>")")
            isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            log("webview finished loading: \(webView.url?.absoluteString ?? "<unknown>")")
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            log("webview load failed: \(error.localizedDescription)")
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            log("webview provisional load failed: \(error.localizedDescription)")
            isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            let scheme = url.scheme?.lowercased()
            if scheme == "http" || scheme == "https" {
                decisionHandler(.allow)
                return
            }
            log("intercepted non-http url: \(url.absoluteString)")
            if let request = paymentRequest(from: url) {
                decisionHandler(.cancel)
                Task {
                    await handlePurchaseRequest(request, source: "url-scheme")
                }
                return
            }
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            let bodyDescription = describe(body: message.body)
            log("received bridge message [\(message.name)]: \(bodyDescription)")
            let configuredListener = AppConfig.h5PaymentCallPay.trimmingCharacters(in: .whitespacesAndNewlines)
            if !configuredListener.isEmpty && message.name == configuredListener {
                log("configured payment listener executed: \(configuredListener)")
            }
            guard let request = paymentRequest(from: message.body) else {
                log("bridge message ignored because product id was not found")
                Task { @MainActor in
                    ToastManager.shared.show("Unsupported H5 payment request")
                }
                return
            }
            Task {
                await handlePurchaseRequest(request, source: "js-bridge:\(message.name)")
            }
        }

        private func handlePurchaseRequest(_ request: H5NativePurchaseRequest, source: String) async {
            log("purchase request from \(source), rawProductID=\(request.rawProductID), mappedProductID=\(request.productID)")
            do {
                try await WalletIAPService.shared.purchase(productID: request.productID)
                log("native purchase succeeded for mappedProductID=\(request.productID)")
                await MainActor.run {
                    ToastManager.shared.show("Payment succeeded")
                }
                await notifyH5(success: true, productID: request.rawProductID, message: "success")
                await reloadH5()
            } catch {
                let supportedProducts = MockWallet.rechargeOptions.map(\.productID).joined(separator: ", ")
                log("native purchase failed for rawProductID=\(request.rawProductID), mappedProductID=\(request.productID), error=\(error.localizedDescription), supportedProducts=\(supportedProducts)")
                await MainActor.run {
                    ToastManager.shared.show("Payment failed: \(request.rawProductID)")
                }
                await notifyH5(success: false, productID: request.rawProductID, message: error.localizedDescription)
            }
        }

        @MainActor
        private func reloadH5() {
            webView?.reload()
        }

        @MainActor
        private func notifyH5(success: Bool, productID: String, message: String) {
            guard let webView else {
                return
            }
            let escapedProductID = jsEscaped(productID)
            let escapedMessage = jsEscaped(message)
            let script = """
            (function() {
                var detail = { success: \(success ? "true" : "false"), productId: "\(escapedProductID)", message: "\(escapedMessage)" };
                window.dispatchEvent(new CustomEvent('eula-iap-result', { detail: detail }));
                document.dispatchEvent(new CustomEvent('eula-iap-result', { detail: detail }));
                if (typeof window.onEulaIAPResult === 'function') { window.onEulaIAPResult(detail); }
            })();
            """
            webView.evaluateJavaScript(script)
        }

        private func paymentRequest(from body: Any) -> H5NativePurchaseRequest? {
            if let string = body as? String {
                if let data = string.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                    return paymentRequest(from: jsonObject)
                }
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return nil
                }
                return H5NativePurchaseRequest(rawProductID: trimmed)
            }

            if let dictionary = body as? [String: Any] {
                if let productID = firstValue(in: dictionary, keys: ["productId", "productID", "product_id", "sku", "goodsId", "goods_id", "id"]) {
                    return H5NativePurchaseRequest(rawProductID: productID)
                }
                if let payload = dictionary["payload"] {
                    return paymentRequest(from: payload)
                }
                if let data = dictionary["data"] {
                    return paymentRequest(from: data)
                }
            }

            if let array = body as? [Any] {
                for item in array {
                    if let request = paymentRequest(from: item) {
                        return request
                    }
                }
            }
            return nil
        }

        private func paymentRequest(from url: URL) -> H5NativePurchaseRequest? {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }

            if let productID = components.queryItems?.first(where: { item in
                ["productId", "productID", "product_id", "sku", "goodsId", "goods_id", "id"].contains(item.name)
            })?.value,
               !productID.isEmpty
            {
                return H5NativePurchaseRequest(rawProductID: productID)
            }

            let host = components.host?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
            if !host.isEmpty && host.lowercased() != "pay" && host.lowercased() != "purchase" {
                return H5NativePurchaseRequest(rawProductID: host)
            }

            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let last = pathComponents.last, !last.isEmpty {
                return H5NativePurchaseRequest(rawProductID: last)
            }
            return nil
        }

        private func firstValue(in dictionary: [String: Any], keys: [String]) -> String? {
            for key in keys {
                if let value = dictionary[key] as? String, !value.isEmpty {
                    return value
                }
            }
            return nil
        }

        private func describe(body: Any) -> String {
            if let dictionary = body as? [String: Any],
               JSONSerialization.isValidJSONObject(dictionary),
               let data = try? JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted]),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            if let array = body as? [Any],
               JSONSerialization.isValidJSONObject(array),
               let data = try? JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted]),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return String(describing: body)
        }

        private func jsEscaped(_ value: String) -> String {
            value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
        }

        func log(_ message: String) {
            #if DEBUG
            print("[H5Bridge] \(message)")
            #endif
        }
    }
}

private struct H5NativePurchaseRequest {
    let rawProductID: String
    let productID: String

    init(rawProductID: String) {
        self.rawProductID = rawProductID
        self.productID = H5ProductMapper.nativeProductID(for: rawProductID)
    }
}

private enum H5ProductMapper {
    private static let explicitMappings: [String: String] = [
        "com.vidoo.coins.xx001": "com.eula.stars.p028",
        "com.vidoo.coins.xx002": "com.eula.stars.p066",
        "com.vidoo.coins.xx003": "com.eula.stars.p150",
        "com.vidoo.coins.xx004": "com.eula.stars.p330",
        "com.vidoo.coins.xx005": "com.eula.stars.p530",
        "com.vidoo.coins.xx006": "com.eula.stars.p950",
        "xx001": "com.eula.stars.p028",
        "xx002": "com.eula.stars.p066",
        "xx003": "com.eula.stars.p150",
        "xx004": "com.eula.stars.p330",
        "xx005": "com.eula.stars.p530",
        "xx006": "com.eula.stars.p950"
    ]

    static func nativeProductID(for rawProductID: String) -> String {
        let trimmed = rawProductID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return rawProductID
        }
        if let mapped = explicitMappings[trimmed] {
            return mapped
        }
        return trimmed
    }
}
