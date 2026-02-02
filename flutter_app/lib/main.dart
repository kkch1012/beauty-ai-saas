import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Re-enable after fixing RevenueCat compatibility
// import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/env.dart';
import 'core/providers/router_provider.dart';
import 'core/constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (tablet landscape/portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // TODO: Re-enable after fixing RevenueCat compatibility
  // await _initRevenueCat();

  runApp(
    const ProviderScope(
      child: BeautyAIApp(),
    ),
  );
}

// TODO: Re-enable after fixing RevenueCat compatibility
// Future<void> _initRevenueCat() async {
//   await Purchases.setLogLevel(LogLevel.debug);
//
//   PurchasesConfiguration configuration;
//
//   if (Env.isIOS) {
//     configuration = PurchasesConfiguration(Env.revenueCatAppleKey);
//   } else {
//     configuration = PurchasesConfiguration(Env.revenueCatGoogleKey);
//   }
//
//   await Purchases.configure(configuration);
//
//   // Link with Supabase user if logged in
//   final user = Supabase.instance.client.auth.currentUser;
//   if (user != null) {
//     await Purchases.logIn(user.id);
//   }
// }

class BeautyAIApp extends ConsumerWidget {
  const BeautyAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Beauty AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        // Disable text scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}
