import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  String? _token;
  StreamSubscription<String>? _refreshSub;

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