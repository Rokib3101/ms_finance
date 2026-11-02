// HiveList is used to preserve the current on-disk relationship schema.
// ignore_for_file: experimental_member_use

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/comparator_models.dart';

class UnitPriceComparatorDetailScreen extends StatefulWidget {
  final ComparatorList comparatorList;
  const UnitPriceComparatorDetailScreen(
      {super.key, required this.comparatorList});

  @override
  State<UnitPriceComparatorDetailScreen> createState() =>
      _UnitPriceComparatorDetailScreenState();
}

class _UnitPriceComparatorDetailScreenState
    extends State<UnitPriceComparatorDetailScreen> {
  late Box<ComparatorItem> _itemBox;
  bool _sortByRankAsc = true;

  @override
  void initState() {
    super.initState();
    _itemBox = Hive.box<ComparatorItem>('comparator_items');
    // Initialize HiveList if null
    if (widget.comparatorList.items == null) {
      widget.comparatorList.items = HiveList(_itemBox);
      widget.comparatorList.save();
    }
  }

  Map<ComparatorItem, int> _calculateRanks(List<ComparatorItem> items) {
    final validItems = items.where((item) => item.quantity > 0).toList();
    validItems.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));

    final Map<ComparatorItem, int> ranks = {};
    for (int i = 0; i < validItems.length; i++) {
      ranks[validItems[i]] = i + 1;
    }
    return ranks;
  }

  List<ComparatorItem> _getSortedItems(
      List<ComparatorItem> items, Map<ComparatorItem, int> ranks) {
    final list = List<ComparatorItem>.from(items);
    list.sort((a, b) {
      final rankA = ranks[a];
      final rankB = ranks[b];
      if (rankA == null && rankB == null) return 0;
      if (rankA == null) return 1; // move invalid to end
      if (rankB == null) return -1; // move invalid to end

      return _sortByRankAsc ? rankA.compareTo(rankB) : rankB.compareTo(rankA);
    });
    return list;
  }

  void _showItemDialog({ComparatorItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final qtyController = TextEditingController(
        text: item != null ? item.quantity.toString() : '');
    final unitController = TextEditingController(text: item?.unit ?? 'gm');
    final priceController = TextEditingController(
        text: item != null ? item.totalPrice.toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add New Item' : 'Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g. Miniket Rice',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'e.g. 500',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'e.g. gm/kg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Total Price',
                  hintText: 'e.g. 150',
                  prefixText: '৳',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final qty = double.tryParse(qtyController.text) ?? 0.0;
              final unit = unitController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;

              setState(() {
                if (item == null) {
                  final newItem = ComparatorItem(
                    name: name,
                    quantity: qty,
                    unit: unit,
                    totalPrice: price,
                  );
                  _itemBox.add(newItem);
                  widget.comparatorList.items!.add(newItem);
                  widget.comparatorList.save();
                } else {
                  item.name = name;
                  item.quantity = qty;
                  item.unit = unit;
                  item.totalPrice = price;
                  item.save();
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(ComparatorItem item) {
    setState(() {
      widget.comparatorList.items!.remove(item);
      widget.comparatorList.save();
      item.delete();
    });
  }

  void _showDeleteConfirmation(ComparatorItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text(
            'Are you sure you want to delete "${item.name.isEmpty ? 'Unnamed Item' : item.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              _deleteItem(item);
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
    final items = widget.comparatorList.items?.toList() ?? <ComparatorItem>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.comparatorList.title),
      ),
      body: Column(
        children: [
          _buildSortingControl(),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _itemBox.listenable(),
              builder: (context, Box<ComparatorItem> box, _) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.scale_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'No items in list',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Recompute ranks and sorting when box changes
                final currentItems =
                    widget.comparatorList.items?.toList() ?? <ComparatorItem>[];
                final currentRanks = _calculateRanks(currentItems);
                final currentSortedItems =
                    _getSortedItems(currentItems, currentRanks);

                return Column(
                  children: [
                    _buildHeader(),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: currentSortedItems.length,
                        itemBuilder: (context, index) {
                          final item = currentSortedItems[index];
                          return _buildItemRow(item, index, currentRanks);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        tooltip: 'Add New Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSortingControl() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Sort by savings rank:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _sortByRankAsc = !_sortByRankAsc;
              });
            },
            icon: Icon(
                _sortByRankAsc ? Icons.arrow_upward : Icons.arrow_downward),
            label: Text(_sortByRankAsc
                ? 'Low to High (Cheapest First)'
                : 'High to Low (Most Expensive First)'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.blue.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: const Row(
        children: [
          SizedBox(
            width: 25,
            child: Text(
              'No.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Item Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Quantity',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Total Price',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Unit Price',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              'Rank',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
      ComparatorItem item, int index, Map<ComparatorItem, int> ranks) {
    final rank = ranks[item];
    final isBest = rank == 1;
    final rankText = rank != null ? rank.toString() : '--';

    return InkWell(
      onTap: () => _showItemDialog(item: item),
      onLongPress: () => _showDeleteConfirmation(item),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
          color: isBest ? Colors.green.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              child: Text(
                (index + 1).toString(),
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.name.isEmpty ? 'Unnamed' : item.name,
                style: TextStyle(
                  fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${item.quantity} ${item.unit}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '৳${item.totalPrice}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.quantity > 0
                    ? '৳${item.unitPrice.toStringAsFixed(2)}'
                    : '0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                  color: isBest ? Colors.green[700] : Colors.black87,
                  fontSize: 11,
                ),
              ),
            ),
            SizedBox(
              width: 45,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isBest
                        ? Colors.green[100]
                        : (rank != null ? Colors.blue[50] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rankText,
                    style: TextStyle(
                      color: isBest
                          ? Colors.green[800]
                          : (rank != null ? Colors.blue[800] : Colors.grey),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Text(
        'Tip: Tap an item to edit, long press to delete. The item with the lowest unit price is ranked #1 (best value).',
        style: TextStyle(fontSize: 13, color: Colors.blueGrey),
        textAlign: TextAlign.center,
      ),
    );
  }
}
