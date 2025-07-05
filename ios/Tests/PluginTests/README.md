# Tauri Plugin IAP - iOS Tests

This directory contains comprehensive tests for the iOS implementation of the Tauri IAP plugin, covering both StoreKit 1 and StoreKit 2 functionality.

## Test Structure

### Mock Objects (`Mocks/MockStoreKit.swift`)
- `MockSKProduct`: Simulates App Store products
- `MockSKPaymentQueue`: Simulates payment queue operations
- `MockSKPaymentTransaction`: Simulates purchase transactions
- `MockProduct` (StoreKit 2): Simulates modern product API
- `MockTransaction` (StoreKit 2): Simulates modern transactions

### Test Cases (`IapPluginTests.swift`)
1. Common Tests
   - Plugin initialization
   - StoreKit availability
   - Country code retrieval

2. StoreKit 1 Tests (iOS 13+)
   - Product queries
   - Purchase flow
   - Transaction handling
   - Purchase restoration

3. StoreKit 2 Tests (iOS 15+)
   - Modern product queries
   - Async purchase flow
   - Transaction verification
   - Purchase restoration

4. Error Handling Tests
   - Invalid product IDs
   - Failed purchases
   - Network errors
   - Verification failures

## Running Tests

1. Unit Tests
```bash
swift test
```

2. Running Specific Test Cases
```bash
swift test --filter IapPluginTests/testStoreKit1ProductQuery
```

## Test Coverage

The test suite covers:
- Basic functionality
- Edge cases
- Error conditions
- Version-specific features
- Data serialization
- Callback handling

### Key Areas Tested

1. Product Management
   - Product queries
   - Product caching
   - Price formatting

2. Purchase Flow
   - Non-consumable purchases
   - Consumable purchases
   - Transaction completion
   - Purchase restoration

3. Error Handling
   - Network errors
   - Invalid products
   - Transaction failures
   - Verification failures

4. Data Handling
   - JSON serialization
   - Receipt validation
   - Callback data

## Adding New Tests

When adding new tests:

1. Follow the existing pattern:
```swift
func testNewFeature() {
    // Given
    // Set up test conditions
    
    // When
    // Perform the action
    
    // Then
    // Verify the results
}
```

2. Use appropriate mocks:
```swift
let mockProduct = MockSKProduct(
    productIdentifier: "test.product",
    localizedTitle: "Test Product",
    localizedDescription: "Test Description",
    price: NSDecimalNumber(string: "0.99"),
    priceLocale: Locale(identifier: "en_US")
)
```

3. Test both success and failure cases:
```swift
func testFailureCase() {
    // Test with invalid data
    // Verify error handling
}
```

## Mocking Guidelines

1. StoreKit 1 Mocks:
   - Use `MockSKProduct` for product data
   - Use `MockSKPaymentQueue` for transactions
   - Simulate different transaction states

2. StoreKit 2 Mocks:
   - Use `MockProduct` for modern API
   - Use async/await pattern
   - Test verification flows

## Test Data

The test suite includes sample data for:
- Product configurations
- Purchase parameters
- Transaction states
- Error scenarios

Example:
```swift
let productDetails = ProductDetails(
    id: "com.test.product",
    title: "Test Product",
    description: "Test Description",
    price: "0.99",
    rawPrice: 0.99,
    currencyCode: "USD",
    currencySymbol: "$"
)
```

## Debugging Tests

1. Common Issues:
   - StoreKit version mismatches
   - Async timing issues
   - Memory management
   - Callback timing

2. Debug Tips:
   - Use breakpoints in mock objects
   - Check callback data thoroughly
   - Verify transaction states
   - Monitor memory usage

## Continuous Integration

The test suite is designed to run in CI environments:
- Supports automated testing
- Provides clear failure messages
- Maintains consistent state
- Cleans up resources