import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

admin.initializeApp();

interface TargetRecipient {
  userId: string;
  name: string;
  fcmToken: string;
}

/**
 * Resolves the partner (recipient) and their FCM device token.
 * Searches the users collection for the user who is NOT senderIdOrName.
 */
async function getPartnerRecipient(
  senderIdOrName?: string | null
): Promise<TargetRecipient | null> {
  const usersSnap = await admin.firestore().collection('users').get();
  if (usersSnap.empty) return null;

  const normalizedSender = (senderIdOrName || '').trim().toLowerCase();

  // 1. Match partner who is not the sender and has a valid FCM token
  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const docId = doc.id.toLowerCase();
    const docName = (data.name || '').toLowerCase();
    const docEmail = (data.email || '').toLowerCase();

    const isSender =
      normalizedSender.length > 0 &&
      (docId === normalizedSender ||
        docName === normalizedSender ||
        docEmail.includes(normalizedSender));

    const token = data.fcmToken || data.token;

    if (!isSender && token) {
      return {
        userId: doc.id,
        name: data.name || (doc.id === 'HfzubbPMBsgQugeC5AcNqyWbwlw2' ? 'Puja' : 'Vicky'),
        fcmToken: token,
      };
    }
  }

  // 2. Fallback: If sender couldn't be determined, pick any user with an active token
  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const token = data.fcmToken || data.token;
    if (token) {
      return {
        userId: doc.id,
        name: data.name || (doc.id === 'HfzubbPMBsgQugeC5AcNqyWbwlw2' ? 'Puja' : 'Vicky'),
        fcmToken: token,
      };
    }
  }

  return null;
}

/**
 * Sends a high-priority push notification compatible with both Android (Flutter) and Web.
 */
async function sendPushNotification({
  token,
  title,
  body,
  data = {},
  channelId = 'puvi_love_channel',
}: {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  channelId?: string;
}): Promise<void> {
  try {
    await admin.messaging().send({
      token,
      notification: {
        title,
        body,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        ...data,
      },
      android: {
        priority: 'high',
        notification: {
          channelId,
          sound: 'default',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      webpush: {
        notification: {
          icon: '/icons.svg',
        },
      },
    });
    console.log(`✓ Push notification sent successfully: "${title}"`);
  } catch (error: any) {
    console.error('Failed to send push notification:', error);
    if (
      error.code === 'messaging/registration-token-not-registered' ||
      error.code === 'messaging/invalid-registration-token'
    ) {
      console.warn(`[FCM] Token is no longer registered: ${token.substring(0, 15)}...`);
    }
  }
}

/**
 * Trigger: moods/{userId}
 * Notifies the partner when mood is updated or when an interactive love action (hug, kiss, miss you) is sent.
 */
export const onMoodChange = functions.firestore
  .document('moods/{userId}')
  .onWrite(async (change, context) => {
    const userId = context.params.userId;
    const newData = change.after.data();
    const prevData = change.before.data();

    if (!newData) return null; // Document deleted

    // The recipient is the partner, NOT the user writing the mood
    const recipient = await getPartnerRecipient(userId);
    if (!recipient) {
      console.log('No recipient FCM token found for mood change.');
      return null;
    }

    let title = '';
    let body = '';
    let actionType = '';

    if (newData.hugStatedAt && newData.hugStatedAt !== prevData?.hugStatedAt) {
      const sender = newData.hugSentBy || 'Your partner';
      title = 'You received a hug! 🤗';
      body = `${sender} sent you a warm hug!`;
      actionType = 'hug';
    } else if (newData.missYouSentAt && newData.missYouSentAt !== prevData?.missYouSentAt) {
      const sender = newData.missYouSentBy || 'Your partner';
      title = 'Someone misses you! 🥺';
      body = `${sender} misses you so much!`;
      actionType = 'missYou';
    } else if (newData.kissSentAt && newData.kissSentAt !== prevData?.kissSentAt) {
      const sender = newData.kissSentBy || 'Your partner';
      title = 'A kiss for you! 💋';
      body = `${sender} sent you a kiss!`;
      actionType = 'kiss';
    } else if (newData.label !== prevData?.label) {
      const senderDoc = await admin.firestore().collection('users').doc(userId).get();
      const senderName = senderDoc.data()?.name || 'Your partner';
      title = 'Mood Update';
      body = `${senderName} feels ${newData.label} now.`;
      actionType = 'mood';
    } else {
      return null;
    }

    await sendPushNotification({
      token: recipient.fcmToken,
      title,
      body,
      data: { type: actionType },
      channelId: 'puvi_love_channel',
    });

    return null;
  });

/**
 * Trigger: chatMessages/{messageId}
 * Notifies the partner when a new message, kiss, or hug is sent in the chat.
 */
export const onNewMessage = functions.firestore
  .document('chatMessages/{messageId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const senderId = data.senderId;

    const recipient = await getPartnerRecipient(senderId);
    if (!recipient) {
      console.log('No target FCM token found for chat message.');
      return null;
    }

    // Determine sender name
    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = senderDoc.data()?.name || 'Your partner';

    let title = `${senderName}`;
    let body = data.text || '';
    let actionType = 'chat';

    if (data.type === 'kiss') {
      title = `${senderName} sent a kiss! 💋`;
      body = 'Open Our Space to catch it!';
      actionType = 'kiss';
    } else if (data.type === 'hug') {
      title = `${senderName} sent a hug! 🤗`;
      body = 'Open Our Space to receive it!';
      actionType = 'hug';
    }

    await sendPushNotification({
      token: recipient.fcmToken,
      title,
      body,
      data: {
        type: actionType,
        messageId: context.params.messageId,
      },
      channelId: 'puvi_chat',
    });

    return null;
  });

/**
 * Trigger: pings/{pingId}
 * Restored function: Notifies partner when a "thinking of you" love ping is sent.
 */
export const onNewPing = functions.firestore
  .document('pings/{pingId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    // Love count updates are handled seamlessly by onLoveCountUpdate on shared/stats
    if (data.count && Number(data.count) > 0) {
      return null;
    }

    const senderId = data.senderId;

    const recipient = await getPartnerRecipient(senderId);
    if (!recipient) {
      console.log('No recipient FCM token found for ping.');
      return null;
    }

    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = senderDoc.data()?.name || 'Your partner';

    const title = `${senderName} is thinking of you! 💕`;
    const body = data.message || 'Tap to see the love!';

    await sendPushNotification({
      token: recipient.fcmToken,
      title,
      body,
      data: {
        type: 'ping',
        pingId: context.params.pingId,
      },
      channelId: 'puvi_love_channel',
    });

    return null;
  });

/**
 * Trigger: shared/stats
 * Notifies partner when the shared love tap count increases.
 */
export const onLoveCountUpdate = functions.firestore
  .document('shared/stats')
  .onUpdate(async (change) => {
    const newData = change.after.data();
    const prevData = change.before.data();

    if (!newData || !prevData) return null;

    const loveCountDiff = (newData.loveCount || 0) - (prevData.loveCount || 0);
    if (loveCountDiff <= 0) return null;

    const senderId = newData.lastUpdatedBy;
    const recipient = await getPartnerRecipient(senderId);
    if (!recipient) {
      console.log('No target FCM token found for love count update.');
      return null;
    }

    const senderDoc = senderId
      ? await admin.firestore().collection('users').doc(senderId).get()
      : null;
    const senderName =
      senderDoc?.data()?.name ||
      (senderId === 'HfzubbPMBsgQugeC5AcNqyWbwlw2' ? 'Puja' : 'Vicky');

    const isMegaShower = loveCountDiff >= 1000;
    const title = isMegaShower
      ? `✨ Mega Love Shower from ${senderName}! 💖`
      : `${senderName} loved you more! ❤️`;
    const body = isMegaShower
      ? `${senderName} showered you with +${loveCountDiff.toLocaleString()} love pings with your song! Tap to feel the love 💕`
      : `Shared love count reached ${(newData.loveCount || 0).toLocaleString()} pings! Tap to reciprocate 💕`;

    await sendPushNotification({
      token: recipient.fcmToken,
      title,
      body,
      data: {
        type: 'love_update',
        increment: loveCountDiff.toString(),
        isMegaShower: isMegaShower.toString(),
        senderId: senderId || '',
        senderName,
        totalLoveCount: (newData.loveCount || 0).toString(),
        playMusic: isMegaShower.toString(),
      },
      channelId: 'puvi_love_channel',
    });

    return null;
  });

/**
 * Common handler for couple ledger notifications.
 * Sends push notification to partner when a shared bill, expense, or settlement is recorded.
 */
async function handleLedgerNotification(
  data: admin.firestore.DocumentData | undefined,
  entryId: string
) {
  if (!data) return null;

  const paidBy = data.paidBy || 'Partner';
  const owedBy = data.owedBy || '';
  const totalBill = Number(data.totalBill || 0);
  const owedAmount = Number(data.owedAmount || 0);
  const type = data.type || 'split';
  const splitMode = data.splitMode || 'equal';
  const titleText = data.title || 'Shared Expense';

  // Target the owedBy person, or partner who is not paidBy
  const recipient = await getPartnerRecipient(owedBy ? undefined : paidBy);
  const targetToken = recipient?.fcmToken;

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
  } else if (type === 'split' || splitMode === 'equal') {
    notifTitle = `Shared Bill: ${titleText} ✂️`;
    notifBody = `${paidBy} paid ${formattedTotal} (Split 50/50). Your share is ${formattedOwed}.`;
    actionType = 'ledger_split';
  } else if (type === 'lent') {
    notifTitle = `New Expense: ${titleText} 💸`;
    notifBody = `${paidBy} covered ${formattedOwed} for you.`;
    actionType = 'ledger_lent';
  } else {
    notifTitle = `Ledger Entry: ${titleText} 📝`;
    notifBody = `${paidBy} logged an expense of ${formattedTotal}.`;
    actionType = 'ledger_entry';
  }

  await sendPushNotification({
    token: targetToken,
    title: notifTitle,
    body: notifBody,
    data: {
      type: actionType,
      entryId: entryId,
    },
    channelId: 'puvi_ledger',
  });

  return null;
}

/**
 * Triggers when a ledger entry is created in the top-level collection.
 */
export const onLedgerEntryCreated = functions.firestore
  .document('ledger/{entryId}')
  .onCreate(async (snap, context) => {
    return handleLedgerNotification(snap.data(), context.params.entryId);
  });

/**
 * Triggers when a ledger entry is created in the couple subcollection.
 */
export const onCoupleLedgerEntryCreated = functions.firestore
  .document('couples/{coupleId}/ledger/{entryId}')
  .onCreate(async (snap, context) => {
    return handleLedgerNotification(snap.data(), context.params.entryId);
  });
