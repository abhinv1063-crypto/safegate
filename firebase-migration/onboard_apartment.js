const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const auth = admin.auth();

async function onboardNewApartment(name, rooms) {
  const aptId = name.toLowerCase().replace(/\s+/g, '');
  const domain = `${aptId}.app`;

  console.log(`--- Onboarding ${name} ---`);

  // 1. Create Apartment Document
  await db.collection('apartments').doc(aptId).set({
    name: name,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    config: { totalRooms: rooms.length }
  });

  // 2. Create the Guard Account
  const guardEmail = `guard@${domain}`;
  await createAccount(guardEmail, 'guard123', name, '000', 'security', aptId);

  // 3. Create Resident Accounts (Rooms 100-105)
  for (const room of rooms) {
    const email = `${room}@${domain}`;
    await createAccount(email, 'pass123', name, room, 'resident', aptId);
  }
}

async function createAccount(email, password, aptName, room, role, aptId) {
  try {
    const userRecord = await auth.createUser({ email, password });
    const uid = userRecord.uid;

    const userData = {
      uid, email, role,
      apartmentName: aptName,
      apartmentNumber: room,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Save to nested path and global path
    await db.collection('apartments').doc(aptId).collection('users').doc(uid).set(userData);
    await db.collection('users').doc(uid).set({
      ...userData,
      profileRef: `/apartments/${aptId}/users/${uid}`
    });

    console.log(`✓ Created ${role}: ${email}`);
  } catch (e) {
    console.log(`! Skipping ${email}: ${e.message}`);
  }
}

// EXECUTION: New Apartment name and Room range
onboardNewApartment('Landmark Calicut', ['100', '101'])