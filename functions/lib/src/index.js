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
exports.onMoodChange = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
exports.onMoodChange = functions.firestore
    .document('moods/{userId}')
    .onWrite(async (change, context) => {
    var _a, _b;
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
    if (newData.hugStatedAt && newData.hugStatedAt !== (prevData === null || prevData === void 0 ? void 0 : prevData.hugStatedAt)) {
        targetUserId = userId;
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        targetToken = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
        if (!targetToken)
            return null;
        const sender = newData.hugSentBy || 'Your partner';
        title = `You received a hug! ❤️`;
        body = `${sender} sent you a warm hug!`;
    }
    else if (newData.label !== (prevData === null || prevData === void 0 ? void 0 : prevData.label)) {
        const myDoc = await admin.firestore().collection('users').doc(userId).get();
        const myName = ((_b = myDoc.data()) === null || _b === void 0 ? void 0 : _b.name) || 'Your partner';
        title = `Mood Update`;
        body = `${myName} feels ${newData.label} now.`;
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
        });
        console.log('Notification sent successfully to', targetUserId);
    }
    catch (e) {
        console.error('Failed to send notification', e);
    }
    return null;
});
//# sourceMappingURL=index.js.map