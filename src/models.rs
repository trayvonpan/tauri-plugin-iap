use serde::{Deserialize, Serialize};

/// Product details from the app store (Apple App Store or Google Play)
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ProductDetails {
    /// Unique identifier of the product
    pub id: String,
    /// Localized title of the product
    pub title: String,
    /// Localized description of the product
    pub description: String,
    /// Localized price of the product (formatted string with currency symbol)
    pub price: String,
    /// Raw numerical value of the price
    pub raw_price: f64,
    /// ISO 4217 currency code (e.g., "USD")
    pub currency_code: String,
    /// Currency symbol (e.g., "$")
    pub currency_symbol: String,
}

/// Purchase verification data used for server-side validation
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PurchaseVerificationData {
    /// Platform-specific local verification data
    pub local_verification_data: String,
    /// Platform-specific server verification data
    pub server_verification_data: String,
    /// Source platform ("apple" or "google")
    pub source: String,
}

/// Status of a purchase transaction
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum PurchaseStatus {
    /// Purchase is in progress
    Pending,
    /// Purchase completed successfully
    Purchased,
    /// Purchase encountered an error
    Error,
    /// Purchase was restored from the store
    Restored,
    /// Purchase was canceled by the user
    Canceled,
}

/// Error information for IAP operations
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct IAPError {
    /// Error code
    pub code: String,
    /// Human-readable error message
    pub message: String,
    /// Additional error details (optional)
    pub details: Option<serde_json::Value>,
}

/// Details of a purchase transaction
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PurchaseDetails {
    /// Unique identifier for the purchase (optional)
    pub purchase_id: Option<String>,
    /// Identifier of the purchased product
    pub product_id: String,
    /// Verification data for server-side validation
    pub verification_data: PurchaseVerificationData,
    /// ISO datetime string of the transaction (optional)
    pub transaction_date: Option<String>,
    /// Current status of the purchase
    pub status: PurchaseStatus,
    /// Error information if status is 'error' (optional)
    pub error: Option<IAPError>,
    /// Whether the purchase needs to be completed
    pub pending_complete_purchase: bool,
}

/// Parameters for initiating a purchase
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PurchaseParam {
    /// Product details of the item to purchase
    pub product_details: ProductDetails,
    /// Application-specific user identifier (optional)
    pub application_user_name: Option<String>,
}

/// Response from querying product details
#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ProductDetailsResponse {
    /// Array of found product details
    pub product_details: Vec<ProductDetails>,
    /// Array of product IDs that were not found
    pub not_found_ids: Vec<String>,
    /// Error information if the query partially failed (optional)
    pub error: Option<IAPError>,
}
