import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      dotenv.env['FIREBASE_URL']!,
      'shopping_list.json',
    );

    try {
      final response = await http.get(url);
      final statusCode = response.statusCode;

      if (statusCode >= 400) {
        setState(() {
          _error = 'Failed to load items, please try again later.';
        });
      }
      final data = response.body;
      if (data == 'null') {
        setState(() {
          isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(data);

      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (element) => element.value.name == item.value['category'],
            )
            .value;
        final groceryItem = GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        );
        loadedItems.add(groceryItem);
      }
      setState(() {
        _groceryItems = loadedItems;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong, please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (context) => const NewItem(),
    ));

    if (newItem == null) return;
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item, int index) async {
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      dotenv.env['FIREBASE_URL']!,
      'shopping_list/${item.id}.json',
    );

    final response = await http.delete(url);
    final statusCode = response.statusCode;

    if (statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet'),
    );
    if (isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) {
          final item = _groceryItems[index];
          return Dismissible(
            key: ValueKey(item.id),
            background: Container(
              color: Colors.red,
            ),
            onDismissed: (_) {
              _removeItem(item, index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} removed from cart'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      setState(() {
                        _groceryItems.insert(index, item);
                      });
                    },
                  ),
                ),
              );
            },
            child: ListTile(
              title: Text(item.name),
              leading: Container(
                width: 30,
                height: 30,
                color: item.category.color,
              ),
              trailing: Text('${item.quantity}'),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: content,
    );
  }
}
