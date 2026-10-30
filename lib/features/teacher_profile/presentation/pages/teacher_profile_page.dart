import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/session/session.dart';
import 'package:app_study_share/core/utils/ui_helpers.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';
import 'package:app_study_share/features/teacher_profile/presentation/bloc/teacher_profile_bloc.dart';
import 'package:app_study_share/features/teacher_profile/presentation/bloc/teacher_profile_event.dart';
import 'package:app_study_share/features/teacher_profile/presentation/bloc/teacher_profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context) => BlocProvider<TeacherProfileBloc>(
    create: (_) => getIt<TeacherProfileBloc>()..add(TeacherProfileRequested(teacherId)),
    child: Scaffold(
      appBar: AppBar(title: Text(context.tr('teacher.title'))),
      body: BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
        builder: (context, state) => switch (state) {
          TeacherProfileLoaded() => _Body(
            profile: state.details.profile,
            slots: state.details.slots,
          ),
          TeacherProfileNotFound() => StateView.empty(
            icon: Icons.person_off_rounded,
            title: context.tr('teacher.notFound'),
          ),
          TeacherProfileError() => StateView.error(
            message: context.errorText(state.code, state.message),
            onAction: () => context.read<TeacherProfileBloc>().add(TeacherProfileRequested(teacherId)),
          ),
          _ => const StateView.loading(),
        },
      ),
    ),
  );
}

class _Body extends StatefulWidget {
  const _Body({required this.profile, required this.slots});

  final TeacherProfile profile;
  final List<AvailabilitySlot> slots;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String? _slotId;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final scheme = Theme.of(context).colorScheme;
    final isStudent = getIt<Session>().isStudent;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: ResponsiveBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(name: p.name, imageUrl: p.imageUrl, radius: 38),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
                            Text(p.specialization, style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (p.subjects.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final s in p.subjects) Chip(label: Text(s))],
                    ),
                  if (p.biography.trim().isNotEmpty) ...[
                    SectionTitle(context.tr('teacher.about')),
                    Text(p.biography, style: const TextStyle(height: 1.6)),
                  ],
                  SectionTitle(context.tr('teacher.prices')),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          for (final l in kLevels)
                            if ((p.prices[l] ?? 0) > 0)
                              InfoRow(context.levelLabel(l), context.priceLabel(p.prices[l]!), emphasis: true),
                          const Divider(height: 20),
                          InfoRow(
                            context.tr('teacher.groupSize'),
                            '${p.minStudents} – ${p.maxStudents}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SectionTitle(context.tr('teacher.slots')),
                  if (widget.slots.isEmpty)
                    StateView.empty(
                      icon: Icons.event_busy_rounded,
                      title: context.tr('teacher.noSlots'),
                      message: context.tr('teacher.noSlotsHint'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in widget.slots)
                          ChoiceChip(
                            label: Text('${context.when(s.startAt)} · ${s.durationMinutes}′'),
                            selected: _slotId == s.id,
                            onSelected: isStudent
                                ? (_) => setState(() => _slotId = _slotId == s.id ? null : s.id)
                                : null,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isStudent)
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: PrimaryButton(
              label: context.tr('teacher.createGroup'),
              icon: Icons.group_add_rounded,
              onPressed: _slotId == null
                  ? null
                  : () => Navigator.of(context).pushNamed(
                      RouteNames.createGroup,
                      arguments: {'teacherId': p.uid, 'slotId': _slotId},
                    ),
            ),
          ),
      ],
    );
  }
}
