// Sets the song of the day for everyone (Firestore `song_days/<date>`).
// The app shows the song set for today, or else the latest one before it.
//
// Run from D:\depitun (uses firebase-admin from functions/node_modules):
//
//   node tool/set_song.js <service-account.json> "aram asatryan" [2026-11-16]
//       Searches iTunes, lists the matches and asks which one to set for
//       the date (default: today). Search in Latin letters: iTunes lists
//       Armenian songs only that way.
//   node tool/set_song.js <service-account.json> --id 1440818663 [date]
//       Sets a track by its iTunes id (the number after "i=" or at the end
//       of an Apple Music song link).
//   node tool/set_song.js <service-account.json> --list
//       Shows the songs set from 7 days ago on.
//   node tool/set_song.js <service-account.json> --delete 2026-11-16
//       Removes the song set for that date.
const path = require("path");
const readline = require("readline/promises");
const req = require("module").createRequire(path.resolve("functions/index.js"));
const { initializeApp, cert } = req("firebase-admin/app");
const { getFirestore, FieldValue } = req("firebase-admin/firestore");

const [, , keyFile, ...args] = process.argv;
if (!keyFile || args.length === 0) {
  console.log(
    'Usage: node tool/set_song.js <key.json> "query" [yyyy-mm-dd] | --id <trackId> [date] | --list | --delete <date>',
  );
  process.exit(1);
}
initializeApp({ credential: cert(require(path.resolve(keyFile))) });
const db = getFirestore();
const days = db.collection("song_days");

const dayKey = (d) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
const isDay = (s) => /^\d{4}-\d{2}-\d{2}$/.test(s ?? "");

async function itunes(pathname, params) {
  const url = new URL(`https://itunes.apple.com${pathname}`);
  for (const [k, v] of Object.entries({ country: "US", ...params })) {
    url.searchParams.set(k, v);
  }
  const res = await fetch(url);
  if (!res.ok) throw new Error(`iTunes HTTP ${res.status}`);
  const body = await res.json();
  return body.results.filter((r) => r.kind === "song" && r.trackId);
}

const describe = (t) =>
  `${t.trackName} — ${t.artistName}${t.previewUrl ? "" : "  (no preview!)"}`;

async function setSong(track, day) {
  await days.doc(day).set({
    day,
    source: "appleMusic",
    trackId: String(track.trackId),
    title: track.trackName,
    artist: track.artistName,
    artworkUrl: track.artworkUrl100?.replace("100x100bb", "200x200bb") ?? null,
    previewUrl: track.previewUrl ?? null,
    storeUrl: track.trackViewUrl ?? null,
    setAt: FieldValue.serverTimestamp(),
  });
  console.log(`✔ ${day}: ${describe(track)}`);
}

(async () => {
  if (args[0] === "--list") {
    const from = new Date();
    from.setDate(from.getDate() - 7);
    const snap = await days.where("day", ">=", dayKey(from)).orderBy("day").get();
    if (snap.empty) console.log("No songs set.");
    for (const d of snap.docs) {
      const s = d.data();
      console.log(`${s.day}  ${s.title} — ${s.artist}`);
    }
    return;
  }

  if (args[0] === "--delete") {
    if (!isDay(args[1])) throw new Error("Give the date as yyyy-mm-dd");
    await days.doc(args[1]).delete();
    console.log(`✔ Removed ${args[1]}`);
    return;
  }

  if (args[0] === "--id") {
    const day = isDay(args[2]) ? args[2] : dayKey(new Date());
    const [track] = await itunes("/lookup", { id: args[1], entity: "song" });
    if (!track) throw new Error(`No song with id ${args[1]}`);
    await setSong(track, day);
    return;
  }

  const day = isDay(args[1]) ? args[1] : dayKey(new Date());
  const tracks = await itunes("/search", {
    term: args[0],
    media: "music",
    entity: "song",
    limit: "10",
  });
  if (tracks.length === 0) {
    console.log("Nothing found. Try Latin letters or the artist's name.");
    return;
  }
  tracks.forEach((t, i) => console.log(`${i + 1}. ${describe(t)}`));
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const answer = await rl.question(`Number to set for ${day} (Enter = cancel): `);
  rl.close();
  const track = tracks[Number(answer) - 1];
  if (!track) {
    console.log("Cancelled.");
    return;
  }
  await setSong(track, day);
})().catch((e) => {
  console.error("✘", e.message);
  process.exit(1);
});
