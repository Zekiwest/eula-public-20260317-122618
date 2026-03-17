import SwiftUI
import StoreKit

struct WalletRechargeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarHiddenBinding) private var tabBarHiddenBinding
    @State private var selectedOptionIndex: Int = 0
    @State private var coins: Int?
    @State private var isLoadingCoins = false
    @State private var isLoadingProducts = false
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var productPriceByID: [String: String] = [:]

    private let options: [WalletOption] = MockWallet.rechargeOptions

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / 375, proxy.size.height / 812)

            AppScreen {
                ZStack(alignment: .top) {
                    AppScrollView(showsIndicators: false) {
                        VStack(spacing: 24 * scale) {
                            ZStack(alignment: .leading) {
                                Image("wallet_bg_new")
                                    .resizable()
                                    .frame(width: 343 * scale, height: 100 * scale)
                                
                                HStack(spacing: 21 * scale) {
                                    Text("Wallet Balance:")
                                        .font(.system(size: 20 * scale, weight: .semibold))
                                        .foregroundStyle(Color(hexString: "FF8796"))
                                    
                                    HStack(spacing: 9 * scale) {
                                        Image("coin_icon_ref")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 44 * scale, height: 44 * scale)
                                        
                                        Text(balanceText)
                                            .font(.custom("Notable-Regular", size: 16 * scale))
                                            .foregroundStyle(Color(hexString: "333333"))
                                    }
                                }
                                .padding(.leading, 20 * scale)
                                .offset(y: 2 * scale)
                            }
                            .frame(width: 343 * scale, height: 100 * scale)

                            LazyVGrid(
                                columns: [
                                    GridItem(.fixed(105 * scale), spacing: 14 * scale),
                                    GridItem(.fixed(105 * scale), spacing: 14 * scale),
                                    GridItem(.fixed(105 * scale), spacing: 14 * scale)
                                ],
                                spacing: 32 * scale
                            ) {
                                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                                    WalletOptionCard(
                                        scale: scale,
                                        option: option,
                                        priceText: priceText(for: option),
                                        isSelected: index == selectedOptionIndex,
                                        onTap: {
                                            selectedOptionIndex = index
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16 * scale)

                            WalletRechargeButton(
                                scale: scale,
                                isLoading: isPurchasing,
                                isDisabled: isPurchasing || isRestoring || isLoadingProducts || options.isEmpty
                            ) {
                                Task {
                                    await purchaseSelectedOption()
                                }
                            }

                            VStack(spacing: 10 * scale) {
                                Text("All top-ups are consumable digital credits.")
                                    .font(.system(size: 12 * scale, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20 * scale)

                                Button(isRestoring ? "Restoring..." : "Restore Purchases") {
                                    Task {
                                        await restorePurchases()
                                    }
                                }
                                .font(.system(size: 14 * scale, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(height: 36 * scale)
                                .padding(.horizontal, 16 * scale)
                                .background(Color.white.opacity(0.15))
                                .clipShape(.rect(cornerRadius: 18 * scale, style: .continuous))
                                .disabled(isRestoring || isPurchasing)
                                .opacity((isRestoring || isPurchasing) ? 0.7 : 1)
                                .accessibilityIdentifier("wallet_restore_purchases_button")
                            }
                        }
                        .padding(.top, 66)
                        .padding(.bottom, 40 * scale)
                    }

                    topBar(scale: scale)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadCoinsIfNeeded()
            await loadProductsIfNeeded()
        }
        .toast()
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = true
            }
        }
        .onDisappear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                tabBarHiddenBinding?.wrappedValue = false
            }
        }
    }

    private var balanceText: String {
        if let coins {
            return String(coins)
        }
        return isLoadingCoins ? "..." : "--"
    }

    private func priceText(for option: WalletOption) -> String {
        productPriceByID[option.productID] ?? option.price
    }

    @MainActor
    private func loadProductsIfNeeded() async {
        if isLoadingProducts {
            return
        }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let productIDs = options.map(\.productID)
            let products = try await WalletIAPService.shared.loadProducts(productIDs: productIDs)
            productPriceByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0.displayPrice) })
        } catch {
            ToastManager.shared.show("Failed to load in-app purchase products")
        }
    }

    @MainActor
    private func purchaseSelectedOption() async {
        if isPurchasing || options.isEmpty {
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        let selectedOption = options[selectedOptionIndex]
        do {
            try await WalletIAPService.shared.purchase(productID: selectedOption.productID)
            ToastManager.shared.show("Top-up successful")
            await loadCoinsIfNeeded()
        } catch WalletIAPError.userCancelled {
        } catch WalletIAPError.pending {
            ToastManager.shared.show("Payment is pending")
        } catch WalletIAPError.productNotFound {
            ToastManager.shared.show("Product unavailable")
        } catch {
            ToastManager.shared.show("Top-up failed, please try again later")
        }
    }

    @MainActor
    private func loadCoinsIfNeeded() async {
        if isLoadingCoins {
            return
        }
        isLoadingCoins = true
        defer { isLoadingCoins = false }

        do {
            coins = try await ChatBackend.shared.walletBalance()
        } catch {
            coins = nil
        }
    }

    @MainActor
    private func restorePurchases() async {
        if isRestoring || isPurchasing {
            return
        }
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await WalletIAPService.shared.restorePurchases()
            ToastManager.shared.show("Purchases restored")
            await loadCoinsIfNeeded()
        } catch {
            ToastManager.shared.show("Unable to restore purchases right now")
        }
    }

    private func topBar(scale: CGFloat) -> some View {
        HStack(spacing: 20 * scale) {
            AppBackButton(action: { dismiss() })

            Text("My Wallet")
                .font(.custom("Notable-Regular", size: 20 * scale))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.leading, 16)
        .padding(.top, 10)
        .padding(.trailing, 32)
    }
}

struct WalletOptionCard: View {
    let scale: CGFloat
    let option: WalletOption
    let priceText: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [Color(hexString: "FF8796").opacity(0), Color(hexString: "FF8796")]
                                : [Color.white.opacity(0), Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0), Color.white],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1 * scale
                                )
                        }
                    }

                VStack(spacing: 0) {
                    VStack(spacing: 2 * scale) {
                        Image("coin_icon_ref")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30 * scale, height: 30 * scale)

                        Text(option.coins)
                            .font(.custom("Notable-Regular", size: 16 * scale))
                            .foregroundStyle(.white)
                    }
                    .offset(y: -13 * scale)

                    Spacer(minLength: 0)

                    Text(priceText)
                        .font(.system(size: 14 * scale, weight: .regular))
                        .foregroundStyle(isSelected ? Color(hexString: "FF8796") : .white)
                        .frame(width: 87 * scale, height: 31 * scale)
                        .background {
                            if isSelected {
                                Color.white
                            } else {
                                LinearGradient(
                                    colors: [Color(hexString: "FF8796"), Color(hexString: "F7B257")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                        .clipShape(.rect(cornerRadius: 20 * scale, style: .continuous))
                        .padding(.bottom, 6 * scale)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 105 * scale, height: 87 * scale)
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.96, opacity: 0.9))
        .padding(.top, 10)
    }
    
}

struct WalletRechargeButton: View {
    let scale: CGFloat
    let isLoading: Bool
    let isDisabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(isLoading ? "Processing..." : "Recharge")
                    .font(.custom("Notable-Regular", size: 16 * scale))
                    .foregroundStyle(.white)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(width: 238 * scale, height: 58 * scale)
            .background(
                RoundedRectangle(cornerRadius: 40 * scale)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 255/255, green: 135/255, blue: 150/255), location: 0.32),
                                .init(color: Color(red: 247/255, green: 178/255, blue: 87/255), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40 * scale)
                            .stroke(Color.white.opacity(0.25), lineWidth: 4 * scale)
                            .blur(radius: 4 * scale)
                            .mask(
                                RoundedRectangle(cornerRadius: 40 * scale)
                                    .fill(
                                        LinearGradient(
                                            colors: [.black, .clear, .black],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 40 * scale))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 40 * scale)
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 2 * scale)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 4 * scale, x: 0, y: 4 * scale)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.7 : 1)
    }
}

struct WalletRechargeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
    WalletRechargeView()
}
    }
}
