use serde::de::DeserializeOwned;
use tauri::{plugin::PluginApi, AppHandle, Runtime};

use crate::models::*;

pub fn init<R: Runtime, C: DeserializeOwned>(
  app: &AppHandle<R>,
  _api: PluginApi<R, C>,
) -> crate::Result<Iap<R>> {
  Ok(Iap(app.clone()))
}

/// Access to the iap APIs.
pub struct Iap<R: Runtime>(AppHandle<R>);

impl<R: Runtime> Iap<R> {
    /// Initialize the in-app purchase system.
    ///
    /// # Errors
    ///
    /// Always returns `Error::PlatformNotSupported` on desktop platforms.
    pub fn initialize(&self) -> crate::Result<()> {
        Err(crate::Error::PlatformNotSupported)
    }

    /// Check if in-app purchases are available on this platform.
    ///
    /// # Returns
    ///
    /// Returns `Error::PlatformNotSupported` as IAP is not available on desktop.
    pub fn is_available(&self) -> crate::Result<bool> {
        Err(crate::Error::PlatformNotSupported)
    }

    /// Query details for multiple products from the store.
    ///
    /// # Arguments
    ///
    /// * `product_ids` - List of product identifiers to query
    ///
    /// # Errors
    ///
    /// Always returns `Error::PlatformNotSupported` on desktop platforms.
    pub fn query_product_details(&self, _product_ids: Vec<String>) -> crate::Result<ProductDetailsResponse> {
        Err(crate::Error::PlatformNotSupported)
    }

    /// Initiate purchase of a non-consumable product.
    ///
    /// # Arguments
    ///
    /// * `purchase_param` - Parameters for the purchase
    ///
    /// # Errors
    ///
    /// Always returns `Error::PlatformNotSupported` on desktop platforms.
    pub fn buy_non_consumable(&self, _purchase_param: PurchaseParam) -> crate::Result<bool> {
        Err(crate::Error::PlatformNotSupported)
    }

    /// Initiate purchase of a consumable product.
    ///
    /// # Arguments
    ///
    /// * `purchase_param` - Parameters for the purchase
    /// * `auto_consume` - Whether to automatically consume the purchase after successful transaction
    ///
    /// # Errors
    ///
    /// Always returns `Error::PlatformNotSupported` on desktop platforms.
    pub fn buy_consumable(&self, _purchase_param: PurchaseParam, _auto_consume: bool) -> crate::Result<bool> {
        Err(crate::Error::PlatformNotSupported)
    }

    /// Complete a purchase transaction.
    ///
    /// # Arguments
    ///
    /// * `purchase` - Details of the purchase to complete
    ///
    /// # Errors
    ///
    /// Always returns `Error::PlatformNotSupported` on desktop platforms.
    pub fn complete_purchase(&self, _purchase: PurchaseDetails) -> crate::Result<()> {
        Err(crate::Error::PlatformNotSupported)
    }

    /// Restore previously purchased items.
    ///
    /// # Arguments
    ///
    /// * `application_user_name` - Optional user identifier for the restoration
    ///
    /// # Errors
    ///
    /// Always returns `Error::PlatformNotSupported` on desktop platforms.
    pub fn restore_purchases(&self, _application_user_name: Option<String>) -> crate::Result<()> {
        Err(crate::Error::PlatformNotSupported)
    }

    /// Get the store country/region code.
    ///
    /// # Errors
    ///
    /// Always returns `Error::PlatformNotSupported` on desktop platforms.
    pub fn country_code(&self) -> crate::Result<String> {
        Err(crate::Error::PlatformNotSupported)
    }
}
