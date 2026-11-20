const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

exports.sendAnnouncementNotification = onDocumentCreated(
  {
    document: 'announcements/{announcementId}',
    region: 'europe-west1',
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const title = String(data.title || 'إعلان جديد من الجامعة').slice(0, 90);
    const body = String(data.body || '').slice(0, 180);
    const type = data.type === 'task' ? 'task' : 'announcement';

    await getMessaging().send({
      topic: 'all_users',
      notification: {
        title,
        body,
      },
      data: {
        type,
        announcementId: event.params.announcementId,
      },
      android: {
        priority: 'high',
      },
    });
  },
);
