import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  static const _allowedRoutes = {'/dashboard'};
  bool _handlersReady = false;

  String? _token;
  StreamSubscription<String>? _refreshSub;

  Future<void> initMessageHandkers({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
    required GoRouter router,
    required VoidCallback onForegroundMessage,
  }) async {
    if (_handlersReady) return;
    _handlersReady = true;

    void open(RemoteMessage m) {
      final route = m.data['route'];
      if (route is String && _allowedRoutes.contains(route)) router.go(route);
    }

    FirebaseMessaging.onMessage.listen((m) {
      onForegroundMessage();
      final n = m.notification;
      if (n == null) return;
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (n.title != null)
               Text(n.title!, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (n.body != null) Text(n.body!),
            ],
          ),
          action: SnackBarAction(label: 'Lihat', onPressed: () => open(m)),
          ));
    });

    FirebaseMessaging.onMessageOpenedApp.listen(open);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) open(initial);
  }

  Future<void> registerDevice() async {
    try {
      final messanging = FirebaseMessaging.instance;
      await messanging.requestPermission();
      // ignore: deprecated_member_use
      _token = await messanging.getToken();
      if (_token != null) await ApiService().registerDeviceToken(_token!);

      // ignore: deprecated_member_use
      _refreshSub ??= messanging.onTokenRefresh.listen((newToken) async {
        _token = newToken;
        try {
         await ApiService().registerDeviceToken(newToken);
        } catch (_) {}
      });
    } catch (e) {
      // ignore: avoid_print
      print('Device registration failed silently: $e');
    }
  }

  Future<void> unregisterDevice() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    try {
      // ignore: deprecated_member_use
      final token = _token ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService()
          .unregisterDeviceToken(token)
          .timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Device unregistration failed silently: $e');
    }
    _token = null;
  }
}