// lib/services/app_lifecycle_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';
import 'websocket_data_source.dart';

class AppLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;
  const AppLifecycleManager({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}
final lifecycleManagerStateProvider = StateProvider<_AppLifecycleManagerState?>((ref) => null);


class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager> with WidgetsBindingObserver {
  String? _currentUserUUID;
  WebSocketService? _webSocketService;
  
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
  
  void setUserUUID(String userUUID) {
    _currentUserUUID = userUUID;
  }
  
  void setWebSocketService(WebSocketService webSocketService) {
    _webSocketService = webSocketService;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed - connecting WebSocket');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        print('App paused - WebSocket will handle disconnection');
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        print('App detached - disconnecting WebSocket');
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        break;
    }
  }
  
  void _handleAppResumed() {
    // Reconnect WebSocket when app comes to foreground
    if (_currentUserUUID != null && _webSocketService != null) {
      if (!_webSocketService!.isConnected) {
        final wsUrl = 'wss://chatterg-go-production.up.railway.app/ws?userID=$_currentUserUUID';
        _webSocketService!.connect(wsUrl);
      }
    }
    
    // Clear notifications when app is opened
    NotificationService.clearAllNotifications();
  }
  
  void _handleAppPaused() {
    // WebSocket service will handle disconnection automatically
    // No need to manually disconnect here as it might interfere with background message handling
  }
  
  void _handleAppDetached() {
    // App is being terminated, clean up resources
    _webSocketService?.disconnect();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Provider for app lifecycle manager
final appLifecycleManagerProvider = StateProvider<AppLifecycleManager?>((ref) => null);