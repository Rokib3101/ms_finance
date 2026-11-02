// HiveList is used to preserve the current on-disk relationship schema.
// ignore_for_file: experimental_member_use

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';
import '../../models/market_models.dart';

class MarketDetailScreen extends StatefulWidget {
  final MarketList marketList;
  const MarketDetailScreen({super.key, required this.marketList});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  late Box<MarketItem> _itemBox;

  @override
  void initState() {
    super.initState();
    _itemBox = Hive.box<MarketItem>('market_items');
    // Ensure HiveList is initialized
    if (widget.marketList.items == null) {
      widget.marketList.items = HiveList(_itemBox);
      widget.marketList.save();
    }
  }

  double get _totalPrice =>
      widget.marketList.items?.fold(0.0, (sum, item) => sum! + item.total) ??
      0.0;
  double get _boughtPrice =>
      widget.marketList.items
          ?.where((i) => i.isBought)
          .fold(0.0, (sum, item) => sum! + item.total) ??
      0.0;
  double get _toBuyPrice => _totalPrice - _boughtPrice;

  void _showItemDialog({MarketItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final qtyController = TextEditingController(
        text: item != null ? item.quantity.toString() : '1');
    final unitController = TextEditingController(text: item?.unit ?? '');
    final priceController = TextEditingController(
        text: item != null ? item.unitPrice.toString() : '0');

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
                    labelText: 'Item Name', border: OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      decoration: const InputDecoration(
                          labelText: 'Quantity', border: OutlineInputBorder()),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                          labelText: 'Unit (kg/pcs)',
                          border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                    labelText: 'Unit Price',
                    prefixText: '৳',
                    border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final qty = double.tryParse(qtyController.text) ?? 1.0;
                final price = double.tryParse(priceController.text) ?? 0.0;

                setState(() {
                  if (item == null) {
                    final newItem = MarketItem(
                      name: nameController.text.trim(),
                      quantity: qty,
                      unit: unitController.text.trim(),
                      unitPrice: price,
                    );
                    _itemBox.add(newItem);
                    widget.marketList.items!.add(newItem);
                    widget.marketList.save();
                  } else {
                    item.name = nameController.text.trim();
                    item.quantity = qty;
                    item.unit = unitController.text.trim();
                    item.unitPrice = price;
                    item.save();
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(MarketItem item) {
    setState(() {
      widget.marketList.items!.remove(item);
      widget.marketList.save();
      item.delete();
    });
  }

  void _convertToExpense() {
    final amount = _boughtPrice;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোনো কেনাকাটা বা ক্রয়কৃত আইটেম নেই!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final financeProvider =
            Provider.of<FinanceProvider>(context, listen: false);
        final wallets = financeProvider.wallets;
        String selectedWalletId = wallets.firstOrNull?.id ?? 'cash';

        return AlertDialog(
          title: const Text('Convert to Finance Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('List: ${widget.marketList.title}'),
              const SizedBox(height: 8),
              Text('Bought Amount: ৳${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.red)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedWalletId,
                decoration: const InputDecoration(
                    labelText: 'Select Wallet', border: OutlineInputBorder()),
                items: wallets
                    .map((w) =>
                        DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedWalletId = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final tx = Transaction.create(
                  amount: amount,
                  category: 'Food',
                  type: TransactionType.expense,
                  walletId: selectedWalletId,
                  note: 'Shopping: ${widget.marketList.title}',
                );
                await financeProvider.addTransaction(tx);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Successfully added as Finance Expense!')),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.marketList.items ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.marketList.title),
        actions: [
          IconButton(
            tooltip: 'Convert to Expense',
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _convertToExpense,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(),
          const Divider(height: 1),
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _itemBox.listenable(),
              builder: (context, Box<MarketItem> box, _) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('No items in list',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemRow(item, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: const Row(
        children: [
          SizedBox(
              width: 30,
              child: Text('No.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              flex: 3,
              child: Text('Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              flex: 2,
              child: Text('Quantity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              flex: 2,
              child: Text('Price',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(
              flex: 2,
              child: Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          SizedBox(
              width: 40,
              child: Text('Bought',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildItemRow(MarketItem item, int index) {
    return InkWell(
      onLongPress: () => _showDeleteConfirmation(item),
      onTap: () => _showItemDialog(item: item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
          color: item.isBought ? Colors.green.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                (index + 1).toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 14,
                  decoration: item.isBought ? TextDecoration.lineThrough : null,
                  color: item.isBought ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${item.quantity} ${item.unit}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '৳${item.unitPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '৳${item.total.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 40,
              child: Checkbox(
                value: item.isBought,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    item.isBought = val ?? false;
                    item.save();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(MarketItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
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

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem('Total Market', _totalPrice, Colors.white),
          _summaryItem('Bought', _boughtPrice, Colors.greenAccent),
          _summaryItem('Remaining', _toBuyPrice, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          '৳${value.toStringAsFixed(0)}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}
