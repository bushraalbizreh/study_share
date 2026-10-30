# StudyShare

Collaborative study groups with verified teachers. Flutter (BLoC, Clean Architecture) + Firebase
(Auth, Firestore, Cloud Functions, FCM) + Supabase Storage for profile images. English and Arabic (RTL).

## How it works

1. A **teacher** completes a profile (subjects, price per student for each stage, allowed group size) and publishes future **availability slots**.
2. A **student** browses teachers, picks a slot and creates a **study group** (status `Open`, creator is member #1).
3. Other students **join**. When the group is **full** it becomes `Pending` and the teacher is notified (in-app + push).
4. The teacher **accepts** (`Accepted`, group chat opens) or **rejects** (`Rejected`, slot is released). Members are notified.

Students and teachers see different home screens; the role is chosen once at sign-up and cannot change.

## Architecture

```
lib/
  core/        di · routing (role guards) · theme · localization · storage (Hive) · session · network · utils · widgets
  features/    auth · onboarding · splash · profile · teacher_profile · availability · discovery
               student_home · study_groups · teacher_requests · notifications · group_chat
               each: domain (entities, repository contract, use cases) → data (models, remote source, repository impl)
                     → presentation (BLoC, pages, widgets)
functions/     Firebase Cloud Functions (TypeScript): group lifecycle + Supabase signed upload URLs
firestore.rules · firestore.indexes.json · firebase.json
supabase/migrations/   profile-images bucket
test/          use case, BLoC, state and localization tests
```

Repositories throw typed `Failure`s (`core/error/failures.dart`); BLoCs catch them and emit states. The UI maps
`failure.code` to localized text (`err.<code>` in `core/localization`).

## Security model (important)

| Concern | Where it is enforced |
|---|---|
| Role cannot be changed | Firestore rules: `users` create requires role ∈ {student, teacher}; updates may only touch `name` |
| Capacity, joining, leaving, status changes, slot booking | **Cloud Functions** (Firestore transactions). Clients cannot write `studyGroups` at all |
| Only the assigned teacher decides a request | `decideGroupRequest` re-checks role, assignment and `Pending` status |
| Slots | Teachers create/edit/delete only their own `available` slots; `booked` is set by functions only |
| Chat | Rules allow read/write only when the group is `Accepted` and the user is a member or its teacher |
| Notifications | Created only by functions; users may only flip `read` on their own |
| Images | The app never holds Supabase credentials. A function verifies the Firebase identity and returns a short-lived **signed upload URL**; the service-role key lives in Firebase Secret Manager |

Client-side route guards and validation are UX only.

## Setup

### 1. Flutter
```bash
# in your existing project: replace lib/, test/, pubspec.yaml, analysis_options.yaml with these
flutter pub get
flutter analyze && flutter test
```
`lib/firebase_options.dart` is kept as you had it. The client no longer uses `supabase_flutter`, `firebase_storage` or `shared_preferences`.

Platform configuration you still need to do:
- **Android 13+**: add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`.
- **iOS**: add `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` to `Info.plist`; enable Push Notifications + Background Modes, and upload your APNs key in Firebase.

### 2. Supabase
Run `supabase/migrations/20260101000000_profile_images_bucket.sql` (SQL editor or `supabase db push`). It creates the public `profile-images` bucket (5 MB, JPEG/PNG/WebP) and no client write policies.

### 3. Firebase backend
```bash
cd functions && npm install && cd ..
firebase functions:secrets:set SUPABASE_SERVICE_ROLE_KEY      # service role key, never in the app
echo 'SUPABASE_URL=https://<project-ref>.supabase.co' > functions/.env.<your-project-id>
firebase deploy --only firestore:rules,firestore:indexes,functions
```
Functions default to region `us-central1`. If you change it, use `FirebaseFunctions.instanceFor(region: ...)` in the three
remote sources that call functions (study groups, teacher requests, profile).

### 4. Rotate the key that was hard-coded
The old `main.dart` contained a Supabase publishable key and project URL. It is removed; if the project is public, consider rotating it.

## Data model

`users/{uid}` name, role, imageUrl, imagePath · `users/{uid}/devices/{token}` FCM tokens ·
`teacherProfiles/{uid}` specialization, subjects, biography, prices{elementary,middle,high}, minStudents, maxStudents, isComplete ·
`availabilitySlots/{id}` teacherId, startAt, durationMinutes, status(available|booked), groupId ·
`studyGroups/{id}` creatorId, teacherId, slotId, startAt, subject, gradeLevel, pricePerStudent, capacity, memberIds, memberNames, notes, status(Open|Pending|Accepted|Rejected) ·
`studyGroups/{id}/messages/{id}` senderId, senderName, text, createdAt ·
`notifications/{id}` userId, type(group_full|group_accepted|group_rejected), groupId, subject, read, createdAt.

## Assumptions to confirm

- "min/max students" in the plan is read as the **allowed group-size range** a teacher accepts (min ≥ 2, including the creator).
- Prices are **per student per session**, one price per stage; the currency label is `SAR` / `ر.س` (`currency` key in `core/localization`).
- Profile images use a **public** bucket with unguessable paths. Switch to private + signed read URLs if photos must not be reachable by link.
- Push texts are bilingual (EN · AR) because the server does not know the user's language; in-app texts are localized per device.
- Leaving an `Open` group as its last member deletes the group and frees the slot.
