const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

// 1. Initialize Firebase Admin
const admin = require(path.resolve(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
const serviceAccount = require(path.resolve(__dirname, '..', 'serviceAccountKey.json'));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id
  });
}

const db = admin.firestore();

const PUJA_UID = 'HfzubbPMBsgQugeC5AcNqyWbwlw2';
const VICKY_UID = 'bx3PgTysxeX7HMfkyPWiCwtqLZG3';
const COUPLE_ID = 'puvi_couple';
const ANNIVERSARY_SALT = '2026-04-11';

// Derive 32-byte AES key from couple secret & member UIDs
function deriveKey(secret) {
  const salt = [PUJA_UID, VICKY_UID, ANNIVERSARY_SALT].sort().join('_');
  return crypto.createHash('sha256').update(secret + ':' + salt).digest();
}

function encryptText(plainText, key) {
  if (!plainText || plainText.length === 0) return '';
  if (plainText.startsWith('enc:v1:')) return plainText; // Already encrypted

  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  let encrypted = cipher.update(plainText, 'utf8', 'base64');
  encrypted += cipher.final('base64');
  return 'enc:v1:' + iv.toString('base64') + ':' + encrypted;
}

function decryptText(encryptedText, key) {
  if (!encryptedText || !encryptedText.startsWith('enc:v1:')) return encryptedText;

  const parts = encryptedText.split(':');
  if (parts.length !== 4) return encryptedText;

  const iv = Buffer.from(parts[2], 'base64');
  const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
  let decrypted = decipher.update(parts[3], 'base64', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

async function run() {
  console.log('=== Puvi Chat E2EE Migration Script ===');
  console.log('Firebase Project:', serviceAccount.project_id);

  // 1. Fetch or create E2EE master secret in couples/puvi_couple
  const coupleRef = db.collection('couples').doc(COUPLE_ID);
  const coupleSnap = await coupleRef.get();
  if (!coupleSnap.exists) {
    throw new Error('Couple document puvi_couple does not exist!');
  }

  let e2eeSecret = coupleSnap.data().e2eeSecret;
  if (!e2eeSecret) {
    e2eeSecret = crypto.randomBytes(32).toString('hex');
    await coupleRef.set({
      e2eeSecret: e2eeSecret,
      e2eeAlgorithm: 'AES-256-CBC-PKCS7',
      e2eeUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    console.log('✓ Created and secured new e2eeSecret in couples/puvi_couple');
  } else {
    console.log('✓ Found existing e2eeSecret in couples/puvi_couple');
  }

  const aesKey = deriveKey(e2eeSecret);
  console.log('✓ Derived 256-bit AES key successfully.');

  // 2. Fetch all messages & create backup
  console.log('\n--- Step 1: Fetching & Backing Up Live Messages ---');
  const chatSnap = await db.collection('chatMessages').get();
  console.log(`Found ${chatSnap.size} messages in chatMessages collection.`);

  const backupData = [];
  chatSnap.forEach(doc => {
    backupData.push({ _id: doc.id, ...doc.data() });
  });

  const backupPath = path.resolve(__dirname, '..', 'scratch', 'chat_messages_backup_before_e2ee.json');
  fs.mkdirSync(path.dirname(backupPath), { recursive: true });
  fs.writeFileSync(backupPath, JSON.stringify(backupData, null, 2), 'utf8');
  console.log(`✓ Saved backup of ${backupData.length} documents to: ${backupPath}`);

  // 3. Prepare Batch Writes for E2EE encryption & field enrichment
  console.log('\n--- Step 2: Encrypting & Enriching Documents ---');
  const batch = db.batch();
  let encryptedTextCount = 0;
  let kissCount = 0;
  let hugCount = 0;

  for (const doc of chatSnap.docs) {
    const data = doc.data();
    const docRef = db.collection('chatMessages').doc(doc.id);

    // Receiver resolution
    let receiverId = data.receiverId;
    if (!receiverId) {
      receiverId = data.senderId === PUJA_UID ? VICKY_UID : PUJA_UID;
    }

    // Timestamp resolution
    let timestamp = data.timestamp;
    if (!timestamp && data.createdAt) {
      const d = new Date(data.createdAt);
      if (!isNaN(d.getTime())) {
        timestamp = admin.firestore.Timestamp.fromDate(d);
      }
    }

    // Encryption of text
    let newText = data.text || '';
    let isEncrypted = false;
    if (newText.length > 0) {
      if (!newText.startsWith('enc:v1:')) {
        newText = encryptText(newText, aesKey);
        encryptedTextCount++;
      }
      isEncrypted = true;
    }

    if (data.type === 'kiss') kissCount++;
    if (data.type === 'hug') hugCount++;

    const updatePayload = {
      coupleId: COUPLE_ID,
      receiverId: receiverId,
      text: newText,
      isEncrypted: isEncrypted,
      type: data.type || 'text',
      isSeen: data.isSeen !== undefined ? data.isSeen : true
    };

    if (timestamp) {
      updatePayload.timestamp = timestamp;
    }

    batch.set(docRef, updatePayload, { merge: true });
  }

  await batch.commit();
  console.log(`✓ Successfully updated ${chatSnap.size} documents in Firestore.`);
  console.log(`  - Encrypted text messages: ${encryptedTextCount}`);
  console.log(`  - Kisses: ${kissCount}`);
  console.log(`  - Hugs: ${hugCount}`);

  // 4. Verification Step: Verify decryption matches backup
  console.log('\n--- Step 3: Verification & Integrity Check ---');
  const verifySnap = await db.collection('chatMessages').get();
  const backupMap = new Map(backupData.map(d => [d._id, d]));

  let verifiedMatches = 0;
  let verificationErrors = 0;

  for (const doc of verifySnap.docs) {
    const data = doc.data();
    const original = backupMap.get(doc.id);
    if (!original) {
      console.error(`Verification error: doc ${doc.id} not found in backup!`);
      verificationErrors++;
      continue;
    }

    if (original.text && original.text.length > 0) {
      // Must be encrypted in Firestore
      if (!data.text.startsWith('enc:v1:')) {
        console.error(`Doc ${doc.id} is NOT encrypted! Raw text: ${data.text}`);
        verificationErrors++;
        continue;
      }

      // Decrypt and compare
      const decrypted = decryptText(data.text, aesKey);
      if (decrypted !== original.text) {
        console.error(`Decryption mismatch for doc ${doc.id}!`);
        verificationErrors++;
        continue;
      }
    }

    // Verify receiverId & coupleId
    if (data.coupleId !== COUPLE_ID || !data.receiverId) {
      console.error(`Doc ${doc.id} missing coupleId or receiverId!`);
      verificationErrors++;
      continue;
    }

    verifiedMatches++;
  }

  if (verificationErrors === 0 && verifiedMatches === verifySnap.size) {
    console.log(`🎉 100% SUCCESS! All ${verifiedMatches} messages verified, encrypted, and tested.`);
  } else {
    console.error(`⚠️ Found ${verificationErrors} verification errors! Check logs.`);
    process.exit(1);
  }
}

run().catch(err => {
  console.error('Fatal migration error:', err);
  process.exit(1);
});
