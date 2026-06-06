import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Standard for clean URLs
import 'package:seo/seo.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/stores_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/demands_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/units_provider.dart';
import 'providers/locations_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/subscription_plans_provider.dart';
import 'providers/notifications_provider.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use PathUrlStrategy to remove the '#' from URLs on web
  usePathUrlStrategy();

  // Initialize API service
  final apiService = ApiService();
  await apiService.init();

  runApp(const AlamatiApp());
}

class AlamatiApp extends StatelessWidget {
  const AlamatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => StoresProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => DemandsProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => UnitsProvider()),
        ChangeNotifierProvider(create: (_) => LocationsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionPlansProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: SeoController(
        enabled: kIsWeb,
        tree: WidgetTree(context: context),
        child: MaterialApp.router(
          title: '3alamati',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
