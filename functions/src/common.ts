import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { CallableRequest, HttpsError, FunctionsErrorCode } from "firebase-functions/v2/https";

if (getApps().length === 0) initializeApp();

export const db = getFirestore();
export { FieldValue, Timestamp };

export const LEVELS = ["elementary", "middle", "high"] as const;
export type Level = (typeof LEVELS)[number];

/** Throws an HttpsError whose `details.code` is the stable code the Flutter app localizes (`err.<code>`). */
export function fail(code: FunctionsErrorCode, appCode: string, message: string): never {
  throw new HttpsError(code, message, { code: appCode });
}

export function requireUid(req: CallableRequest<unknown>): string {
  if (!req.auth) fail("unauthenticated", "unauthenticated", "Sign in required.");
  return req.auth.uid;
}

export function asString(v: unknown, name: string, max = 500): string {
  if (typeof v !== "string" || v.length > max) fail("invalid-argument", `invalid-${name}`, `Invalid ${name}.`);
  return v;
}

/** Reads a user's role from Firestore (the source of truth, never from the client). */
export async function roleOf(uid: string): Promise<{ role: string; name: string } | null> {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) return null;
  const d = snap.data() ?? {};
  return { role: String(d.role ?? ""), name: String(d.name ?? "") };
}

export function notificationDoc(userId: string, type: string, groupId: string, subject: string) {
  return { userId, type, groupId, subject, read: false, createdAt: FieldValue.serverTimestamp() };
}

const PUSH_TEXT: Record<string, { title: string; body: (s: string) => string }> = {
  group_full: {
    title: "A group is full · اكتملت مجموعة",
    body: (s) => `“${s}” needs your decision · تحتاج قرارك`,
  },
  group_accepted: {
    title: "Group accepted · تم قبول المجموعة",
    body: (s) => `“${s}” – chat is open · المحادثة مفتوحة`,
  },
  group_rejected: {
    title: "Group declined · تم رفض المجموعة",
    body: (s) => `“${s}”`,
  },
};

/** Best-effort FCM push to every device of the given users; prunes dead tokens. */
export async function pushToUsers(userIds: string[], type: string, groupId: string, subject: string): Promise<void> {
  const text = PUSH_TEXT[type];
  if (!text || userIds.length === 0) return;
  try {
    const entries: { uid: string; token: string }[] = [];
    for (const uid of userIds) {
      const devices = await db.collection("users").doc(uid).collection("devices").get();
      devices.forEach((d) => {
        const token = d.get("token");
        if (typeof token === "string") entries.push({ uid, token });
      });
    }
    if (entries.length === 0) return;
    const res = await getMessaging().sendEachForMulticast({
      tokens: entries.map((e) => e.token),
      notification: { title: text.title, body: text.body(subject) },
      data: { type, groupId },
    });
    await Promise.all(
      res.responses.map(async (r, i) => {
        const code = r.error?.code ?? "";
        if (!r.success && (code.includes("registration-token-not-registered") || code.includes("invalid-argument"))) {
          const { uid, token } = entries[i];
          await db.collection("users").doc(uid).collection("devices").doc(token).delete();
        }
      }),
    );
  } catch (e) {
    console.error("push failed", e); // Push is best-effort; in-app notifications already exist.
  }
}
