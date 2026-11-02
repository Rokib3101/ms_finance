import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy & Data Security',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'MS Finance prioritizes your privacy and data security above all else. Below is our comprehensive data handling and permission policy:',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              title: '1. Local Data Storage (Offline & Encrypted)',
              icon: Icons.storage_outlined,
              content:
                  '• Finance Data: Transactions, wallets, and categories are stored on this device in Hive boxes encrypted with a key held in Android secure storage.\n'
                  '• Other Local Data: Shopping lists, price-comparison lists, and assets are stored in encrypted Hive boxes on this device. Appearance preferences are stored separately by the platform and are not encrypted by the app. Existing app data is migrated to encrypted boxes the next time the app starts.\n'
                  '• Network: The app has no account or cloud-sync service. It only shares or exports data when you choose an export or share action; the destination app then handles that data.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context: context,
              title: '2. Permission Policy',
              icon: Icons.security_outlined,
              content:
                  'The app does not request camera or photo-library access for the features currently included. Exporting or sharing a file is started by you and uses Android’s file or share interface. Android may request access depending on the destination you choose.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context: context,
              title: '3. Data Export & Erasure',
              icon: Icons.download_done_outlined,
              content:
                  '• Data Export: You can export your financial reports and records in JSON or CSV format whenever you choose. Export files are ordinary files in the destination you select and are not encrypted by the app.\n'
                  '• Data Erasure: You retain full authority to clear trashed items, permanently delete specific records, or perform a full app data reset at any time.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context: context,
              title: '4. Third-Party Services & Analytics',
              icon: Icons.verified_user_outlined,
              content:
                  '• Zero Tracking: MS Finance contains no third-party tracking, user analytics SDKs, or advertising networks that collect or profile user information.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
