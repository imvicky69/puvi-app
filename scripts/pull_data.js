const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 1. Initialize Firebase Admin with serviceAccountKey.json
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

async function main() {
  console.log('Connecting to Firestore project:', serviceAccount.project_id);

  // 1. Pull users collection
  console.log('\n--- Fetching "users" collection ---');
  const usersSnapshot = await db.collection('users').get();
  const usersData = [];

  usersSnapshot.forEach(doc => {
    usersData.push({
      _id: doc.id,
      ...serializeValue(doc.data())
    });
  });

  console.log(`Found ${usersData.length} document(s) in "users" collection.`);
  
  // Write users.json
  const usersJsonPath = path.resolve(__dirname, '..', 'users.json');
  fs.writeFileSync(usersJsonPath, JSON.stringify(usersData, null, 2), 'utf8');
  console.log('Saved users collection to:', usersJsonPath);

  // 2. Also inspect and fetch ALL root collections to see couple data
  console.log('\n--- Listing all Firestore root collections ---');
  const collections = await db.listCollections();
  const allData = { users: usersData };

  for (const col of collections) {
    if (col.id === 'users') continue;
    const snap = await col.get();
    const items = [];
    snap.forEach(d => {
      items.push({
        _id: d.id,
        ...serializeValue(d.data())
      });
    });
    allData[col.id] = items;
    console.log(`Collection "${col.id}": ${items.length} document(s)`);
  }

  // Also check Firebase Auth users if accessible
  try {
    const listAuthUsers = await admin.auth().listUsers();
    allData['auth_users'] = listAuthUsers.users.map(u => ({
      uid: u.uid,
      email: u.email,
      displayName: u.displayName,
      photoURL: u.photoURL,
      disabled: u.disabled,
      createdAt: u.metadata.creationTime,
      lastSignInTime: u.metadata.lastSignInTime
    }));
    console.log(`Found ${allData['auth_users'].length} Firebase Auth user(s).`);
  } catch (authErr) {
    console.warn('Note: Could not list Firebase Auth users:', authErr.message);
  }

  // Write full summary json
  const fullDataJsonPath = path.resolve(__dirname, '..', 'old_app_data.json');
  fs.writeFileSync(fullDataJsonPath, JSON.stringify(allData, null, 2), 'utf8');
  console.log('Saved all collections summary to:', fullDataJsonPath);

  console.log('\n=== USERS COLLECTION CONTENT ===');
  console.log(JSON.stringify(usersData, null, 2));

  if (allData.auth_users) {
    console.log('\n=== FIREBASE AUTH USERS ===');
    console.log(JSON.stringify(allData.auth_users, null, 2));
  }
}

main().catch(err => {
  console.error('Error fetching data:', err);
  process.exit(1);
});
