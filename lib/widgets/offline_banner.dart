import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/theme_ext.dart';

/// Slim banner shown at the top of a dashboard while the device is offline.
///
/// The connectivity stream is injectable so the widget can be tested without
/// the platform plugin.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, this.stream});

  /// Defaults to [Connectivity.onConnectivityChanged].
  final Stream<List<ConnectivityResult>>? stream;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    final stream = widget.stream ?? Connectivity().onConnectivityChanged;
    _subscription = stream.listen((results) {
      final offline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (offline != _offline && mounted) {
        setState(() => _offline = offline);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: context.colors.error,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 16, color: context.colors.onError),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Hakuna muunganisho wa mtandao / You are offline',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
