// lib/widgets/notifications_ai_settings.dart
// Shared Notifications & AI Assistant settings card for consumers and vendors.
// Reads and writes users/{uid}.notification_channel and ai_assistant_enabled
// live, so a change applies to the very next dispatch.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core/theme_ext.dart';
import '../services/notification_preferences.dart';
import 'app_ui.dart';

class NotificationsAiSettings extends StatefulWidget {
  const NotificationsAiSettings({super.key, required this.uid});

  final String uid;

  @override
  State<NotificationsAiSettings> createState() =>
      _NotificationsAiSettingsState();
}

class _NotificationsAiSettingsState extends State<NotificationsAiSettings> {
  final NotificationPreferences _preferences = NotificationPreferences();
  bool _savingChannel = false;
  bool _savingAi = false;

  Future<void> _setChannel(
    BuildContext context,
    NotificationChannel channel,
  ) async {
    if (widget.uid.isEmpty || _savingChannel) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final successColor = context.gasColors.success;
    final errorColor = context.colors.error;
    setState(() => _savingChannel = true);
    try {
      await _preferences.saveChannel(widget.uid, channel);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.preferenceSaved),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.preferenceSaveFailed),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingChannel = false);
    }
  }

  Future<void> _setAiEnabled(BuildContext context, bool enabled) async {
    if (widget.uid.isEmpty || _savingAi) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final successColor = context.gasColors.success;
    final errorColor = context.colors.error;
    setState(() => _savingAi = true);
    try {
      await _preferences.saveAiAssistantEnabled(widget.uid, enabled);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.preferenceSaved),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.preferenceSaveFailed),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingAi = false);
    }
  }

  String _channelLabel(
    AppLocalizations l10n,
    NotificationChannel channel,
  ) {
    return switch (channel) {
      NotificationChannel.pushOnly => l10n.notificationChannelPushOnly,
      NotificationChannel.smsOnly => l10n.notificationChannelSmsOnly,
      NotificationChannel.both => l10n.notificationChannelBoth,
      NotificationChannel.none => l10n.notificationChannelNone,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uid.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppCard(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final channel = NotificationChannel.fromStorage(
          data['notification_channel'],
        );
        final aiEnabled = data['ai_assistant_enabled'] == true;

        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  Icons.chat_bubble_outline,
                  color: context.colors.primary,
                ),
                title: Text(
                  l10n.notificationChannel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(l10n.notificationChannelHint),
              ),
              ...NotificationChannel.values.map((option) {
                return RadioListTile<NotificationChannel>(
                  value: option,
                  groupValue: channel,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  dense: true,
                  title: Text(_channelLabel(l10n, option)),
                  activeColor: context.colors.primary,
                  onChanged: _savingChannel
                      ? null
                      : (value) {
                          if (value != null) _setChannel(context, value);
                        },
                );
              }),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(
                  Icons.smart_toy_outlined,
                  color: context.colors.primary,
                ),
                title: Text(
                  l10n.aiAssistantTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(l10n.aiAssistantSubtitle),
                value: aiEnabled,
                activeColor: context.colors.primary,
                onChanged:
                    _savingAi ? null : (value) => _setAiEnabled(context, value),
              ),
            ],
          ),
        );
      },
    );
  }
}
