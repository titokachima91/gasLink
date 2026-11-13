// lib/widgets/root_back_guard.dart
// Shared back handling for the app's root shells.
//
// A root shell has nowhere to pop to, so back asks before exiting. Screens that
// have a meaningful back destination pass [onBack] instead.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RootBackGuard extends StatelessWidget {
  const RootBackGuard({
    super.key,
    required this.child,
    this.onBack,
  });

  final Widget child;

  /// When provided, back runs this action instead of showing the exit dialog.
  final Future<void> Function()? onBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (onBack != null) {
          await onBack!();
          return;
        }

        final l10n = AppLocalizations.of(context);
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.exitAppTitle),
            content: Text(l10n.exitAppMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.exit),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          await SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
