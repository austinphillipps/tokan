const functions = require('firebase-functions');
const admin     = require('firebase-admin');
admin.initializeApp();

exports.sendNewCommentNotif = functions.firestore
  .document('comments/{commentId}')
  .onCreate(async (snap, ctx) => {
    const { postId, authorId, body } = snap.data();
    const userFcmToken = await getUserToken(authorId);
    await admin.messaging().send({
      token: userFcmToken,
      notification: {
        title: 'Nouveau commentaire',
        body,
      },
      data: { screen: 'comments', postId },
    });
  });

async function getUserToken(userId) {
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  return userDoc.data().fcmToken;
}
