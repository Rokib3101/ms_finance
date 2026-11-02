import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../navigation/app_router.dart';

class AppMoreMenuButton extends StatelessWidget {
  const AppMoreMenuButton({super.key});

  static void handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'about':
        context.push(AppRoutes.about);
        break;
      case 'social_media':
        context.push(AppRoutes.socialMedia);
        break;
      case 'share_app':
        SharePlus.instance.share(
          ShareParams(
            text:
                'Check out MS Finance on GitHub: https://github.com/Rokib3101/ms_finance',
          ),
        );
        break;
      case 'privacy_policy':
        context.push(AppRoutes.privacyPolicy);
        break;
      case 'settings':
        context.push(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Menu',
      onSelected: (value) => handleMenuSelection(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'about',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20),
              SizedBox(width: 12),
              Text('About'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'social_media',
          child: Row(
            children: [
              Icon(Icons.public, size: 20),
              SizedBox(width: 12),
              Text('Social Media'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'share_app',
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 20),
              SizedBox(width: 12),
              Text('Share App'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'privacy_policy',
          child: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, size: 20),
              SizedBox(width: 12),
              Text('Privacy Policy'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
      ],
    );
  }
}
