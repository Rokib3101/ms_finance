import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ms_finance/core/navigation/app_router.dart';
import 'package:intl/intl.dart';
import '../../models/comparator_models.dart';

class UnitPriceComparatorScreen extends StatefulWidget {
  const UnitPriceComparatorScreen({super.key});

  @override
  State<UnitPriceComparatorScreen> createState() =>
      _UnitPriceComparatorScreenState();
}

class _UnitPriceComparatorScreenState extends State<UnitPriceComparatorScreen> {
  late Box<ComparatorList> _comparatorListBox;

  @override
  void initState() {
    super.initState();
    _comparatorListBox = Hive.box<ComparatorList>('comparator_lists');
  }

  void _createNewList() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Comparison List'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'e.g. Rice Price Comparison',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final newList = ComparatorList(
                  title: titleController.text.trim(),
                  createdAt: DateTime.now(),
                );
                _comparatorListBox.add(newList);
                Navigator.pop(context);
                context.push(AppRoutes.unitPriceDetail, extra: newList);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteList(ComparatorList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List?'),
        content: Text('Are you sure you want to delete "${list.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              if (list.items != null) {
                for (var item in List.from(list.items!)) {
                  item.delete();
                }
              }
              list.delete();
              Navigator.pop(context);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Comparator'),
      ),
      body: ValueListenableBuilder(
        valueListenable: _comparatorListBox.listenable(),
        builder: (context, Box<ComparatorList> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.compare_arrows, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No comparison lists',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createNewList,
                    icon: const Icon(Icons.add),
                    label: const Text('Start New Comparison'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          final lists = box.values.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              final itemCount = list.items?.length ?? 0;
              final dateStr =
                  DateFormat('dd MMM yyyy, hh:mm a').format(list.createdAt);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Icon(Icons.analytics_outlined,
                        color: Theme.of(context).primaryColor),
                  ),
                  title: Text(
                    list.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Date: $dateStr\nItems: $itemCount',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => _deleteList(list),
                  ),
                  onTap: () {
                    context.push(AppRoutes.unitPriceDetail, extra: list);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewList,
        label: const Text('New Comparison'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
