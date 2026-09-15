import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/tender_provider.dart';
import 'providers/auction_provider.dart';
import 'providers/admin_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LogiQApp());
}

class LogiQApp extends StatelessWidget {
  const LogiQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TenderProvider()),
        ChangeNotifierProvider(create: (_) => AuctionProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp.router(
        title: 'LogiQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}