import 'package:flutter/material.dart';
import 'package:ms_finance/core/utils/core_utils.dart';
import 'package:provider/provider.dart';
import 'package:ms_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:ms_finance/features/finance/data/models/finance_models.dart';
import 'package:uuid/uuid.dart';

class WalletManagementScreen extends StatelessWidget {
  const WalletManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final wallets = provider.wallets;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Management')),
      body: wallets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'কোন ওয়ালেট পাওয়া যায়নি।\nনতুন ওয়ালেট যোগ করতে + বাটনে চাপুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                        child: Icon(Icons.account_balance_wallet)),
                    title: Text(wallet.name),
                    subtitle:
                        Text('Balance: ৳ ${wallet.balance.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showWalletDialog(context, provider,
                              wallet: wallet),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(
                              context, provider, wallet),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWalletDialog(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showWalletDialog(BuildContext context, FinanceProvider provider,
      {Wallet? wallet}) {
    final nameController = TextEditingController(text: wallet?.name);
    final balanceController =
        TextEditingController(text: wallet?.balance.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(wallet == null ? 'New Wallet' : 'Edit Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name (e.g. Nagad)'),
            ),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(labelText: 'Initial Balance'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final rawBalance = balanceController.text.trim();
              final balance =
                  BanglaUtils.parse(rawBalance.isEmpty ? '0' : rawBalance);
              if (name.isNotEmpty) {
                if (wallet == null) {
                  await provider.addWallet(Wallet(
                    id: const Uuid().v4(),
                    name: name,
                    balance: balance,
                    icon: 'account_balance_wallet',
                  ));
                } else {
                  await provider.updateWallet(
                      wallet.copyWith(name: name, balance: balance));
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, FinanceProvider provider, Wallet wallet) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Warning'),
        content:
            Text('Are you sure you want to delete "${wallet.name}" wallet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await provider.deleteWallet(wallet.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on StateError catch (error) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message.toString())),
                  );
                }
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
