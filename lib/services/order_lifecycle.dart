// ============================================================================
// FILE PATH: lib/services/order_lifecycle.dart
// ROLE: Single source of truth for the GasLink order state machine.
//
// Every screen and service asks this file whether a transition is legal.
// Legacy status words are read as aliases but never written again.
// ============================================================================

/// Canonical order lifecycle:
///
/// placed → seen → confirmed → on_the_way → delivered_pending → delivered
///                                                   ↘ disputed
/// Any active state can be cancelled by the right actor.
class OrderLifecycle {
  OrderLifecycle._();

  static const String placed = 'placed';
  static const String seen = 'seen';
  static const String confirmed = 'confirmed';
  static const String onTheWay = 'on_the_way';
  static const String deliveredPending = 'delivered_pending';
  static const String delivered = 'delivered';
  static const String disputed = 'disputed';
  static const String cancelled = 'cancelled';

  static const String actorConsumer = 'consumer';
  static const String actorVendor = 'vendor';
  static const String actorSystem = 'system';
  static const String actorAdmin = 'admin';

  /// Old documents and old app builds used these words. Read them as the
  /// canonical equivalent; new writes must use the canonical word.
  static String canonical(String? raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    switch (value) {
      case 'pending':
      case 'planned':
        return placed;
      case 'accepted':
        return confirmed;
      case 'dispatched':
      case 'in_transit':
      case 'delivering':
        return onTheWay;
      case 'completed':
        return delivered;
      case 'rejected':
      case 'refused':
        return cancelled;
      default:
        return value.isEmpty ? placed : value;
    }
  }

  /// Allowed target states for one actor. System is the trusted sweeper and
  /// migration path; admin is the mediation console.
  static const Map<String, Map<String, Set<String>>> _allowed = {
    placed: {
      actorVendor: {seen, cancelled},
      actorConsumer: {cancelled},
      actorSystem: {seen, cancelled},
      actorAdmin: {seen, confirmed, cancelled},
    },
    seen: {
      actorVendor: {confirmed, cancelled},
      actorConsumer: {cancelled},
      actorSystem: {confirmed, cancelled},
      actorAdmin: {confirmed, cancelled},
    },
    confirmed: {
      actorVendor: {onTheWay, cancelled},
      actorConsumer: {},
      actorSystem: {onTheWay, cancelled},
      actorAdmin: {onTheWay, cancelled},
    },
    onTheWay: {
      actorVendor: {deliveredPending},
      actorConsumer: {delivered, disputed},
      actorSystem: {deliveredPending, delivered},
      actorAdmin: {deliveredPending, delivered, cancelled},
    },
    deliveredPending: {
      actorVendor: {onTheWay},
      actorConsumer: {delivered, disputed},
      actorSystem: {delivered, onTheWay},
      actorAdmin: {delivered, onTheWay, cancelled},
    },
    delivered: {
      actorSystem: {},
      actorAdmin: {},
      actorVendor: {},
      actorConsumer: {},
    },
    disputed: {
      actorSystem: {delivered, cancelled},
      actorAdmin: {delivered, cancelled},
      actorVendor: {},
      actorConsumer: {},
    },
    cancelled: {
      actorSystem: {},
      actorAdmin: {},
      actorVendor: {},
      actorConsumer: {},
    },
  };

  static bool canTransition({
    required String from,
    required String to,
    required String actor,
  }) {
    final source = canonical(from);
    final target = canonical(to);
    if (source == target) return false;
    final byActor = _allowed[source];
    if (byActor == null) return false;
    final targets = byActor[actor];
    if (targets == null) return false;
    return targets.contains(target);
  }

  /// Statuses that belong on the vendor's active dashboard.
  static bool isActive(String? raw) {
    switch (canonical(raw)) {
      case placed:
      case seen:
      case confirmed:
      case onTheWay:
      case deliveredPending:
        return true;
      default:
        return false;
    }
  }

  /// Statuses that should be counted as new / unconfirmed work.
  static bool isNew(String? raw) {
    switch (canonical(raw)) {
      case placed:
      case seen:
        return true;
      default:
        return false;
    }
  }

  static bool isClosed(String? raw) {
    switch (canonical(raw)) {
      case delivered:
      case disputed:
      case cancelled:
        return true;
      default:
        return false;
    }
  }

  /// Only refill and full-set orders touch the kitchen cylinder ledger.
  static bool isCylinderOrder(String? type) {
    final value = (type ?? '').toString().trim().toLowerCase();
    return value == 'refill' || value == 'full_set';
  }

  /// Short order code used in notifications and SMS.
  static String orderCode(String orderId) {
    final clean = orderId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.isEmpty) return '----';
    return clean.length <= 6 ? clean : clean.substring(clean.length - 6);
  }
}
