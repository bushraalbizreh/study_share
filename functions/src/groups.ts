import { onCall } from "firebase-functions/v2/https";
import {
  db, fail, requireUid, asString, roleOf, notificationDoc, pushToUsers, FieldValue, Timestamp, LEVELS, Level,
} from "./common";

const opts = { cors: true };

/** Student creates a group from a teacher's available slot (atomic: group + slot booking). */
export const createStudyGroup = onCall(opts, async (req) => {
  const uid = requireUid(req);
  const teacherId = asString(req.data?.teacherId, "teacher", 128);
  const slotId = asString(req.data?.slotId, "slot", 128);
  const subject = asString(req.data?.subject, "subject", 80).trim();
  const notes = asString(req.data?.notes ?? "", "notes", 300).trim();
  const level = req.data?.gradeLevel as Level;
  const capacity = req.data?.capacity;
  if (!LEVELS.includes(level)) fail("invalid-argument", "invalid-level", "Invalid level.");
  if (!Number.isInteger(capacity)) fail("invalid-argument", "invalid-capacity", "Invalid capacity.");

  const groupRef = db.collection("studyGroups").doc();
  await db.runTransaction(async (tx) => {
    const studentSnap = await tx.get(db.collection("users").doc(uid));
    if (studentSnap.get("role") !== "student") fail("permission-denied", "student-only", "Students only.");

    const [teacherUser, profile, slot] = await Promise.all([
      tx.get(db.collection("users").doc(teacherId)),
      tx.get(db.collection("teacherProfiles").doc(teacherId)),
      tx.get(db.collection("availabilitySlots").doc(slotId)),
    ]);
    if (teacherUser.get("role") !== "teacher" || !profile.exists || profile.get("isComplete") !== true) {
      fail("not-found", "teacher-not-found", "Teacher not available.");
    }
    const subjects: string[] = profile.get("subjects") ?? [];
    if (!subjects.includes(subject)) fail("invalid-argument", "invalid-subject", "Subject not offered.");
    const price = Number(profile.get(`prices.${level}`) ?? 0);
    if (!(price > 0)) fail("invalid-argument", "invalid-level", "Level not offered.");
    const min = Math.max(2, Number(profile.get("minStudents") ?? 2));
    const max = Number(profile.get("maxStudents") ?? 6);
    if (capacity < min || capacity > max) fail("invalid-argument", "invalid-capacity", "Capacity out of range.");

    if (!slot.exists || slot.get("teacherId") !== teacherId) fail("not-found", "slot-not-found", "Slot not found.");
    const startAt = slot.get("startAt") as Timestamp;
    if (slot.get("status") !== "available" || startAt.toMillis() <= Date.now()) {
      fail("failed-precondition", "slot-unavailable", "Slot unavailable.");
    }

    const name = String(studentSnap.get("name") ?? "");
    tx.set(groupRef, {
      creatorId: uid,
      teacherId,
      teacherName: String(teacherUser.get("name") ?? profile.get("name") ?? ""),
      slotId,
      startAt,
      durationMinutes: slot.get("durationMinutes"),
      subject,
      gradeLevel: level,
      pricePerStudent: price,
      capacity,
      memberIds: [uid],
      memberNames: { [uid]: name },
      notes,
      status: "Open",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(slot.ref, { status: "booked", groupId: groupRef.id });
  });
  return { groupId: groupRef.id };
});

/** Student joins an Open group. When it fills, status becomes Pending and the teacher is notified. */
export const joinStudyGroup = onCall(opts, async (req) => {
  const uid = requireUid(req);
  const groupId = asString(req.data?.groupId, "group", 128);
  const ref = db.collection("studyGroups").doc(groupId);

  const outcome = await db.runTransaction(async (tx) => {
    const [user, snap] = await Promise.all([tx.get(db.collection("users").doc(uid)), tx.get(ref)]);
    if (user.get("role") !== "student") fail("permission-denied", "student-only", "Students only.");
    if (!snap.exists) fail("not-found", "group-not-found", "Group not found.");
    const members: string[] = snap.get("memberIds") ?? [];
    if (snap.get("status") !== "Open") fail("failed-precondition", "group-not-open", "Group is not open.");
    if (members.includes(uid)) fail("already-exists", "already-member", "Already a member.");
    const capacity = Number(snap.get("capacity"));
    if (members.length >= capacity) fail("failed-precondition", "group-full", "Group is full.");

    const full = members.length + 1 === capacity;
    tx.update(ref, {
      memberIds: FieldValue.arrayUnion(uid),
      [`memberNames.${uid}`]: String(user.get("name") ?? ""),
      ...(full ? { status: "Pending" } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
    const teacherId = String(snap.get("teacherId"));
    const subject = String(snap.get("subject"));
    if (full) tx.set(db.collection("notifications").doc(), notificationDoc(teacherId, "group_full", groupId, subject));
    return { full, teacherId, subject };
  });

  if (outcome.full) await pushToUsers([outcome.teacherId], "group_full", groupId, outcome.subject);
  return { status: outcome.full ? "Pending" : "Open" };
});

/** Student leaves an Open group. An emptied group is removed and its slot released. */
export const leaveStudyGroup = onCall(opts, async (req) => {
  const uid = requireUid(req);
  const groupId = asString(req.data?.groupId, "group", 128);
  const ref = db.collection("studyGroups").doc(groupId);

  await db.runTransaction(async (tx) => {
    const [user, snap] = await Promise.all([tx.get(db.collection("users").doc(uid)), tx.get(ref)]);
    if (user.get("role") !== "student") fail("permission-denied", "student-only", "Students only.");
    if (!snap.exists) fail("not-found", "group-not-found", "Group not found.");
    if (snap.get("status") !== "Open") fail("failed-precondition", "group-not-open", "Group is not open.");
    const members: string[] = snap.get("memberIds") ?? [];
    if (!members.includes(uid)) fail("failed-precondition", "not-member", "Not a member.");

    if (members.length === 1) {
      tx.delete(ref);
      tx.update(db.collection("availabilitySlots").doc(String(snap.get("slotId"))), {
        status: "available",
        groupId: null,
      });
    } else {
      tx.update(ref, {
        memberIds: FieldValue.arrayRemove(uid),
        [`memberNames.${uid}`]: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
  return { ok: true };
});

/** Assigned teacher accepts or rejects a Pending group. Rejecting releases the slot. */
export const decideGroupRequest = onCall(opts, async (req) => {
  const uid = requireUid(req);
  const groupId = asString(req.data?.groupId, "group", 128);
  const decision = req.data?.decision;
  if (decision !== "accept" && decision !== "reject") fail("invalid-argument", "invalid-decision", "Invalid decision.");
  const ref = db.collection("studyGroups").doc(groupId);

  const result = await db.runTransaction(async (tx) => {
    const [teacher, snap] = await Promise.all([roleOf(uid), tx.get(ref)]);
    if (teacher?.role !== "teacher") fail("permission-denied", "teacher-only", "Teachers only.");
    if (!snap.exists) fail("not-found", "group-not-found", "Group not found.");
    if (snap.get("teacherId") !== uid) fail("permission-denied", "not-assigned-teacher", "Not your request.");
    if (snap.get("status") !== "Pending") fail("failed-precondition", "not-pending", "Already decided.");

    const accept = decision === "accept";
    const members: string[] = snap.get("memberIds") ?? [];
    const subject = String(snap.get("subject"));
    const type = accept ? "group_accepted" : "group_rejected";

    tx.update(ref, { status: accept ? "Accepted" : "Rejected", updatedAt: FieldValue.serverTimestamp() });
    if (!accept) {
      tx.update(db.collection("availabilitySlots").doc(String(snap.get("slotId"))), {
        status: "available",
        groupId: null,
      });
    }
    for (const m of members) tx.set(db.collection("notifications").doc(), notificationDoc(m, type, groupId, subject));
    return { members, subject, type };
  });

  await pushToUsers(result.members, result.type, groupId, result.subject);
  return { status: decision === "accept" ? "Accepted" : "Rejected" };
});
