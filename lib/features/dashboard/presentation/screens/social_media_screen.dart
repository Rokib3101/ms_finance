import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaItem {
  final String title;
  final String subtitle;
  final String? url;
  final IconData icon;
  final Color iconColor;

  const SocialMediaItem({
    required this.title,
    required this.subtitle,
    this.url,
    required this.icon,
    required this.iconColor,
  });
}

class SocialMediaScreen extends StatelessWidget {
  const SocialMediaScreen({super.key});

  static const List<SocialMediaItem> items = [
    SocialMediaItem(
      title: 'GitHub',
      subtitle: 'https://github.com/Rokib3101/ms_finance',
      url: 'https://github.com/Rokib3101/ms_finance',
      icon: Icons.code,
      iconColor: Color(0xFF24292E),
    ),
  ];

  Future<void> _handleTap(BuildContext context, SocialMediaItem item) async {
    if (item.url != null && item.url!.isNotEmpty) {
      final Uri uri = Uri.parse(item.url!);
      try {
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        }
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open ${item.title} link')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open ${item.title} link')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.title} link is not set yet.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Media'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final hasUrl = item.url != null && item.url!.isNotEmpty;

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
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 26,
                ),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasUrl
                        ? theme.colorScheme.primary
                        : (theme.brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                    decoration:
                        hasUrl ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
              ),
              trailing: hasUrl
                  ? Icon(
                      Icons.open_in_new,
                      size: 20,
                      color: theme.colorScheme.primary,
                    )
                  : Icon(
                      Icons.link_off,
                      size: 20,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
              onTap: () => _handleTap(context, item),
            ),
          );
        },
      ),
    );
  }
}
