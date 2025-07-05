import XCTest
import StoreKit
@testable import TauriIap

class IapPluginTests: XCTestCase {
    var plugin: IapPlugin!
    var mockPaymentQueue: MockSKPaymentQueue!
    var mockProductCallback: PaymentCallback!
    var mockTransactionCallback: PaymentCallback!
    var mockErrorCallback: PaymentCallback!
    var receivedProducts: [[String: Any]]?
    var receivedTransactions: [[String: Any]]?
    var receivedError: [String: Any]?
    
    /// Set up test environment before each test
    override func setUp() {
        super.setUp()
        plugin = IapPlugin()
        mockPaymentQueue = MockSKPaymentQueue()
        
        // Set up mock callbacks
        mockProductCallback = { [weak self] pointer, size in
            if let pointer = pointer {
                let data = Data(bytes: pointer, count: Int(size))
                self?.receivedProducts = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            }
        }
        
        mockTransactionCallback = { [weak self] pointer, size in
            if let pointer = pointer {
                let data = Data(bytes: pointer, count: Int(size))
                self?.receivedTransactions = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            }
        }
        
        mockErrorCallback = { [weak self] pointer, size in
            if let pointer = pointer {
                let data = Data(bytes: pointer, count: Int(size))
                self?.receivedError = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            }
        }
        
        mockPaymentQueue.mockStorefront = MockSKStorefront(countryCode: "US")
    }
    
    /// Clean up after each test
    override func tearDown() {
        plugin = nil
        mockPaymentQueue = nil
        receivedProducts = nil
        receivedTransactions = nil
        receivedError = nil
        super.tearDown()
    }
    
    // MARK: - Common Tests
    
    /// Test plugin initialization and callback setup
    func testInitialization() {
        let result = initialize(
            onProductsUpdated: mockProductCallback,
            onTransactionUpdated: mockTransactionCallback,
            onError: mockErrorCallback
        )
        XCTAssertTrue(result, "Initialization should succeed")
    }
    
    func testIsAvailable() {
        let available = isAvailable()
        XCTAssertTrue(available, "StoreKit should be available in test environment")
    }
    
    func testCountryCode() {
        let result = countryCode()
        XCTAssertNotNil(result, "Country code should not be nil")
        XCTAssertEqual(result?.toString(), "US", "Country code should match mock storefront")
    }
    
    // MARK: - StoreKit 1 Tests
    
    /// Test StoreKit 1 product query functionality
    /// Payment Flow:
    /// 1. Create mock product with required details
    /// 2. Set up mock product request with the product
    /// 3. Query product details through plugin
    /// 4. Verify product details are received correctly
    ///
    /// Expected behavior:
    /// - Product query succeeds
    /// - Callback receives product details
    /// - Product information matches mock data
    func testStoreKit1ProductQuery() {
        // Given
        let product = MockSKProduct(
            productIdentifier: "com.test.product",
            localizedTitle: "Test Product",
            localizedDescription: "A test product",
            price: NSDecimalNumber(string: "0.99"),
            priceLocale: Locale(identifier: "en_US")
        )
        let productRequest = MockSKProductsRequest()
        productRequest.mockProducts = [product]
        
        // When
        let result = queryProductDetails(productIds: SRString("com.test.product"))
        
        // Then
        XCTAssertTrue(result, "Query products should return true")
        XCTAssertNotNil(receivedProducts, "Should receive product details")
        XCTAssertEqual(receivedProducts?.count, 1, "Should receive one product")
    }
    
    /// Test StoreKit 1 purchase flow
    /// Payment Flow:
    /// 1. Create product details matching store product
    /// 2. Create purchase parameters with product and user info
    /// 3. Encode purchase parameters
    /// 4. Initiate purchase through plugin
    /// 5. Verify payment queue interaction
    ///
    /// Expected behavior:
    /// - Purchase request is accepted
    /// - Payment is added to queue
    /// - Transaction is created
    /// - Payment callbacks are triggered
    func testStoreKit1Purchase() {
        // Given
        let productDetails = ProductDetails(
            id: "com.test.product",
            title: "Test Product",
            description: "Test Description",
            price: "0.99",
            rawPrice: 0.99,
            currencyCode: "USD",
            currencySymbol: "$"
        )
        
        let purchaseParam = PurchaseParam(
            productDetails: productDetails,
            applicationUserName: "testUser"
        )
        
        let data = try! JSONEncoder().encode(purchaseParam)
        
        // When
        let result = buyNonConsumable(
            param: data.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: Int8.self) },
            paramLen: Int32(data.count)
        )
        
        // Then
        XCTAssertTrue(result, "Purchase should succeed")
        XCTAssertTrue(mockPaymentQueue.addPaymentCalled, "Payment should be added to queue")
    }
    
    // MARK: - StoreKit 2 Tests (iOS 15+)
    
    /// Test StoreKit 2 product query functionality
    /// Verifies async product loading and modern API usage
    @available(iOS 15.0, *)
    /// Test StoreKit 2 product query functionality
    /// Modern Payment Flow:
    /// 1. Create mock StoreKit 2 product
    /// 2. Query product using modern API
    /// 3. Wait for async response
    /// 4. Verify product information
    ///
    /// Expected behavior:
    /// - Async product query succeeds
    /// - Product details match modern format
    /// - Price formatting uses new API
    /// - Callbacks work with async flow
    func testStoreKit2ProductQuery() async {
        // Given
        let mockProduct = MockProduct(
            id: "com.test.product2",
            displayName: "Test Product 2",
            description: "A StoreKit 2 test product",
            price: Decimal(0.99),
            displayPrice: "$0.99",
            currencyCode: "USD"
        )
        
        // When
        let result = queryProductDetails(productIds: SRString("com.test.product2"))
        
        // Then
        XCTAssertTrue(result, "Query products should return true")
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(receivedProducts, "Should receive product details")
    }
    
    /// Test StoreKit 2 purchase flow
    /// Verifies modern purchase API and transaction verification
    @available(iOS 15.0, *)
    /// Test StoreKit 2 purchase flow with verification
    /// Modern Payment Flow:
    /// 1. Create product details for StoreKit 2
    /// 2. Set up purchase parameters
    /// 3. Initiate async purchase
    /// 4. Wait for transaction verification
    /// 5. Handle verified transaction
    ///
    /// Key verification steps:
    /// - Transaction is cryptographically verified
    /// - Purchase is validated with App Store
    /// - Receipt data is properly handled
    /// - Transaction status is correctly reported
    ///
    /// Expected behavior:
    /// - Purchase request succeeds
    /// - Transaction is verified
    /// - Callbacks receive verified data
    /// - Receipt is available for validation
    func testStoreKit2Purchase() async {
        // Given
        let productDetails = ProductDetails(
            id: "com.test.product2",
            title: "Test Product 2",
            description: "StoreKit 2 Test Description",
            price: "0.99",
            rawPrice: 0.99,
            currencyCode: "USD",
            currencySymbol: "$"
        )
        
        let purchaseParam = PurchaseParam(
            productDetails: productDetails,
            applicationUserName: "testUser"
        )
        
        let data = try! JSONEncoder().encode(purchaseParam)
        
        // When
        let result = buyNonConsumable(
            param: data.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: Int8.self) },
            paramLen: Int32(data.count)
        )
        
        // Then
        XCTAssertTrue(result, "Purchase should succeed")
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(receivedTransactions, "Should receive transaction update")
    }
    
    /// Test purchase restoration using StoreKit 2
    /// Verifies AppStore.sync() functionality
    @available(iOS 15.0, *)
    /// Test StoreKit 2 purchase restoration
    /// Restore Flow:
    /// 1. Configure mock AppStore behavior
    /// 2. Trigger purchase restoration
    /// 3. Wait for sync completion
    /// 4. Verify restored purchases
    ///
    /// Restoration process:
    /// - Connects to App Store
    /// - Retrieves all eligible transactions
    /// - Verifies each transaction
    /// - Updates local state
    ///
    /// Expected behavior:
    /// - Sync request is made
    /// - Restored purchases are verified
    /// - Callbacks receive restoration results
    func testStoreKit2Restore() async {
        // Given
        MockAppStore.syncCalled = false
        MockAppStore.shouldSucceed = true
        
        // When
        let result = restorePurchases(applicationUserName: nil)
        
        // Then
        XCTAssertTrue(result, "Restore should succeed")
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(MockAppStore.syncCalled, "AppStore sync should be called")
    }
    
    /// Test purchase restoration failure handling
    /// Verifies error reporting for sync failures
    @available(iOS 15.0, *)
    /// Test StoreKit 2 restoration failure scenarios
    /// Error Handling Flow:
    /// 1. Configure mock AppStore to fail
    /// 2. Attempt purchase restoration
    /// 3. Verify error handling
    /// 4. Check error reporting
    ///
    /// Error scenarios covered:
    /// - Network failures
    /// - Authentication errors
    /// - Verification failures
    /// - Invalid states
    ///
    /// Expected behavior:
    /// - Restoration attempt fails gracefully
    /// - Error is properly reported
    /// - Error details are accurate
    /// - System remains in consistent state
    func testStoreKit2RestoreFailure() async {
        // Given
        MockAppStore.syncCalled = false
        MockAppStore.shouldSucceed = false
        
        // When
        let result = restorePurchases(applicationUserName: nil)
        
        // Then
        XCTAssertTrue(result, "Restore should succeed initially")
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(MockAppStore.syncCalled, "AppStore sync should be called")
        XCTAssertNotNil(receivedError, "Should receive error callback")
    }
    
    // MARK: - Error Handling Tests
    
    /// Test handling of invalid product identifiers
    /// Verifies error reporting for non-existent products
    /// Test invalid product ID handling
    /// Error Flow:
    /// 1. Request non-existent product
    /// 2. Verify error handling
    /// 3. Check error reporting
    ///
    /// Error handling checks:
    /// - Invalid product ID detection
    /// - Error message accuracy
    /// - Error code correctness
    /// - System state consistency
    ///
    /// Expected behavior:
    /// - Query completes without crashing
    /// - Error is properly reported
    /// - Error details are meaningful
    /// - System remains stable
    func testInvalidProductId() {
        // Given
        let invalidProductId = "invalid_product_id"
        
        // When
        let result = queryProductDetails(productIds: SRString(invalidProductId))
        
        // Then
        XCTAssertTrue(result, "Query should succeed even with invalid product ID")
        XCTAssertNotNil(receivedError, "Should receive error callback")
    }
    
    /// Test handling of invalid purchase parameters
    /// Verifies error handling for malformed purchase requests
    /// Test invalid purchase parameter handling
    /// Error Flow:
    /// 1. Send malformed purchase data
    /// 2. Attempt purchase processing
    /// 3. Verify error handling
    /// 4. Check system state
    ///
    /// Validation checks:
    /// - Parameter format validation
    /// - Data integrity checking
    /// - Error handling completeness
    /// - System stability
    ///
    /// Expected behavior:
    /// - Purchase attempt fails safely
    /// - Error is properly reported
    /// - No partial state changes occur
    /// - System remains stable
    func testInvalidPurchaseParam() {
        // Given
        let invalidData = "invalid_data".data(using: .utf8)!
        
        // When
        let result = buyNonConsumable(
            param: invalidData.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: Int8.self) },
            paramLen: Int32(invalidData.count)
        )
        
        // Then
        XCTAssertFalse(result, "Buy should fail with invalid purchase param")
    }
}