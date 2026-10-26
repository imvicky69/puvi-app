"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onCoupleLedgerEntryCreated = exports.onLedgerEntryCreated = exports.onLoveCountUpdate = exports.onNewMessage = exports.onMoodChange = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
exports.onMoodChange = functions.firestore
    .document('moods/{userId}')
    .onWrite(async (change, context) => {
    var _a, _b, _c, _d;
    const userId = context.params.userId;
    const newData = change.after.data();
    const prevData = change.before.data();
    if (!newData)
        return null; // Document deleted
    let targetToken = null;
    let targetUserId = null;
    const usersSnap = await admin.firestore().collection('users').get();
    usersSnap.forEach(doc => {
        if (doc.id !== userId) {
            targetUserId = doc.id;
            targetToken = doc.data().fcmToken;
        }
    });
    if (!targetToken) {
        console.log('No target FCM token found.');
        return null;
    }
    let title = '';
    let body = '';
    let actionType = '';
    if (newData.hugStatedAt && newData.hugStatedAt !== (prevData === null || prevData === void 0 ? void 0 : prevData.hugStatedAt)) {
        targetUserId = userId;
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        targetToken = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
        if (!targetToken)
            return null;
        const sender = newData.hugSentBy || 'Your partner';
        title = `You received a hug! 🤗`;
        body = `${sender} sent you a warm hug!`;
        actionType = 'hug';
    }
    else if (newData.missYouSentAt && newData.missYouSentAt !== (prevData === null || prevData === void 0 ? void 0 : prevData.missYouSentAt)) {
        targetUserId = userId;
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        targetToken = (_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
        if (!targetToken)
            return null;
        const sender = newData.missYouSentBy || 'Your partner';
        title = `Someone misses you! 🥺`;
        body = `${sender} misses you so much!`;
        actionType = 'missYou';
    }
    else if (newData.kissSentAt && newData.kissSentAt !== (prevData === null || prevData === void 0 ? void 0 : prevData.kissSentAt)) {
        targetUserId = userId;
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        targetToken = (_c = userDoc.data()) === null || _c === void 0 ? void 0 : _c.fcmToken;
        if (!targetToken)
            return null;
        const sender = newData.kissSentBy || 'Your partner';
        title = `A kiss for you! 💋`;
        body = `${sender} sent you a kiss!`;
        actionType = 'kiss';
    }
    else if (newData.label !== (prevData === null || prevData === void 0 ? void 0 : prevData.label)) {
        const myDoc = await admin.firestore().collection('users').doc(userId).get();
        const myName = ((_d = myDoc.data()) === null || _d === void 0 ? void 0 : _d.name) || 'Your partner';
        title = `Mood Update`;
        body = `${myName} feels ${newData.label} now.`;
        actionType = 'mood';
    }
    else {
        return null;
    }
    try {
        await admin.messaging().send({
            token: targetToken,
            notification: {
                title,
                body,
            },
            data: {
                type: actionType,
            },
            webpush: {
                notification: {
                    icon: '/icons.svg',
                },
            },
        });
        console.log('Notification sent successfully to', targetUserId);
    }
    catch (e) {
        console.error('Failed to send notification', e);
    }
    return null;
});
exports.onNewMessage = functions.firestore
    .document('chatMessages/{messageId}')
    .onCreate(async (snap, context) => {
    var _a;
    const data = snap.data();
    const senderId = data.senderId;
    // Find the other user's FCM token
    let targetToken = null;
    let targetUserId = null;
    const usersSnap = await admin.firestore().collection('users').get();
    usersSnap.forEach(doc => {
        if (doc.id !== senderId) {
            targetUserId = doc.id;
            targetToken = doc.data().fcmToken;
        }
    });
    if (!targetToken) {
        console.log('No target FCM token found for chat message.');
        return null;
    }
    // Determine sender name
    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = ((_a = senderDoc.data()) === null || _a === void 0 ? void 0 : _a.name) || 'Your partner';
    let title = `${senderName}`;
    let body = data.text;
    let actionType = 'chat';
    if (data.type === 'kiss') {
        title = `${senderName} sent a kiss! 💋`;
        body = 'Open Our Space to catch it!';
        actionType = 'kiss';
    }
    else if (data.type === 'hug') {
        title = `${senderName} sent a hug! 🤗`;
        body = 'Open Our Space to receive it!';
        actionType = 'hug';
    }
    try {
        await admin.messaging().send({
            token: targetToken,
            notification: {
                title,
                body,
            },
            data: {
                type: actionType,
                messageId: context.params.messageId,
            },
            webpush: {
                notification: {
                    icon: '/icons.svg',
                },
            },
        });
        console.log('Chat notification sent successfully to', targetUserId);
    }
    catch (e) {
        console.error('Failed to send chat notification', e);
    }
    return null;
});
exports.onLoveCountUpdate = functions.firestore
    .document('shared/stats')
    .onUpdate(async (change, context) => {
    var _a;
    const newData = change.after.data();
    const prevData = change.before.data();
    console.log('❤️ Love count update triggered');
    console.log('New Data:', JSON.stringify(newData));
    console.log('Prev Data:', JSON.stringify(prevData));
    if (!newData || !prevData) {
        console.log('Missing data, returning');
        return null;
    }
    // Only notify if loveCount increased
    const loveCountDiff = (newData.loveCount || 0) - (prevData.loveCount || 0);
    console.log('Love count diff:', loveCountDiff);
    if (loveCountDiff <= 0) {
        console.log('No increase in love count');
        return null;
    }
    const senderId = newData.lastUpdatedBy;
    console.log('Sender ID:', senderId);
    // Find the other user's FCM token
    let targetToken = null;
    let targetUserId = null;
    const usersSnap = await admin.firestore().collection('users').get();
    console.log('Found', usersSnap.size, 'users in database');
    usersSnap.forEach(doc => {
        const userData = doc.data();
        const token = userData.fcmToken;
        const name = userData.name || doc.id;
        console.log(`Checking user: "${name}" (${doc.id}), hasToken: ${!!token}`);
        if (senderId) {
            if (doc.id !== senderId && token) {
                targetUserId = doc.id;
                targetToken = token;
            }
        }
        else {
            // Fallback: If no senderId, track if we find anyone with a token
            if (token) {
                targetUserId = doc.id;
                targetToken = token;
            }
        }
    });
    if (!targetToken) {
        console.log('❌ No target FCM token found for love count update. Are notifications enabled for anyone?');
        return null;
    }
    // Determine sender name
    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = ((_a = senderDoc.data()) === null || _a === void 0 ? void 0 : _a.name) || 'Your partner';
    const title = 'More Love! ❤️';
    const body = `${senderName} loved you more! Shared count increased by ${loveCountDiff.toLocaleString()}!`;
    try {
        await admin.messaging().send({
            token: targetToken,
            notification: {
                title,
                body,
            },
            data: {
                type: 'love_update',
            },
            webpush: {
                notification: {
                    icon: '/icons.svg',
                },
            },
        });
        console.log('Love update notification sent successfully to', targetUserId);
    }
    catch (e) {
        console.error('Failed to send love update notification', e);
    }
    return null;
});
/**
 * Common handler for couple ledger notifications.
 * Sends push notification to partner when a shared bill, expense, or settlement is recorded.
 */
async function handleLedgerNotification(data, entryId) {
    if (!data)
        return null;
    const paidBy = data.paidBy || 'Partner';
    const owedBy = data.owedBy || '';
    const totalBill = Number(data.totalBill || 0);
    const owedAmount = Number(data.owedAmount || 0);
    const type = data.type || 'split';
    const splitMode = data.splitMode || 'equal';
    const titleText = data.title || 'Shared Expense';
    // Find partner's FCM token from users collection
    let targetToken = null;
    let targetUserId = null;
    const usersSnap = await admin.firestore().collection('users').get();
    usersSnap.forEach(doc => {
        const userData = doc.data();
        const userName = (userData.name || '').toLowerCase();
        const userEmail = (userData.email || '').toLowerCase();
        // If owedBy is defined, match it
        if (owedBy) {
            if (userName === owedBy.toLowerCase() || userEmail.includes(owedBy.toLowerCase())) {
                targetUserId = doc.id;
                targetToken = userData.fcmToken || null;
            }
        }
        else {
            // Otherwise match the partner who is not paidBy
            if (userName !== paidBy.toLowerCase() && !userEmail.includes(paidBy.toLowerCase())) {
                targetUserId = doc.id;
                targetToken = userData.fcmToken || null;
            }
        }
    });
    // Fallback: If still not resolved, pick whichever user isn't paidBy and has a token
    if (!targetToken) {
        usersSnap.forEach(doc => {
            const userData = doc.data();
            const userName = (userData.name || '').toLowerCase();
            if (userName !== paidBy.toLowerCase() && userData.fcmToken) {
                targetUserId = doc.id;
                targetToken = userData.fcmToken;
            }
        });
    }
    if (!targetToken) {
        console.log('No recipient FCM token found for ledger entry:', entryId);
        return null;
    }
    let notifTitle = '';
    let notifBody = '';
    let actionType = 'ledger';
    const formattedTotal = `₹${totalBill.toLocaleString('en-IN')}`;
    const formattedOwed = `₹${owedAmount.toLocaleString('en-IN')}`;
    if (type === 'settlement') {
        notifTitle = 'All Settled Up! 💕';
        notifBody = `${paidBy} settled up ${formattedTotal}. All shared dues are cleared!`;
        actionType = 'ledger_settlement';
    }
    else if (type === 'split' || splitMode === 'equal') {
        notifTitle = `Shared Bill: ${titleText} ✂️`;
        notifBody = `${paidBy} paid ${formattedTotal} (Split 50/50). Your share is ${formattedOwed}.`;
        actionType = 'ledger_split';
    }
    else if (type === 'lent') {
        notifTitle = `New Expense: ${titleText} 💸`;
        notifBody = `${paidBy} covered ${formattedOwed} for you.`;
        actionType = 'ledger_lent';
    }
    else {
        notifTitle = `Ledger Entry: ${titleText} 📝`;
        notifBody = `${paidBy} logged an expense of ${formattedTotal}.`;
        actionType = 'ledger_entry';
    }
    try {
        await admin.messaging().send({
            token: targetToken,
            notification: {
                title: notifTitle,
                body: notifBody,
            },
            data: {
                type: actionType,
                entryId: entryId,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'puvi_ledger',
                    sound: 'default',
                },
            },
            webpush: {
                notification: {
                    icon: '/icons.svg',
                },
            },
        });
        console.log(`✓ Ledger notification sent successfully to ${targetUserId}: "${notifTitle}"`);
    }
    catch (e) {
        console.error('Failed to send ledger notification:', e);
    }
    return null;
}
/**
 * Triggers when a ledger entry is created in the top-level collection.
 */
exports.onLedgerEntryCreated = functions.firestore
    .document('ledger/{entryId}')
    .onCreate(async (snap, context) => {
    return handleLedgerNotification(snap.data(), context.params.entryId);
});
/**
 * Triggers when a ledger entry is created in the couple subcollection.
 */
exports.onCoupleLedgerEntryCreated = functions.firestore
    .document('couples/{coupleId}/ledger/{entryId}')
    .onCreate(async (snap, context) => {
    return handleLedgerNotification(snap.data(), context.params.entryId);
});
//# sourceMappingURL=index.js.map