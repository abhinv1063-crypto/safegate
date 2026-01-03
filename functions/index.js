/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const admin = require("firebase-admin");

admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Resident Panic Alert Notification Function
exports.sendResidentPanicNotification = onDocumentCreated(
  "apartments/{apartmentId}/resident_panic_alerts/{alertId}",
  (event) => {
    const apartmentId = event.params.apartmentId;
    const message = {
      topic: `guards_${apartmentId}`,
      notification: {
        title: "🚨 RESIDENT PANIC ALERT! 🚨",
        body: "A resident has triggered a panic alert. Please respond immediately.",
      },
      android: {
        notification: {
          sound: "siren",
          channelId: "panic_channel",
          priority: "high",
          defaultSound: false,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "siren.mp3",
            badge: 1,
          },
        },
      },
    };

    return getMessaging()
      .send(message)
      .then((response) => {
        console.log("Successfully sent resident panic notification:", response);
        return null;
      })
      .catch((error) => {
        console.error("Error sending resident panic notification:", error);
        return null;
      });
  }
);

// Panic Alert Notification Function
exports.sendPanicNotification = onDocumentCreated(
  "apartments/{apartmentId}/panic_alerts/{alertId}",
  (event) => {
    const apartmentId = event.params.apartmentId;
    const message = {
      topic: `residents_${apartmentId}`,
      notification: {
        title: "🚨 SECURITY EMERGENCY! 🚨",
        body: "Emergency situation detected at the security gate. " +
          "Please stay safe and follow security instructions.",
      },
      android: {
        notification: {
          sound: "siren",
          channelId: "panic_channel",
          priority: "high",
          defaultSound: false,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "siren.mp3",
            badge: 1,
          },
        },
      },
    };

    return getMessaging()
      .send(message)
      .then((response) => {
        console.log("Successfully sent panic notification:", response);
        return null;
      })
      .catch((error) => {
        console.error("Error sending panic notification:", error);
        return null;
      });
  }
);

// Panic Alert Resolved Notification Function
exports.sendPanicResolvedNotification = onDocumentUpdated(
  "apartments/{apartmentId}/panic_alerts/{alertId}",
  (event) => {
    const apartmentId = event.params.apartmentId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Check if status changed to 'resolved'
    if (beforeData.status !== 'resolved' && afterData.status === 'resolved') {
      const message = {
        topic: `residents_${apartmentId}`,
        data: {
          type: 'panic_resolved',
          alertId: event.params.alertId,
        },
        android: {
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
            },
          },
        },
      };

      return getMessaging()
        .send(message)
        .then((response) => {
          console.log("Successfully sent panic resolved notification:", response);
          return null;
        })
        .catch((error) => {
          console.error("Error sending panic resolved notification:", error);
          return null;
        });
    }

    return null;
  }
);

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer'); // Run 'npm install nodemailer'

admin.initializeApp();

// Configure your email sender (e.g., Gmail, SendGrid, or Mailtrap)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com',
    pass: 'your-app-password' // Use a Google App Password
  }
});

exports.onPasswordResetRequest = functions.firestore
  .document('password_resets/{requestId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { apartmentNumber, apartmentName, tempPassword, email } = data;

    // 1. Reconstruct the authEmail exactly as your app does
    const apartmentDomain = apartmentName.toLowerCase().replace(/[^a-z0-9]/g, '');
    const authEmail = `${apartmentNumber.toLowerCase().replace(/[^a-z0-9]/g, '')}@${apartmentDomain}.app`;

    try {
      // 2. Find the User's UID
      const userRecord = await admin.auth().getUserByEmail(authEmail);
      
      // 3. Update the Password in Firebase Authentication
      await admin.auth().updateUser(userRecord.uid, {
        password: tempPassword
      });

      // 4. Send the email to the REAL email address (the one the user entered)
      const mailOptions = {
        from: '"SafeGate Security" <your-email@gmail.com>',
        to: email,
        subject: 'Your SafeGate Temporary Password',
        html: `<h3>Password Reset Successful</h3>
               <p>Your password for <b>${apartmentName}</b>, Apt <b>${apartmentNumber}</b> has been reset.</p>
               <p>Temporary Password: <b>${tempPassword}</b></p>
               <p>Please login and change your password immediately.</p>`
      };

      await transporter.sendMail(mailOptions);
      
      return snap.ref.update({ status: 'completed', processedAt: admin.firestore.FieldValue.serverTimestamp() });

    } catch (error) {
      console.error("Error processing reset:", error);
      return snap.ref.update({ status: 'failed', error: error.message });
    }
  });