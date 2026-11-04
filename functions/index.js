// functions/index.js
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions");

// Initialize the Admin SDK inside Google's secure ecosystem
initializeApp();

/**
 * Cloud Function trigger that wakes up the exact millisecond a new 
 * document is added to the 'notifications' collection.
 */
exports.sendAutomatedNotification = onDocumentCreated("notifications/{notificationId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        logger.error("No data associated with this event.");
        return null;
    }

    const data = snapshot.data();
    const docId = event.params.notificationId;

    // Avoid duplicate dispatch iterations
    if (data.status === "sent") {
        logger.info(`Notification ${docId} has already been marked as sent.`);
        return null;
    }

    const fcmToken = data.fcmToken;
    const title = data.title || "GasLink Alert";
    const body = data.body || "";
    const payloadData = data.data || {};

    // Validate targeting credentials
    if (!fcmToken) {
        logger.warn(`Skipping notification ${docId}: Missing target fcmToken.`);
        return null;
    }

    logger.info(`Processing outgoing notification request for user record: ${data.userId}`);

    // Build the structural payload targeting Android (ColorOS) and iOS
    const message = {
        token: fcmToken,
        notification: {
            title: title,
            body: body,
        },
        // Flatten payload data fields into strings for native app compatibility
        data: Object.keys(payloadData).reduce((acc, key) => {
            acc[key] = String(payloadData[key]);
            return acc;
        }, {}),
        android: {
            priority: "high",
            notification: {
                sound: "default",
                clickAction: "FLUTTER_NOTIFICATION_CLICK" // Restores background click handling
            }
        }
    };

    try {
        // Send the payload over Google Play Services channel
        const response = await getMessaging().send(message);
        logger.info(`Successfully dispatched message vector. Message ID: ${response}`);

        // Clean up the tracking doc state so it doesn't loop
        await snapshot.ref.update({
            status: "sent",
            sentAt: new Date()
        });
        
        logger.info(`Firestore notification ledger ${docId} updated with execution confirmation.`);
    } catch (error) {
        logger.error(`FCM gateway transmission failure for document ${docId}:`, error);
    }

    return null;
});
