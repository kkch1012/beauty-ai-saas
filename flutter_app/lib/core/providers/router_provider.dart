import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/capture/presentation/capture_screen.dart';
import '../../features/simulation/presentation/simulation_screen.dart';
import '../../features/design/presentation/design_library_screen.dart';
import '../../features/customer/presentation/customer_list_screen.dart';
import '../../features/customer/presentation/customer_detail_screen.dart';
import '../../features/booking/presentation/booking_calendar_screen.dart';
import '../../features/contract/presentation/contract_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../services/auth_service.dart';
import '../../shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authService.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // Home / Capture
          GoRoute(
            path: '/',
            builder: (context, state) => const CaptureScreen(),
          ),

          // Design Library
          GoRoute(
            path: '/designs',
            builder: (context, state) => const DesignLibraryScreen(),
          ),

          // Customers
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CustomerDetailScreen(customerId: id);
                },
              ),
            ],
          ),

          // Bookings
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingCalendarScreen(),
          ),

          // Settings
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Simulation (full screen)
      GoRoute(
        path: '/simulation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SimulationScreen(
            targetImagePath: extra?['targetImagePath'],
            customerId: extra?['customerId'],
          );
        },
      ),

      // Contract (full screen)
      GoRoute(
        path: '/contract',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ContractScreen(
            customerId: extra?['customerId'],
            simulationId: extra?['simulationId'],
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
