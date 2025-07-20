use jni::objects::{JClass, JObject, JString, JValue};
use jni::JNIEnv;
use serde::de::DeserializeOwned;
use serde_json::json;
use tauri::{
    plugin::{PluginApi, PluginHandle},
    AppHandle, Runtime,
};

use crate::models::*;

#[cfg(target_os = "ios")]
tauri::ios_plugin_binding!(init_plugin_iap);

// initializes the Kotlin or Swift plugin classes
pub fn init<R: Runtime, C: DeserializeOwned>(
    _app: &AppHandle<R>,
    api: PluginApi<R, C>,
) -> crate::Result<Iap<R>> {
    #[cfg(target_os = "android")]
    let handle = api.register_android_plugin("com.plugin.iap", "IapPlugin")?;
    #[cfg(target_os = "ios")]
    let handle = api.register_ios_plugin(init_plugin_iap)?;
    Ok(Iap(handle))
}

/// Access to the iap APIs.
pub struct Iap<R: Runtime>(PluginHandle<R>);

impl<R: Runtime> Iap<R> {
    /// Initialize the in-app purchase system.
    ///
    /// # Errors
    ///
    /// Returns an error if the initialization fails on the native platform.
    pub fn initialize(&self) -> crate::Result<()> {
        self.0
            .run_mobile_plugin("initialize", ())
            .map_err(Into::into)
    }

    /// Check if in-app purchases are available on this platform.
    ///
    /// # Returns
    ///
    /// Returns true if IAP is available on this platform.
    pub fn is_available(&self) -> crate::Result<bool> {
        self.0
            .run_mobile_plugin("is_available", ())
            .map_err(Into::into)
    }

    /// Query details for multiple products from the store.
    ///
    /// # Arguments
    ///
    /// * `product_ids` - List of product identifiers to query
    pub fn query_product_details(
        &self,
        product_ids: Vec<String>,
    ) -> crate::Result<ProductDetailsResponse> {
        self.0
            .run_mobile_plugin(
                "query_product_details",
                json!({ "productIds": product_ids }),
            )
            .map_err(Into::into)
    }

    /// Initiate purchase of a non-consumable product.
    ///
    /// # Arguments
    ///
    /// * `purchase_param` - Parameters for the purchase
    pub fn buy_non_consumable(&self, purchase_param: PurchaseParam) -> crate::Result<bool> {
        self.0
            .run_mobile_plugin("buy_non_consumable", purchase_param)
            .map_err(Into::into)
    }

    /// Initiate purchase of a consumable product.
    ///
    /// # Arguments
    ///
    /// * `purchase_param` - Parameters for the purchase
    /// * `auto_consume` - Whether to automatically consume the purchase after successful transaction
    pub fn buy_consumable(
        &self,
        purchase_param: PurchaseParam,
        auto_consume: bool,
    ) -> crate::Result<bool> {
        self.0
            .run_mobile_plugin(
                "buy_consumable",
                json!({
                    "purchaseParam": purchase_param,
                    "autoConsume": auto_consume
                }),
            )
            .map_err(Into::into)
    }

    /// Complete a purchase transaction.
    ///
    /// # Arguments
    ///
    /// * `purchase` - Details of the purchase to complete
    pub fn complete_purchase(&self, purchase: PurchaseDetails) -> crate::Result<()> {
        self.0
            .run_mobile_plugin("complete_purchase", purchase)
            .map_err(Into::into)
    }

    /// Restore previously purchased items.
    ///
    /// # Arguments
    ///
    /// * `application_user_name` - Optional user identifier for the restoration
    pub fn restore_purchases(&self, application_user_name: Option<String>) -> crate::Result<()> {
        self.0
            .run_mobile_plugin(
                "restore_purchases",
                json!({ "applicationUserName": application_user_name }),
            )
            .map_err(Into::into)
    }

    /// Get the store country/region code.
    pub fn country_code(&self) -> crate::Result<String> {
        self.0
            .run_mobile_plugin("country_code", ())
            .map_err(Into::into)
    }
}

#[cfg(target_os = "android")]
#[allow(non_snake_case)]
pub mod android {
    use super::*;
    use jni::sys::jobject;

    #[no_mangle]
    pub extern "system" fn Java_com_plugin_iap_IapPlugin_onPurchaseUpdate(
        env: JNIEnv,
        _class: JClass,
        purchases_json: JString,
    ) {
        let purchases_str: String = env
            .get_string(purchases_json)
            .expect("Couldn't get java string!")
            .into();

        let purchases: Vec<PurchaseDetails> =
            serde_json::from_str(&purchases_str).expect("Failed to parse purchase details");

        // Here we would emit the purchase update event to the Tauri event system
        // This needs to be implemented based on how Tauri handles plugin events
    }

    #[no_mangle]
    pub extern "system" fn Java_com_plugin_iap_IapPlugin_handleError(
        env: JNIEnv,
        _class: JClass,
        error_json: JString,
    ) {
        let error_str: String = env
            .get_string(error_json)
            .expect("Couldn't get java string!")
            .into();

        // Here we would handle the error, possibly by emitting an error event
        // This needs to be implemented based on how Tauri handles plugin errors
    }
}
