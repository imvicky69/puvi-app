const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 1. Initialize Firebase Admin using serviceAccountKey.json
const serviceAccountPath = path.resolve(__dirname, '..', 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('serviceAccountKey.json not found at:', serviceAccountPath);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

const db = admin.firestore();

const PUJA_UID = 'HfzubbPMBsgQugeC5AcNqyWbwlw2';
const VICKY_UID = 'bx3PgTysxeX7HMfkyPWiCwtqLZG3';
const COUPLE_ID = 'puvi_couple';
const TOGETHER_SINCE = '2026-04-11T00:00:00.000Z';

function serializeValue(val) {
  if (val === null || val === undefined) return val;
  if (typeof val.toDate === 'function') {
    return val.toDate().toISOString();
  }
  if (Array.isArray(val)) {
    return val.map(serializeValue);
  }
  if (typeof val === 'object') {
    const res = {};
    for (const key of Object.keys(val)) {
      res[key] = serializeValue(val[key]);
    }
    return res;
  }
  return val;
}

async function updateUsers() {
  console.log('--- Reboosting & Updating Puvi Users in Firestore ---');
  console.log('Target Project:', serviceAccount.project_id);

  const batch = db.batch();

  // 1. Update Puja's user document
  const pujaRef = db.collection('users').doc(PUJA_UID);
  batch.set(
    pujaRef,
    {
      name: 'Puja',
      email: 'puja@puvi.com',
      partnerId: VICKY_UID,
      partnerName: 'Vicky',
      partnerEmail: 'vicky@puvi.com',
      coupleId: COUPLE_ID,
      togetherSince: TOGETHER_SINCE,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    { merge: true }
  );

  // 2. Update Vicky's user document
  const vickyRef = db.collection('users').doc(VICKY_UID);
  batch.set(
    vickyRef,
    {
      name: 'Vicky',
      email: 'vicky@puvi.com',
      partnerId: PUJA_UID,
      partnerName: 'Puja',
      partnerEmail: 'puja@puvi.com',
      coupleId: COUPLE_ID,
      togetherSince: TOGETHER_SINCE,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    { merge: true }
  );

  // 3. Create / Update shared couple record for clean relationship modeling
  const coupleRef = db.collection('couples').doc(COUPLE_ID);
  batch.set(
    coupleRef,
    {
      id: COUPLE_ID,
      members: [PUJA_UID, VICKY_UID],
      user1: {
        id: PUJA_UID,
        name: 'Puja',
        email: 'puja@puvi.com'
      },
      user2: {
        id: VICKY_UID,
        name: 'Vicky',
        email: 'vicky@puvi.com'
      },
      togetherSince: TOGETHER_SINCE,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    { merge: true }
  );

  await batch.commit();
  console.log('✓ Successfully committed batch updates to Firestore!');

  // 4. Fetch the refreshed user data to verify and update local users.json
  console.log('\n--- Fetching updated user documents ---');
  const snap = await db.collection('users').get();
  const refreshedUsers = [];
  snap.forEach(doc => {
    refreshedUsers.push({
      _id: doc.id,
      ...serializeValue(doc.data())
    });
  });

  const usersJsonPath = path.resolve(__dirname, '..', 'users.json');
  fs.writeFileSync(usersJsonPath, JSON.stringify(refreshedUsers, null, 2), 'utf8');
  console.log('✓ Saved refreshed users data to:', usersJsonPath);

  console.log('\n=== UPDATED USERS JSON ===');
  console.log(JSON.stringify(refreshedUsers, null, 2));

  // Also fetch couple doc
  const coupleDoc = await coupleRef.get();
  console.log('\n=== COUPLE DOCUMENT ===');
  console.log(JSON.stringify(serializeValue(coupleDoc.data()), null, 2));
}

updateUsers().catch(err => {
  console.error('Error updating users:', err);
  process.exit(1);
});
