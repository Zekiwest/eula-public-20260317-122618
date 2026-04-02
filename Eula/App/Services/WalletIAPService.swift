import Foundation
import StoreKit

enum WalletIAPError: LocalizedError {
    case productNotFound
    case pending
    case userCancelled
    case verificationFailed
    case paymentValidationFailed
    case creditingFailed

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found."
        case .pending:
            return "Purchase is pending."
        case .userCancelled:
            return "Purchase cancelled."
        case .verificationFailed:
            return "Purchase verification failed."
        case .paymentValidationFailed:
            return "Server-side payment validation failed."
        case .creditingFailed:
            return "Top-up crediting failed."
        }
    }
}

actor WalletIAPService {
    static let shared = WalletIAPService()

    private var cachedProducts: [String: Product] = [:]

    func loadProducts(productIDs: [String]) async throws -> [Product] {
        let ids = Array(Set(productIDs.filter { !$0.isEmpty }))
        guard !ids.isEmpty else { return [] }
        log("loadProducts requested ids=\(ids.joined(separator: ", "))")
        let products = try await Product.products(for: ids)
        log("loadProducts loaded product ids=\(products.map(\.id).joined(separator: ", "))")
        cachedProducts = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return productIDs.compactMap { cachedProducts[$0] }
    }

    func purchase(productID: String) async throws {
        log("purchase started productID=\(productID)")
        let product = try await resolveProduct(productID: productID)
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verify(verification)
            do {
                try await H5PaymentService.shared.submitSuccessfulOrder(
                    transactionID: String(transaction.id),
                    receiptData: AppStore.receiptBase64()
                )
            } catch {
                throw WalletIAPError.paymentValidationFailed
            }
            do {
                _ = try await ChatBackend.shared.applyWalletTopup(
                    productID: productID,
                    transactionID: String(transaction.id),
                    originalTransactionID: String(transaction.originalID)
                )
            } catch {
                throw WalletIAPError.creditingFailed
            }
            await transaction.finish()
            log("purchase finished successfully productID=\(productID)")
        case .pending:
            log("purchase pending productID=\(productID)")
            throw WalletIAPError.pending
        case .userCancelled:
            log("purchase cancelled productID=\(productID)")
            throw WalletIAPError.userCancelled
        @unknown default:
            log("purchase failed with unknown result productID=\(productID)")
            throw WalletIAPError.verificationFailed
        }
    }

    private func resolveProduct(productID: String) async throws -> Product {
        if let cached = cachedProducts[productID] {
            log("resolveProduct hit cache productID=\(productID)")
            return cached
        }
        log("resolveProduct fetching from StoreKit productID=\(productID)")
        do {
            let products = try await Product.products(for: [productID])
            log("resolveProduct fetched StoreKit ids=\(products.map(\.id).joined(separator: ", "))")
            guard let product = products.first else {
                log("resolveProduct no StoreKit product returned for productID=\(productID)")
                throw WalletIAPError.productNotFound
            }
            cachedProducts[productID] = product
            return product
        } catch {
            log("resolveProduct StoreKit request failed productID=\(productID), error=\(error.localizedDescription)")
            throw error
        }
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw WalletIAPError.verificationFailed
        }
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[WalletIAP] \(message)")
        #endif
    }
}
