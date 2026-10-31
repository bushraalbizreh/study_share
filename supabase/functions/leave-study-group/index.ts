
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

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

let cachedToken: { token: string; expiresAt: number } | null = null;

async function getGoogleAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60000) {
    return cachedToken.token;
  }

  const encoded = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON_B64");

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
        Uint8Array.from(atob(encoded), (c) => c.charCodeAt(0)),
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

  const privateKey = await importPKCS8(account.private_key, "RS256");
  const now = Math.floor(Date.now() / 1000);

  const assertion = await new SignJWT({
    scope: FIRESTORE_SCOPE,
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
    console.error("[leave-study-group] Google authentication failed");

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

async function getDocument(
  path: string[],
  accessToken: string,
): Promise<any | null> {
  const response = await fetch(documentUrl(...path), {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  const text = await response.text();

  let result: any = {};

  try {
    result = text ? JSON.parse(text) : {};
  } catch {
    result = {};
  }

  if (response.status === 404) return null;

  if (!response.ok) {
    console.error("[leave-study-group] Firestore read failed", {
      status: response.status,
      path,
      error: result.error?.message,
    });

    throw new ApiError(
      502,
      "firestore-read-failed",
      "Could not read group data.",
    );
  }

  return result;
}

function stringField(
  fields: Record<string, any>,
  name: string,
): string | null {
  const value = fields[name]?.stringValue;
  return typeof value === "string" ? value : null;
}

function numberField(
  fields: Record<string, any>,
  name: string,
): number | null {
  const value = fields[name];

  if (value?.integerValue !== undefined) {
    return Number(value.integerValue);
  }

  if (value?.doubleValue !== undefined) {
    return Number(value.doubleValue);
  }

  return null;
}

async function commitGroupUpdate(
  accessToken: string,
  group: any,
  members: string[],
  memberNames: Record<string, any>,
  status: string,
): Promise<void> {
  if (!group.name || !group.updateTime) {
    throw new ApiError(
      500,
      "invalid-group-document",
      "Group document is missing update information.",
    );
  }

  const response = await fetch(`${FIRESTORE_ROOT}:commit`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      writes: [
        {
          update: {
            name: group.name,
            fields: {
              memberIds: {
                arrayValue: {
                  values: members.map((id) => ({
                    stringValue: id,
                  })),
                },
              },
              memberNames: {
                mapValue: {
                  fields: memberNames,
                },
              },
              status: {
                stringValue: status,
              },
              updatedAt: {
                timestampValue: new Date().toISOString(),
              },
            },
          },
          updateMask: {
            fieldPaths: [
              "memberIds",
              "memberNames",
              "status",
              "updatedAt",
            ],
          },
          currentDocument: {
            updateTime: group.updateTime,
          },
        },
      ],
    }),
  });

  const text = await response.text();

  let result: any = {};

  try {
    result = text ? JSON.parse(text) : {};
  } catch {
    result = {};
  }

  if (!response.ok) {
    console.error("[leave-study-group] Firestore commit failed", {
      status: response.status,
      error: result.error?.message,
    });

    if (response.status === 400 || response.status === 409) {
      throw new ApiError(
        409,
        "group-changed-retry",
        "The group changed while leaving. Please try again.",
      );
    }

    throw new ApiError(
      502,
      "group-update-failed",
      "Could not update group membership.",
    );
  }
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

    // 2. Validate request body.
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

    // 3. Get Google credentials.
    const accessToken = await getGoogleAccessToken();

    // 4. Read the user and group.
    const [user, group] = await Promise.all([
      getDocument(["users", uid], accessToken),
      getDocument(["studyGroups", groupId], accessToken),
    ]);

    if (!user || user.fields?.role?.stringValue !== "student") {
      throw new ApiError(
        403,
        "student-only",
        "Only student accounts can leave a group.",
      );
    }

    if (!group) {
      throw new ApiError(
        404,
        "group-not-found",
        "Study group not found.",
      );
    }

    const fields = group.fields ?? {};

    // 5. Read membership.
    const rawMembers = fields.memberIds?.arrayValue?.values;

    if (!Array.isArray(rawMembers)) {
      throw new ApiError(
        500,
        "invalid-group-members",
        "Group membership data is invalid.",
      );
    }

    const members: string[] = [];

    for (const item of rawMembers) {
      if (typeof item.stringValue !== "string") {
        throw new ApiError(
          500,
          "invalid-group-members",
          "Group membership data is invalid.",
        );
      }

      members.push(item.stringValue);
    }

    if (!members.includes(uid)) {
      throw new ApiError(
        409,
        "not-a-member",
        "You are not a member of this group.",
      );
    }

    // 6. Read member names and remove the current user.
    const rawNames = fields.memberNames?.mapValue?.fields ?? {};

    if (
      typeof rawNames !== "object" ||
      rawNames === null ||
      Array.isArray(rawNames)
    ) {
      throw new ApiError(
        500,
        "invalid-member-names",
        "Group member names are invalid.",
      );
    }

    const updatedMembers = members.filter((id) => id !== uid);
    const updatedNames = { ...rawNames };

    delete updatedNames[uid];

    const currentStatus = stringField(fields, "status") ?? "Open";
    const capacity = numberField(fields, "capacity");

    let updatedStatus = currentStatus;

    // A Pending group becomes Open again when a member leaves.
    // An empty Accepted group also becomes Open so other students
    // can join it again.
    if (
      (currentStatus === "Pending" &&
        capacity !== null &&
        updatedMembers.length < capacity) ||
      (currentStatus === "Accepted" &&
        updatedMembers.length === 0)
    ) {
      updatedStatus = "Open";
    }

    // 7. Update membership without deleting the group or its messages.
    await commitGroupUpdate(
      accessToken,
      group,
      updatedMembers,
      updatedNames,
      updatedStatus,
    );

    console.log("[leave-study-group] Member left successfully", {
      groupId,
      uid,
      remainingMembers: updatedMembers.length,
      status: updatedStatus,
    });

    return jsonResponse({
      ok: true,
      groupId,
      remainingMembers: updatedMembers.length,
      status: updatedStatus,
    });
  } catch (error) {
    console.error("[leave-study-group] Error:", error);
    return handleError(error);
  }
});
