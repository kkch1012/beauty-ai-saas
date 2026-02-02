import 'dart:io';

/// Environment configuration
/// Values are injected at build time via --dart-define
class Env {
  Env._();

  // Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // RevenueCat
  static const String revenueCatAppleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: '',
  );

  static const String revenueCatGoogleKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: '',
  );

  // AI Server
  static const String aiServerUrl = String.fromEnvironment(
    'AI_SERVER_URL',
    defaultValue: 'http://localhost:8000',
  );

  // App Config
  static const bool isProduction = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  ) == 'production';

  // Platform
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
}
