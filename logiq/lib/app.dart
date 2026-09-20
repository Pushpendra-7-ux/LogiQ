import 'package:flutter/material.dart';

import 'package:logiq/core/router/app_router.dart';
import 'package:logiq/core/theme/app_theme.dart';

/// Root widget for the LogiQ application.
///
/// Wraps [MaterialApp.router] with the app theme and go_router config.
/// Provider tree is set up above this in main.dart.
class LogiQApp extends StatefulWidget {
  const LogiQApp({super.key});

  @override
  State<LogiQApp> createState() => _LogiQAppState();
}

class _LogiQAppState extends State<LogiQApp> {
  late final _router = buildRouter(context);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LOGIQ',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
