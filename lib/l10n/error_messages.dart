// lib/l10n/error_messages.dart
// Maps locale-neutral service errors to localized text.

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core/app_error.dart';

String authErrorText(AppLocalizations l10n, Object error) {
  if (error is AppError) {
    return switch (error.code) {
      AppError.invalidPhone => l10n.errorInvalidPhone,
      AppError.invalidPin => l10n.errorInvalidPin,
      AppError.accountExists => l10n.errorAccountExists,
      AppError.accountNotFound => l10n.errorAccountNotFound,
      AppError.accountLocked => l10n.errorAccountLocked,
      AppError.incorrectPin => l10n.errorIncorrectPin,
      AppError.roleNotConfigured => l10n.accountRoleMissing,
      AppError.otpDisabled => l10n.otpDisabled,
      AppError.otpSendFailed => l10n.otpSendFailed,
      AppError.otpInvalid => l10n.otpInvalid,
      _ => l10n.errorGeneric,
    };
  }
  return l10n.errorGeneric;
}
