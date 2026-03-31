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
        let products = try await Product.products(for: ids)
        cachedProducts = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return productIDs.compactMap { cachedProducts[$0] }
    }

    func purchase(productID: String) async throws {
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
        case .pending:
            throw WalletIAPError.pending
        case .userCancelled:
            throw WalletIAPError.userCancelled
        @unknown default:
            throw WalletIAPError.verificationFailed
        }
    }

    private func resolveProduct(productID: String) async throws -> Product {
        if let cached = cachedProducts[productID] {
            return cached
        }
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw WalletIAPError.productNotFound
        }
        cachedProducts[productID] = product
        return product
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw WalletIAPError.verificationFailed
        }
    }
}
