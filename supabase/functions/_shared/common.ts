import { decodeProtectedHeader, importX509, jwtVerify } from "npm:jose@6";
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

// This must match lib/firebase_options.dart and the Firebase Console Project ID.
export const FIREBASE_PROJECT_ID = "project-albaraka-studyshare";
const FIREBASE_CERTS_URL =
  "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function handleError(error: unknown): Response {
  if (error instanceof ApiError) {
    return jsonResponse({ error: error.message, code: error.code }, error.status);
  }
  console.error("Unhandled Edge Function error:", error);
  return jsonResponse({ error: "Internal server error", code: "internal" }, 500);
}

export function createSupabaseAdmin(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) {
    throw new ApiError(
      500,
      "server-config-missing",
      "The Supabase Storage server configuration is missing.",
    );
  }
  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

let cachedCerts: Record<string, string> | null = null;
let certsExpireAt = 0;

async function getFirebaseCerts(): Promise<Record<string, string>> {
  if (cachedCerts && Date.now() < certsExpireAt) return cachedCerts;

  let response: Response;
  try {
    response = await fetch(FIREBASE_CERTS_URL);
  } catch {
    throw new ApiError(503, "auth-verifier-unavailable", "Could not verify the sign-in token.");
  }
  if (!response.ok) {
    throw new ApiError(503, "auth-verifier-unavailable", "Could not verify the sign-in token.");
  }

  const certs = (await response.json()) as Record<string, string>;
  const maxAgeMatch = response.headers.get("cache-control")?.match(/max-age=(\d+)/i);
  const maxAgeSeconds = maxAgeMatch ? Number(maxAgeMatch[1]) : 300;
  cachedCerts = certs;
  certsExpireAt = Date.now() + Math.max(60, maxAgeSeconds) * 1000;
  return certs;
}

/** Validate a Firebase Authentication ID token sent as Authorization: Bearer <token>. */
export async function requireFirebaseUid(request: Request): Promise<string> {
  const authorization = request.headers.get("authorization") ?? "";
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match) throw new ApiError(401, "unauthenticated", "Sign in is required.");

  const token = match[1].trim();
  let header: ReturnType<typeof decodeProtectedHeader>;
  try {
    header = decodeProtectedHeader(token);
  } catch {
    throw new ApiError(401, "unauthenticated", "The sign-in token is invalid.");
  }
  if (header.alg !== "RS256" || typeof header.kid !== "string") {
    throw new ApiError(401, "unauthenticated", "The sign-in token is invalid.");
  }

  const certs = await getFirebaseCerts();
  const certificate = certs[header.kid];
  if (!certificate) {
    // Refresh once in case Google's signing certificates rotated.
    cachedCerts = null;
    const refreshed = await getFirebaseCerts();
    if (!refreshed[header.kid]) {
      throw new ApiError(401, "unauthenticated", "The sign-in token is invalid.");
    }
  }

  const activeCert = (cachedCerts ?? certs)[header.kid];
  if (!activeCert) throw new ApiError(401, "unauthenticated", "The sign-in token is invalid.");
  try {
    const key = await importX509(activeCert, "RS256");
    const { payload } = await jwtVerify(token, key, {
      algorithms: ["RS256"],
      issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
      audience: FIREBASE_PROJECT_ID,
    });
    const now = Math.floor(Date.now() / 1000);
    if (
      typeof payload.sub !== "string" || payload.sub.length === 0 ||
      typeof payload.exp !== "number" ||
      typeof payload.iat !== "number" || payload.iat > now + 60 ||
      typeof payload.auth_time !== "number" || payload.auth_time > now + 60
    ) {
      throw new Error("Missing or invalid Firebase token claims");
    }
    return payload.sub;
  } catch {
    throw new ApiError(401, "unauthenticated", "The sign-in token is invalid or expired.");
  }
}

export function requireOwnImagePath(uid: string, path: unknown): string {
  if (typeof path !== "string") {
    throw new ApiError(400, "invalid-path", "A valid image path is required.");
  }
  const parts = path.split("/");
  const validFilename = /^[0-9a-f-]{36}\.(jpg|png|webp)$/i.test(parts[1] ?? "");
  if (
    parts.length !== 2 || parts[0] !== uid || !validFilename || path.includes("..")
  ) {
    throw new ApiError(403, "invalid-path", "The image path does not belong to this user.");
  }
  return path;
}
