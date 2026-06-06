import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_shell.dart';
import '../screens/store_detail/store_detail_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Splash Screen
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    
    // Main Shell (Bottom Nav)
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShell(),
    ),
    
    // Auth
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // Store Detail
    GoRoute(
      path: '/store/:id',
      builder: (context, state) {
        final idOrSlug = state.pathParameters['id'] ?? '';
        return StoreDetailScreen(slugOrId: idOrSlug);
      },
    ),

    // Product Detail
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'];
        final id = int.tryParse(idStr ?? '') ?? 0;
        return ProductDetailScreen(productId: id);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);
