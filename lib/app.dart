import 'package:flutter/material.dart';

import 'core/theme/themedata.dart';
import 'pages/splashscreen/splashscreen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "GoDZilla",
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const Splashscreen(),
    );
  }
}
