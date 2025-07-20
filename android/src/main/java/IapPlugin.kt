package com.plugin.iap

import android.app.Activity
import android.util.Log
import app.tauri.annotation.CommandHandler
import app.tauri.annotation.TauriPlugin
import app.tauri.plugin.JSObject
import app.tauri.plugin.Plugin
import com.android.billingclient.api.ProductDetails
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

private const val TAG = "IapPlugin"

/**
 * Tauri plugin for handling In-App Purchases through Google Play Billing.
 *
 * This plugin bridges the Rust core with Android's billing implementation.
 */
@TauriPlugin
class IapPlugin(activity: Activity): Plugin(activity) {
    private val implementation = Iap(activity)
    private val scope = CoroutineScope(Dispatchers.Main)
    private val productDetailsCache = mutableMapOf<String, ProductDetails>()

    @CommandHandler
    fun initialize(args: JSObject, callback: (Result<Boolean>) -> Unit) {
        scope.launch {
            try {
                val result = implementation.initialize()
                Log.d(TAG, "Initialization result: $result")
                callback(Result.success(result))
            } catch (e: Exception) {
                Log.e(TAG, "Initialization failed", e)
                callback(Result.failure(e))
            }
        }
    }

    @CommandHandler
    fun isAvailable(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    @CommandHandler
    fun queryProductDetails(args: JSObject, callback: (Result<JSObject>) -> Unit) {
        scope.launch {
            try {
                val productIds = args.getJSONArray("productIds")?.let {
                    List(it.length()) { i -> it.getString(i) }
                } ?: emptyList()

                val result = implementation.queryProductDetails(productIds)
                Log.d(TAG, "Query result: ${result.productDetails.size} products found")
                
                // Cache the product details for later use
                result.productDetails.forEach { details ->
                    productDetailsCache[details.productId] = details
                }
                
                val response = JSObject().apply {
                    put("success", result.success)
                    put("productDetails", JSONArray().apply {
                        result.productDetails.forEach { details ->
                            put(convertProductDetails(details))
                        }
                    })
                    put("notFoundIds", JSONArray().apply {
                        result.notFoundIds.forEach { put(it) }
                    })
                    put("errorMessage", result.errorMessage)
                }
                callback(Result.success(response))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    @CommandHandler
    fun buyNonConsumable(args: JSObject, callback: (Result<Boolean>) -> Unit) {
        scope.launch {
            try {
                val productId = args.getJSONObject("productDetails").getString("id")
                val productDetails = getProductDetails(productId)
                val result = implementation.purchase(productDetails, isConsumable = false)
                Log.d(TAG, "Non-consumable purchase result: ${result.success}")
                callback(Result.success(result.success))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    @CommandHandler
    fun buyConsumable(args: JSObject, callback: (Result<Boolean>) -> Unit) {
        scope.launch {
            try {
                val productId = args.getJSONObject("productDetails").getString("id")
                val productDetails = getProductDetails(productId)
                val result = implementation.purchase(productDetails, isConsumable = true)
                Log.d(TAG, "Consumable purchase result: ${result.success}")
                callback(Result.success(result.success))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    @CommandHandler
    fun completePurchase(args: JSObject, callback: (Result<Boolean>) -> Unit) {
        scope.launch {
            try {
                val purchaseId = args.getString("purchaseId")
                val purchase = implementation.restorePurchases().find { it.orderId == purchaseId }
                if (purchase != null) {
                    val result = implementation.completePurchase(purchase)
                    callback(Result.success(result))
                } else {
                    callback(Result.failure(Exception("Purchase not found")))
                }
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    @CommandHandler
    fun restorePurchases(args: JSObject?, callback: (Result<JSObject>) -> Unit) {
        scope.launch {
            try {
                val purchases = implementation.restorePurchases()
                val response = JSObject().apply {
                    put("purchases", JSONArray().apply {
                        purchases.forEach { purchase ->
                            put(JSONObject().apply {
                                put("purchaseId", purchase.orderId)
                                put("productId", purchase.products.firstOrNull())
                                put("purchaseToken", purchase.purchaseToken)
                                put("purchaseTime", purchase.purchaseTime)
                                put("purchaseState", purchase.purchaseState)
                            })
                        }
                    })
                }
                callback(Result.success(response))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    /**
     * Converts a ProductDetails object to a JSON representation.
     */
    private fun convertProductDetails(details: ProductDetails): JSONObject {
        return JSONObject().apply {
            put("id", details.productId)
            put("title", details.title)
            put("description", details.description)
            details.oneTimePurchaseOfferDetails?.let { offer ->
                put("price", offer.formattedPrice)
                put("rawPrice", offer.priceAmountMicros / 1_000_000.0)
                put("currencyCode", offer.priceCurrencyCode)
            }
        }
    }

    /**
     * Retrieves cached ProductDetails by product ID.
     *
     * @param productId The ID of the product to retrieve
     * @throws IllegalStateException if the product details are not found in cache
     */
    private fun getProductDetails(productId: String): ProductDetails {
        return productDetailsCache[productId]
            ?: throw IllegalStateException("Product details not found for $productId. Call queryProductDetails first.")
    }

    init {
        implementation.setPurchaseUpdateListener { purchases ->
            Log.d(TAG, "Purchase update received: ${purchases.size} purchases")
            val event = JSObject().apply {
                put("purchases", JSONArray().apply {
                    purchases.forEach { purchase ->
                        put(JSONObject().apply {
                            put("purchaseId", purchase.orderId)
                            put("productId", purchase.products.firstOrNull())
                            put("purchaseToken", purchase.purchaseToken)
                            put("purchaseTime", purchase.purchaseTime)
                            put("purchaseState", purchase.purchaseState)
                            put("isAcknowledged", purchase.isAcknowledged)
                        })
                    }
                })
            }
            notifyListeners("purchaseUpdate", event)
        }
    }
}
