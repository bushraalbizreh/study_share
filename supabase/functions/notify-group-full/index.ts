
import {
  ApiError,
  corsHeaders,
  handleError,
  jsonResponse,
  requireFirebaseUid,
  FIREBASE_PROJECT_ID,
} from "../_shared/common.ts";

const FIRESTORE_ROOT =
  `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;

const OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const FIRESTORE_SCOPE = "https://www.googleapis.com/auth/datastore";

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

let cachedAccessToken: {
  token: string;
  expiresAt: number;
} | null = null;

function base64Url(bytes: Uint8Array): string {
  let binary = "";

  for (let i = 0; i < bytes.length; i += 0x8000) {
    binary += String.fromCharCode(
      ...bytes.subarray(i, i + 0x8000),
    );
  }

  return btoa(binary)
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function encodeJwtPart(value: unknown): string {
  return base64Url(
    new TextEncoder().encode(JSON.stringify(value)),
  );
}

function firestoreUrl(...parts: string[]): string {
  return `${FIRESTORE_ROOT}/${parts
    .map(encodeURIComponent)
    .join("/")}`;
}

function stringField(
  fields: Record<string, any>,
  name: string,
): string | null {
  const value = fields[name]?.stringValue;
  return typeof value === "string" ? value : null;
}

async function getServiceAccount(): Promise<ServiceAccount> {
  const encoded = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON_B64");

  if (!encoded) {
    throw new ApiError(
      500,
      "firebase-service-account-missing",
      "Firebase service account configuration is missing.",
    );
  }

  try {
    const binary = atob(encoded.replace(/\s/g, ""));
    const bytes = Uint8Array.from(
      binary,
      (character) => character.charCodeAt(0),
    );

    const account = JSON.parse(
      new TextDecoder().decode(bytes),
    ) as ServiceAccount;

    if (
      account.project_id !== FIREBASE_PROJECT_ID ||
      !account.client_email ||
      !account.private_key
    ) {
      throw new Error("Invalid service account fields.");
    }

    return account;
  } catch {
    throw new ApiError(
      500,
      "invalid-firebase-service-account",
      "Firebase service account configuration is invalid.",
    );
  }
}

async function getGoogleAccessToken(): Promise<string> {
  if (
    cachedAccessToken &&
    cachedAccessToken.expiresAt > Date.now() + 60_000
  ) {
    return cachedAccessToken.token;
  }

  const account = await getServiceAccount();

  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const claims = {
    iss: account.client_email,
    scope: `${FIRESTORE_SCOPE} ${FCM_SCOPE}`,
    aud: OAUTH_TOKEN_URL,
    iat: now,
    exp: now + 3600,
  };

  const unsignedJwt =
    `${encodeJwtPart(header)}.${encodeJwtPart(claims)}`;

  const pem = account.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");

  const keyBytes = Uint8Array.from(
    atob(pem),
    (character) => character.charCodeAt(0),
  );

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(unsignedJwt),
  );

  const assertion =
    `${unsignedJwt}.${base64Url(new Uint8Array(signature))}`;

  const response = await fetch(OAUTH_TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type:
        "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  const result = await response.json();

  if (!response.ok || !result.access_token) {
    console.error(
      "[notify-group-full] Google OAuth failed:",
      result.error ?? response.status,
    );

    throw new ApiError(
      502,
      "google-auth-failed",
      "Could not authenticate with Google services.",
    );
  }

  cachedAccessToken = {
    token: result.access_token,
    expiresAt: Date.now() +
      Number(result.expires_in ?? 3600) * 1000,
  };

  return result.access_token as string;
}

async function firestoreRequest(
  url: string,
  accessToken: string,
  options: RequestInit = {},
): Promise<any> {
  const response = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      ...(options.headers as Record<string, string> ?? {}),
    },
  });

  const text = await response.text();

  let result: any = {};

  try {
    result = text ? JSON.parse(text) : {};
  } catch {
    result = {};
  }

  if (!response.ok) {
    const message =
      result.error?.message ?? "Firestore request failed.";

    throw new ApiError(
      response.status,
      "firestore-request-failed",
      message,
    );
  }

  return result;
}

async function makeNotificationId(
  groupId: string,
  teacherId: string,
): Promise<string> {
  const input = `group_full:${groupId}:${teacherId}`;

  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(input),
  );

  const hex = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");

  return `group_full_${hex}`;
}

async function sendPushNotifications(
  accessToken: string,
  teacherId: string,
  groupId: string,
  subject: string,
): Promise<{ sent: number; failed: number }> {
  const devicesUrl = `${firestoreUrl(
    "users",
    teacherId,
    "devices",
  )}?pageSize=100`;

  const result = await firestoreRequest(
    devicesUrl,
    accessToken,
  );

  const documents = Array.isArray(result.documents)
    ? result.documents
    : [];

  const tokens = documents
    .map((document: any) => document.fields?.token?.stringValue)
    .filter((token: unknown): token is string =>
      typeof token === "string" && token.length > 0
    );

  let sent = 0;
  let failed = 0;

  for (const token of tokens) {
    try {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title: "StudyShare",
                body: `Your ${subject} study group is full and is waiting for your review.`,
              },
              data: {
                type: "group_full",
                groupId,
                subject,
              },
              android: {
                priority: "HIGH",
                notification: {
                  channel_id: "studyshare_notifications",
                },
              },
            },
          }),
        },
      );

      if (response.ok) {
        sent++;
      } else {
        failed++;

        const errorText = await response.text();

        console.error(
          "[notify-group-full] FCM send failed:",
          response.status,
          errorText.slice(0, 500),
        );
      }
    } catch (error) {
      failed++;
      console.error(
        "[notify-group-full] FCM request failed:",
        error,
      );
    }
  }

  return { sent, failed };
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse(
      { error: "Method not allowed" },
      405,
    );
  }

  try {
    // Authenticate the Firebase user.
    const uid = await requireFirebaseUid(request);

    let body: Record<string, unknown>;

    try {
      body = await request.json();
    } catch {
      throw new ApiError(
        400,
        "invalid-argument",
        "A JSON request body is required.",
      );
    }

    const groupId = body.groupId;

    if (
      typeof groupId !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(groupId)
    ) {
      throw new ApiError(
        400,
        "invalid-group-id",
        "A valid group ID is required.",
      );
    }

    const accessToken = await getGoogleAccessToken();

    // Read the group from Firestore.
    const group = await firestoreRequest(
      firestoreUrl("studyGroups", groupId),
      accessToken,
    );

    const fields = group.fields ?? {};

    const teacherId = stringField(fields, "teacherId");
    const subject =
      stringField(fields, "subject") ?? "Study group";
    const status =
      (stringField(fields, "status") ?? "").toLowerCase();

    const memberValues =
      fields.memberIds?.arrayValue?.values ?? [];

    const memberIds = memberValues
      .map((value: any) => value.stringValue)
      .filter((value: unknown): value is string =>
        typeof value === "string"
      );

    const capacity = Number(
      fields.capacity?.integerValue ??
      fields.capacity?.doubleValue,
    );

    // The caller must be a member of this group.
    if (!memberIds.includes(uid)) {
      throw new ApiError(
        403,
        "not-group-member",
        "You are not a member of this group.",
      );
    }

    if (!teacherId) {
      throw new ApiError(
        500,
        "teacher-id-missing",
        "The group does not have a valid teacher ID.",
      );
    }

    // Confirm that the group is actually full and Pending.
    if (
      status !== "pending" ||
      !Number.isSafeInteger(capacity) ||
      capacity <= 0 ||
      memberIds.length < capacity
    ) {
      throw new ApiError(
        409,
        "group-not-ready",
        "The group is not full and Pending.",
      );
    }

    // Create one notification per group for the teacher.
    const notificationId = await makeNotificationId(
      groupId,
      teacherId,
    );

    const notificationUrl =
      `${firestoreUrl("notifications")}` +
      `?documentId=${encodeURIComponent(notificationId)}`;

    try {
      await firestoreRequest(
        notificationUrl,
        accessToken,
        {
          method: "POST",
          body: JSON.stringify({
            fields: {
              userId: { stringValue: teacherId },
              type: { stringValue: "group_full" },
              groupId: { stringValue: groupId },
              subject: { stringValue: subject },
              read: { booleanValue: false },
              createdAt: {
                timestampValue: new Date().toISOString(),
              },
            },
          }),
        },
      );
    } catch (error) {
      // Prevent duplicate notification documents.
      if (error instanceof ApiError && error.status === 409) {
        return jsonResponse({
          ok: true,
          alreadyExists: true,
          pushSent: 0,
        });
      }

      throw error;
    }

    // Send push notifications to the teacher's registered devices.
    const pushResult = await sendPushNotifications(
      accessToken,
      teacherId,
      groupId,
      subject,
    );

    return jsonResponse({
      ok: true,
      notificationCreated: true,
      pushSent: pushResult.sent,
      pushFailed: pushResult.failed,
    });
  } catch (error) {
    console.error("[notify-group-full] Error:", error);
    return handleError(error);
  }
});
