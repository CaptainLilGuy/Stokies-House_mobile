import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/tag.dart';
import '../services/api_service.dart';

class InventoryProvider extends ChangeNotifier {
  static const matchAllTags = false;
  List<InventoryItem> items = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  String selectedCategory = 'All';
  final Set<int> selectedTagIds = {};

  List<InventoryItem> get filtered {
    final q = searchQuery.toLowerCase();
    return items.where((item) {
      final matchSearch = item.name.toLowerCase().contains(q) || 
        item.tags.any((t) => t.name.toLowerCase().contains(q));
      final matchCategory = selectedCategory == 'All' || item.categoryName == selectedCategory;
      final ids = item.tags.map((t) => t.id).toSet();
      final matchTag = selectedTagIds.isEmpty || 
        (matchAllTags
            ? selectedTagIds.every(ids.contains)
            : selectedTagIds.any(ids.contains));
      return matchSearch && matchCategory && matchTag;
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

  List<Tag> get availableTags {
    final byId = <int, Tag>{};
    for (final item in items){
      for (final t in item.tags) {
        byId[t.id] = t;
      }
    }
    return byId.values.toList()
      ..sort(((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
  }

  Future<void> fetchItems() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try{
      final data = await ApiService().getInventory();
      items = data.map((j) => InventoryItem.fromJson(j)).toList();
      final live = availableTags.map((t) => t.id).toSet();
      selectedTagIds.removeWhere((id) => !live.contains(id));
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

  void toggleTag(int id) {
    if (!selectedTagIds.remove(id)) selectedTagIds.add(id);
    notifyListeners();
  }

  void clearTag() {
    selectedTagIds.clear();
    notifyListeners();
  }
}