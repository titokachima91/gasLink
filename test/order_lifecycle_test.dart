import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/services/order_lifecycle.dart';

void main() {
  group('canonical status aliases', () {
    test('maps legacy words to the canonical lifecycle', () {
      expect(OrderLifecycle.canonical('pending'), OrderLifecycle.placed);
      expect(OrderLifecycle.canonical('planned'), OrderLifecycle.placed);
      expect(OrderLifecycle.canonical('accepted'), OrderLifecycle.confirmed);
      expect(OrderLifecycle.canonical('dispatched'), OrderLifecycle.onTheWay);
      expect(OrderLifecycle.canonical('in_transit'), OrderLifecycle.onTheWay);
      expect(OrderLifecycle.canonical('completed'), OrderLifecycle.delivered);
      expect(OrderLifecycle.canonical('rejected'), OrderLifecycle.cancelled);
      expect(OrderLifecycle.canonical('refused'), OrderLifecycle.cancelled);
    });

    test('keeps canonical words and defaults empty to placed', () {
      expect(OrderLifecycle.canonical('seen'), OrderLifecycle.seen);
      expect(OrderLifecycle.canonical('delivered_pending'),
          OrderLifecycle.deliveredPending);
      expect(OrderLifecycle.canonical('  CONFIRMED  '),
          OrderLifecycle.confirmed);
      expect(OrderLifecycle.canonical(null), OrderLifecycle.placed);
    });
  });

  group('vendor transitions', () {
    test('placed can be opened or rejected, never confirmed directly', () {
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.placed,
          to: OrderLifecycle.seen,
          actor: OrderLifecycle.actorVendor,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.placed,
          to: OrderLifecycle.confirmed,
          actor: OrderLifecycle.actorVendor,
        ),
        isFalse,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.placed,
          to: OrderLifecycle.cancelled,
          actor: OrderLifecycle.actorVendor,
        ),
        isTrue,
      );
    });

    test('seen can be confirmed or rejected', () {
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.seen,
          to: OrderLifecycle.confirmed,
          actor: OrderLifecycle.actorVendor,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.seen,
          to: OrderLifecycle.cancelled,
          actor: OrderLifecycle.actorVendor,
        ),
        isTrue,
      );
    });

    test('confirmed moves to journey, not back to placed', () {
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.confirmed,
          to: OrderLifecycle.onTheWay,
          actor: OrderLifecycle.actorVendor,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.confirmed,
          to: OrderLifecycle.placed,
          actor: OrderLifecycle.actorVendor,
        ),
        isFalse,
      );
    });

    test('journey can arrive and arrived can be undone', () {
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.onTheWay,
          to: OrderLifecycle.deliveredPending,
          actor: OrderLifecycle.actorVendor,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.deliveredPending,
          to: OrderLifecycle.onTheWay,
          actor: OrderLifecycle.actorVendor,
        ),
        isTrue,
      );
    });
  });

  group('buyer transitions', () {
    test('buyer confirms receipt from on_the_way or arrived', () {
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.onTheWay,
          to: OrderLifecycle.delivered,
          actor: OrderLifecycle.actorConsumer,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.deliveredPending,
          to: OrderLifecycle.delivered,
          actor: OrderLifecycle.actorConsumer,
        ),
        isTrue,
      );
    });

    test('buyer denies receipt into mediation', () {
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.deliveredPending,
          to: OrderLifecycle.disputed,
          actor: OrderLifecycle.actorConsumer,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.onTheWay,
          to: OrderLifecycle.disputed,
          actor: OrderLifecycle.actorConsumer,
        ),
        isTrue,
      );
    });

    test('buyer cannot confirm before the vendor confirms', () {
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.placed,
          to: OrderLifecycle.delivered,
          actor: OrderLifecycle.actorConsumer,
        ),
        isFalse,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.seen,
          to: OrderLifecycle.delivered,
          actor: OrderLifecycle.actorConsumer,
        ),
        isFalse,
      );
    });

    test('buyer can cancel only before confirmation', () {
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.placed,
          to: OrderLifecycle.cancelled,
          actor: OrderLifecycle.actorConsumer,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.seen,
          to: OrderLifecycle.cancelled,
          actor: OrderLifecycle.actorConsumer,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.confirmed,
          to: OrderLifecycle.cancelled,
          actor: OrderLifecycle.actorConsumer,
        ),
        isFalse,
      );
    });
  });

  group('system finalizer', () {
    test('finalizes arrived orders and can resolve disputes', () {
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.deliveredPending,
          to: OrderLifecycle.delivered,
          actor: OrderLifecycle.actorSystem,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.disputed,
          to: OrderLifecycle.delivered,
          actor: OrderLifecycle.actorSystem,
        ),
        isTrue,
      );
      expect(
        OrderLifecycle.canTransition(
          from: OrderLifecycle.disputed,
          to: OrderLifecycle.cancelled,
          actor: OrderLifecycle.actorSystem,
        ),
        isTrue,
      );
    });

    test('closed orders never reopen', () {
      for (final closed in [
        OrderLifecycle.delivered,
        OrderLifecycle.cancelled,
      ]) {
        for (final target in [
          OrderLifecycle.placed,
          OrderLifecycle.seen,
          OrderLifecycle.confirmed,
          OrderLifecycle.onTheWay,
        ]) {
          expect(
            OrderLifecycle.canTransition(
              from: closed,
              to: target,
              actor: OrderLifecycle.actorSystem,
            ),
            isFalse,
            reason: '$closed -> $target must stay closed',
          );
        }
      }
    });
  });

  group('helpers', () {
    test('active and new statuses match the vendor dashboard', () {
      expect(OrderLifecycle.isActive('pending'), isTrue);
      expect(OrderLifecycle.isActive('seen'), isTrue);
      expect(OrderLifecycle.isActive('accepted'), isTrue);
      expect(OrderLifecycle.isActive('in_transit'), isTrue);
      expect(OrderLifecycle.isActive('delivered_pending'), isTrue);
      expect(OrderLifecycle.isActive('delivered'), isFalse);
      expect(OrderLifecycle.isActive('disputed'), isFalse);

      expect(OrderLifecycle.isNew('placed'), isTrue);
      expect(OrderLifecycle.isNew('seen'), isTrue);
      expect(OrderLifecycle.isNew('confirmed'), isFalse);
    });

    test('only refill and full set touch the cylinder ledger', () {
      expect(OrderLifecycle.isCylinderOrder('refill'), isTrue);
      expect(OrderLifecycle.isCylinderOrder('full_set'), isTrue);
      expect(OrderLifecycle.isCylinderOrder('accessories'), isFalse);
      expect(OrderLifecycle.isCylinderOrder('services'), isFalse);
    });

    test('order code is the last six alphanumeric characters', () {
      expect(OrderLifecycle.orderCode('abc'), 'ABC');
      expect(OrderLifecycle.orderCode('order-123456789'), '456789');
      expect(OrderLifecycle.orderCode(''), '----');
    });
  });
}
