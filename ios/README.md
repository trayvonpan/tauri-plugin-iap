# Tauri Plugin IAP - iOS Implementation

This directory contains the iOS implementation of the Tauri IAP (In-App Purchase) plugin. The implementation supports both StoreKit 1 and StoreKit 2, providing seamless in-app purchase functionality across different iOS versions.

## Architecture

The implementation follows a dual-track approach:

- StoreKit 1 for iOS 13-14
- StoreKit 2 for iOS 15+

### Core Components

1. **IapPlugin**

- Main plugin class that registers with Tauri
- Manages payment handler initialization
- Routes commands between Rust and Swift

2. **PaymentManager Protocol**

- Defines common interface for both StoreKit versions
- Handles product queries, purchases, and restoration
- Manages receipt validation

3. **StoreKit1PaymentManager**

- Legacy implementation using SKPaymentQueue
- Handles transactions through delegate pattern
- Manages product queries and purchases

4. **StoreKit2PaymentManager**

- Modern implementation using async/await
- Uses Transaction.updates for real-time updates
- Provides enhanced verification

## Features

- Product queries
- Non-consumable purchases
- Consumable purchases
- Purchase restoration
- Receipt validation
- Transaction management
- Comprehensive error handling

## Version Support

- Minimum iOS: 13.0
- Optimal iOS: 15.0+ (StoreKit 2)
- Backward compatibility maintained

## Usage

The implementation exposes several bridge functions to Rust:

```swift
@_cdecl("init_plugin_iap")
@_cdecl("initialize")
@_cdecl("is_available")
@_cdecl("query_product_details")
@_cdecl("buy_non_consumable")
@_cdecl("buy_consumable")
@_cdecl("complete_purchase")
@_cdecl("restore_purchases")
@_cdecl("country_code")
```

## Testing

Tests are provided for both StoreKit 1 and 2 implementations:

- Mock objects for StoreKit classes
- Version-specific test cases
- Error handling tests
- Async operation tests

## Error Handling

The implementation includes comprehensive error handling:

1. Network errors
2. Product query failures
3. Purchase failures
4. Verification failures
5. Receipt validation errors

Error codes:

- 1: Product not found
- 2: Product query error
- 3: Network error
- 4: Transaction error
- 5: Restore error
- 6: Verification error

## Best Practices

1. Always check StoreKit version support
2. Handle all transaction states
3. Validate receipts
4. Complete transactions promptly
5. Handle restoration properly
6. Provide clear error messages

## Security Considerations

1. Receipt Validation

   - Base64 encode receipts
   - Support server validation
   - Handle validation errors

2. Transaction Verification

   - Use StoreKit 2 verification when available
   - Check transaction states
   - Validate purchase dates

3. Error Handling
   - Protect sensitive information
   - Log appropriately
   - Handle edge cases

## Known Issues and Limitations

1. StoreKit 2 features require iOS 15+
2. Some features may behave differently between versions
3. Receipt validation requires server-side implementation for production use

## Future Improvements

1. Enhanced StoreKit 2 features
2. Subscription support
3. Offer code redemption
4. Family sharing support
5. Enhanced analytics

## Resources

- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [In-App Purchase Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase)
- [Tauri Plugin Documentation](https://tauri.app/v1/guides/features/plugin)
