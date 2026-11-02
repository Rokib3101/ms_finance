import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ms_finance/core/utils/core_utils.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:ms_finance/features/finance/presentation/providers/asset_provider.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';

class CashCounterScreen extends StatefulWidget {
  const CashCounterScreen({super.key});

  @override
  State<CashCounterScreen> createState() => _CashCounterScreenState();
}

class _CashCounterScreenState extends State<CashCounterScreen> {
  final Map<int, int> _counts = {
    1000: 0,
    500: 0,
    200: 0,
    100: 0,
    50: 0,
    20: 0,
    10: 0,
    5: 0,
    2: 0,
    1: 0,
  };

  double get _totalAmount {
    double total = 0;
    _counts.forEach((note, count) => total += note * count);
    return total;
  }

  void _saveCashCount() {
    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('মোট পরিমাণ শূন্যের বেশি হতে হবে!')),
      );
      return;
    }

    String selectedType = 'Expense'; // Options: 'Income', 'Expense', 'Asset'

    showDialog(
      context: context,
      builder: (dialogContext) {
        final financeProvider = Provider.of<FinanceProvider>(
          context,
          listen: false,
        );
        final assetProvider = Provider.of<AssetProvider>(
          context,
          listen: false,
        );

        final wallets = financeProvider.wallets;
        final assets = assetProvider.assets;

        String? selectedWalletId = wallets.firstOrNull?.id;
        String? selectedAssetId = assets.firstOrNull?.id;

        final newAssetNameController = TextEditingController(
          text: 'Cash Count',
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Save Cash Count'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cash Count: ৳${_totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Select Target Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Expense',
                          child: Text('Expense (ব্যয়)'),
                        ),
                        DropdownMenuItem(
                          value: 'Income',
                          child: Text('Income (আয়)'),
                        ),
                        DropdownMenuItem(
                          value: 'Asset',
                          child: Text('Asset (সম্পদ)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (selectedType == 'Income' ||
                        selectedType == 'Expense') ...[
                      if (wallets.isEmpty)
                        const Text(
                          'No wallets available. Please create a wallet first.',
                          style: TextStyle(color: Colors.red),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue:
                              wallets.any((w) => w.id == selectedWalletId)
                              ? selectedWalletId
                              : wallets.first.id,
                          decoration: const InputDecoration(
                            labelText: 'Select Wallet',
                            border: OutlineInputBorder(),
                          ),
                          items: wallets
                              .map(
                                (w) => DropdownMenuItem(
                                  value: w.id,
                                  child: Text(w.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedWalletId = val;
                              });
                            }
                          },
                        ),
                    ] else if (selectedType == 'Asset') ...[
                      DropdownButtonFormField<String>(
                        initialValue:
                            (selectedAssetId != null &&
                                (assets.any((a) => a.id == selectedAssetId) ||
                                    selectedAssetId == 'NEW'))
                            ? selectedAssetId
                            : (assets.isNotEmpty ? assets.first.id : 'NEW'),
                        decoration: const InputDecoration(
                          labelText: 'Select Asset',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ...assets.map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.name} (৳${a.amount.toStringAsFixed(0)})',
                              ),
                            ),
                          ),
                          const DropdownMenuItem(
                            value: 'NEW',
                            child: Text('+ Create New Asset'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedAssetId = val;
                            });
                          }
                        },
                      ),
                      if (selectedAssetId == 'NEW' || assets.isEmpty) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: newAssetNameController,
                          decoration: const InputDecoration(
                            labelText: 'New Asset Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedType == 'Income' || selectedType == 'Expense') {
                      final walletIdToUse =
                          wallets.any((w) => w.id == selectedWalletId)
                          ? selectedWalletId
                          : (wallets.isNotEmpty ? wallets.first.id : null);
                      if (walletIdToUse == null) return;

                      final txType = selectedType == 'Income'
                          ? TransactionType.income
                          : TransactionType.expense;
                      final tx = Transaction.create(
                        amount: _totalAmount,
                        category: 'Others',
                        type: txType,
                        walletId: walletIdToUse,
                        note: 'Cash Counter Total',
                      );
                      await financeProvider.addTransaction(tx);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Successfully added as Finance $selectedType!',
                            ),
                          ),
                        );
                      }
                    } else if (selectedType == 'Asset') {
                      if (selectedAssetId == 'NEW' ||
                          assets.isEmpty ||
                          selectedAssetId == null) {
                        final name = newAssetNameController.text.trim();
                        if (name.isEmpty) return;
                        await assetProvider.addAsset(name, _totalAmount);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Successfully created new Asset!'),
                            ),
                          );
                        }
                      } else {
                        final existingAsset = assets.firstWhere(
                          (a) => a.id == selectedAssetId,
                        );
                        await assetProvider.updateAsset(
                          existingAsset.id,
                          amount: existingAsset.amount + _totalAmount,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Successfully updated Asset "${existingAsset.name}"!',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _shareSummary() {
    final buffer = StringBuffer();
    buffer.writeln('--- Cash Counter Report ---');
    _counts.forEach((note, count) {
      if (count > 0) {
        buffer.writeln('৳$note × $count = ৳${note * count}');
      }
    });
    buffer.writeln('---------------------------');
    buffer.writeln('Total: ৳${_totalAmount.toStringAsFixed(0)}');
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Counter (BDT)'),
        actions: [
          IconButton(
            tooltip: 'Share Summary',
            icon: const Icon(Icons.share),
            onPressed: _shareSummary,
          ),
          IconButton(
            tooltip: 'Save Cash Count',
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _saveCashCount,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTotalCard(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _counts.keys
                  .map((note) => _buildNoteRow(note))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counts.updateAll((key, value) => 0)),
        tooltip: 'Reset',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.green[700],
      child: Column(
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '৳ ${_totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteRow(int note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '৳ $note',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text('×', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  setState(() {
                    _counts[note] =
                        int.tryParse(BanglaUtils.toEnglish(val)) ?? 0;
                  });
                },
                decoration: const InputDecoration(
                  hintText: '0',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Text(
              '৳ ${(note * (_counts[note] ?? 0)).toString()}',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
