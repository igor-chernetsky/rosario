import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _subscriptionKey = 'is_subscribed';
  /// Product ID must match App Store Connect (iOS) and Google Play (Android).
  static const String subscriptionProductId = 'pro';
  static const String _subscriptionProductId = subscriptionProductId;
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _purchasePending = false;

  // Check if subscription is active
  static Future<bool> isSubscribed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_subscriptionKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  // Set subscription status
  static Future<void> setSubscribed(bool isSubscribed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_subscriptionKey, isSubscribed);
    } catch (_) {
      // ignore write errors
    }
  }

  // Initialize the service
  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (_isAvailable) {
      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('Purchase stream error: $error'),
      );

      // Load products
      await loadProducts();
      
      // Restore purchases
      await restorePurchases();
    }
  }

  // Load available products
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final Set<String> productIds = {_subscriptionProductId};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Product not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
  }

  // Get product details
  ProductDetails? getProduct() {
    return _products.isNotEmpty ? _products.first : null;
  }

  // Purchase subscription
  Future<bool> purchaseSubscription() async {
    if (!_isAvailable || _products.isEmpty || _purchasePending) {
      return false;
    }

    final ProductDetails productDetails = _products.first;
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    _purchasePending = true;
    final bool success = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!success) {
      _purchasePending = false;
    }

    return success;
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    await _inAppPurchase.restorePurchases();
  }

  // Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        debugPrint('Purchase pending');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
          _purchasePending = false;
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Verify and activate subscription
          _verifyPurchase(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  // Verify purchase and activate subscription
  void _verifyPurchase(PurchaseDetails purchaseDetails) {
    // Check if this is our subscription product
    if (purchaseDetails.productID == _subscriptionProductId) {
      // Verify the purchase is valid
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Activate subscription
        setSubscribed(true);
        _purchasePending = false;
        debugPrint('Subscription activated');
      }
    }
  }

  /// Whether the store is available (can be false on iOS if not configured or in simulator without StoreKit config).
  bool get isStoreAvailable => _isAvailable;

  /// Check current subscription status (restores purchases on iOS/Android and returns cached status).
  Future<bool> checkSubscriptionStatus() async {
    if (!_isAvailable) {
      return await isSubscribed();
    }

    // Restore purchases to check current status
    await restorePurchases();
    
    // Return cached status (will be updated by purchase stream)
    return await isSubscribed();
  }

  // Dispose
  void dispose() {
    _subscription?.cancel();
  }
}

