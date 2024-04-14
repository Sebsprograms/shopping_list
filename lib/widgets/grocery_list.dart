import 'package:flutter/material.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final List<GroceryItem> _groceryItems = [];

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

  void _removeItem(int index) {
    setState(() {
      _groceryItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet'),
    );
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
              _removeItem(index);
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
