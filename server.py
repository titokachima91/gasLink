# server.py
import time
import firebase_admin
from firebase_admin import credentials, firestore, messaging

# Initialize the Google Admin SDK
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("🚀 GasLink Production Notification Dispatcher is ONLINE...")
print("👀 Listening to 'notifications' AND 'orders' collections 24/7...\n")

def send_fcm_push(token, title, body, payload_data=None):
    """Helper method to send high-priority wireless pushes safely."""
    try:
        message = messaging.Message(
            token=token,
            notification=messaging.Notification(title=title, body=body),
            data={str(k): str(v) for k, v in payload_data.items()} if payload_data else None,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    click_action='FLUTTER_NOTIFICATION_CLICK'
                )
            )
        )
        response = messaging.send(message)
        print(f"✅ Wireless transmission successful! Message ID: {response}")
        return True
    except Exception as e:
        print(f"❌ FCM Gateway transmission failure: {e}")
        return False

def on_notification_added(col_snapshot, changes, read_time):
    """Listens to direct manual notification queue logs (e.g. New Orders)"""
    for change in changes:
        if change.type.name == 'ADDED':
            doc_id = change.document.id
            data = change.document.to_dict()
            
            if data.get('status') == 'sent':
                continue
                
            fcm_token = data.get('fcmToken')
            if not fcm_token:
                continue

            print(f"📦 Notification collection request detected for User: {data.get('userId')}")
            if send_fcm_push(fcm_token, data.get('title', 'GasLink'), data.get('body', ''), data.get('data')):
                db.collection('notifications').document(doc_id).update({
                    'status': 'sent',
                    'sentAt': firestore.SERVER_TIMESTAMP
                })

def on_order_updated(col_snapshot, changes, read_time):
    """AUTOMATED CLOUD BRIDGE: Watches order status changes and alerts consumers natively"""
    for change in changes:
        if change.type.name == 'MODIFIED':
            order_id = change.document.id
            order_data = change.document.to_dict()
            status = str(order_data.get('status', '')).lower().strip()
            
            # Extract tracking targets safely using your model attributes
            consumer_uid = order_data.get('consumer_uid') or order_data.get('user_id')
            brand = order_data.get('brand_name') or order_data.get('brand') or "Gesi"
            
            if not consumer_uid:
                continue

            # Check if this status change has already been alerted to prevent loops
            alert_key = f"alerted_{status}"
            if order_data.get(alert_key) is True:
                continue

            # Map appropriate user-friendly language to stepper shifts.
            # Statuses match Flutter's AppConstants.orderStatuses:
            # placed, seen, confirmed, on_the_way, delivered_pending, delivered, cancelled
            title, body = None, None
            if status == 'confirmed':
                title = 'Oda Imethibitishwa! / Order Confirmed!'
                body = f"Muuzaji amethibitisha oda yako. Muda wa kuwasili ni takriban dakika {order_data.get('eta_minutes', 20)}."
            elif status == 'on_the_way':
                title = 'Ipo Njiani! / On The Way!'
                body = f"Dereva yuko njiani kuleta oda yako ya {brand}."
            elif status == 'delivered_pending':
                title = 'Mzigo Umewasilishwa / Delivered (Pending Confirm)'
                body = f"Muuzaji amesema oda yako ya {brand} imewasilishwa. Tafadhali thibitisha kupokea."
            elif status == 'delivered':
                title = 'Imewasili! / Delivered!'
                body = f"Oda yako ya {brand} imekamilika kikamilifu. Asante!"
            elif status == 'cancelled':
                title = 'Oda Imesitishwa / Order Cancelled'
                body = "Muuzaji amesitisha oda yako. Tafadhali jaribu muuzaji mwingine."

            if title and body:
                # Look up consumer token directly from their user record safely
                user_doc = db.collection('users').document(consumer_uid).get()
                if user_doc.exists:
                    fcm_token = user_doc.to_dict().get('fcmToken')
                    if fcm_token:
                        print(f"🔔 Order status shift detected ({status}). Alerting consumer: {consumer_uid}")
                        if send_fcm_push(fcm_token, title, body, {'orderId': order_id, 'type': 'order_status'}):
                            # Mark this status as alerted on the order doc so it never double-fires
                            db.collection('orders').document(order_id).update({
                                alert_key: True
                            })

# Attach the background listeners to your cloud database nodes
db.collection('notifications').on_snapshot(on_notification_added)
db.collection('orders').on_snapshot(on_order_updated)

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("\n🛑 Shutting down GasLink Dispatcher.")
