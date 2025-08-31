import 'package:dev_log/dev_log.dart';
import 'package:flutter/material.dart';

import 'navigation_service.dart';
import 'notification_service.dart';
import 'websocket_data_source.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        L.i('App in foreground - reconnecting WebSocket');
        WebSocketService().reconnect(); // You can create this method if not yet
        final currentChatUser = NavigationService.getCurrentChatUser();
        if (currentChatUser != null) {
          NotificationService.clearNotificationsForUser(currentChatUser);
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        L.i('App moved to background - can manage tasks here');
        break;
      case AppLifecycleState.detached:
        L.i('App is terminating - disconnecting WebSocket');
        WebSocketService().disconnect();
        break;
      case AppLifecycleState.hidden:
        L.i('App is hidden - disconnecting WebSocket');
        WebSocketService().disconnect();
        // throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
