const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const { title, message, recipientId } = data;

  const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
  const token = userDoc.data().fcmToken;

  const payload = {
    notification: {
      title: title,
      body: message,
    },
  };

  try {
    await admin.messaging().sendToDevice(token, payload);
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    return { success: false, error: error.message };
  }
});
