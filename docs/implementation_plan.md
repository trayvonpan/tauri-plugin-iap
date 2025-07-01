# Implementation Plan: `tauri-plugin-iap` In-App Purchase Plugin

This document outlines the detailed plan for implementing the `tauri-plugin-iap` In-App Purchase plugin, covering all aspects of the design document.

### 1. Project Goal & Guiding Principles

- **Goal:** To provide a single, unified JavaScript/TypeScript API for developers to implement In-App Purchases (IAP) in a Tauri application, abstracting away the platform-specific native complexities of Apple StoreKit and Google Play Billing.
- **Guiding Principles:**
  - **Unified API:** Identical JavaScript API across all platforms.
  - **Lean Core:** Rust core acts as a thin, safe bridge.
  - **Platform-Specific Modules:** Native code (Swift, Kotlin) and FFI/JNI bindings are isolated.
  - **Security First:** Plugin provides secure `receipt`/`token`; server-side validation is mandatory.
  - **Clear Error Handling:** Distinct error types for failures.
  - **Non-Blocking:** All API calls are asynchronous.

### 2. Implementation Steps

1. **Project Initialization**

   - Create new plugin using Tauri CLI
   - Set up project structure following official template
   - Configure initial Cargo.toml and package.json

2. **Core Rust Implementation**

   - Implement data structures in src/models.rs
   - Create error types in src/error.rs
   - Define command interface in src/commands.rs
   - Set up plugin in src/lib.rs

3. **Platform Integration**

   - Create iOS Swift package with StoreKit implementation
   - Develop Android library with Google Play Billing
   - Implement platform bridges in src/mobile.rs
   - Add desktop fallback in src/desktop.rs

4. **JavaScript API Development**

   - Design TypeScript interface in guest-js/
   - Implement API methods and types
   - Set up build process to generate dist-js/

5. **Commands and Permissions**

   - Register plugin commands
   - Configure command permissions
   - Set up event system for purchase updates
   - Implement error handling

6. **Testing and Documentation**

   - Write unit and integration tests
   - Create example applications
   - Document API and usage
   - Add server-side validation guide

7. **Release and Maintenance**
   - Publish to crates.io and npm
   - Set up version management
   - Monitor and handle issues

### 3. Detailed Breakdown:

1.  **Understand Requirements:**

    - 1.1: The project provides a unified, asynchronous JavaScript/TypeScript API for IAP in Tauri apps, abstracting Apple StoreKit and Google Play Billing via a Rust core and native Swift/Kotlin modules. Architecture and principles are detailed in [`docs/tauri_plugin_iap_design.md`](docs/tauri_plugin_iap_design.md).
    - 1.2: Rust core dependencies are managed in [`Cargo.toml`](Cargo.toml). Platform-specific native code uses Swift (via `swift-rs` for StoreKit on Apple platforms) and Kotlin (via JNI for Google Play Billing on Android), as described in the design doc.
    - 1.3: The JavaScript/TypeScript API surface is defined in [`guest-js/index.ts`](guest-js/index.ts) and [`guest-js/types.ts`](guest-js/types.ts), including:
      - Functions: `initialize`, `isAvailable`, `queryProductDetails`, `buyNonConsumable`, `buyConsumable`, `completePurchase`, `restorePurchases`, `countryCode`, `onPurchaseUpdate`.
      - Data models: `ProductDetails`, `PurchaseDetails`, `PurchaseParam`, `PurchaseStatus`, `PurchaseVerificationData`, `IAPError`, `ProductDetailsResponse`.
      - Event: `onPurchaseUpdate` (listens for purchase updates via Tauri events).

2.  **Project Setup:**

    - 2.1: The project was initialized using the Tauri CLI to scaffold a new plugin structure.
    - 2.2: The Rust core crate is located at the root directory, with its manifest in [`Cargo.toml`](Cargo.toml).
    - 2.3: `Cargo.toml` manages Rust dependencies and platform-specific features. Native code integration (Swift/Kotlin) is handled via build scripts and platform modules as described in the design doc.
    - 2.4: The JavaScript/TypeScript API is implemented in [`guest-js`](guest-js/), with configuration in [`package.json`](package.json) and [`tsconfig.json`](tsconfig.json).

3.  **Core Module Implementation:**

    - 3.1: Implement core data structures in `src/models.rs` using `serde` for serialization.
    - 3.2: Define the command interface in `src/commands.rs` for webview interactions.
    - 3.3: Create error types and handling in `src/error.rs`.
    - 3.4: Implement the plugin setup in `src/lib.rs` with command registration and re-exports.

4.  **Platform Adaptation:**

    - 4.1: Create the iOS implementation:
      - Set up Swift package in `ios/` directory
      - Implement StoreKit wrapper in Swift
      - Create FFI bridge in `src/mobile.rs` for iOS
    - 4.2: Create the Android implementation:
      - Set up Android library in `android/` directory
      - Implement Google Play Billing wrapper in Kotlin
      - Create JNI bridge in `src/mobile.rs` for Android
    - 4.3: Implement the desktop fallback in `src/desktop.rs`, returning appropriate errors for unsupported operations.

5.  **Interface Design:**

    - 5.1: Design the JavaScript/TypeScript API in `guest-js` with promise-based functions.
    - 5.2: Generate TypeScript types from Rust models.
    - 5.3: Build and output transpiled JavaScript to `dist-js`.

6.  **Data Flow Implementation:**

    - 6.1: Set up command invocations from JavaScript to Rust.
    - 6.2: Configure command permissions in the `permissions/` directory.
    - 6.3: Implement error propagation through the invoke system.
    - 6.4: Set up event emitters for asynchronous updates.

7.  **Security Implementation:**

    - 8.1: Document the server-side validation requirement, emphasizing that the client-side should never be trusted for purchase verification.
    - 8.2: Implement the handling of receipt/token strings, ensuring they are sent to the developer's server for validation.

8.  **Testing and Documentation:**

    - 9.1: Write unit tests for the Rust core and platform-specific modules.
    - 9.2: Write integration tests to ensure the plugin works correctly with a Tauri application.
    - 9.3: Write comprehensive documentation covering installation, API usage, error handling, and server-side validation.
    - 9.4: Create a basic example Tauri app to demonstrate the plugin's functionality.

9.  **Release and Maintenance:**
    - 10.1: Publish the plugin to `crates.io` (Rust core) and `npm` (JavaScript/TypeScript API).
    - 10.2: Monitor issues and pull requests on the plugin's repository.
    - 10.3: Implement feature requests and address bug reports.
    - 10.4: Update dependencies regularly to ensure compatibility and security.
