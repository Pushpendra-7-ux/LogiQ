import 'package:flutter/material.dart';

import 'package:logiq/core/router/app_router.dart';
import 'package:logiq/core/theme/app_theme.dart';

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
