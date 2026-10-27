const path = require('path');
const fs = require('fs');

// Use firebase-admin from functions/node_modules
const admin = require(path.resolve(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
const serviceAccount = require(path.resolve(__dirname, '..', 'serviceAccountKey.json'));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id
  });
}

const db = admin.firestore();

async function runMigration() {
  console.log('--- Starting Puvi Timeline Audit Migration ---');
  console.log('Project ID:', serviceAccount.project_id);

  // 1. Fetch current timeline snapshot and make backup
  const timelineCol = db.collection('timeline');
  const snapshot = await timelineCol.get();
  console.log(`Current live documents count: ${snapshot.size}`);

  const backupData = [];
  snapshot.forEach(doc => {
    backupData.push({ _id: doc.id, ...doc.data() });
  });

  const backupPath = path.resolve(__dirname, '..', 'scratch', 'timeline_backup_before_migration.json');
  fs.mkdirSync(path.dirname(backupPath), { recursive: true });
  fs.writeFileSync(backupPath, JSON.stringify(backupData, null, 2), 'utf8');
  console.log(`✓ Saved backup of ${backupData.length} documents to: ${backupPath}`);

  // 2. Delete Ghost Duplicate: GnYtyKLxtftwZUM7p8Wb (May 20, 2026 draft with no image)
  const ghostId = 'GnYtyKLxtftwZUM7p8Wb';
  const ghostDoc = await timelineCol.doc(ghostId).get();
  if (ghostDoc.exists) {
    await timelineCol.doc(ghostId).delete();
    console.log(`✓ Deleted ghost draft duplicate document: ${ghostId}`);
  } else {
    console.log(`- Ghost draft ${ghostId} was not found or already deleted.`);
  }

  // 3. Define curated metadata enrichments and fixes
  const updates = {
    // 2025-11-22
    'daI9TsSwZ9usH222ocgH': {
      title: '“First Chat, First Connection.”',
      location: 'Facebook / Online',
      category: 'Firsts',
      authorName: 'Puja',
      coupleId: 'puvi_couple'
    },
    // 2025-12-02
    'oc9bKBhh3iU6zrVbCIoL': {
      title: '“Edited by Him”',
      location: 'Instagram / Online',
      category: 'Firsts',
      authorName: 'Puja',
      coupleId: 'puvi_couple'
    },
    // 2026-04-01
    'e4aTZX7oSOkMZ5POR5Kk': {
      title: 'The First Sight',
      location: 'Lanka BHU & VT, Varanasi',
      category: 'Firsts',
      authorName: 'Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-04-20
    '1IiKFKUu93TtE57xSzfY': {
      title: 'The longing',
      location: 'Varanasi Junction',
      category: 'Long Distance',
      authorName: 'Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-05-01
    'QjBd0sAdbnsUIqzdG38u': {
      title: 'Missing each other',
      location: 'Varanasi – Bela',
      category: 'Long Distance',
      authorName: 'Puja & Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-05-10: Fix Africa GPS anomaly (-4.34, 15.35)
    'wcPji1kYtsrKmk7SijB0': {
      title: 'Aaj hamara one month anniversary hai 🩷',
      location: 'WhatsApp',
      coordinates: null,
      category: 'Anniversary',
      authorName: 'Puja',
      coupleId: 'puvi_couple'
    },
    // 2026-05-13
    'eL2Lc7I1I5I7zz50AMUE': {
      title: 'Finally we met , मैं १३',
      note: 'After days of counting hours, we finally embraced at IP Sigra.',
      location: 'IP Sigra, Varanasi',
      category: 'Dates',
      authorName: 'Puja & Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-05-13
    'y0PK23ekOryI28pQQnm0': {
      title: 'Our First movie date 🩷',
      note: 'Sharing popcorn, quiet glances, and our first cinema date together.',
      location: 'IP Sigra, Varanasi',
      category: 'Dates',
      authorName: 'Puja & Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-05-14
    '5NJY6pvy9QWdZXKGi8n0': {
      title: 'Cute we smiling together at the Dusk.',
      location: 'Assi Ghat, Varanasi',
      category: 'Dates',
      authorName: 'Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-05-14
    'OO0HeffzUhYxgBwN8EL7': {
      title: 'Jhumka for beautiful people',
      location: 'VT, BHU, Varanasi',
      category: 'Dates',
      authorName: 'Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-05-16
    'KzqdrmM63bmBaCADmrME': {
      title: 'We went Namo Ghat',
      location: 'Namo Ghat, Varanasi',
      category: 'Dates',
      authorName: 'Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-05-19: Engaged
    'vw4KqxB69B34gWHKOPvY': {
      title: 'The beginning of our forever',
      location: 'Varanasi',
      category: 'Milestones',
      authorName: 'Puja',
      coupleId: 'puvi_couple'
    },
    // 2026-05-20
    'viIk6bvgh7voewDfXb2P': {
      title: 'नजर से नजर मिले 👀',
      location: 'Varanasi',
      category: 'Love Notes',
      authorName: 'Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-05-23
    '2lQeYtc6RMhfFUzOPO4w': {
      title: 'Assi again',
      location: 'Assi Ghat, Varanasi',
      category: 'Dates',
      authorName: 'Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-06-04
    'T57EE0fb9O84cndqwq4N': {
      title: 'Me with my boondi ka laddu 😘.',
      location: 'Varanasi',
      category: 'Love Notes',
      authorName: 'Puja',
      coupleId: 'puvi_couple'
    },
    // 2026-07-01
    'AIwHbMOeRfgQam1coaNL': {
      title: '“तेरे कंधे से ही लग के बीते ये उम्र सारी” ♾️....',
      location: 'Varanasi',
      category: 'Love Notes',
      authorName: 'Puja & Vicky',
      coupleId: 'puvi_couple'
    },
    // 2026-08-03
    '4eaGvJpFzKl44Q17zH0i': {
      title: 'B day girl',
      location: 'Varanasi',
      category: 'Milestones',
      authorName: 'Vicky',
      coupleId: 'puvi_couple'
    }
  };

  const batch = db.batch();
  for (const [docId, fields] of Object.entries(updates)) {
    const docRef = timelineCol.doc(docId);
    batch.set(docRef, fields, { merge: true });
    console.log(`  -> Queued update for: ${docId} (${fields.title})`);
  }

  // 4. Add official Anniversary Milestone: April 11, 2026
  const anniversaryDocId = 'puvi_anniversary_20260411';
  const anniversaryRef = timelineCol.doc(anniversaryDocId);
  const anniversaryData = {
    title: 'The Day We Became Us 💍',
    date: '2026-04-11',
    note: 'April 11, 2026 — The sacred beginning of our forever together. Two souls, one heartbeat, and an eternal promise.',
    location: 'Varanasi',
    category: 'Anniversary',
    authorName: 'Puja & Vicky',
    coupleId: 'puvi_couple',
    imageUrl: 'https://firebasestorage.googleapis.com/v0/b/puvi-love.firebasestorage.app/o/timeline%2Fe0c9adac-8162-4daf-977b-6cfdee06735a_1000026483.jpg?alt=media&token=3ffdf2f3-1a20-4b48-bb33-c3bd58f85d8a',
    coordinates: {
      lat: 25.3176,
      lng: 82.9739
    },
    createdAt: '2026-04-11T00:00:00.000Z'
  };

  batch.set(anniversaryRef, anniversaryData, { merge: true });
  console.log(`  -> Queued official Anniversary anchor: ${anniversaryDocId}`);

  await batch.commit();
  console.log('✓ Successfully committed all batch updates to Firestore!');

  // 5. Verify live state
  const updatedSnap = await timelineCol.get();
  console.log(`\nUpdated live timeline documents count: ${updatedSnap.size}`);

  const allItems = [];
  updatedSnap.forEach(d => {
    allItems.push({ _id: d.id, ...d.data() });
  });

  // Sort chronologically
  allItems.sort((a, b) => new Date(a.date) - new Date(b.date));

  // Also write an updated assets/timeline.json for offline-first instant loading!
  const assetsTimelinePath = path.resolve(__dirname, '..', 'assets', 'timeline.json');
  fs.writeFileSync(assetsTimelinePath, JSON.stringify(allItems, null, 2), 'utf8');
  console.log(`✓ Generated bundled offline asset at: ${assetsTimelinePath}`);

  console.log('\n--- Timeline Migration Complete ---');
}

runMigration().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
