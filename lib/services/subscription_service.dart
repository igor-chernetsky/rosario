import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform_helper.dart';

/// Single shared instance so [purchaseStream] is only subscribed once and
/// [purchasePending] is not split across multiple dialog opens.
class SubscriptionService {
  SubscriptionService._internal();
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;

  static const String _subscriptionKey = 'is_subscribed';
  /// Product ID must match App Store Connect (iOS) and Google Play (Android).
  static const String subscriptionProductId = 'pro';
  static const String _subscriptionProductId = subscriptionProductId;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _purchasePending = false;
  Timer? _stalePurchaseTimer;

  void _cancelStalePurchaseTimer() {
    _stalePurchaseTimer?.cancel();
    _stalePurchaseTimer = null;
  }

  /// If StoreKit never sends a terminal update (common on simulator), unblock new attempts.
  void _scheduleStalePurchaseReset() {
    _cancelStalePurchaseTimer();
    _stalePurchaseTimer = Timer(const Duration(minutes: 2), () {
      if (_purchasePending) {
        _purchasePending = false;
      }
      _stalePurchaseTimer = null;
    });
  }

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
      await _subscription?.cancel();
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (_) {},
      );

      await loadProducts();
      await restorePurchases();
    }
  }

  // Load available products
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final Set<String> productIds = {_subscriptionProductId};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

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
      applicationUserName: isIOS ? 'rosario_app_user' : null,
    );

    _purchasePending = true;
    bool success = false;
    try {
      success = await _inAppPurchase
          .buyNonConsumable(purchaseParam: purchaseParam)
          .timeout(
        const Duration(seconds: 45),
        onTimeout: () => false,
      );
    } catch (_) {
      success = false;
    }

    if (!success) {
      _purchasePending = false;
      _cancelStalePurchaseTimer();
    } else {
      _scheduleStalePurchaseReset();
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
      if (purchaseDetails.status != PurchaseStatus.pending) {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _purchasePending = false;
          _cancelStalePurchaseTimer();
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          _purchasePending = false;
          _cancelStalePurchaseTimer();
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _verifyPurchase(purchaseDetails);
          _cancelStalePurchaseTimer();
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  // Verify purchase and activate subscription
  void _verifyPurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.productID == _subscriptionProductId) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        setSubscribed(true);
        _purchasePending = false;
      }
    } else {
      _purchasePending = false;
    }
  }

  /// Whether the store is available (can be false on iOS if not configured or in simulator without StoreKit config).
  bool get isStoreAvailable => _isAvailable;

  /// Check current subscription status (restores purchases on iOS/Android and returns cached status).
  Future<bool> checkSubscriptionStatus() async {
    if (!_isAvailable) {
      return await isSubscribed();
    }

    await restorePurchases();

    return await isSubscribed();
  }

  // Dispose
  void dispose() {
    _cancelStalePurchaseTimer();
    _subscription?.cancel();
    _subscription = null;
  }
}
