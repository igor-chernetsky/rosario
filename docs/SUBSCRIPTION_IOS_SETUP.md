# iOS subscription setup (In-App Purchase)

For subscriptions / in-app purchases to work on iOS, you need to configure App Store Connect and Xcode. Until this is done, the store will report as unavailable or the product will not load.

## 1. App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → your app → **Features** → **In-App Purchases**.
2. Click **+** to create a new in-app purchase.
3. Choose type:
   - **Non-Consumable** (one-time unlock, recommended for “pro” lifetime access) — matches the app’s use of `buyNonConsumable`.
   - Or **Auto-Renewable Subscription** if you want recurring billing (you’d still use the same purchase flow; renewal/expiry would need extra handling).
4. Use **Product ID**: `pro` (must match `SubscriptionService.subscriptionProductId` in code).
5. Fill **Reference Name**, **Pricing**, and **Availability**.
6. Submit for review with your app (or save for later). Product status must be **Ready to Submit** for it to be queryable in production/sandbox.

## 2. Xcode: In-App Purchase capability

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Click **+ Capability** and add **In-App Purchase**.

Without this, `InAppPurchase.isAvailable()` can be false or purchases will fail.

## 3. Testing: StoreKit Configuration (optional but recommended)

To test purchases in the simulator or on a device without App Store review:

1. In Xcode: **File** → **New** → **File** → **StoreKit Configuration File**.
2. Add a product with Product ID `pro` (type: Non-Consumable or Subscription, as in App Store Connect).
3. In the scheme: **Product** → **Scheme** → **Edit Scheme** → **Run** → **Options** → **StoreKit Configuration** → select this `.storekit` file.

Then run the app from Xcode; the StoreKit config is used so the product loads and purchases can be tested.

## 4. Sandbox testing (real App Store Connect product)

1. On the device/simulator, sign out of the real Apple ID in **Settings** → **App Store** (or use a dedicated Sandbox account).
2. Create a **Sandbox Tester** in App Store Connect: **Users and Access** → **Sandbox** → **Testers**.
3. When the app triggers a purchase, sign in with the Sandbox tester Apple ID when prompted.
4. Purchases and restores will use the sandbox product (same ID `pro`).

## 5. Checklist

- [ ] In-App Purchase capability added in Xcode (Runner target).
- [ ] Product with ID `pro` created in App Store Connect (Non-Consumable or Subscription).
- [ ] Product status **Ready to Submit** (or equivalent) so it can be queried.
- [ ] For local testing: StoreKit Configuration file with product `pro` and selected in the Run scheme.
- [ ] Paid Applications Agreement and banking/tax info completed in App Store Connect (required for real/sandbox sales).

## 6. “Manage Subscription” on iOS

When the user taps **Manage Subscription** and the app is running on iOS, the app opens:

`https://apps.apple.com/account/subscriptions`

so the user can manage subscriptions in the App Store. This is implemented in `lib/screens/settings.dart` using the `isIOS` platform helper.

## 7. Restore purchases

**Restore Purchases** in the subscription dialog calls `InAppPurchase.restorePurchases()`. On iOS this uses StoreKit’s restore flow; the purchase stream then receives restored transactions and the app marks the user as subscribed via `SubscriptionService.setSubscribed(true)`.
