import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

class InventoryProvider extends ChangeNotifier {
  List<InventoryItem> items = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  String selectedCategory = 'All';

  List<InventoryItem> get filtered {
    return items.where((item) {
      final matchSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchCategory = selectedCategory == 'All' || item.categoryName == selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  List<String> get categories {
    final cats = items
      .map((e) => e.categoryName)
      .whereType<String>()
      .toSet()
      .toList();
    cats.sort();
    return ['All', ...cats];
  }

  Future<void> fetchItems() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      final data = await ApiService().getInventory();
      items = data.map((j) => InventoryItem.fromJson(j)).toList();
    } catch (e) {
        errorMessage = e is DioException ? parseApiError(e) : e.toString(); 
    } finally {
      isLoading = false;
      notifyListeners();
    }
  } 

  Future<bool> deleteItem(int id) async {
    try{
      await ApiService().deleteItem(id);
      items.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch(e) {
      errorMessage = parseApiError(e);
      notifyListeners();
      return false;
    }
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setCategory(String cat) {
    selectedCategory = cat;
    notifyListeners();
  }
}