import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Re-enable after fixing RevenueCat compatibility
// import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final subscriptionStatusProvider = FutureProvider<SubscriptionStatus>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getSubscriptionStatus();
});

final usageProvider = FutureProvider<UsageInfo>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getUsageInfo();
});

enum SubscriptionTier { free, basic, premium }

class SubscriptionStatus {
  final SubscriptionTier tier;
  final bool isActive;
  final String? expirationDate;
  final String? productId;

  SubscriptionStatus({
    required this.tier,
    required this.isActive,
    this.expirationDate,
    this.productId,
  });

  bool get canSynthesize => isActive;

  int get monthlyLimit {
    switch (tier) {
      case SubscriptionTier.free:
        return 10;
      case SubscriptionTier.basic:
        return 100;
      case SubscriptionTier.premium:
        return 999999; // Unlimited
    }
  }
}

class UsageInfo {
  final int used;
  final int limit;
  final DateTime periodStart;

  UsageInfo({
    required this.used,
    required this.limit,
    required this.periodStart,
  });

  int get remaining => limit - used;
  double get percentage => limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
  bool get hasRemaining => remaining > 0;
  bool get isUnlimited => limit >= 999999;
}

class SubscriptionService {
  final _supabase = Supabase.instance.client;

  /// Get current subscription status (mock for testing)
  /// TODO: Re-enable RevenueCat integration
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    // Mock: return free tier for testing
    return SubscriptionStatus(
      tier: SubscriptionTier.free,
      isActive: true,
    );
  }

  /// Get usage information from Supabase
  Future<UsageInfo> getUsageInfo() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return UsageInfo(
        used: 0,
        limit: 10,
        periodStart: DateTime.now(),
      );
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select('monthly_synthesis_count, monthly_synthesis_limit, current_period_start')
          .eq('id', user.id)
          .single();

      return UsageInfo(
        used: response['monthly_synthesis_count'] ?? 0,
        limit: response['monthly_synthesis_limit'] ?? 10,
        periodStart: DateTime.parse(
          response['current_period_start'] ?? DateTime.now().toIso8601String(),
        ),
      );
    } catch (e) {
      // Return default on error
      return UsageInfo(
        used: 0,
        limit: 10,
        periodStart: DateTime.now(),
      );
    }
  }

  /// Check if user can perform synthesis
  Future<bool> canSynthesize() async {
    final usage = await getUsageInfo();
    return usage.hasRemaining;
  }

  // TODO: Re-enable after fixing RevenueCat compatibility
  // /// Get available offerings (packages)
  // Future<Offerings?> getOfferings() async {
  //   try {
  //     return await Purchases.getOfferings();
  //   } catch (e) {
  //     return null;
  //   }
  // }

  // /// Purchase a package
  // Future<bool> purchasePackage(Package package) async {
  //   try {
  //     final customerInfo = await Purchases.purchasePackage(package);
  //     await _syncSubscriptionToSupabase(customerInfo);
  //     return customerInfo.entitlements.active.isNotEmpty;
  //   } on PurchasesErrorCode catch (e) {
  //     if (e == PurchasesErrorCode.purchaseCancelledError) {
  //       return false;
  //     }
  //     rethrow;
  //   }
  // }

  // /// Restore purchases
  // Future<bool> restorePurchases() async {
  //   try {
  //     final customerInfo = await Purchases.restorePurchases();
  //     await _syncSubscriptionToSupabase(customerInfo);
  //     return customerInfo.entitlements.active.isNotEmpty;
  //   } catch (e) {
  //     return false;
  //   }
  // }
}
