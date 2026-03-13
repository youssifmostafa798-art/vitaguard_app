import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

async function assertAdmin(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const userDoc = await db.doc(`users/${context.auth.uid}`).get();
  if (!userDoc.exists || userDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required.');
  }
}

export const reviewDoctorVerification = functions.https.onCall(async (data, context) => {
  await assertAdmin(context);

  const doctorId = data?.doctorId as string | undefined;
  const status = data?.status as string | undefined;
  if (!doctorId || !status) {
    throw new functions.https.HttpsError('invalid-argument', 'doctorId and status are required.');
  }
  if (!['approved', 'rejected'].includes(status)) {
    throw new functions.https.HttpsError('invalid-argument', 'status must be approved or rejected.');
  }

  await db.doc(`doctors/${doctorId}`).set(
    {
      verificationStatus: status,
      reviewedBy: context.auth.uid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { doctorId, verificationStatus: status };
});

export const reviewFacilityVerification = functions.https.onCall(async (data, context) => {
  await assertAdmin(context);

  const facilityId = data?.facilityId as string | undefined;
  const status = data?.status as string | undefined;
  if (!facilityId || !status) {
    throw new functions.https.HttpsError('invalid-argument', 'facilityId and status are required.');
  }
  if (!['approved', 'rejected'].includes(status)) {
    throw new functions.https.HttpsError('invalid-argument', 'status must be approved or rejected.');
  }

  await db.doc(`facilities/${facilityId}`).set(
    {
      verificationStatus: status,
      reviewedBy: context.auth.uid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { facilityId, verificationStatus: status };
});
