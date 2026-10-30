import {
  ApiError,
  createSupabaseAdmin,
  corsHeaders,
  handleError,
  jsonResponse,
  requireFirebaseUid,
  requireOwnImagePath,
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
    const parts = path.split("/");
    const storage = createSupabaseAdmin().storage.from(BUCKET);
    const { data: files, error: listError } = await storage.list(uid, {
      search: parts[1],
      limit: 100,
    });
    if (listError || !files?.some((file) => file.name === parts[1])) {
      throw new ApiError(404, "upload-missing", "The uploaded image could not be found.");
    }

    const imageUrl = storage.getPublicUrl(path).data.publicUrl;
    // Firestore image metadata is updated by the authenticated Flutter client,
    // because this is a Supabase function and does not use Firebase Admin.
    return jsonResponse({ imageUrl, path });
  } catch (error) {
    return handleError(error);
  }
});
