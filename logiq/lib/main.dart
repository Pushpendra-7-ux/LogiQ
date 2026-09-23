import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:logiq/app.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/auction_provider.dart';
import 'package:logiq/providers/bid_provider.dart';
import 'package:logiq/providers/admin_provider.dart';
import 'package:logiq/providers/navigation_provider.dart';
import 'package:logiq/providers/draft_timer_provider.dart';
import 'package:logiq/core/database/database_helper.dart';
import 'package:logiq/core/database/database_seed.dart';
import 'package:logiq/core/database/database_factory.dart' as db_init;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  db_init.initDatabaseFactory();

  try {
    final db = await DatabaseHelper.instance.database;
    await DatabaseSeed.ensureSeeded(db);
  } catch (e) {
    debugPrint('Database initialization warning: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => TenderProvider()),
        ChangeNotifierProvider(create: (_) => AuctionProvider()),
        ChangeNotifierProvider(create: (_) => BidProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => DraftTimerProvider()),
      ],
      child: const LogiQApp(),
    ),
  );
}
