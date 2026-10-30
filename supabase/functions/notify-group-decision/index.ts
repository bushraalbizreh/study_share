
import { importPKCS8, SignJWT } from "npm:jose@6";

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

const OAUTH_URL = "https://oauth2.googleapis.com/token";

const FIRESTORE_SCOPE =
  "https://www.googleapis.com/auth/datastore";

const FCM_SCOPE =
  "https://www.googleapis.com/auth/firebase.messaging";

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type GoogleTokenCache = {
  token: string;
  expiresAt: number;
};

let cachedToken: GoogleTokenCache | null = null;

async function getGoogleAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60000) {
    return cachedToken.token;
  }

  const encoded = Deno.env.get(
    "FIREBASE_SERVICE_ACCOUNT_JSON_B64",
  );

  if (!encoded) {
    throw new ApiError(
      500,
      "service-account-missing",
      "Firebase service account is not configured.",
    );
  }

  let account: ServiceAccount;

  try {
    account = JSON.parse(
      new TextDecoder().decode(
        Uint8Array.from(
          atob(encoded),
          (char) => char.charCodeAt(0),
        ),
      ),
    );
  } catch {
    throw new ApiError(
      500,
      "invalid-service-account",
      "Firebase service account configuration is invalid.",
    );
  }

  if (
    account.project_id !== FIREBASE_PROJECT_ID ||
    !account.client_email ||
    !account.private_key
  ) {
    throw new ApiError(
      500,
      "invalid-service-account",
      "Firebase service account details are invalid.",
    );
  }

  const privateKey = await importPKCS8(
    account.private_key,
    "RS256",
  );

  const now = Math.floor(Date.now() / 1000);

  const assertion = await new SignJWT({
    scope: `${FIRESTORE_SCOPE} ${FCM_SCOPE}`,
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(account.client_email)
    .setAudience(OAUTH_URL)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const response = await fetch(OAUTH_URL, {
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
      "[notify-group-decision] Google authentication failed:",
      result.error ?? response.status,
    );

    throw new ApiError(
      502,
      "google-auth-failed",
      "Google authentication failed.",
    );
  }

  cachedToken = {
    token: result.access_token,
    expiresAt: Date.now() +
      Number(result.expires_in ?? 3600) * 1000,
  };

  return cachedToken.token;
}

function documentUrl(...parts: string[]): string {
  return `${FIRESTORE_ROOT}/${parts
    .map(encodeURIComponent)
    .join("/")}`;
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
    throw new ApiError(
      response.status,
      "firestore-request-failed",
      result.error?.message ?? "Firestore request failed.",
    );
  }

  return result;
}

function getStringField(
  fields: Record<string, any>,
  name: string,
): string | null {
  const value = fields[name]?.stringValue;

  return typeof value === "string" ? value : null;
}

async function makeNotificationId(
  groupId: string,
  studentId: string,
  type: string,
): Promise<string> {
  const input = `${groupId}:${studentId}:${type}`;

  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(input),
  );

  const hex = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");

  return `group_decision_${hex}`;
}

async function sendPushToStudent(
  accessToken: string,
  studentId: string,
  groupId: string,
  subject: string,
  type: string,
): Promise<{ sent: number; failed: number }> {
  const devicesUrl =
    `${documentUrl("users", studentId, "devices")}?pageSize=100`;

  const devicesResult = await firestoreRequest(
    devicesUrl,
    accessToken,
  );

  const devices = Array.isArray(devicesResult.documents)
    ? devicesResult.documents
    : [];

  const tokens = [
    ...new Set(
      devices
        .map((device: any) =>
          device.fields?.token?.stringValue
        )
        .filter((token: unknown): token is string =>
          typeof token === "string" && token.length > 0
        ),
    ),
  ];

  let sent = 0;
  let failed = 0;

  const accepted = type === "group_accepted";

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
                body: accepted
                  ? `Your ${subject} study group has been accepted.`
                  : `Your ${subject} study group has been rejected.`,
              },
              data: {
                type,
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
          "[notify-group-decision] FCM failed:",
          response.status,
          errorText.slice(0, 400),
        );
      }
    } catch (error) {
      failed++;

      console.error(
        "[notify-group-decision] FCM request error:",
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
    // 1. Verify Firebase user.
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
    const decision = body.decision;

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

    if (
      decision !== "accepted" &&
      decision !== "rejected"
    ) {
      throw new ApiError(
        400,
        "invalid-decision",
        "Decision must be accepted or rejected.",
      );
    }

    const accessToken = await getGoogleAccessToken();

    // 2. Read the group.
    const group = await firestoreRequest(
      documentUrl("studyGroups", groupId),
      accessToken,
    );

    const fields = group.fields ?? {};

    const teacherId = getStringField(fields, "teacherId");
    const status = (
      getStringField(fields, "status") ?? ""
    ).toLowerCase();

    const subject =
      getStringField(fields, "subject") ?? "Study group";

    // 3. Ensure only the group teacher can notify students.
    if (teacherId !== uid) {
      throw new ApiError(
        403,
        "not-group-teacher",
        "Only this group's teacher can make this decision.",
      );
    }

    // 4. Ensure the saved decision matches the request.
    if (status !== decision) {
      throw new ApiError(
        409,
        "decision-not-saved",
        "The group decision has not been saved yet.",
      );
    }

    // 5. Read all student members.
    const rawMembers = fields.memberIds?.arrayValue?.values ?? [];

    const studentIds = [
      ...new Set(
        rawMembers
          .map((member: any) => member.stringValue)
          .filter((id: unknown): id is string =>
            typeof id === "string" && id.length > 0
          ),
      ),
    ];

    if (studentIds.length === 0) {
      throw new ApiError(
        409,
        "no-group-members",
        "This group has no student members.",
      );
    }

    const notificationType = decision === "accepted"
      ? "group_accepted"
      : "group_rejected";

    let notificationsCreated = 0;
    let alreadyExisted = 0;
    let pushSent = 0;
    let pushFailed = 0;

    // 6. Create one notification for each student.
    for (const studentId of studentIds) {
      const notificationId = await makeNotificationId(
        groupId,
        studentId,
        notificationType,
      );

      const createUrl =
        `${documentUrl("notifications")}` +
        `?documentId=${encodeURIComponent(notificationId)}`;

      let created = false;

      try {
        await firestoreRequest(
          createUrl,
          accessToken,
          {
            method: "POST",
            body: JSON.stringify({
              fields: {
                userId: { stringValue: studentId },
                type: { stringValue: notificationType },
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

        notificationsCreated++;
        created = true;
      } catch (error) {
        if (
          error instanceof ApiError &&
          error.status === 409
        ) {
          alreadyExisted++;
        } else {
          throw error;
        }
      }

      // Do not send duplicate pushes for existing notifications.
      if (!created) continue;

      // 7. Send push to this student's registered devices.
      const pushResult = await sendPushToStudent(
        accessToken,
        studentId,
        groupId,
        subject,
        notificationType,
      );

      pushSent += pushResult.sent;
      pushFailed += pushResult.failed;
    }

    return jsonResponse({
      ok: true,
      decision,
      notificationType,
      students: studentIds.length,
      notificationsCreated,
      alreadyExisted,
      pushSent,
      pushFailed,
    });
  } catch (error) {
    console.error("[notify-group-decision] Error:", error);
    return handleError(error);
  }
});
