/// Firestore collection names shared by data sources.
class FirestorePaths {
  static const users = 'users';
  static const teacherProfiles = 'teacherProfiles';
  static const slots = 'availabilitySlots';
  static const groups = 'studyGroups';
  static const messages = 'messages';
  static const notifications = 'notifications';
  static const devices = 'devices';
}

/// Study group lifecycle statuses (exact values required by the spec).
class GroupStatus {
  static const open = 'Open';
  static const pending = 'Pending';
  static const accepted = 'Accepted';
  static const rejected = 'Rejected';
}
