import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_lock_service.dart';
import 'app_lock_screen.dart';

class AppLockGuard extends StatelessWidget {
  final Widget child;

  const AppLockGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockService>(
      builder: (context, lockService, _) {
        if (lockService.isPinSet && lockService.isLocked) {
          return AppLockScreen(
            mode: AppLockMode.unlock,
            onSuccess: () {
              lockService.unlockApp();
            },
          );
        }
        return child;
      },
    );
  }
}
