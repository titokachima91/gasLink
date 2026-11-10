import 'package:flutter/material.dart';

/// Semantic status colors that Material's [ColorScheme] does not provide.
///
/// Registered as a [ThemeExtension] so every screen can resolve success,
/// warning and info colors that remain readable in both light and dark mode.
@immutable
class GasLinkStatusColors extends ThemeExtension<GasLinkStatusColors> {
  const GasLinkStatusColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  static const light = GasLinkStatusColors(
    success: Color(0xFF2E7D32),
    onSuccess: Colors.white,
    successContainer: Color(0xFFE6F4EA),
    onSuccessContainer: Color(0xFF145A1E),
    warning: Color(0xFFA35F00),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFF4E5),
    onWarningContainer: Color(0xFF7A3E00),
    info: Color(0xFF1565C0),
    onInfo: Colors.white,
    infoContainer: Color(0xFFE8F1FB),
    onInfoContainer: Color(0xFF0D3C75),
  );

  static const dark = GasLinkStatusColors(
    success: Color(0xFF81C995),
    onSuccess: Color(0xFF003912),
    successContainer: Color(0xFF1B3A24),
    onSuccessContainer: Color(0xFFA5E8B3),
    warning: Color(0xFFFFB74D),
    onWarning: Color(0xFF4A2800),
    warningContainer: Color(0xFF3B2A12),
    onWarningContainer: Color(0xFFFFD9A1),
    info: Color(0xFF8AB4F8),
    onInfo: Color(0xFF0A2A52),
    infoContainer: Color(0xFF1B2C44),
    onInfoContainer: Color(0xFFC3DAFF),
  );

  @override
  GasLinkStatusColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return GasLinkStatusColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  GasLinkStatusColors lerp(
    covariant ThemeExtension<GasLinkStatusColors>? other,
    double t,
  ) {
    if (other is! GasLinkStatusColors) return this;
    return GasLinkStatusColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}
