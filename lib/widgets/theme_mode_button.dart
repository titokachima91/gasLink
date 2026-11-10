import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme_controller.dart';

/// App bar button that lets the user pick System, Light or Dark mode.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);

    return IconButton(
      tooltip: 'Mandhari / Theme',
      icon: Icon(switch (mode) {
        ThemeMode.system => Icons.brightness_auto,
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
      }),
      onPressed: () => _showPicker(context, ref, mode),
    );
  }

  Future<void> _showPicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final controller = ref.read(themeControllerProvider.notifier);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Mandhari / Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                value: mode,
                groupValue: current,
                secondary: Icon(_icon(mode)),
                title: Text(_label(mode)),
                onChanged: (value) => Navigator.pop(context, value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null) {
      await controller.setMode(selected);
    }
  }

  static IconData _icon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }

  static String _label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Inafuata mfumo / System';
      case ThemeMode.light:
        return 'Nuru / Light';
      case ThemeMode.dark:
        return 'Giza / Dark';
    }
  }
}
