const COMMANDS: &[&str] = &[
    "initialize",
    "is_available",
    "query_product_details",
    "buy_non_consumable",
    "buy_consumable",
    "complete_purchase",
    "restore_purchases",
    "country_code",
];

fn main() {
    tauri_plugin::Builder::new(COMMANDS)
        .android_path("android")
        .ios_path("ios")
        .build();
}
