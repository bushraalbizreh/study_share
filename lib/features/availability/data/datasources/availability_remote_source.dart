import 'package:app_study_share/core/utils/firestore_paths.dart';
import 'package:app_study_share/features/availability/data/models/availability_slot_model.dart';
import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AvailabilityRemoteSource {
  Future<List<AvailabilitySlot>> getTeacherSlots({required String teacherId});

  Future<List<AvailabilitySlot>> getAvailableSlots({required String teacherId});

  Future<void> createSlot({
    required String teacherId,
    required DateTime startAt,
    required int durationMinutes,
  });

  Future<void> updateSlot({
    required String slotId,
    required DateTime startAt,
    required int durationMinutes,
  });

  Future<void> deleteSlot({required String slotId});
}

class AvailabilityRemoteSourceImpl implements AvailabilityRemoteSource {
  AvailabilityRemoteSourceImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _slots =>
      _db.collection(FirestorePaths.slots);

  List<AvailabilitySlot> _future(QuerySnapshot<Map<String, dynamic>> snap) {
    final now = DateTime.now();
    final list = snap.docs
        .map(AvailabilitySlotModel.fromDoc)
        .where((s) => s.startAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  @override
  Future<List<AvailabilitySlot>> getTeacherSlots({required String teacherId}) async =>
      _future(await _slots.where('teacherId', isEqualTo: teacherId).get());

  @override
  Future<List<AvailabilitySlot>> getAvailableSlots({required String teacherId}) async =>
      _future(
        await _slots
            .where('teacherId', isEqualTo: teacherId)
            .where('status', isEqualTo: 'available')
            .get(),
      );

  @override
  Future<void> createSlot({
    required String teacherId,
    required DateTime startAt,
    required int durationMinutes,
  }) async {
    await _slots.add(
      AvailabilitySlotModel.createMap(
        teacherId: teacherId,
        startAt: startAt,
        durationMinutes: durationMinutes,
      ),
    );
  }

  @override
  Future<void> updateSlot({
    required String slotId,
    required DateTime startAt,
    required int durationMinutes,
  }) => _slots.doc(slotId).update({
    'startAt': Timestamp.fromDate(startAt),
    'durationMinutes': durationMinutes,
  });

  @override
  Future<void> deleteSlot({required String slotId}) => _slots.doc(slotId).delete();
}
