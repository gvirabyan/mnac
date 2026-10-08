/**
 * Scheduled broadcast pushes, with a history the app can show.
 *
 * Every push is a document in `announcements`:
 *
 *   title:  string
 *   body:   string
 *   sendAt: timestamp   when it should go out
 *   status: "scheduled" → "sending" → "sent"   (or "failed" / "expired")
 *
 * Add a document with status "scheduled" and it is sent to PUSH_TOPIC the
 * first time this function runs after `sendAt`. The app lists only documents
 * whose status is "sent", so a scheduled one stays invisible until its push
 * has actually gone out.
 *
 * Old pushes sent from the console can be backfilled for the history by
 * adding them with status "sent" directly — this function never looks at
 * those, so they are not sent again.
 *
 * The message carries a `notification` block, exactly like a console send:
 * that is all older app versions know how to display, and they are
 * subscribed to the same topic, so they keep receiving every push.
 */
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const {
  getFirestore,
  Timestamp,
  FieldValue,
} = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Topic every send goes to. Set in functions/.env: "test" while trying
 * things out on your own device, "all" to reach every user — "all" is the
 * topic the app (old versions included) subscribes everyone to.
 */
const PUSH_TOPIC = defineString("PUSH_TOPIC", { default: "test" });

/**
 * A scheduled document whose `sendAt` is further in the past than this is
 * marked "expired" instead of sent. Guards against a backfilled old push
 * accidentally saved as "scheduled" going out to every user, and against a
 * stale backlog firing all at once after the function was down.
 */
const MAX_LATENESS_MS = 6 * 60 * 60 * 1000;

const COLLECTION = "announcements";

exports.sendScheduledAnnouncements = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "Asia/Yerevan",
    region: "europe-west1",
  },
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();
    const topic = PUSH_TOPIC.value();

    const due = await db
      .collection(COLLECTION)
      .where("status", "==", "scheduled")
      .where("sendAt", "<=", now)
      .orderBy("sendAt")
      .limit(20)
      .get();

    for (const doc of due.docs) {
      await sendOne(doc, topic, now);
    }
  }
);

async function sendOne(doc, topic, now) {
  const { title, body, sendAt } = doc.data();

  if (now.toMillis() - sendAt.toMillis() > MAX_LATENESS_MS) {
    await doc.ref.update({ status: "expired" });
    logger.warn(`${doc.id}: sendAt too far in the past, not sent`);
    return;
  }

  if (!title && !body) {
    await doc.ref.update({ status: "failed", error: "empty title and body" });
    return;
  }

  // Claim the document before sending. The precondition fails if anything
  // touched it since it was read — an overlapping run included — so a push
  // can never go out twice to the whole user base.
  try {
    await doc.ref.update(
      { status: "sending" },
      { lastUpdateTime: doc.updateTime }
    );
  } catch (e) {
    logger.info(`${doc.id}: claimed elsewhere, skipping`);
    return;
  }

  try {
    const messageId = await getMessaging().send({
      topic,
      notification: { title: title ?? "", body: body ?? "" },
      data: { announcementId: doc.id },
    });
    await doc.ref.update({
      status: "sent",
      sentAt: FieldValue.serverTimestamp(),
      topic,
      messageId,
    });
    logger.info(`${doc.id}: sent to ${topic}`);
  } catch (e) {
    // Not retried automatically: set status back to "scheduled" by hand
    // once the cause is fixed.
    await doc.ref.update({ status: "failed", error: String(e) });
    logger.error(`${doc.id}: send failed`, e);
  }
}
