// lib/widgets/language_picker.dart
// Shared language selector used by auth, consumer, vendor, and admin surfaces.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_locale.dart';
import '../core/locale_controller.dart';
import '../core/theme_ext.dart';

/// App bar / hero action that opens the language sheet.
class LanguageActionButton extends ConsumerWidget {
  const LanguageActionButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: AppLocalizations.of(context).language,
      icon: Icon(Icons.translate, color: color),
      onPressed: () => showLanguageSheet(context),
    );
  }
}

/// Opens the shared language bottom sheet.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const LanguageSheet(),
  );
}

/// Bottom sheet with System / Kiswahili / English.
class LanguageSheet extends ConsumerWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.chooseLanguage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          for (final locale in AppLocale.values)
            RadioListTile<AppLocale>(
              value: locale,
              groupValue: selected,
              secondary: Icon(_icon(locale)),
              title: Text(_label(l10n, locale)),
              subtitle: locale == AppLocale.system
                  ? Text(l10n.languageSystemHint)
                  : null,
              onChanged: (value) async {
                if (value == null) return;
                await controller.setLocale(value);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static IconData _icon(AppLocale locale) {
    return switch (locale) {
      AppLocale.system => Icons.settings_suggest_outlined,
      AppLocale.sw => Icons.translate,
      AppLocale.en => Icons.language,
    };
  }

  static String _label(AppLocalizations l10n, AppLocale locale) {
    return switch (locale) {
      AppLocale.system => l10n.languageSystem,
      AppLocale.sw => l10n.languageSwahili,
      AppLocale.en => l10n.languageEnglish,
    };
  }
}

/// Settings row that shows the current language and opens the sheet.
class LanguagePickerTile extends ConsumerWidget {
  const LanguagePickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);

    return ListTile(
      leading: Icon(
        Icons.translate_outlined,
        color: context.colors.primary,
      ),
      title: Text(l10n.language),
      subtitle: Text(_currentLabel(l10n, locale)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => showLanguageSheet(context),
    );
  }

  static String _currentLabel(AppLocalizations l10n, AppLocale locale) {
    return switch (locale) {
      AppLocale.system => l10n.languageSystem,
      AppLocale.sw => l10n.languageSwahili,
      AppLocale.en => l10n.languageEnglish,
    };
  }
}
