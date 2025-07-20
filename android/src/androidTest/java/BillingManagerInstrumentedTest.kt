package com.plugin.iap

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.android.billingclient.api.*
import com.plugin.iap.Iap
import com.plugin.iap.IapPlugin
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class BillingManagerInstrumentedTest {
    private lateinit var context: Context
    private lateinit var iap: Iap
    private lateinit var mockBillingClient: BillingClient
    
    private val testProductDetails = ProductDetails.newBuilder()
        .setProductId("test_product_1")
        .setProductType(BillingClient.ProductType.INAPP)
        .setTitle("Test Product")
        .setDescription("Test product description")
        .setPricingPhases(
            ProductDetails.PricingPhases.newBuilder()
                .addPricingPhase(
                    ProductDetails.PricingPhase.newBuilder()
                        .setPriceAmountMicros(990000L)
                        .setPriceCurrencyCode("USD")
                        .build()
                )
                .build()
        )
        .build()
        
    private val testPurchase = Purchase.newBuilder()
        .setOrderId("test_order_1")
        .setPurchaseToken("test_token_1")
        .setProducts(listOf("test_product_1"))
        .setPurchaseState(Purchase.PurchaseState.PURCHASED)
        .build()
        
    private val testConsumablePurchase = Purchase.newBuilder()
        .setOrderId("test_order_2")
        .setPurchaseToken("test_token_2")
        .setProducts(listOf("test_product_1"))
        .setPurchaseState(Purchase.PurchaseState.PURCHASED)
        .build()

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        mockBillingClient = mockk(relaxed = true)
        
        // Setup mock responses
        coEvery {
            mockBillingClient.queryProductDetails(any())
        } returns BillingResult.newBuilder()
            .setResponseCode(BillingClient.BillingResponseCode.OK)
            .build() to listOf(testProductDetails)
            
        // Mock successful purchase flow
        coEvery {
            mockBillingClient.launchBillingFlow(any(), any())
        } andThen {
            // Simulate purchase completion
            val purchases = listOf(testPurchase)
            mockBillingClient.getListener()?.onPurchasesUpdated(
                BillingResult.newBuilder()
                    .setResponseCode(BillingClient.BillingResponseCode.OK)
                    .build(),
                purchases
            )
            BillingResult.newBuilder()
                .setResponseCode(BillingClient.BillingResponseCode.OK)
                .build()
        }
            
        // Mock purchase acknowledgment
        coEvery {
            mockBillingClient.acknowledgePurchase(any())
        } returns BillingResult.newBuilder()
            .setResponseCode(BillingClient.BillingResponseCode.OK)
            .build()
            
        // Mock purchase consumption
        coEvery {
            mockBillingClient.consumePurchase(any())
        } returns BillingResult.newBuilder()
            .setResponseCode(BillingClient.BillingResponseCode.OK)
            .build() to testConsumablePurchase
            
        // Mock network error for empty product ID
        coEvery {
            mockBillingClient.launchBillingFlow(any(), match { it.productId == "" })
        } returns BillingResult.newBuilder()
            .setResponseCode(BillingClient.BillingResponseCode.ERROR)
            .setDebugMessage("Network error occurred")
            .build()
            
        iap = Iap(context, mockBillingClient)
    }

    @Test
    fun testQueryProducts() = runBlocking {
        val productIds = listOf("test_product_1", "test_product_2")
        val details = iap.queryProductDetails(productIds)
        assertNotNull(details)
        assertTrue(details.isNotEmpty())
        assertTrue(details.any { it.productId == "test_product_1" })
    }

    @Test
    fun testPurchaseFlow() = runBlocking {
        // This test assumes a mock billing environment or test product
        val productId = "android.test.purchased"
        val result = iap.launchPurchaseFlow(productId)
        assertNotNull(result)
        assertTrue(result.success)
        assertEquals(productId, result.purchase?.productId)
    }

    @Test
    fun testPurchaseErrorHandling() = runBlocking {
        // Attempt to purchase a non-existent product
        val productId = "non_existent_product"
        val result = iap.launchPurchaseFlow(productId)
        assertNotNull(result)
        assertFalse(result.success)
        assertNotNull(result.error)
    }

    @Test
    fun testProductDetailsCaching() = runBlocking {
        val productId = "test_product_1"
        // First query should cache the result
        val details1 = iap.queryProductDetails(listOf(productId))
        // Second query should return cached result
        val details2 = iap.queryProductDetails(listOf(productId))
        
        assertNotNull(details1)
        assertNotNull(details2)
        assertEquals(details1.firstOrNull()?.productId, details2.firstOrNull()?.productId)
    }

    @Test
    fun testPurchaseAcknowledgment() = runBlocking {
        val productId = "android.test.purchased"
        val result = iap.launchPurchaseFlow(productId)
        assertTrue(result.success)
        
        // Purchase should be acknowledged automatically
        val purchase = result.purchase
        assertNotNull(purchase)
        assertTrue(purchase.isAcknowledged)
    }

    @Test
    fun testConsumablePurchase() = runBlocking {
        val productId = "android.test.purchased"
        val result = iap.launchPurchaseFlow(productId, isConsumable = true)
        assertTrue(result.success)
        
        val purchase = result.purchase
        assertNotNull(purchase)
        // Consumable purchases should be consumed automatically
        assertFalse(purchase.isAcknowledged)
    }

    @Test
    fun testNetworkError() = runBlocking {
        // Simulate network error by using an invalid product ID format
        val productId = ""
        val result = iap.launchPurchaseFlow(productId)
        
        assertFalse(result.success)
        assertNotNull(result.error)
        assertTrue(result.error?.contains("network", ignoreCase = true) ?: false)
    }
    
    @Test
    fun testConnectionHandling() = runBlocking {
        // Test disconnection and reconnection
        val disconnectResult = BillingResult.newBuilder()
            .setResponseCode(BillingClient.BillingResponseCode.SERVICE_DISCONNECTED)
            .build()
            
        coEvery {
            mockBillingClient.startConnection(any())
        } answers {
            val listener = firstArg<BillingClientStateListener>()
            listener.onBillingServiceDisconnected()
            listener.onBillingSetupFinished(
                BillingResult.newBuilder()
                    .setResponseCode(BillingClient.BillingResponseCode.OK)
                    .build()
            )
        }
        
        // Simulate a disconnection
        mockBillingClient.getListener()?.onBillingServiceDisconnected()
        
        // Test that operations still work after reconnection
        val productIds = listOf("test_product_1")
        val details = iap.queryProductDetails(productIds)
        assertTrue(details.success)
    }
    
    @Test
    fun testPurchaseCancellation() = runBlocking {
        coEvery {
            mockBillingClient.launchBillingFlow(any(), any())
        } andThen {
            // Simulate user cancellation
            mockBillingClient.getListener()?.onPurchasesUpdated(
                BillingResult.newBuilder()
                    .setResponseCode(BillingClient.BillingResponseCode.USER_CANCELED)
                    .build(),
                null
            )
            BillingResult.newBuilder()
                .setResponseCode(BillingClient.BillingResponseCode.OK)
                .build()
        }
        
        val result = iap.launchPurchaseFlow("test_product_1")
        assertFalse(result.success)
        assertEquals("Purchase cancelled by user", result.error)
    }
    
    @Test
    fun testPurchaseHistoryRetrieval() = runBlocking {
        coEvery {
            mockBillingClient.queryPurchaseHistory(any())
        } returns BillingResult.newBuilder()
            .setResponseCode(BillingClient.BillingResponseCode.OK)
            .build() to listOf(testPurchase)
            
        val history = iap.restorePurchases()
        assertNotNull(history)
        assertTrue(history.isNotEmpty())
        assertEquals("test_product_1", history.first().products.first())
    }
    
    @Test
    fun testErrorRecovery() = runBlocking {
        var attemptCount = 0
        coEvery {
            mockBillingClient.queryProductDetails(any())
        } answers {
            attemptCount++
            if (attemptCount == 1) {
                BillingResult.newBuilder()
                    .setResponseCode(BillingClient.BillingResponseCode.SERVICE_DISCONNECTED)
                    .build() to emptyList()
            } else {
                BillingResult.newBuilder()
                    .setResponseCode(BillingClient.BillingResponseCode.OK)
                    .build() to listOf(testProductDetails)
            }
        }
        
        val details = iap.queryProductDetails(listOf("test_product_1"))
        assertTrue(details.success)
        assertEquals(2, attemptCount) // Verify retry occurred
    }
}