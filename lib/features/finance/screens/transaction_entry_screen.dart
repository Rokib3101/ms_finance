import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';
import 'package:ms_finance/core/utils/core_utils.dart';

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key});

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String? _selectedCategory;
  String _selectedWalletId = 'cash';
  String? _toWalletId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      setState(() {
        _selectedCategory =
            provider.getCategoriesByType(_type).firstOrNull?.name ?? 'Others';
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _amountController.clear();
    _noteController.clear();
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    setState(() {
      _toWalletId = null;
      if (_type == TransactionType.transfer) {
        _selectedCategory = 'Transfer';
      } else {
        _selectedCategory =
            provider.getCategoriesByType(_type).firstOrNull?.name ?? 'Others';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final wallets = provider.wallets;
    final activeWalletId = wallets.any((w) => w.id == _selectedWalletId)
        ? _selectedWalletId
        : (wallets.isNotEmpty ? wallets.first.id : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
        actions: [
          IconButton(
            tooltip: 'Clear Form',
            icon: const Icon(Icons.refresh),
            onPressed: _clearForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.add_circle_outline)),
                ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.remove_circle_outline)),
                ButtonSegment(
                    value: TransactionType.transfer,
                    label: Text('Transfer'),
                    icon: Icon(Icons.swap_horiz)),
              ],
              selected: {_type},
              onSelectionChanged: (val) {
                setState(() {
                  _type = val.first;
                  if (_type == TransactionType.transfer) {
                    _selectedCategory = 'Transfer';
                  } else {
                    final provider =
                        Provider.of<FinanceProvider>(context, listen: false);
                    _selectedCategory =
                        provider.getCategoriesByType(_type).firstOrNull?.name ??
                            'Others';
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '৳ ',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_type != TransactionType.transfer)
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: provider
                    .getCategoriesByType(_type)
                    .map((c) =>
                        DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: activeWalletId,
              decoration: InputDecoration(
                labelText: _type == TransactionType.transfer
                    ? 'From Wallet'
                    : 'Wallet',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: wallets
                  .map(
                      (w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedWalletId = val!),
            ),
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _toWalletId,
                decoration: InputDecoration(
                  labelText: 'To Wallet',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: wallets
                    .where((w) => w.id != (activeWalletId ?? _selectedWalletId))
                    .map((w) =>
                        DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (val) => setState(() => _toWalletId = val!),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = BanglaUtils.parse(_amountController.text);
                  if (amount <= 0) {
                    return;
                  }
                  final walletToUse = activeWalletId ?? _selectedWalletId;
                  if (walletToUse.isEmpty) {
                    return;
                  }
                  if (_type == TransactionType.transfer &&
                      _toWalletId == null) {
                    return;
                  }

                  final tx = Transaction.create(
                    amount: amount,
                    category: _selectedCategory ?? 'Others',
                    type: _type,
                    walletId: walletToUse,
                    toWalletId: _toWalletId,
                    note: _noteController.text,
                  );

                  await provider.addTransaction(tx);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == TransactionType.income
                      ? Colors.green
                      : (_type == TransactionType.expense
                          ? Colors.red
                          : Colors.blue),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
