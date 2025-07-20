use serde::{ser::Serializer, Serialize};

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error(transparent)]
    Io(#[from] std::io::Error),

    #[cfg(mobile)]
    #[error(transparent)]
    PluginInvoke(#[from] tauri::plugin::mobile::PluginInvokeError),

    #[error("In-app purchases are not supported on this platform")]
    PlatformNotSupported,

    #[error("Failed to initialize billing client: {0}")]
    BillingClientInitError(String),

    #[error("Product details query failed: {0}")]
    ProductQueryError(String),

    #[error("Purchase flow failed: {0}")]
    PurchaseError(String),

    #[error("Failed to consume purchase: {0}")]
    ConsumptionError(String),

    #[error("Purchase restoration failed: {0}")]
    RestoreError(String),

    #[error("Invalid purchase token or receipt: {0}")]
    InvalidPurchaseToken(String),

    #[error("Network error during billing operation: {0}")]
    NetworkError(String),

    #[error("User cancelled the purchase")]
    UserCancelled,

    #[error("Item already owned")]
    ItemAlreadyOwned,

    #[error("Service disconnected")]
    ServiceDisconnected,

    #[error("Feature not supported: {0}")]
    FeatureNotSupported(String),

    #[error("Internal billing error: {0}")]
    InternalError(String),
}

impl Serialize for Error {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(self.to_string().as_ref())
    }
}

#[cfg(target_os = "android")]
impl Error {
    pub(crate) fn from_response_code(code: i32, message: Option<String>) -> Self {
        use std::format as f;
        match code {
            0 => {
                Error::InternalError(message.unwrap_or_else(|| f!("Unknown error code: {}", code)))
            }
            1 => Error::UserCancelled,
            2 => Error::ServiceDisconnected,
            3 => Error::BillingClientInitError(
                message.unwrap_or_else(|| "Billing unavailable".into()),
            ),
            4 => Error::ItemAlreadyOwned,
            5 => Error::ItemNotOwned(message.unwrap_or_else(|| "Item not owned".into())),
            6 => Error::NetworkError(message.unwrap_or_else(|| "Network error".into())),
            7 => Error::FeatureNotSupported(
                message.unwrap_or_else(|| "Feature not supported".into()),
            ),
            _ => {
                Error::InternalError(message.unwrap_or_else(|| f!("Unknown error code: {}", code)))
            }
        }
    }
}

#[derive(Debug, thiserror::Error)]
#[error("Item not owned: {0}")]
pub struct ItemNotOwned(String);

impl Serialize for ItemNotOwned {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(self.0.as_ref())
    }
}
