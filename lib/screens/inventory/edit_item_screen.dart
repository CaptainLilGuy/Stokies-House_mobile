import 'package:flutter/material.dart';
import 'package:homeventory/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_item.dart';
import '../../models/category.dart';

class EditItemScreen extends StatefulWidget {
  final InventoryItem item;
  const EditItemScreen({super.key, required this.item});

  @override
  State<StatefulWidget> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
    );
  }
}