let admin;
try {
  admin = require('firebase-admin');
} catch (e) {
  try {
    admin = require('C:/Users/rajvi/Repo/Apps/Indivio-App/functions/node_modules/firebase-admin');
  } catch (e2) {
    admin = require('C:/Users/rajvi/Repo/Apps/Lele-App/functions/node_modules/firebase-admin');
  }
}
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

function determineMediaType(storagePath, existingType) {
  if (!storagePath) {
    return existingType === 'video' ? 'video' : 'image';
  }
  const ext = path.extname(storagePath).toLowerCase();
  if (['.mp4', '.mov', '.webm', '.m4v'].includes(ext)) {
    return 'video';
  }
  return 'image';
}

async function organizeGallery() {
  console.log('=== Organizing & Refining Puvi Gallery in Firestore ===');
  console.log('Project ID:', serviceAccount.project_id);

  const galleryCol = db.collection('gallery');
  const snapshot = await galleryCol.get();
  console.log(`Found ${snapshot.size} gallery documents in Firestore.`);

  if (snapshot.empty) {
    console.log('No documents found in gallery collection.');
    return;
  }

  let batch = db.batch();
  let operationCount = 0;
  let batchIndex = 1;
  const refinedDocs = [];

  let imageCount = 0;
  let videoCount = 0;
  let fixedMissingTypeCount = 0;
  let fixedMissingTakenAtCount = 0;

  for (const doc of snapshot.docs) {
    const rawData = doc.data();
    const storagePath = rawData.storagePath || '';
    const imageUrl = rawData.imageUrl || '';
    
    // 1. Determine media type accurately
    let type = rawData.type;
    const computedType = determineMediaType(storagePath, type);
    if (!type) {
      type = computedType;
      fixedMissingTypeCount++;
    } else {
      type = computedType; // Ensure consistency with file extension (.mp4/.mov vs .jpg)
    }

    const isVideo = type === 'video';
    if (isVideo) videoCount++; else imageCount++;

    // 2. Fix missing takenAt
    let takenAt = rawData.takenAt;
    if (!takenAt) {
      takenAt = rawData.createdAt || admin.firestore.FieldValue.serverTimestamp();
      fixedMissingTakenAtCount++;
    }

    // 3. Construct refined document schema
    const updates = {
      type: type,
      isVideo: isVideo,
      mediaUrl: rawData.mediaUrl || imageUrl,
      imageUrl: imageUrl, // Preserve legacy field for backward compatibility
      thumbnailUrl: rawData.thumbnailUrl || imageUrl, // Ready for video posters/thumbnails
      storagePath: storagePath,
      title: rawData.title && rawData.title.trim().length > 0 ? rawData.title.trim() : 'Our memory',
      takenAt: takenAt,
      createdAt: rawData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      coupleId: rawData.coupleId || 'puvi_couple',
      isFavorite: typeof rawData.isFavorite === 'boolean' ? rawData.isFavorite : false,
      album: rawData.album || 'All',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // If video, note file extension & hint
    const ext = path.extname(storagePath).toLowerCase();
    if (ext) {
      updates.fileExtension = ext;
    }

    batch.set(doc.ref, updates, { merge: true });
    operationCount++;

    // Prepare refined local record
    refinedDocs.push({
      _id: doc.id,
      ...serializeValue(rawData),
      ...serializeValue(updates)
    });

    // Firestore batch limit is 500 writes
    if (operationCount >= 400) {
      console.log(`Committing batch ${batchIndex} (${operationCount} writes)...`);
      await batch.commit();
      batch = db.batch();
      operationCount = 0;
      batchIndex++;
    }
  }

  if (operationCount > 0) {
    console.log(`Committing final batch ${batchIndex} (${operationCount} writes)...`);
    await batch.commit();
  }

  console.log('\n--- Gallery Refinement Summary ---');
  console.log(`Total documents processed: ${snapshot.size}`);
  console.log(`Images: ${imageCount}`);
  console.log(`Videos: ${videoCount} (with isVideo flag & mediaUrl separated)`);
  console.log(`Fixed missing type: ${fixedMissingTypeCount}`);
  console.log(`Fixed missing takenAt: ${fixedMissingTakenAtCount}`);
  console.log(`Enriched with: isVideo, mediaUrl, thumbnailUrl, coupleId, isFavorite, album, fileExtension`);

  // Save refined copy locally for app use
  const outputPath = path.resolve(__dirname, '..', 'gallery_refined.json');
  fs.writeFileSync(outputPath, JSON.stringify(refinedDocs, null, 2), 'utf8');
  console.log(`Saved refined gallery dataset to: ${outputPath}`);

  // Also update old_app_data.json gallery section
  const oldAppDataPath = path.resolve(__dirname, '..', 'old_app_data.json');
  if (fs.existsSync(oldAppDataPath)) {
    try {
      const oldAppData = JSON.parse(fs.readFileSync(oldAppDataPath, 'utf8'));
      oldAppData.gallery = refinedDocs;
      fs.writeFileSync(oldAppDataPath, JSON.stringify(oldAppData, null, 2), 'utf8');
      console.log(`Updated gallery collection inside ${oldAppDataPath}`);
    } catch (e) {
      console.warn('Could not update old_app_data.json:', e.message);
    }
  }

  console.log('\n=== Gallery Refinement Complete! ===');
}

organizeGallery().catch(err => {
  console.error('Error organizing gallery:', err);
  process.exit(1);
});
