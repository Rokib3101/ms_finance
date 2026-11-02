import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/app_more_menu.dart';
import '../../../core/navigation/app_router.dart';

class FinanceHomeScreen extends StatelessWidget {
  const FinanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MS Finance',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: const [
          AppMoreMenuButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildToolCard(
                  context,
                  title: 'Personal Finance',
                  subtitle: 'Budget & Expenses',
                  icon: Icons.account_balance_wallet,
                  color: Colors.indigo,
                  onTap: () => context.push(AppRoutes.finance),
                ),
                _buildToolCard(
                  context,
                  title: 'Cash Counter',
                  subtitle: 'Notes & Coins',
                  icon: Icons.money,
                  color: Colors.green,
                  onTap: () => context.push(AppRoutes.cashCounter),
                ),
                _buildToolCard(
                  context,
                  title: 'Price Comparator',
                  subtitle: 'Compare Unit Prices',
                  icon: Icons.price_check,
                  color: Colors.purple,
                  onTap: () => context.push(AppRoutes.comparator),
                ),
                _buildToolCard(
                  context,
                  title: 'Shopping List',
                  subtitle: 'Checklists & Markets',
                  icon: Icons.shopping_cart,
                  color: Colors.blueAccent,
                  onTap: () => context.push(AppRoutes.shopping),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
