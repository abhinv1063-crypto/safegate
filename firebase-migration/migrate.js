const admin = require('firebase-admin');

const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

// We define the apartments with their intended trial numbers
const trialData = [
  { name: 'Green Valley Apartments', number: '101' },
  { name: 'Sunrise Residency', number: '201' }
];

async function runSync() {
  console.log('--- Starting Sync (Using .app and Apartment Numbers) ---');

  for (const data of trialData) {
    const apartmentId = data.name.toLowerCase().replace(/\s+/g, '');
    
    // Create the Apartment Document
    await db.collection('apartments').doc(apartmentId).set({
      name: data.name,
      settings: { allowVisitorRegistration: true }
    });

    // Generate email based on your logic: number@apartmentid.app
    // Example: 101@greenvalleyapartments.app
    const email = `${data.number}@${apartmentId}.app`;
    const password = 'password123';

    try {
      let userRecord;
      try {
        userRecord = await auth.getUserByEmail(email);
        console.log(`! User ${email} already exists.`);
      } catch (e) {
        userRecord = await auth.createUser({ email, password });
        console.log(`✓ Auth Created: ${email}`);
      }
      
      const uid = userRecord.uid;
      const userData = {
        uid: uid,
        email: email,
        fullName: `Resident of ${data.number}`,
        apartmentName: data.name,
        apartmentNumber: data.number,
        role: 'resident',
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Create doc in the nested path your Flutter AuthService expects
      await db.collection('apartments').doc(apartmentId)
        .collection('users').doc(uid).set(userData);

      // Create global lookup
      await db.collection('users').doc(uid).set({
        ...userData,
        profileRef: `/apartments/${apartmentId}/users/${uid}`
      });

      console.log(`✓ Firestore Synced for UID: ${uid}`);

    } catch (error) {
      console.error(`✗ Error: ${error.message}`);
    }
  }
}

runSync().then(() => {
  console.log('\n--- DATA READY ---');
  console.log('Login 1: 101@greenvalleyapartments.app');
  console.log('Login 2: 201@sunriseresidency.app');
  process.exit();
});