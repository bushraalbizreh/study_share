import {
  createSupabaseAdmin,
  corsHeaders,
  handleError,
  jsonResponse,
  requireFirebaseUid,
  requireOwnImagePath,
  ApiError,
} from "../_shared/common.ts";

const BUCKET = "profile-images";

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
    const path = requireOwnImagePath(uid, body.path);
    const { error } = await createSupabaseAdmin().storage.from(BUCKET).remove([path]);
    if (error) {
      console.error("Could not delete image:", error);
      throw new ApiError(500, "delete-failed", "Could not delete the stored image.");
    }
    return jsonResponse({ ok: true });
  } catch (error) {
    return handleError(error);
  }
});
