import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../constants.dart';

class AuthProvider extends ChangeNotifier{
  final _storage = const FlutterSecureStorage();
  bool isLoading = false;
  String? errorMessage;
  bool isLoggedIn = false;
  bool hasCheckedAuth = false;

  Future<void> checkLoginStatus() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    isLoggedIn = token != null;
    hasCheckedAuth = true;
    // ignore: avoid_print
    print("hasCheckedAuth has become TRUE!");
    if (isLoggedIn) {
      unawaited(ApiService().processAutoDecrements());
    }
    // ignore: avoid_print
    print("reached");
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      final data = await ApiService().login(username:  username, password: password);
      await _storage.write(key: AppConstants.tokenKey, value: data['access']);
      await _storage.write(key: AppConstants.refreshTokenKey, value: data['refresh']);
      await _storage.write(key: AppConstants.userIdKey, value: data['user_id'].toString());
      isLoggedIn = true;
      unawaited(ApiService().processAutoDecrements());
      return true;
    } catch (e) {
      errorMessage = parseApiError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
    await ApiService().register(username: name, email: email, password: password);
    //auto-login after register
    return await login(name, password);
    } catch (e) {
    errorMessage = parseApiError(e);
    isLoading = false;
    notifyListeners();
    return false;
    }
   }

  Future<void> logout() async {
    await _storage.deleteAll();
    isLoggedIn = false;
    notifyListeners();
  }

  Future<void> forceLogout() async {
    await _storage.deleteAll();
    isLoggedIn = false;
    notifyListeners();
  }
}