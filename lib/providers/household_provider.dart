import 'package:flutter/material.dart';
import '../models/household.dart';
import '../services/api_service.dart';

enum HouseholdStatus {idle, loading, loaded, error}

class HouseholdProvider extends ChangeNotifier {
  Household? household;
  HouseholdStatus status = HouseholdStatus.idle;
  String? errorMessage;

  bool get hasHousehold => household != null;

  Future<void> fetchHousehold() async {
    status = HouseholdStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await ApiService().getHousehold();
      if (data == null) {
        household = null;
      } else {
        household = Household.fromJson(data);
      }
      status = HouseholdStatus.loaded;
    } catch (e) {
      errorMessage = parseApiError(e);
      status = HouseholdStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createHousehold(String name) async {
    status = HouseholdStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService().createHousehold(name);
      household = Household.fromJson(data);
      status = HouseholdStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = parseApiError(e);
      status = HouseholdStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinHousehold(String code) async {
    status = HouseholdStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService().joinHousehold(code);
      household = Household.fromJson(data);
      status = HouseholdStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = parseApiError(e);
      status = HouseholdStatus.error;
      notifyListeners();
      return false;
    }
  }
}