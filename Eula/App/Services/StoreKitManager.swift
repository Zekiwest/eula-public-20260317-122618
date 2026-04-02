//
//  StoreKitManager.swift
//  SwiftUI-demo2
//
//  StoreKit 2 内购支付工具类
//

import Combine
import Foundation
import StoreKit

// MARK: - 购买状态

enum PurchaseState {
    case idle
    case purchasing
    case purchased
    case failed
    case restored
    case pending
}

// MARK: - 产品信息模型

struct IAPProduct: Identifiable {
    let id: String
    let localizedTitle: String
    let localizedDescription: String
    let displayPrice: String
    let product: Product
    
    init(product: Product) {
        id = product.id
        localizedTitle = product.displayName
        localizedDescription = product.description
        displayPrice = product.displayPrice
        self.product = product
    }
}

// MARK: - 交易信息

struct TransactionInfo: Identifiable {
    let id: UInt64
    let productId: String
    let purchaseDate: Date
    let revocationDate: Date?
    let isUpgraded: Bool
    
    init(verificationResult: VerificationResult<Transaction>) {
        switch verificationResult {
        case let .verified(transaction):
            id = transaction.id
            productId = transaction.productID
            purchaseDate = transaction.purchaseDate
            revocationDate = transaction.revocationDate
            isUpgraded = transaction.isUpgraded
        case let .unverified(transaction, _):
            id = transaction.id
            productId = transaction.productID
            purchaseDate = transaction.purchaseDate
            revocationDate = transaction.revocationDate
            isUpgraded = transaction.isUpgraded
        }
    }
}

// MARK: - 支付结果回调

/// 购买成功回调
/// - Parameter transaction: 交易对象
typealias PurchaseSuccessCallback = (Transaction) -> Void

/// 购买失败回调
/// - Parameter error: 错误信息
typealias PurchaseFailureCallback = (Error) -> Void

/// 恢复购买成功回调
typealias RestoreSuccessCallback = () -> Void

/// 恢复购买失败回调
/// - Parameter error: 错误信息
typealias RestoreFailureCallback = (Error) -> Void

// MARK: - StoreKit 管理器

class StoreKitManager: ObservableObject {
    // MARK: - Published 属性
    
    @Published var products: [IAPProduct] = []
    @Published var purchaseState: PurchaseState = .idle
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var purchasedProductIds: Set<String> = []
    @Published var transactions: [TransactionInfo] = []
    
    // MARK: - 回调属性
    
    var onPurchaseSuccess: PurchaseSuccessCallback?
    var onPurchaseFailure: PurchaseFailureCallback?
    var onRestoreSuccess: RestoreSuccessCallback?
    var onRestoreFailure: RestoreFailureCallback?
    
    // MARK: - 私有属性
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - 单例
    
    static let shared = StoreKitManager()
    
    private init() {
        // 监听交易更新
        updateListenerTask = listenForTransactions()
        
        // 加载当前权益状态
        Task {
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 公开方法
    
    /// 获取产品列表
    /// - Parameter productIds: 产品 ID 数组
    @MainActor
    func fetchProducts(productIds: Set<String>) async {
        guard !productIds.isEmpty else {
            errorMessage = "产品 ID 列表为空"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIds)
            products = storeProducts.map { IAPProduct(product: $0) }
            isLoading = false
        } catch {
            errorMessage = "获取产品失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    @MainActor
    func purchaseProduct(productId: String) {
        Task {
            do {
                guard let iapProduct = self.products.first(where: { $0.id == productId }) else {
                    ToastManager.shared.show("Product not found")
                    onPurchaseFailure?(StoreError.productNotFound)
                    return
                }

                print("💰 开始购买: \(productId) ")

                let transaction = try await self.purchase(product: iapProduct)

                await handlePurchaseSuccess(transaction)

                print("✅ 购买成功 - Transaction ID: \(transaction.id)")

            } catch let error as StoreError {
                print("❌ 购买失败: \(error.localizedDescription)")
                onPurchaseFailure?(error)
            } catch {
                print("❌ 购买失败: \(error.localizedDescription)")
                onPurchaseFailure?(error)
            }
        }
    }

    private func handlePurchaseSuccess(_ transaction: Transaction) async {
        do {
            try await AppStore.sync()

            let receiptData = await AppStore.receiptBase64()
            let isXcodeEnv = transaction.environment.rawValue == "Xcode"

            let transactionID = transaction.id == 0
                ? String(transaction.originalID)
                : String(transaction.id)

            let originalID = String(transaction.originalID)

            print("[StoreKit] handlePurchaseSuccess transactionID=\(transactionID), originalID=\(originalID), hasReceipt=\(receiptData != nil), environment=\(transaction.environment.rawValue)")

            do {
                try await H5PaymentService.shared.submitSuccessfulOrder(
                    transactionID: transactionID,
                    receiptData: receiptData
                )
            } catch {
                print("[StoreKit] payment validation failed: \(error.localizedDescription)")
                ToastManager.shared.show("Payment completed but server validation failed")
                return
            }

            do {
                _ = try await ChatBackend.shared.applyWalletTopup(
                    productID: transaction.productID,
                    transactionID: transactionID,
                    originalTransactionID: originalID
                )
                ToastManager.shared.show("Top-up successful")
            } catch {
                print("[StoreKit] crediting failed: \(error.localizedDescription)")
                ToastManager.shared.show("Payment verified but crediting failed")
                return
            }

            print("[StoreKit] purchase finished successfully")

        } catch {
            print("[StoreKit] handlePurchaseSuccess failed: \(error.localizedDescription)")
        }
    }
    
    /// 购买产品
    /// - Parameter product: 要购买的产品
    /// - Returns: 购买结果
    @MainActor
    func purchase(product: IAPProduct) async throws -> Transaction {
        purchaseState = .purchasing
        errorMessage = nil
        
        do {
            let result = try await product.product.purchase()
            
            switch result {
            case let .success(verificationResult):
                // 验证交易
                let transaction = try checkVerified(verificationResult)
                
                // 更新购买状态
                await updatePurchasedProducts()
                
                // 完成交易
                await transaction.finish()
                
                purchaseState = .purchased
                
                // ✅ 调用成功回调
                onPurchaseSuccess?(transaction)
                
                return transaction
                
            case .userCancelled:
                purchaseState = .failed
                errorMessage = "支付已取消"
                let error = StoreError.userCancelled
                
                // ✅ 调用失败回调
                onPurchaseFailure?(error)
                
                throw error
                
            case .pending:
                purchaseState = .pending
                errorMessage = "购买需要家长批准，请稍后查看"
                let error = StoreError.pending
                
                // ✅ 调用失败回调
                onPurchaseFailure?(error)
                
                throw error
                
            @unknown default:
                purchaseState = .failed
                errorMessage = "未知错误"
                let error = StoreError.unknown
                
                // ✅ 调用失败回调
                onPurchaseFailure?(error)
                
                throw error
            }
        } catch {
            purchaseState = .failed
            errorMessage = "购买失败: \(error.localizedDescription)"
            
            // ✅ 调用失败回调（如果不是已知错误）
            if !(error is StoreError) {
                onPurchaseFailure?(error)
            }
            
            throw error
        }
    }
    
    /// 恢复购买
    @MainActor
    func restorePurchases() async {
        purchaseState = .purchasing
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            purchaseState = .restored
            errorMessage = "恢复成功"
            
            // ✅ 调用恢复成功回调
            onRestoreSuccess?()
            
        } catch {
            purchaseState = .failed
            errorMessage = "恢复失败: \(error.localizedDescription)"
            
            // ✅ 调用恢复失败回调
            onRestoreFailure?(error)
        }
    }
    
    /// 检查是否已购买某个产品
    /// - Parameter productId: 产品 ID
    /// - Returns: 是否已购买
    func isPurchased(productId: String) -> Bool {
        return purchasedProductIds.contains(productId)
    }
    
    /// 检查产品是否有权益（未过期、未撤销）
    /// - Parameter productId: 产品 ID
    /// - Returns: 是否有权益
    @MainActor
    func hasEntitlement(for productId: String) async -> Bool {
        // 获取当前权益
        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result,
               transaction.productID == productId,
               transaction.revocationDate == nil
            {
                return true
            }
        }
        return false
    }
    
    /// 获取所有交易历史
    @MainActor
    func loadTransactionHistory() async {
        var transactionList: [TransactionInfo] = []
        
        for await result in Transaction.all {
            let info = TransactionInfo(verificationResult: result)
            transactionList.append(info)
        }
        
        transactions = transactionList.sorted { $0.purchaseDate > $1.purchaseDate }
    }
    
    // MARK: - 私有方法
    
    /// 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // 更新购买状态
                    await self.updatePurchasedProducts()
                    
                    // 完成交易
                    await transaction.finish()
                } catch {
                    print("交易验证失败: \(error)")
                }
            }
        }
    }
    
    /// 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case let .verified(safe):
            return safe
        }
    }
    
    /// 更新已购买的产品列表
    @MainActor
    private func updatePurchasedProducts() async {
        var purchasedIds: Set<String> = []
        
        // 获取当前所有权益
        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result,
               transaction.revocationDate == nil
            {
                purchasedIds.insert(transaction.productID)
            }
        }
        
        purchasedProductIds = purchasedIds
    }
}

// MARK: - 错误类型

enum StoreError: LocalizedError {
    case failedVerification
    case userCancelled
    case pending
    case productNotFound
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "交易验证失败"
        case .userCancelled:
            return "用户取消购买"
        case .pending:
            return "购买等待审批"
        case .productNotFound:
            return "Product not found"
        case .unknown:
            return "未知错误"
        }
    }
}

/* 使用示例
 
 ## 基本用法
 
 ```swift
 struct ProductView: View {
 @StateObject private var storeManager = StoreKitManager.shared
 @EnvironmentObject var appState: AppState
 
 var body: some View {
 VStack {
 // 你的 UI
 }
 .onAppear {
 setupCallbacks()
 }
 }
 
 func setupCallbacks() {
 // ✅ 设置购买成功回调
 storeManager.onPurchaseSuccess = { transaction in
 print("✅ 购买成功: \(transaction.id)")
 
 // 刷新 WebView
 appState.reloadTrigger = true
 
 // 显示成功提示
 showSuccessAlert()
 
 // 上报后端
 uploadPurchaseToServer(transaction)
 }
 
 // ✅ 设置购买失败回调
 storeManager.onPurchaseFailure = { error in
 print("❌ 购买失败: \(error.localizedDescription)")
 
 // 显示错误提示
 showErrorAlert(error)
 }
 
 // ✅ 设置恢复购买成功回调
 storeManager.onRestoreSuccess = {
 print("✅ 恢复购买成功")
 showRestoreSuccessAlert()
 }
 
 // ✅ 设置恢复购买失败回调
 storeManager.onRestoreFailure = { error in
 print("❌ 恢复失败: \(error.localizedDescription)")
 showErrorAlert(error)
 }
 }
 }
 ```
 
 ## 购买流程
 
 ```swift
 Task {
 do {
 // 1. 获取产品列表
 await storeManager.fetchProducts(productIds: ["com.app.product1"])
 
 // 2. 开始购买
 if let product = storeManager.products.first {
 let transaction = try await storeManager.purchase(product: product)
 // 购买成功后，回调会自动触发
 }
 } catch {
 // 错误处理（回调也会触发）
 print("购买失败: \(error)")
 }
 }
 ```
 
 ## 恢复购买
 
 ```swift
 Button("恢复购买") {
 Task {
 await storeManager.restorePurchases()
 // 恢复结果会通过回调通知
 }
 }
 ```
 
 ## 回调时机
 
 - `onPurchaseSuccess`: 购买成功并验证通过后触发
 - `onPurchaseFailure`: 购买失败、用户取消、验证失败时触发
 - `onRestoreSuccess`: 恢复购买成功后触发
 - `onRestoreFailure`: 恢复购买失败时触发
 
 ## 注意事项
 
 1. 回调会在 MainActor 上执行，可以直接更新 UI
 2. 购买成功后，`purchase()` 方法仍会返回 transaction
 3. 购买失败时，会同时触发回调和抛出异常
 4. 回调是可选的，如果不设置不会影响功能
 5. 建议在 `onAppear` 中设置回调，避免重复设置
 
 */
