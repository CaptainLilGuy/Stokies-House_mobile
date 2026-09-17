import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homeventory/models/category.dart';
import '../constants.dart';

class ApiService{
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  void Function()? onSessionExpired;

  ApiService._internal(){
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'content-type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async{
        if (e.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            try {
              final retryResponse = await _dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              return handler.next(e);
            }
          } else {
            await _storage.deleteAll();
            onSessionExpired?.call();
          }
        }
        return handler.next(e);
      },
    ));
  }

  // ─── AUTH ──────────────────────────────────────────────

  Future<Map<String, dynamic>> register ({
    required String username,
    required String password,
    required String email,
  }) async {
    final res = await _dio.post('/users/register/', data: {
      'username': username,
      'password': password,
      'email': email,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> login ({
    required String username,
    required String password,
  }) async {
    final res = await _dio.post('/users/login/', data: {
      'username': username,
      'password': password,
    });
    return res.data;
  }

  // ─── INVENTORY ─────────────────────────────────────────

  Future<List<dynamic>> getInventory() async {
    final res = await _dio.get('/inventory/items/');
    return res.data;
  }

  Future<Map<String, dynamic>> addItem(Map<String, dynamic> item) async {
    final res = await _dio.post('/inventory/items/', data: item);
    return res.data;
  }

  Future<Map<String, dynamic>> updateItem(int id, Map<String, dynamic> item) async {
    final res = await _dio.put('/inventory/items/$id/', data: item);
    return res.data;
  }

  Future<void> deleteItem(int id) async {
    await _dio.delete('/inventory/items/$id/');
  }

  Future<void> restockItem(int itemId, double quantityDelta, {String? note}) async {
    await _dio.post('/inventory/transactions/', data: {
      'item': itemId,
      'change_type': 'restocked',
      'quantity_delta': quantityDelta,
      'source': 'manual',
      if (note != null && note.isNotEmpty)'note': note,
    });
  }

  Future<List<Category>> getCategories() async {
    final response = await _dio.get('/inventory/categories/');
    return (response.data as List)
      .map((e) => Category.fromJson(e))
      .toList();
  }

  Future<void> addCategory(String name) async {
    await _dio.post('/inventory/categories/', data: {'name':name});
  }

  Future<void> deleteCategory(int id) async {
    await _dio.delete('/inventory/categories/$id/');
  }

  Future<void> getItemDetail(int id) async {
    await _dio.get('/inventory/$id/');
  }

  Future<void> processAutoDecrements() async {
    try {
      await _dio.post('/inventory/process-auto-decrements/');
    } catch (e) {
      // ignore: avoid_print
      print('Auto-decrement processing failed silently: $e');
    }
  }

  Future<Map<String, dynamic>> parseReceipt(String rawText) async {
    final response = await _dio.post(
      '/inventory/ocr-parse/', data: {'raw_text': rawText},
    );
      return response.data as Map<String, dynamic>;
  }

  // ─── Expense ─────────────────────────────────────────
  Future<List<dynamic>> getExpenses() async {
    final res = await _dio.get('/expense/');
    return res.data;
  }

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> expense) async {
    final res = await _dio.post('/expense/', data: expense);
    return res.data;
  }


  // ─── Household ─────────────────────────────────────────


  Future<Map<String, dynamic>?> getHousehold() async {
    try {
      final res = await _dio.get('/households/me/');
      return res.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createHousehold(String name) async {
    final res = await _dio.post('/households/create/', data: {'name': name});
    return res.data;
  }

  Future<Map<String, dynamic>> joinHousehold(String code) async {
    final res = await _dio.post('/households/join/', data: {'invite_code': code});
    return res.data;
  }

  // ─── Others ───────────────────────────────────────────

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final res = await Dio(BaseOptions(baseUrl: AppConstants.baseUrl)).post(
        '/users/token/refresh/',
        data: {'refresh': refreshToken},
      );
      await _storage.write(key: AppConstants.tokenKey, value: res.data['access']);
      return true;
    } catch (e) {
      return false;
    }
  }

}

String parseApiError(dynamic error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      if (data.containsKey('detail')) return data['detail'];
      final firstKey = data.keys.first;
      final firstVal = data[firstKey];
      if (firstVal is List) return '$firstKey: ${firstVal.join(', ')}';
      return firstVal.toString();
    }
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timed out. Check your server.';
    }
  }
  return 'Something went wrong on the API';
}