import { randomUUID } from "crypto";
import { createClient, SupabaseClient } from "@supabase/supabase-js";
import { defineSecret, defineString } from "firebase-functions/params";
import { onCall } from "firebase-functions/v2/https";
import { db, fail, requireUid, asString, FieldValue } from "./common";
/** Supabase project URL (non-secret) and service-role key (secret, never shipped to the app). */
const SUPABASE_URL = defineString("SUPABASE_URL");

const SUPABASE_SERVICE_ROLE_KEY = defineSecret(
  "SUPABASE_SERVICE_ROLE_KEY"
);
const BUCKET = "profile-images";
const MAX_BYTES = 5 * 1024 * 1024;
const EXT: Record<string, string> = { "image/jpeg": "jpg", "image/png": "png", "image/webp": "webp" };

const opts = { cors: true, secrets: [SUPABASE_SERVICE_ROLE_KEY] };

function supabase(): SupabaseClient {
  return createClient(SUPABASE_URL.value(), SUPABASE_SERVICE_ROLE_KEY.value(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** Step 1: verifies the caller and returns a short-lived signed upload URL for `<uid>/<uuid>.<ext>`. */
export const createProfileImageUpload = onCall(opts, async (req) => {
  const uid = requireUid(req);
  const contentType = asString(req.data?.contentType, "content-type", 40);
  const size = Number(req.data?.size);
  const ext = EXT[contentType];
  if (!ext) fail("invalid-argument", "invalid-content-type", "Unsupported image type.");
  if (!Number.isFinite(size) || size <= 0 || size > MAX_BYTES) fail("invalid-argument", "image-too-large", "Image too large.");

  const path = `${uid}/${randomUUID()}.${ext}`;
  const { data, error } = await supabase().storage.from(BUCKET).createSignedUploadUrl(path);
  if (error || !data) fail("internal", "upload-missing", "Could not prepare upload.");
  return { signedUrl: data.signedUrl, path };
});

/** Step 2: checks the object exists, swaps the profile image, deletes the previous file. */
export const confirmProfileImage = onCall(opts, async (req) => {
  const uid = requireUid(req);
  const path = asString(req.data?.path, "path", 200);
  const parts = path.split("/");
  if (parts.length !== 2 || parts[0] !== uid || path.includes("..")) fail("permission-denied", "invalid-path", "Invalid path.");

  const sb = supabase();
  const listed = await sb.storage.from(BUCKET).list(uid, { search: parts[1], limit: 1 });
  if (listed.error || !listed.data?.some((f) => f.name === parts[1])) {
    fail("failed-precondition", "upload-missing", "Upload not found.");
  }
  const imageUrl = sb.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;

  const userRef = db.collection("users").doc(uid);
  const user = await userRef.get();
  const previous = user.get("imagePath") as string | undefined;
  await userRef.set({ imagePath: path, imageUrl, imageUpdatedAt: FieldValue.serverTimestamp() }, { merge: true });
  if (user.get("role") === "teacher") {
    await db.collection("teacherProfiles").doc(uid).set({ imageUrl }, { merge: true });
  }
  if (previous && previous !== path && previous.startsWith(`${uid}/`)) {
    await sb.storage.from(BUCKET).remove([previous]);
  }
  return { imageUrl };
});

/** Removes the caller's profile image from Supabase Storage and clears the references. */
export const deleteProfileImage = onCall(opts, async (req) => {
  const uid = requireUid(req);
  const userRef = db.collection("users").doc(uid);
  const user = await userRef.get();
  const path = user.get("imagePath") as string | undefined;
  if (path && path.startsWith(`${uid}/`)) await supabase().storage.from(BUCKET).remove([path]);
  await userRef.set({ imagePath: FieldValue.delete(), imageUrl: FieldValue.delete() }, { merge: true });
  if (user.get("role") === "teacher") {
    await db.collection("teacherProfiles").doc(uid).set({ imageUrl: FieldValue.delete() }, { merge: true });
  }
  return { ok: true };
});
