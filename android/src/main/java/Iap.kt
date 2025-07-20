package com.plugin.iap

import android.app.Activity
import android.util.Log
import com.android.billingclient.api.*
import kotlinx.coroutines.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

private const val TAG = "Iap"

/**
 * Core implementation of In-App Purchase functionality using Google Play Billing Library.
 *
 * This class handles all interactions with the Google Play Billing system, including:
 * - Connecting to the billing service
 * - Querying product details
 * - Processing purchases
 * - Handling purchase state changes
 * - Managing purchase completion/consumption
 *
 * @property activity The Android Activity context required for billing operations
 */
class Iap(private val activity: Activity) {
    private lateinit var billingClient: BillingClient
    
    /**
     * Secondary constructor for testing purposes that accepts a pre-configured BillingClient
     */
    internal constructor(activity: Activity, testBillingClient: BillingClient) : this(activity) {
        billingClient = testBillingClient
    }
    private var purchaseUpdateListener: ((List<Purchase>) -> Unit)? = null
    private val purchaseCache = mutableMapOf<String, Purchase>()
    
    /**
     * Initializes the billing client when the class is instantiated.
     * This ensures the billing client is ready for use when needed.
     */
    init {
        setupBillingClient()
    }

    /**
     * Sets up the BillingClient with required configurations.
     * Configures the purchase update listener and enables pending purchases.
     */
    private fun setupBillingClient() {
        if (!::billingClient.isInitialized) {
            billingClient = BillingClient.newBuilder(activity)
                .setListener { billingResult, purchases ->
                    handlePurchaseUpdate(billingResult, purchases)
                }
                .enablePendingPurchases()
                .build()
        }
    }

    private fun handlePurchaseUpdate(billingResult: BillingResult, purchases: List<Purchase>?) {
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            Log.d(TAG, "Purchase update received: ${purchases.size} purchases")
            for (purchase in purchases) {
                purchaseCache[purchase.orderId] = purchase
            }
            purchaseUpdateListener?.invoke(purchases)
        } else {
            Log.e(TAG, "Purchase update error: ${billingResult.debugMessage}")
        }
    }

    /**
     * Initializes the connection to Google Play Billing service.
     *
     * @return Boolean indicating whether the initialization was successful
     * @throws BillingException if the service connection fails
     */
    suspend fun initialize(): Boolean = suspendCoroutine { continuation ->
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                val success = billingResult.responseCode == BillingClient.BillingResponseCode.OK
                Log.d(TAG, "Billing setup finished: ${billingResult.debugMessage}")
                continuation.resume(success)
            }

            override fun onBillingServiceDisconnected() {
                Log.w(TAG, "Billing service disconnected, attempting to reconnect")
                setupBillingClient()
            }
        })
    }

    /**
     * Queries product details from Google Play for the specified product IDs.
     *
     * @param productIds List of product IDs to query
     * @return ProductDetailsResult containing the query results and any error information
     * @throws BillingException if the query fails
     */
    suspend fun queryProductDetails(productIds: List<String>): ProductDetailsResult {
        val productList = productIds.map { productId ->
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(BillingClient.ProductType.INAPP)
                .build()
        }

        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(productList)
            .build()

        return suspendCoroutine { continuation ->
            billingClient.queryProductDetailsAsync(params) { billingResult, productDetailsList ->
                Log.d(TAG, "Product details query result: ${billingResult.debugMessage}")
                val notFoundIds = productIds.toMutableList()
                productDetailsList.forEach { notFoundIds.remove(it.productId) }
                
                continuation.resume(
                    ProductDetailsResult(
                        success = billingResult.responseCode == BillingClient.BillingResponseCode.OK,
                        productDetails = productDetailsList,
                        notFoundIds = notFoundIds,
                        errorMessage = billingResult.debugMessage
                    )
                )
            }
        }
    }

    /**
     * Initiates a purchase flow for the specified product.
     *
     * @param productDetails The product details for the item to purchase
     * @return PurchaseResult containing the purchase status and any error information
     * @throws BillingException if the purchase flow fails to launch
     */
    suspend fun purchase(productDetails: ProductDetails): PurchaseResult = suspendCoroutine { continuation ->
        val flowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(productDetails)
                        .build()
                )
            )
            .build()

        val responseCode = billingClient.launchBillingFlow(activity, flowParams).responseCode
        if (responseCode != BillingClient.BillingResponseCode.OK) {
            continuation.resume(
                PurchaseResult(
                    success = false,
                    errorMessage = "Failed to launch billing flow: $responseCode"
                )
            )
        }
    }

    /**
     * Completes a purchase by consuming the purchase token.
     * This is required for consumable products to be purchasable again.
     *
     * @param purchase The purchase to complete
     * @return Boolean indicating whether the consumption was successful
     * @throws BillingException if the consumption fails
     */
    suspend fun completePurchase(purchase: Purchase): Boolean {
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
            // First acknowledge the purchase if not acknowledged
            if (!purchase.isAcknowledged) {
                Log.d(TAG, "Acknowledging purchase: ${purchase.orderId}")
                val acknowledgeResult = acknowledgePurchase(purchase)
                if (!acknowledgeResult) {
                    Log.e(TAG, "Failed to acknowledge purchase: ${purchase.orderId}")
                    return false
                }
            }

            // Then consume the purchase
            Log.d(TAG, "Consuming purchase: ${purchase.orderId}")
            val consumeParams = ConsumeParams.newBuilder()
                .setPurchaseToken(purchase.purchaseToken)
                .build()

            return suspendCoroutine { continuation ->
                billingClient.consumeAsync(consumeParams) { billingResult, _ ->
                    val success = billingResult.responseCode == BillingClient.BillingResponseCode.OK
                    if (!success) {
                        Log.e(TAG, "Failed to consume purchase: ${billingResult.debugMessage}")
                    }
                    continuation.resume(success)
                }
            }
        }
        return false
    }

    private suspend fun acknowledgePurchase(purchase: Purchase): Boolean = suspendCoroutine { continuation ->
        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()

        billingClient.acknowledgePurchase(params) { billingResult ->
            val success = billingResult.responseCode == BillingClient.BillingResponseCode.OK
            if (!success) {
                Log.e(TAG, "Failed to acknowledge purchase: ${billingResult.debugMessage}")
            }
            continuation.resume(success)
        }
    }

    /**
     * Restores all purchases made by the user.
     * This is useful for handling non-consumable purchases across device installations.
     *
     * @return List of all active purchases
     * @throws BillingException if the query fails
     */
    suspend fun restorePurchases(): List<Purchase> = suspendCoroutine { continuation ->
        billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.INAPP)
                .build()
        ) { billingResult, purchaseList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                Log.d(TAG, "Restored ${purchaseList.size} purchases")
                purchaseList.forEach { purchase ->
                    purchaseCache[purchase.orderId] = purchase
                }
                continuation.resume(purchaseList)
            } else {
                Log.e(TAG, "Failed to restore purchases: ${billingResult.debugMessage}")
                continuation.resume(emptyList())
            }
        }
    }

    /**
     * Sets a listener for purchase updates.
     * This listener will be called whenever a purchase state changes.
     *
     * @param listener Callback function that receives a list of updated purchases
     */
    fun setPurchaseUpdateListener(listener: (List<Purchase>) -> Unit) {
        purchaseUpdateListener = listener
    }
}

/**
 * Represents the result of a product details query.
 *
 * @property success Whether the query was successful
 * @property productDetails List of retrieved product details
 * @property errorMessage Error message if the query failed
 */
data class ProductDetailsResult(
    val success: Boolean,
    val productDetails: List<ProductDetails>,
    val notFoundIds: List<String>,
    val errorMessage: String
)

/**
 * Represents the result of a purchase operation.
 *
 * @property success Whether the purchase was successful
 * @property errorMessage Error message if the purchase failed
 */
data class PurchaseResult(
    val success: Boolean,
    val errorMessage: String? = null
)
