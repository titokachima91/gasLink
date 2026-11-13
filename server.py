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

# Attach the background listener to the notification ledger only.
# Order events are dispatched centrally by the Flutter NotificationDispatcher,
# which applies each user's notification_channel preference and mirrors to SMS.
# The previous orders listener is intentionally NOT attached: it bypassed those
# preferences and duplicated every status push.
db.collection('notifications').on_snapshot(on_notification_added)

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("\n🛑 Shutting down GasLink Dispatcher.")
