# Firebase setup for Chapp

Phone/OTP auth already works. To enable the chat features (realtime chats,
presence, typing, read receipts, image messages, groups) you need to do the
following once for project **`chapp-99c50`**.

## 1. Enable Cloud Storage (required for image messages & profile photos)

The bucket is already configured (`chapp-99c50.firebasestorage.app`), but
Storage must be turned on:

1. Firebase console → **Build → Storage → Get started**.
2. Choose a location and accept.

Without this, sending an image or updating a profile photo will fail.

## 2. Deploy security rules & indexes

Rules and the composite index live in the repo:

- `firestore.rules` – Firestore access control
- `storage.rules` – Storage access control
- `firestore.indexes.json` – composite index for the chat-list query

Deploy them (needs the Firebase CLI, `npm i -g firebase-tools`, then
`firebase login`):

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage --project chapp-99c50
```

If you prefer the console: paste `firestore.rules` into
**Firestore → Rules**, paste `storage.rules` into **Storage → Rules**, and
create the index from step 3.

## 3. Composite index

The chat list runs:

```dart
chats.where('participants', arrayContains: myUid)
     .orderBy('lastMessageAt', descending: true)
```

which needs a composite index on `participants` (Arrays / CONTAINS) +
`lastMessageAt` (Descending). It's in `firestore.indexes.json` (deployed in
step 2). Alternatively, the first time the query runs Firestore prints a
**"create index"** link in the debug console — clicking it builds the same
index. Index builds take a minute or two.

## Notes

- **Presence:** Firestore has no `onDisconnect` (that's Realtime Database), so a
  hard-killed app can look "online" for up to ~2 minutes until the freshness
  window lapses. This is expected.
- **Storage scoping:** Storage rules can't read Firestore, so group/chat media
  is readable/writable by any signed-in user. Tighten with custom claims or a
  Cloud Function if you need strict per-chat access.
