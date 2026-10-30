import {
  ApiError,
  createSupabaseAdmin,
  corsHeaders,
  handleError,
  jsonResponse,
  requireFirebaseUid,
} from "../_shared/common.ts";

const BUCKET = "profile-images";
const MAX_BYTES = 5 * 1024 * 1024;
const EXT_BY_CONTENT_TYPE: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  try {
    const uid = await requireFirebaseUid(request);
    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch {
      throw new ApiError(400, "invalid-argument", "A JSON request body is required.");
    }

    const contentType = body.contentType;
    const size = Number(body.size);
    if (typeof contentType !== "string" || !EXT_BY_CONTENT_TYPE[contentType]) {
      throw new ApiError(400, "invalid-content-type", "Use JPEG, PNG, or WebP images.");
    }
    if (!Number.isFinite(size) || size <= 0 || size > MAX_BYTES) {
      throw new ApiError(400, "image-too-large", "Images must be between 1 byte and 5 MB.");
    }

    const path = `${uid}/${crypto.randomUUID()}.${EXT_BY_CONTENT_TYPE[contentType]}`;
    const { data, error } = await createSupabaseAdmin()
      .storage.from(BUCKET).createSignedUploadUrl(path);
    if (error || !data?.signedUrl) {
      console.error("Could not create signed upload URL:", error);
      throw new ApiError(500, "upload-missing", "Could not prepare the image upload.");
    }

    return jsonResponse({ signedUrl: data.signedUrl, path });
  } catch (error) {
    return handleError(error);
  }
});
