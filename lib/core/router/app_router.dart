import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/bookings/domain/booking_model.dart';
import '../../features/bookings/presentation/screens/booking_confirmation_screen.dart';
import '../../features/bookings/presentation/screens/booking_success_screen.dart';
import '../../features/bookings/presentation/screens/my_bookings_screen.dart';
import '../../features/bookings/presentation/screens/select_date_time_screen.dart';
import '../../features/doctors/presentation/screens/doctor_details_screen.dart';
import '../../features/doctors/presentation/screens/doctors_list_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/labs/presentation/screens/lab_details_screen.dart';
import '../../features/labs/presentation/screens/labs_list_screen.dart';
import '../../features/map/presentation/screens/nearby_map_screen.dart';
import '../../features/orders/presentation/screens/my_orders_screen.dart';
import '../../features/pharmacies/presentation/screens/pharmacies_list_screen.dart';
import '../../features/pharmacies/presentation/screens/pharmacy_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/radiology/presentation/screens/radiology_details_screen.dart';
import '../../features/radiology/presentation/screens/radiology_list_screen.dart';
import '../widgets/main_shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // 1. Splash
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      // 2. Login
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      // 3. Sign Up
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignUpScreen(),
      ),
      // 4. Reset Password
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),

      // Persistent 4-Tab Bottom Navigation Shell (Screens 5, 11, 18, 19)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: الرئيسية
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 2: الخريطة (Live Nearby Map)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (_, __) => const NearbyMapScreen(),
              ),
            ],
          ),
          // Tab 3: مواعيدي
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (_, __) => const MyBookingsScreen(),
              ),
            ],
          ),
          // Tab 4: طلباتي
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (_, __) => const MyOrdersScreen(),
              ),
            ],
          ),
          // Tab 5: حسابي
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // 6 & 7. Doctors
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/doctors',
        builder: (_, __) => const DoctorsListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/doctors/:id',
        builder: (_, state) => DoctorDetailsScreen(
          doctorId: state.pathParameters['id'] ?? '',
        ),
      ),

      // 8, 9, 10. Booking Flow
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/booking/select-date-time',
        builder: (_, state) {
          final draft = state.extra as BookingDraft;
          return SelectDateTimeScreen(draft: draft);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/booking/confirm',
        builder: (_, state) {
          final draft = state.extra as BookingDraft;
          return BookingConfirmationScreen(draft: draft);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/booking/success',
        builder: (_, state) {
          final booking = state.extra as BookingModel;
          return BookingSuccessScreen(booking: booking);
        },
      ),

      // 12 & 13. Labs
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/labs',
        builder: (_, __) => const LabsListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/labs/:id',
        builder: (_, state) => LabDetailsScreen(
          labId: state.pathParameters['id'] ?? '',
          initialTestId: state.uri.queryParameters['testId'],
        ),
      ),

      // 14 & 15. Pharmacies
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pharmacies',
        builder: (_, __) => const PharmaciesListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pharmacies/:id',
        builder: (_, state) => PharmacyDetailsScreen(
          pharmacyId: state.pathParameters['id'] ?? '',
        ),
      ),

      // 16 & 17. Radiology
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/radiology',
        builder: (_, __) => const RadiologyListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/radiology/:id',
        builder: (_, state) => RadiologyDetailsScreen(
          centerId: state.pathParameters['id'] ?? '',
          initialScanType: state.uri.queryParameters['scanType'],
        ),
      ),
    ],
  );
});
