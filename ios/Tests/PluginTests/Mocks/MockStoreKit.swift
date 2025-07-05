import Foundation
import StoreKit

// MARK: - StoreKit 1 Mocks

class MockSKProduct: SKProduct {
    private let mockProductIdentifier: String
    private let mockLocalizedTitle: String
    private let mockLocalizedDescription: String
    private let mockPrice: NSDecimalNumber
    private let mockPriceLocale: Locale
    
    override var productIdentifier: String { return mockProductIdentifier }
    override var localizedTitle: String { return mockLocalizedTitle }
    override var localizedDescription: String { return mockLocalizedDescription }
    override var price: NSDecimalNumber { return mockPrice }
    override var priceLocale: Locale { return mockPriceLocale }
    
    init(
        productIdentifier: String,
        localizedTitle: String,
        localizedDescription: String,
        price: NSDecimalNumber,
        priceLocale: Locale
    ) {
        self.mockProductIdentifier = productIdentifier
        self.mockLocalizedTitle = localizedTitle
        self.mockLocalizedDescription = mockLocalizedDescription
        self.mockPrice = price
        self.mockPriceLocale = priceLocale
        super.init()
    }
}

class MockSKPaymentQueue: SKPaymentQueue {
    var mockTransactions: [SKPaymentTransaction] = []
    var mockStorefront: SKStorefront?
    var addPaymentCalled = false
    var finishTransactionCalled = false
    var restoreTransactionsCalled = false
    var lastPayment: SKPayment?
    var lastFinishedTransaction: SKPaymentTransaction?
    
    override func add(_ payment: SKPayment) {
        addPaymentCalled = true
        lastPayment = payment
        
        let transaction = MockSKPaymentTransaction(
            payment: payment,
            transactionIdentifier: UUID().uuidString,
            transactionState: .purchased
        )
        mockTransactions.append(transaction)
        
        if let observer = transactionObservers.first {
            observer.paymentQueue(self, updatedTransactions: [transaction])
        }
    }
    
    override func finishTransaction(_ transaction: SKPaymentTransaction) {
        finishTransactionCalled = true
        lastFinishedTransaction = transaction
        mockTransactions.removeAll { $0.transactionIdentifier == transaction.transactionIdentifier }
    }
    
    override func restoreCompletedTransactions() {
        restoreTransactionsCalled = true
        
        if let observer = transactionObservers.first {
            observer.paymentQueueRestoreCompletedTransactionsFinished(self)
        }
    }
    
    override var storefront: SKStorefront? {
        return mockStorefront
    }
    
    private var transactionObservers: [SKPaymentTransactionObserver] = []
    
    override func add(_ observer: SKPaymentTransactionObserver) {
        transactionObservers.append(observer)
    }
    
    override func remove(_ observer: SKPaymentTransactionObserver) {
        transactionObservers.removeAll { $0 === observer }
    }
}

class MockSKPaymentTransaction: SKPaymentTransaction {
    private let mockPayment: SKPayment
    private let mockTransactionIdentifier: String?
    private let mockTransactionState: SKPaymentTransactionState
    private let mockError: Error?
    private let mockTransactionDate: Date
    
    override var payment: SKPayment { return mockPayment }
    override var transactionIdentifier: String? { return mockTransactionIdentifier }
    override var transactionState: SKPaymentTransactionState { return mockTransactionState }
    override var error: Error? { return mockError }
    override var transactionDate: Date? { return mockTransactionDate }
    
    init(
        payment: SKPayment,
        transactionIdentifier: String?,
        transactionState: SKPaymentTransactionState,
        error: Error? = nil,
        transactionDate: Date = Date()
    ) {
        self.mockPayment = payment
        self.mockTransactionIdentifier = transactionIdentifier
        self.mockTransactionState = transactionState
        self.mockError = error
        self.mockTransactionDate = transactionDate
        super.init()
    }
}

// MARK: - StoreKit 2 Mocks

@available(iOS 15.0, *)
class MockProduct: Product {
    private let mockId: String
    private let mockDisplayName: String
    private let mockDescription: String
    private let mockPrice: Decimal
    private let mockDisplayPrice: String
    private let mockCurrencyCode: String
    
    override var id: String { return mockId }
    override var displayName: String { return mockDisplayName }
    override var description: String { return mockDescription }
    override var price: Decimal { return mockPrice }
    override var displayPrice: String { return mockDisplayPrice }
    override var priceFormatStyle: Product.PriceFormatStyle {
        return MockPriceFormatStyle(currencyCode: mockCurrencyCode)
    }
    
    init(
        id: String,
        displayName: String,
        description: String,
        price: Decimal,
        displayPrice: String,
        currencyCode: String
    ) {
        self.mockId = id
        self.mockDisplayName = displayName
        self.mockDescription = description
        self.mockPrice = price
        self.mockDisplayPrice = displayPrice
        self.mockCurrencyCode = currencyCode
        super.init()
    }
    
    override func purchase(options: Set<Product.PurchaseOption> = []) async throws -> Product.PurchaseResult {
        return .success(MockTransaction(productID: id))
    }
}

@available(iOS 15.0, *)
class MockPriceFormatStyle: Product.PriceFormatStyle {
    private let mockCurrencyCode: String
    
    var currencyCode: String { return mockCurrencyCode }
    var currencySymbol: String? { return "$" }
    
    init(currencyCode: String) {
        self.mockCurrencyCode = currencyCode
        super.init()
    }
}

@available(iOS 15.0, *)
class MockTransaction: Transaction {
    private let mockId: UInt64 = UInt64.random(in: 1...1000)
    private let mockProductID: String
    private let mockPurchaseDate: Date = Date()
    private let mockPurchaseState: Transaction.PurchaseState = .purchased
    
    override var id: UInt64 { return mockId }
    override var productID: String { return mockProductID }
    override var purchaseDate: Date { return mockPurchaseDate }
    override var purchaseState: Transaction.PurchaseState { return mockPurchaseState }
    
    init(productID: String) {
        self.mockProductID = productID
        super.init()
    }
    
    override func finish() async { }
}

@available(iOS 15.0, *)
class MockAppStore {
    static var syncCalled = false
    static var shouldSucceed = true
    
    static func sync() async throws {
        syncCalled = true
        if !shouldSucceed {
            throw NSError(domain: "MockAppStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock sync error"])
        }
    }
}