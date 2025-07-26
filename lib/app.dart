import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/remote/app_lifecycle_manager.dart';
import 'data/datasources/remote/navigation_service.dart';
import 'presentation/pages/splashscreen/splashscreen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLifecycleManager(
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: "Chatter G",
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: const Splashscreen(),
        // routes: appRoutes,
      ),
    );
  }
}
