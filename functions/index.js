/**
 * Scheduled broadcast pushes, with a history the app can show.
 *
 * Every push is a document in `announcements`:
 *
 *   title_hy, body_hy:  string   Armenian
 *   title_ru, body_ru:  string   Russian
 *   title_en, body_en:  string   English
 *   sendAt: timestamp   when it should go out
 *   status: "scheduled" → "sending" → "sent"   (or "failed" / "expired")
 *
 * Any language may be left out. Russian and English stand in for each other
 * (see FALLBACKS); Armenian is never sent in their place, so a push written
 * only in Armenian reaches only users reading the app in Armenian. The plain
 * `title` / `body` of documents from before translation count as Armenian.
 *
 * Add a document with status "scheduled" and it is sent the first time this
 * function runs after `sendAt`: each language to its own topic,
 * `<PUSH_TOPIC>_hy` / `_ru` / `_en`, which the app joins by its language, and
 * the Armenian text also to `<PUSH_TOPIC>` itself for app versions from
 * before translation. The app lists only documents
 * whose status is "sent", so a scheduled one stays invisible until its push
 * has actually gone out.
 *
 * Old pushes sent from the console can be backfilled for the history by
 * adding them with status "sent" directly — this function never looks at
 * those, so they are not sent again.
 *
 * The message carries a `notification` block, exactly like a console send:
 * that is all older app versions know how to display.
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
 * Base of the topics sends go to. Set in functions/.env: "test" while trying
 * things out on your own device, "all" to reach every user. The app joins
 * "all_<language>"; versions from before translation join "all".
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

const LANGUAGES = ["hy", "ru", "en"];

/**
 * Which languages stand in for a missing one, best first. Must match
 * `Announcement.fallbacks` in the app, so its history shows the very text
 * that was pushed.
 */
const FALLBACKS = {
  hy: ["hy", "ru", "en"],
  ru: ["ru", "en"],
  en: ["en", "ru"],
};

/** The text written in [lang], or null; plain title/body count as Armenian. */
function ownText(data, lang) {
  const pick = (name) => {
    const own = data[`${name}_${lang}`];
    if (typeof own === "string" && own) return own;
    const legacy = data[name];
    return lang === "hy" && typeof legacy === "string" ? legacy : "";
  };
  const title = pick("title");
  const body = pick("body");
  return title || body ? { title, body } : null;
}

/** What users reading the app in [lang] get, or null for nothing. */
function textFor(data, lang) {
  for (const l of FALLBACKS[lang]) {
    const text = ownText(data, l);
    if (text) return text;
  }
  return null;
}

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

/** Yerevan date of the send plus the doc id's start; FCM allows [a-zA-Z0-9-_.~%]{1,50}. */
function analyticsLabel(id, sendAt) {
  const yerevan = new Date(sendAt.toMillis() + 4 * 3600 * 1000);
  return `${yerevan.toISOString().slice(0, 10)}_${id.slice(0, 6)}`;
}

async function sendOne(doc, topic, now) {
  const data = doc.data();
  const { sendAt } = data;

  if (now.toMillis() - sendAt.toMillis() > MAX_LATENESS_MS) {
    await doc.ref.update({ status: "expired" });
    logger.warn(`${doc.id}: sendAt too far in the past, not sent`);
    return;
  }

  // One message per topic. The Armenian one also goes to the bare topic,
  // which only app versions from before translation are on.
  const targets = [];
  for (const lang of LANGUAGES) {
    const text = textFor(data, lang);
    if (text) targets.push({ topic: `${topic}_${lang}`, text });
  }
  const armenian = textFor(data, "hy");
  if (armenian) targets.push({ topic, text: armenian });

  if (targets.length === 0) {
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
    const response = await getMessaging().sendEach(
      targets.map(({ topic, text }) => ({
        topic,
        notification: { title: text.title, body: text.body },
        data: { announcementId: doc.id },
        // Console sends show up in Messaging → Campaigns; API sends don't. The
        // label makes this push a row in Messaging → Reports instead (sends,
        // received, impressions, opens), e.g. "2026-10-10_Hzwy05".
        fcmOptions: { analyticsLabel: analyticsLabel(doc.id, sendAt) },
      }))
    );
    const sentTo = [];
    const errors = {};
    response.responses.forEach((r, i) => {
      if (r.success) sentTo.push(targets[i].topic);
      else errors[targets[i].topic] = String(r.error);
    });
    if (sentTo.length === 0) throw new Error(JSON.stringify(errors));

    // Topics that did get it must not get it again, so a partial failure is
    // still "sent", with what failed recorded next to it.
    await doc.ref.update({
      status: "sent",
      sentAt: FieldValue.serverTimestamp(),
      topics: sentTo,
      ...(Object.keys(errors).length ? { errors } : {}),
      // App versions from before translation read only these two.
      ...(armenian ? { title: armenian.title, body: armenian.body } : {}),
    });
    logger.info(`${doc.id}: sent to ${sentTo.join(", ")}`);
    if (Object.keys(errors).length) {
      logger.error(`${doc.id}: some topics failed`, errors);
    }
  } catch (e) {
    // Not retried automatically: set status back to "scheduled" by hand
    // once the cause is fixed.
    await doc.ref.update({ status: "failed", error: String(e) });
    logger.error(`${doc.id}: send failed`, e);
  }
}
