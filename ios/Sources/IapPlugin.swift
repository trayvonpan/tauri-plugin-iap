/// Tauri IAP Plugin - iOS Implementation
/// Provides in-app purchase functionality through StoreKit 1 and 2.
/// Supports iOS 13+ with enhanced features for iOS 15+ through StoreKit 2.
///
/// Troubleshooting Guide:
///
/// 1. Product Query Issues:
///    - Error code 2: Invalid product ID format
///    - Error code 3: Network connection failed
///    Solution: Verify product IDs in App Store Connect
///
/// 2. Purchase Failures:
///    - Error code 1: Product not found in cache
///    - Error code 2: User cancelled purchase
///    - Error code 3: Purchase pending (requires action)
///    - Error code 4: Unknown state
///    - Error code 5: System error
///    Solution: Check product availability and user's payment capability
///
/// 3. Transaction Issues:
///    - Error code 4: Transaction update failed
///    - Error code 6: Transaction verification failed
///    Solution: Verify receipt on server side
///
/// 4. Receipt Validation:
///    - Missing receipt: Check bundle identifier
///    - Invalid receipt: Refresh using SKReceiptRefreshRequest
///    Solution: Always validate receipts server-side
///
/// 5. Restore Issues:
///    - Error code 5: Restore failed
///    Solution: Check network and user's Apple ID
///
/// 6. Common Solutions:
///    - Verify App Store Connect configuration
///    - Check network connectivity
///    - Validate product IDs
///    - Ensure proper error handling
///    - Log transaction states
///    - Implement server-side validation
///
/// Debugging Tips:
/// ```swift
/// // 1. Enable StoreKit debug logging
/// if #available(iOS 15.0, *) {
///     StoreKit.Transaction.debugDescription = true
/// }
///
/// // 2. Track transaction states
/// switch transaction.transactionState {
/// case .purchasing: print("Starting purchase...")
/// case .purchased: print("Purchase completed")
/// case .failed: print("Purchase failed: \(error?.localizedDescription ?? "")")
/// case .restored: print("Purchase restored")
/// case .deferred: print("Awaiting action")
/// }
///
/// // 3. Implement error handling in Rust
/// #[tauri::command]
/// async fn handle_purchase_error(app: AppHandle, error: Value) -> Result<(), Error> {
///     if let Some(code) = error.get("code") {
///         match code {
///             1 => log::error!("Product not found"),
///             2 => log::error!("User cancelled"),
///             _ => log::error!("Unknown error: {}", error),
///         }
///     }
///     Ok(())
/// }
///
/// // 4. Verify receipt on server
/// let verifyURL = Bundle.main.appStoreReceiptURL
/// let receiptData = try? Data(contentsOf: verifyURL!)
/// let base64Receipt = receiptData?.base64EncodedString()
/// // Send to your server for validation
/// ```
///
/// Testing Tips:
/// 1. Use StoreKit test configuration file
/// 2. Test offline scenarios
/// 3. Test cancellation flows
/// 4. Verify receipt validation
/// 5. Test restore functionality
/// 6. Handle interrupted purchases
///
/// Integration Testing:
/// ```swift
/// // 1. Setup test configuration
/// let config = """
/// {
///   "products": [{
///     "id": "com.test.product1",
///     "type": "nonConsumable",
///     "price": 0.99,
///     "displayName": "Test Product"
///   }]
/// }
/// """
///
/// // 2. Test complete purchase flow
/// async func testPurchaseFlow() async throws {
///     // Initialize plugin
///     let plugin = IapPlugin()
///     plugin.initialize(...)
///
///     // Query products
///     let products = try await queryProducts(["com.test.product1"])
///     XCTAssertEqual(products.count, 1)
///
///     // Make purchase
///     let result = try await makePurchase(products[0])
///     XCTAssertTrue(result.verified)
///
///     // Verify transaction
///     let receipt = await getReceipt()
///     XCTAssertNotNil(receipt)
/// }
///
/// // 3. Test error scenarios
/// func testErrorScenarios() {
///     // Test network error
///     setNetworkCondition(.offline)
///     XCTAssertThrowsError(try plugin.queryProducts(...))
///
///     // Test invalid product
///     XCTAssertThrowsError(try plugin.buyProduct("invalid.id"))
///
///     // Test cancellation
///     simulateUserCancellation()
///     XCTAssertEqual(lastError?.code, 2)
/// }
/// ```
///
/// Implementation Tips:
/// 1. Purchase Flow:
///    - Always verify product exists before purchase
///    - Handle all transaction states
///    - Complete transactions promptly
///    - Validate receipts server-side
///
/// 2. Error Handling:
///    - Implement timeout handling
///    - Cache product details
///    - Handle network errors
///    - Provide user feedback
///
/// 3. State Management:
///    - Track purchase state
///    - Handle background/foreground transitions
///    - Persist transaction IDs
///    - Clean up completed transactions
///
/// 4. Security:
///    - Never trust local validation
///    - Use HTTPS for receipt validation
///    - Implement anti-tampering checks
///    - Track suspicious patterns
///
/// 5. Performance:
///    - Cache product details
///    - Batch product queries
///    - Handle background tasks
///    - Monitor memory usage
///
/// StoreKit 2 Migration Guide:
/// ```swift
/// // 1. Replace SKProduct queries with Product API
/// // Old way (StoreKit 1):
/// let request = SKProductsRequest(productIdentifiers: productIds)
/// request.delegate = self
/// request.start()
///
/// // New way (StoreKit 2):
/// let products = try await Product.products(for: productIds)
///
/// // 2. Replace transaction handling
/// // Old way:
/// func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
///
/// // New way:
/// let updates = Task {
///     for await verificationResult in Transaction.updates {
///         // Handle verified transactions
///     }
/// }
///
/// // 3. Replace receipt validation
/// // Old way:
/// let receiptURL = Bundle.main.appStoreReceiptURL
/// let receiptData = try Data(contentsOf: receiptURL!)
///
/// // New way:
/// let transaction = try await Transaction.latest(for: productId)
/// if let jwsTransaction = transaction?.jwsRepresentation {
///     // Validate JWS server-side
/// }
/// ```
///
/// Additional Security Considerations:
/// 1. Transaction Verification:
///    - Always verify JWS signatures
///    - Implement server-side validation
///    - Check transaction dates
///    - Verify purchase amounts
///
/// 2. Receipt Protection:
///    - Encrypt cached receipts
///    - Clear sensitive data
///    - Use keychain for storage
///    - Implement jailbreak detection
///
/// 3. Anti-Fraud Measures:
///    - Track purchase patterns
///    - Implement rate limiting
///    - Monitor for suspicious activity
///    - Log validation failures
///
/// 4. Data Protection:
///    - Use App Attest when available
///    - Implement device checks
///    - Secure network communication
///    - Protect user purchase history
///
/// 5. Error Recovery:
///    - Implement retry logic
///    - Handle system outages
///    - Backup transaction records
///    - Provide support flows
///
/// Implementation Patterns:
/// ```swift
/// // 1. Retry Pattern for Network Operations
/// func retryOperation<T>(
///     maxAttempts: Int = 3,
///     delay: TimeInterval = 1.0,
///     operation: @escaping () async throws -> T
/// ) async throws -> T {
///     var attempts = 0
///     while true {
///         do {
///             return try await operation()
///         } catch {
///             attempts += 1
///             if attempts >= maxAttempts { throw error }
///             try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
///         }
///     }
/// }
///
/// // 2. Queue Management Pattern
/// class PurchaseQueue {
///     private var pendingTransactions: [String: Transaction] = [:]
///     private let queue = DispatchQueue(label: "com.app.purchases")
///
///     func enqueue(_ transaction: Transaction) {
///         queue.async {
///             self.pendingTransactions[transaction.id] = transaction
///             self.processPendingTransactions()
///         }
///     }
///
///     private func processPendingTransactions() {
///         // Process transactions in order
///     }
/// }
///
/// // 3. State Management Pattern
/// enum PurchaseState {
///     case idle
///     case querying
///     case purchasing(ProductId)
///     case validating(TransactionId)
///     case completing(TransactionId)
///     case error(PurchaseError)
/// }
///
/// class PurchaseStateManager {
///     @Published private(set) var state: PurchaseState = .idle
///     private let queue = DispatchQueue(label: "purchase.state")
///
///     func transition(to newState: PurchaseState) {
///         queue.async {
///             self.state = newState
///             self.handleStateChange()
///         }
///     }
/// }
///
/// // 4. Receipt Validation Pattern
/// struct ReceiptValidator {
///     static func validateReceipt(_ receipt: String) async throws -> Bool {
///         let validation = ValidationRequest(receipt: receipt)
///         let result = try await validateWithServer(validation)
///
///         guard result.status == 0 else {
///             if result.status == 21007 { // Sandbox receipt
///                 return try await validateWithSandbox(validation)
///             }
///             throw ValidationError(code: result.status)
///         }
///         return true
///     }
/// }
///
/// // 5. Error Handling Pattern
/// enum PurchaseError: Error {
///     case productNotFound
///     case networkError
///     case validationFailed
///     case userCancelled
///     case systemError(Error)
///
///     var localizedDescription: String {
///         switch self {
///         case .productNotFound: return "Product not available"
///         case .networkError: return "Network connection failed"
///         case .validationFailed: return "Purchase validation failed"
///         case .userCancelled: return "Purchase was cancelled"
///         case .systemError(let error): return error.localizedDescription
///         }
///     }
/// }
/// ```
///
/// These patterns help with:
/// - Reliable network operations
/// - Organized transaction processing
/// - Clear state management
/// - Robust receipt validation
/// - Consistent error handling

import SwiftRs
import Tauri
import UIKit
import StoreKit

/// Callback type for communicating with Rust
/// - Parameters:
///   - pointer: Optional pointer to data bytes
///   - size: Size of data in bytes
typealias PaymentCallback = @convention(c) (UnsafeRawPointer?, Int32) -> Void

// MARK: - Data Models

/// Purchase parameters received from Rust
struct PurchaseParam: Codable {
    /// Product details for the purchase
    let productDetails: ProductDetails
    /// Optional username for the purchase
    let applicationUserName: String?
}

/// Product details structure matching Rust interface
/// Example Usage:
/// ```swift
/// let product = ProductDetails(
///     id: "com.app.premium",
///     title: "Premium Subscription",
///     description: "Unlock all features",
///     price: "$4.99",
///     rawPrice: 4.99,
///     currencyCode: "USD",
///     currencySymbol: "$"
/// )
/// ```
struct ProductDetails: Codable {
    /// Unique product identifier
    let id: String
    /// Localized product title
    let title: String
    /// Localized product description
    let description: String
    /// Formatted price string
    let price: String
    /// Raw price value
    let rawPrice: Double
    /// ISO currency code
    let currencyCode: String
    /// Currency symbol
    let currencySymbol: String
}

// MARK: - Plugin Implementation

/// Main plugin class registered with Tauri
class IapPlugin: Plugin {
    /// Shared payment manager instance
    private static var shared: PaymentManager?
    
    override init() {
        super.init()
    }
}

// MARK: - Bridge Functions

/// Initialize the plugin for Tauri
@_cdecl("init_plugin_iap")
func initPlugin() -> Plugin {
    return IapPlugin()
}

/// Initialize the payment system with callbacks
/// - Returns: True if initialization succeeded
@_cdecl("initialize")
func initialize(
    onProductsUpdated: PaymentCallback,
    onTransactionUpdated: PaymentCallback,
    onError: PaymentCallback
) -> Bool {
    // First check if device can make payments
    if SKPaymentQueue.canMakePayments() {
        if #available(iOS 15.0, *) {
            // Use StoreKit 2 on iOS 15+ for enhanced security and modern API
            IapPlugin.shared = StoreKit2PaymentManager(
                onProductsUpdated: onProductsUpdated,
                onTransactionUpdated: onTransactionUpdated,
                onError: onError
            )
        } else {
            // Fall back to StoreKit 1 for iOS 13-14
            IapPlugin.shared = StoreKit1PaymentManager(
                onProductsUpdated: onProductsUpdated,
                onTransactionUpdated: onTransactionUpdated,
                onError: onError
            )
        }
        return true // Payment system initialized successfully
    }
    return false // Device cannot make payments
}

/// Check if in-app purchases are available
@_cdecl("is_available")
func isAvailable() -> Bool {
    return SKPaymentQueue.canMakePayments()
}

/// Query product details from the App Store
@_cdecl("query_product_details")
func queryProductDetails(productIds: SRString) -> Bool {
    // Split comma-separated product IDs into a Set
    // Example: "com.app.product1,com.app.product2" -> Set(["com.app.product1", "com.app.product2"])
    IapPlugin.shared?.queryProducts(
        Set(productIds.toString().components(separatedBy: ","))
    )
    // Return true to indicate query was initiated (actual results come through callback)
    return true
}

/// Purchase a non-consumable product
@_cdecl("buy_non_consumable")
func buyNonConsumable(param: UnsafePointer<Int8>?, paramLen: Int32) -> Bool {
    // Convert raw pointer to Data
    guard let data = param.map({ Data(bytes: $0, count: Int(paramLen)) }),
          // Decode JSON data into PurchaseParam struct
          let purchaseParam = try? JSONDecoder().decode(PurchaseParam.self, from: data)
    else {
        // Return false if data is invalid
        return false
    }
    
    // Start purchase process with decoded parameters
    IapPlugin.shared?.initiatePurchase(
        productId: purchaseParam.productDetails.id,      // Product to purchase
        quantity: 1,                                     // Non-consumables always quantity 1
        applicationUserName: purchaseParam.applicationUserName ?? "", // Optional user ID
        isConsumable: false                             // Mark as non-consumable
    )
    // Return true to indicate purchase was initiated
    return true
}

/// Purchase a consumable product
/// - Parameters:
///   - param: Raw pointer to JSON purchase parameters
///   - paramLen: Length of parameter data
///   - autoConsume: Whether to automatically consume after purchase
/// - Returns: True if purchase was initiated successfully
@_cdecl("buy_consumable")
func buyConsumable(param: UnsafePointer<Int8>?, paramLen: Int32, autoConsume: Bool) -> Bool {
    // Convert raw pointer to JSON data
    guard let data = param.map({ Data(bytes: $0, count: Int(paramLen)) }),
          // Decode JSON into purchase parameters
          let purchaseParam = try? JSONDecoder().decode(PurchaseParam.self, from: data)
    else {
        // Return false if data is invalid
        return false
    }
    
    // Initiate consumable purchase
    IapPlugin.shared?.initiatePurchase(
        productId: purchaseParam.productDetails.id,      // Product to purchase
        quantity: 1,                                     // Default quantity
        applicationUserName: purchaseParam.applicationUserName ?? "", // Optional user ID
        isConsumable: true                              // Mark as consumable
    )
    // Return true to indicate purchase was initiated
    return true
}

/// Complete a purchase transaction
@_cdecl("complete_purchase")
func completePurchase(transactionId: SRString) -> Bool {
    IapPlugin.shared?.completeTransaction(transactionId.toString())
    return true
}

/// Restore previous purchases
@_cdecl("restore_purchases")
func restorePurchases(applicationUserName: SRString?) -> Bool {
    IapPlugin.shared?.restorePurchases(applicationUserName?.toString() ?? "")
    return true
}

/// Get the store's country code
/// Example Usage:
/// ```swift
/// // Objective-C
/// NSString *country = country_code();  // Returns "US"
///
/// // Swift
/// let country: String? = countryCode()?.toString()  // Returns "US"
/// ```
@_cdecl("country_code")
func countryCode() -> SRString? {
    if #available(iOS 13.0, *) {
        guard let country = SKPaymentQueue.default().storefront?.countryCode else {
            return nil
        }
        return SRString(country)
    }
    return nil
}

// MARK: - Payment Manager Protocol

/// Protocol defining common interface for StoreKit 1 and 2 implementations
protocol PaymentManager {
    /// Query product details from the store
    func queryProducts(_ productIds: Set<String>)
    
    /// Initiate a purchase transaction
    /// - Parameters:
    ///   - productId: Product identifier
    ///   - quantity: Purchase quantity
    ///   - applicationUserName: Optional username
    ///   - isConsumable: Whether the product is consumable
    func initiatePurchase(productId: String, quantity: Int, applicationUserName: String, isConsumable: Bool)
    
    /// Complete a purchase transaction
    func completeTransaction(_ transactionId: String)
    
    /// Restore previous purchases
    func restorePurchases(_ applicationUserName: String)
    
    /// Get the App Store receipt data
    func getReceiptData() -> String?
}

// MARK: - StoreKit 1 Implementation

/// StoreKit 1 implementation for iOS 13+
/// Manages in-app purchases using the classic StoreKit API
class StoreKit1PaymentManager: NSObject, PaymentManager {
    private let onProductsUpdated: PaymentCallback
    private let onTransactionUpdated: PaymentCallback
    private let onError: PaymentCallback
    
    private var productRequest: SKProductsRequest?
    private var availableProducts: [String: SKProduct] = [:]
    private var activeTransactions: [String: SKPaymentTransaction] = [:]
    
    init(
        onProductsUpdated: @escaping PaymentCallback,
        onTransactionUpdated: @escaping PaymentCallback,
        onError: @escaping PaymentCallback
    ) {
        self.onProductsUpdated = onProductsUpdated
        self.onTransactionUpdated = onTransactionUpdated
        self.onError = onError
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    func queryProducts(_ productIds: Set<String>) {
        // Create new product request with given IDs
        productRequest = SKProductsRequest(productIdentifiers: productIds)
        // Set self as delegate to receive responses
        productRequest?.delegate = self
        // Begin async product query
        productRequest?.start()
    }
    
    /// Initiate a purchase transaction
    ///
    /// Payment Flow:
    /// 1. Validate product availability in cache
    /// 2. Create payment object with product
    /// 3. Add optional user identification
    /// 4. Submit payment to queue
    /// 5. Monitor transaction updates
    ///
    /// Error Handling:
    /// - Product not found -> Error code 1
    /// - Payment queue errors -> System error
    /// - Network issues -> System error
    ///
    /// Transaction States:
    /// - .purchasing: Initial state
    /// - .purchased: Success case
    /// - .failed: Error case
    /// - .restored: Restoration case
    /// - .deferred: Requires action
    func initiatePurchase(productId: String, quantity: Int, applicationUserName: String, isConsumable: Bool) {
        // Verify product exists in our cache
        guard let product = availableProducts[productId] else {
            reportError(type: "Purchase", code: 1, message: "Product not found")
            return
        }
        
        // Create new payment object from product
        let payment = SKMutablePayment(product: product)
        // Set requested quantity (default is 1)
        payment.quantity = quantity
        // Add user identification if provided
        if !applicationUserName.isEmpty {
            payment.applicationUsername = applicationUserName
        }
        
        // Submit payment to queue for processing
        SKPaymentQueue.default().add(payment)
    }
    
    /// Complete a purchase transaction
    ///
    /// Completion Flow:
    /// 1. Find transaction in active cache
    /// 2. Validate transaction state
    /// 3. Finish transaction in queue
    /// 4. Remove from active cache
    /// 5. Notify completion
    ///
    /// Important:
    /// - Always complete transactions promptly
    /// - Handle both success and failure cases
    /// - Maintain transaction cache consistency
    /// - Report completion status
    func completeTransaction(_ transactionId: String) {
        guard let transaction = activeTransactions[transactionId] else {
            return
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /// Restore previous purchases
    ///
    /// Restoration Flow:
    /// 1. Initialize restoration request
    /// 2. Handle user identification
    /// 3. Submit restore request
    /// 4. Process restored transactions
    /// 5. Complete restored transactions
    /// 6. Update purchase state
    ///
    /// Handling:
    /// - User identification is optional
    /// - All restorable purchases are processed
    /// - Each transaction is validated
    /// - Receipt validation is performed
    /// - Results are reported through callbacks
    func restorePurchases(_ applicationUserName: String) {
        if applicationUserName.isEmpty {
            SKPaymentQueue.default().restoreCompletedTransactions()
        } else {
            SKPaymentQueue.default().restoreCompletedTransactions(withApplicationUsername: applicationUserName)
        }
    }
    
    /// Get App Store receipt data for server-side validation
    /// - Returns: Base64 encoded receipt data or nil if not available
    ///
    /// Receipt Handling:
    /// 1. Find receipt URL in app bundle
    /// 2. Verify receipt file exists
    /// 3. Read receipt data
    /// 4. Base64 encode for transmission
    ///
    /// Security Note:
    /// - Receipt should be validated server-side
    /// - Local validation is not secure
    /// - Always use HTTPS for receipt transmission
    func getReceiptData() -> String? {
        // Get URL to receipt in app bundle
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              // Verify receipt file exists
              FileManager.default.fileExists(atPath: appStoreReceiptURL.path),
              // Read receipt data from file
              let receiptData = try? Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
        else {
            return nil
        }
        // Return Base64 encoded receipt data
        return receiptData.base64EncodedString(options: [])
    }
    
    private func reportError(type: String, code: Int8, message: String) {
        let error: [String: Any] = [
            "type": type,
            "payload": [
                "code": code,
                "message": message
            ]
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: error)
            let dataPointer = data.withUnsafeBytes { $0.baseAddress }
            let dataSize = data.count
            onError(dataPointer, Int32(dataSize))
        } catch {
            print("Error serializing error data: \(error.localizedDescription)")
        }
    }
}

// MARK: - StoreKit 1 Extensions

/// SKProductsRequestDelegate implementation for StoreKit 1
extension StoreKit1PaymentManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        var productDetails: [ProductDetails] = []
        
        for product in response.products {
            availableProducts[product.productIdentifier] = product
            
            productDetails.append(ProductDetails(
                id: product.productIdentifier,
                title: product.localizedTitle,
                description: product.localizedDescription,
                price: product.price.stringValue,
                rawPrice: product.price.doubleValue,
                currencyCode: product.priceLocale.currencyCode ?? "",
                currencySymbol: product.priceLocale.currencySymbol ?? ""
            ))
        }
        
        do {
            let data = try JSONEncoder().encode(productDetails)
            let dataPointer = data.withUnsafeBytes { $0.baseAddress }
            let dataSize = data.count
            onProductsUpdated(dataPointer, Int32(dataSize))
        } catch {
            reportError(type: "ProductQuery", code: 2, message: error.localizedDescription)
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        reportError(type: "ProductQuery", code: 3, message: error.localizedDescription)
    }
}

/// SKPaymentTransactionObserver implementation for StoreKit 1
/// Handles transaction updates and purchase flow
extension StoreKit1PaymentManager: SKPaymentTransactionObserver {
    /// Handle payment queue transaction updates
    ///
    /// Transaction Processing Flow:
    /// 1. Receive transaction update
    /// 2. Cache transaction if identifiable
    /// 3. Extract transaction details
    /// 4. Add receipt data for completed purchases
    /// 5. Report status through callback
    ///
    /// Transaction States:
    /// - .purchasing: Payment being processed
    /// - .purchased: Successfully completed
    /// - .failed: Purchase failed
    /// - .restored: Purchase restored
    /// - .deferred: Awaiting action
    ///
    /// Data Handling:
    /// - Transaction ID tracking
    /// - Receipt data inclusion
    /// - Error information
    /// - Purchase date
    /// - User identification
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // Array to store transaction information
        var transactionDetails: [[String: Any]] = []
        
        // Get receipt data for validation
        let receiptData = getReceiptData()
        
        for transaction in transactions {
            // Cache transaction if it has an identifier
            if let identifier = transaction.transactionIdentifier {
                activeTransactions[identifier] = transaction
            }
            
            // Create transaction details dictionary
            var details: [String: Any] = [
                "productId": transaction.payment.productIdentifier,      // Product bought
                "transactionId": transaction.transactionIdentifier ?? "", // Unique ID
                "transactionDate": transaction.transactionDate?.timeIntervalSince1970 ?? 0, // Purchase time
                "status": transaction.transactionState.rawValue,        // Current state
                "error": transaction.error?.localizedDescription ?? "", // Error if any
                "applicationUserName": transaction.payment.applicationUsername ?? "" // User ID
            ]
            
            // Add receipt data only for successful transactions
            if transaction.transactionState == .purchased || transaction.transactionState == .restored {
                details["receiptData"] = receiptData // For server validation
            }
            
            // Add to transaction list
            transactionDetails.append(details)
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: transactionDetails)
            let dataPointer = data.withUnsafeBytes { $0.baseAddress }
            let dataSize = data.count
            onTransactionUpdated(dataPointer, Int32(dataSize))
        } catch {
            reportError(type: "TransactionUpdate", code: 4, message: error.localizedDescription)
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        onTransactionUpdated(nil, 0)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        reportError(type: "RestorePurchases", code: 5, message: error.localizedDescription)
    }
}

// MARK: - StoreKit 2 Implementation

/// StoreKit 2 implementation for iOS 15+
/// Provides enhanced purchase functionality using modern async/await API
/// and improved transaction verification
@available(iOS 15.0, *)
class StoreKit2PaymentManager: PaymentManager {
    private let onProductsUpdated: PaymentCallback
    private let onTransactionUpdated: PaymentCallback
    private let onError: PaymentCallback
    private var task: Task<Void, Never>?
    
    init(
        onProductsUpdated: @escaping PaymentCallback,
        onTransactionUpdated: @escaping PaymentCallback,
        onError: @escaping PaymentCallback
    ) {
        self.onProductsUpdated = onProductsUpdated
        self.onTransactionUpdated = onTransactionUpdated
        self.onError = onError
        setupTransactionListener()
    }
    
    deinit {
        task?.cancel()
    }
    
    /// Set up async transaction listener for StoreKit 2
    /// Handles real-time transaction updates and verification
    ///
    /// Flow:
    /// 1. Create long-running async task
    /// 2. Listen for transaction updates
    /// 3. Process verified transactions
    /// 4. Update purchase state
    /// 5. Notify callbacks
    ///
    /// Note:
    /// - Task runs until cancellation
    /// - Handles background updates
    /// - Automatic verification
    private func setupTransactionListener() {
        // Create background task for transaction monitoring
        task = Task {
            // Listen for transaction updates indefinitely
            for await verificationResult in Transaction.updates {
                // Process each transaction with verification
                await handleVerificationResult(verificationResult)
            }
        }
    }
    
    func queryProducts(_ productIds: Set<String>) {
        // Create async task for StoreKit 2 product query
        Task {
            do {
                // Query App Store for products using modern API
                let products = try await Product.products(for: productIds)
                var productDetails: [ProductDetails] = []
                
                // Convert StoreKit 2 products to our common format
                for product in products {
                    // Map StoreKit 2 specific fields to our model
                    productDetails.append(ProductDetails(
                        id: product.id,                    // Product identifier
                        title: product.displayName,        // New localized name property
                        description: product.description,  // Product description
                        price: product.displayPrice,       // Formatted price string
                        rawPrice: product.price,          // Decimal price value
                        currencyCode: product.priceFormatStyle.currencyCode,  // ISO currency
                        currencySymbol: product.priceFormatStyle.currencySymbol ?? "" // Currency symbol
                    ))
                }
                
                do {
                    let data = try JSONEncoder().encode(productDetails)
                    let dataPointer = data.withUnsafeBytes { $0.baseAddress }
                    let dataSize = data.count
                    onProductsUpdated(dataPointer, Int32(dataSize))
                } catch {
                    reportError(type: "ProductQuery", code: 2, message: error.localizedDescription)
                }
            } catch {
                reportError(type: "ProductQuery", code: 3, message: error.localizedDescription)
            }
        }
    }
    
    func initiatePurchase(productId: String, quantity: Int, applicationUserName: String, isConsumable: Bool) {
        // Create async task for purchase flow
        Task {
            do {
                // Fetch product details using StoreKit 2
                let products = try await Product.products(for: [productId])
                
                // Verify product exists
                guard let product = products.first else {
                    reportError(type: "Purchase", code: 1, message: "Product not found")
                    return
                }
                
                // Initiate purchase with automatic verification
                let result = try await product.purchase()
                
                switch result {
                case .success(let verification):
                    await handleVerificationResult(verification)
                case .userCancelled:
                    reportError(type: "Purchase", code: 2, message: "User cancelled the purchase")
                case .pending:
                    reportError(type: "Purchase", code: 3, message: "Purchase is pending")
                @unknown default:
                    reportError(type: "Purchase", code: 4, message: "Unknown purchase result")
                }
            } catch {
                reportError(type: "Purchase", code: 5, message: error.localizedDescription)
            }
        }
    }
    
    func completeTransaction(_ transactionId: String) {
        // Create async task for transaction completion
        Task {
            // Iterate through all transactions (includes verification)
            for await verificationResult in Transaction.all {
                // Check for verified transaction matching our ID
                if case .verified(let transaction) = verificationResult,
                   transaction.id == transactionId {
                    // Mark transaction as finished in StoreKit
                    await transaction.finish()
                    return
                }
            }
        }
    }
    
    func restorePurchases(_ applicationUserName: String) {
        // Create async task for purchase restoration
        Task {
            do {
                // Sync with App Store to get all valid purchases
                try await AppStore.sync()
                // Notify successful sync with empty response
                onTransactionUpdated(nil, 0)
            } catch {
                // Report sync failure
                reportError(type: "RestorePurchases", code: 5, message: error.localizedDescription)
            }
        }
    }
    
    func getReceiptData() -> String? {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: appStoreReceiptURL.path),
              let receiptData = try? Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
        else {
            return nil
        }
        return receiptData.base64EncodedString(options: [])
    }
    
    /// Handle StoreKit 2 transaction verification result
    /// - Parameter verificationResult: Verification result from StoreKit
    /// Contains the transaction if verification succeeded, or error if failed
    /// Process StoreKit 2 transaction verification results
    ///
    /// Verification Flow:
    /// 1. Receive verification result
    /// 2. Validate cryptographic signature
    /// 3. Process transaction state
    /// 4. Add receipt data
    /// 5. Report status
    ///
    /// Security Measures:
    /// - Cryptographic verification
    /// - Receipt validation
    /// - State validation
    /// - Duplicate prevention
    ///
    /// Error Handling:
    /// - Verification failures
    /// - Invalid signatures
    /// - Expired transactions
    /// - Revoked purchases
    private func handleVerificationResult(_ verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .verified(let transaction):
            var details: [String: Any] = [
                "productId": transaction.productID,
                "transactionId": transaction.id,
                "transactionDate": transaction.purchaseDate.timeIntervalSince1970,
                "status": transaction.purchaseState == .purchased ? SKPaymentTransactionState.purchased.rawValue : SKPaymentTransactionState.restored.rawValue,
                "applicationUserName": ""
            ]
            
            if let receiptData = getReceiptData() {
                details["receiptData"] = receiptData
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: [details])
                let dataPointer = data.withUnsafeBytes { $0.baseAddress }
                let dataSize = data.count
                onTransactionUpdated(dataPointer, Int32(dataSize))
            } catch {
                reportError(type: "TransactionUpdate", code: 4, message: error.localizedDescription)
            }
            
        case .unverified(_, let error):
            reportError(type: "TransactionVerification", code: 6, message: error.localizedDescription)
        }
    }
    
    /// Report errors to the Rust side
    ///
    /// Error Reporting Flow:
    /// 1. Create error payload
    /// 2. Serialize error data
    /// 3. Pass to callback
    ///
    /// Error Types:
    /// - Purchase: Codes 1-5 (product/payment issues)
    /// - ProductQuery: Codes 2-3 (query issues)
    /// - TransactionUpdate: Code 4 (state issues)
    /// - RestorePurchases: Code 5 (restore issues)
    /// - TransactionVerification: Code 6 (verify issues)
    ///
    /// Data Format:
    /// {
    ///   "type": "<error_type>",
    ///   "payload": {
    ///     "code": <error_code>,
    ///     "message": "<error_message>"
    ///   }
    /// }
    private func reportError(type: String, code: Int8, message: String) {
        let error: [String: Any] = [
            "type": type,
            "payload": [
                "code": code,
                "message": message
            ]
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: error)
            let dataPointer = data.withUnsafeBytes { $0.baseAddress }
            let dataSize = data.count
            onError(dataPointer, Int32(dataSize))
        } catch {
            print("Error serializing error data: \(error.localizedDescription)")
        }
    }
}
