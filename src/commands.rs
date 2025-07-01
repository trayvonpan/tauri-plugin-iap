use tauri::{AppHandle, command, Runtime};
use crate::models::*;
use crate::Result;
use crate::IapExt;

#[command]
pub(crate) async fn initialize<R: Runtime>(
    app: AppHandle<R>,
) -> Result<()> {
    app.iap().initialize()
}

#[command]
pub(crate) async fn is_available<R: Runtime>(
    app: AppHandle<R>,
) -> Result<bool> {
    app.iap().is_available()
}

#[command]
pub(crate) async fn query_product_details<R: Runtime>(
    app: AppHandle<R>,
    product_ids: Vec<String>,
) -> Result<ProductDetailsResponse> {
    app.iap().query_product_details(product_ids)
}

#[command]
pub(crate) async fn buy_non_consumable<R: Runtime>(
    app: AppHandle<R>,
    purchase_param: PurchaseParam,
) -> Result<bool> {
    app.iap().buy_non_consumable(purchase_param)
}

#[command]
pub(crate) async fn buy_consumable<R: Runtime>(
    app: AppHandle<R>,
    purchase_param: PurchaseParam,
    auto_consume: Option<bool>,
) -> Result<bool> {
    app.iap().buy_consumable(purchase_param, auto_consume.unwrap_or(false))
}

#[command]
pub(crate) async fn complete_purchase<R: Runtime>(
    app: AppHandle<R>,
    purchase: PurchaseDetails,
) -> Result<()> {
    app.iap().complete_purchase(purchase)
}

#[command]
pub(crate) async fn restore_purchases<R: Runtime>(
    app: AppHandle<R>,
    application_user_name: Option<String>,
) -> Result<()> {
    app.iap().restore_purchases(application_user_name)
}

#[command]
pub(crate) async fn country_code<R: Runtime>(
    app: AppHandle<R>,
) -> Result<String> {
    app.iap().country_code()
}
