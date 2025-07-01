import { invoke } from '@tauri-apps/api/core'
import { listen, UnlistenFn } from '@tauri-apps/api/event'

// --- Types and Interfaces ---

/**
 * Product details from the app store (Apple App Store or Google Play)
 * @interface ProductDetails
 */
export interface ProductDetails {
  /** Unique identifier of the product */
  id: string;
  /** Localized title of the product */
  title: string;
  /** Localized description of the product */
  description: string;
  /** Localized price of the product (formatted string with currency symbol) */
  price: string;
  /** Raw numerical value of the price */
  rawPrice: number;
  /** ISO 4217 currency code (e.g., "USD") */
  currencyCode: string;
  /** Currency symbol (e.g., "$") */
  currencySymbol: string;
}

/**
 * Purchase verification data used for server-side validation
 * @interface PurchaseVerificationData
 */
export interface PurchaseVerificationData {
  /** Platform-specific local verification data */
  localVerificationData: string;
  /** Platform-specific server verification data */
  serverVerificationData: string;
  /** Source platform ("apple" or "google") */
  source: string;
}

/**
 * Status of a purchase transaction
 * @enum {string}
 */
export enum PurchaseStatus {
  /** Purchase is in progress */
  pending = "pending",
  /** Purchase completed successfully */
  purchased = "purchased",
  /** Purchase encountered an error */
  error = "error",
  /** Purchase was restored from the store */
  restored = "restored",
  /** Purchase was canceled by the user */
  canceled = "canceled",
}

/**
 * Error information for IAP operations
 * @interface IAPError
 */
export interface IAPError {
  /** Error code */
  code: string;
  /** Human-readable error message */
  message: string;
  /** Additional error details (optional) */
  details?: any;
}

/**
 * Details of a purchase transaction
 * @interface PurchaseDetails
 */
export interface PurchaseDetails {
  /** Unique identifier for the purchase (optional) */
  purchaseID?: string;
  /** Identifier of the purchased product */
  productID: string;
  /** Verification data for server-side validation */
  verificationData: PurchaseVerificationData;
  /** ISO datetime string of the transaction (optional) */
  transactionDate?: string;
  /** Current status of the purchase */
  status: PurchaseStatus;
  /** Error information if status is 'error' (optional) */
  error?: IAPError;
  /** Whether the purchase needs to be completed */
  pendingCompletePurchase: boolean;
}

/**
 * Parameters for initiating a purchase
 * @interface PurchaseParam
 */
export interface PurchaseParam {
  /** Product details of the item to purchase */
  productDetails: ProductDetails;
  /** Application-specific user identifier (optional) */
  applicationUserName?: string;
}

/**
 * Response from querying product details
 * @interface ProductDetailsResponse
 */
export interface ProductDetailsResponse {
  /** Array of found product details */
  productDetails: ProductDetails[];
  /** Array of product IDs that were not found */
  notFoundIDs: string[];
  /** Error information if the query partially failed (optional) */
  error?: IAPError;
}

// --- API Methods ---

/**
 * Initializes the IAP plugin
 * @returns Promise that resolves when initialization is complete
 * @throws {IAPError} If initialization fails
 * @example
 * ```ts
 * await initialize();
 * ```
 */
export async function initialize(): Promise<void> {
  await invoke('plugin:iap|initialize');
}

/**
 * Checks if in-app purchases are available on the current platform
 * @returns Promise that resolves to true if IAP is available, false otherwise
 * @example
 * ```ts
 * const available = await isAvailable();
 * if (available) {
 *   // IAP is supported on this platform
 * }
 * ```
 */
export async function isAvailable(): Promise<boolean> {
  return await invoke('plugin:iap|is_available');
}

/**
 * Queries details for multiple products from the store
 * @param productIds - Array of product identifiers to query
 * @returns Promise that resolves to product details and any not found products
 * @throws {IAPError} If the query fails
 * @example
 * ```ts
 * const response = await queryProductDetails(['product_1', 'product_2']);
 * console.log('Found products:', response.productDetails);
 * console.log('Not found products:', response.notFoundIDs);
 * ```
 */
export async function queryProductDetails(productIds: string[]): Promise<ProductDetailsResponse> {
  return await invoke('plugin:iap|query_product_details', { productIds });
}

/**
 * Initiates purchase of a non-consumable product
 * @param purchaseParam - Parameters for the purchase
 * @returns Promise that resolves to true if purchase was successful
 * @throws {IAPError} If the purchase fails
 * @example
 * ```ts
 * const success = await buyNonConsumable({
 *   productDetails: product,
 *   applicationUserName: 'user123'
 * });
 * ```
 */
export async function buyNonConsumable(purchaseParam: PurchaseParam): Promise<boolean> {
  return await invoke('plugin:iap|buy_non_consumable', { purchaseParam });
}

/**
 * Initiates purchase of a consumable product
 * @param purchaseParam - Parameters for the purchase
 * @param autoConsume - Whether to automatically consume the purchase after successful transaction
 * @returns Promise that resolves to true if purchase was successful
 * @throws {IAPError} If the purchase fails
 * @example
 * ```ts
 * const success = await buyConsumable({
 *   productDetails: product,
 *   applicationUserName: 'user123'
 * }, true);
 * ```
 */
export async function buyConsumable(purchaseParam: PurchaseParam, autoConsume?: boolean): Promise<boolean> {
  return await invoke('plugin:iap|buy_consumable', { purchaseParam, autoConsume });
}

/**
 * Completes a purchase transaction
 * @param purchase - Details of the purchase to complete
 * @returns Promise that resolves when the purchase is completed
 * @throws {IAPError} If completion fails
 * @example
 * ```ts
 * await completePurchase(purchaseDetails);
 * ```
 */
export async function completePurchase(purchase: PurchaseDetails): Promise<void> {
  await invoke('plugin:iap|complete_purchase', { purchase });
}

/**
 * Restores previously purchased items
 * @param applicationUserName - Optional user identifier for the restoration
 * @returns Promise that resolves when restoration is complete
 * @throws {IAPError} If restoration fails
 * @example
 * ```ts
 * await restorePurchases('user123');
 * ```
 */
export async function restorePurchases(applicationUserName?: string): Promise<void> {
  await invoke('plugin:iap|restore_purchases', { applicationUserName });
}

/**
 * Gets the store country/region code
 * @returns Promise that resolves to the ISO country code
 * @throws {IAPError} If retrieval fails
 * @example
 * ```ts
 * const country = await countryCode();
 * console.log('Store region:', country);
 * ```
 */
export async function countryCode(): Promise<string> {
  return await invoke('plugin:iap|country_code');
}

/**
 * Registers a handler for purchase updates
 * @param handler - Callback function that receives purchase updates
 * @returns Promise that resolves to an unlisten function
 * @example
 * ```ts
 * const unsubscribe = await onPurchaseUpdate((purchases) => {
 *   for (const purchase of purchases) {
 *     console.log('Purchase updated:', purchase);
 *   }
 * });
 *
 * // Later: unsubscribe to stop receiving updates
 * unsubscribe();
 * ```
 */
export async function onPurchaseUpdate(
  handler: (purchases: PurchaseDetails[]) => void
): Promise<UnlistenFn> {
  return await listen<PurchaseDetails[]>('tauri-plugin-iap://purchase-update', (event) => {
    handler(event.payload);
  });
}

