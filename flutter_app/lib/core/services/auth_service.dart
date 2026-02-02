import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Re-enable after fixing RevenueCat compatibility
// import 'package:purchases_flutter/purchases_flutter.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

class AuthService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? businessName,
    String? ownerName,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'business_name': businessName,
        'owner_name': ownerName,
        'phone': phone,
      },
    );

    // TODO: Re-enable after fixing RevenueCat compatibility
    // if (response.user != null) {
    //   await Purchases.logIn(response.user!.id);
    // }

    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // TODO: Re-enable after fixing RevenueCat compatibility
    // if (response.user != null) {
    //   await Purchases.logIn(response.user!.id);
    // }

    return response;
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    final response = await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.beautyai://login-callback',
    );

    return response;
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    final response = await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.beautyai://login-callback',
    );

    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    // TODO: Re-enable after fixing RevenueCat compatibility
    // await Purchases.logOut();
    await _supabase.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .single();

    return response;
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;

    await _supabase
        .from('profiles')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', currentUser!.id);
  }
}
