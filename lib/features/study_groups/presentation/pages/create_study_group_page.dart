import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/utils/ui_helpers.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_bloc.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_event.dart';
import 'package:app_study_share/features/study_groups/presentation/bloc/study_groups_state.dart';
import 'package:app_study_share/features/teacher_profile/domain/usecases/get_teacher_profile_usecase.dart';
import 'package:app_study_share/features/teacher_profile/presentation/bloc/teacher_profile_bloc.dart';
import 'package:app_study_share/features/teacher_profile/presentation/bloc/teacher_profile_event.dart';
import 'package:app_study_share/features/teacher_profile/presentation/bloc/teacher_profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateStudyGroupPage extends StatelessWidget {
  const CreateStudyGroupPage({super.key, required this.teacherId, this.slotId});

  final String teacherId;
  final String? slotId;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<TeacherProfileBloc>(
        create: (_) => getIt<TeacherProfileBloc>()..add(TeacherProfileRequested(teacherId)),
      ),
      BlocProvider<StudyGroupsBloc>(create: (_) => getIt<StudyGroupsBloc>()),
    ],
    child: Scaffold(
      appBar: AppBar(title: Text(context.tr('create.title'))),
      body: BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
        builder: (context, state) => switch (state) {
          TeacherProfileLoaded() => _Form(details: state.details, initialSlotId: slotId),
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

class _Form extends StatefulWidget {
  const _Form({required this.details, this.initialSlotId});

  final TeacherProfileDetails details;
  final String? initialSlotId;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _notes = TextEditingController();
  String? _subject;
  String? _slotId;
  String? _level;
  late int _capacity;

  @override
  void initState() {
    super.initState();
    final p = widget.details.profile;
    _subject = p.subjects.isNotEmpty ? p.subjects.first : null;
    _level = p.levels.isNotEmpty ? p.levels.first : null;
    final ids = widget.details.slots.map((s) => s.id);
    _slotId = ids.contains(widget.initialSlotId) ? widget.initialSlotId : null;
    _capacity = p.minStudents.clamp(2, p.maxStudents < 2 ? 2 : p.maxStudents);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final p = widget.details.profile;
    if (_subject == null || _slotId == null || _level == null) {
      showFeedback(context, context.tr('create.incomplete'), error: true);
      return;
    }
    context.read<StudyGroupsBloc>().add(
      StudyGroupCreated(
        teacherId: p.uid,
        subject: _subject!,
        gradeLevel: _level!,
        slotId: _slotId!,
        notes: _notes.text,
        capacity: _capacity,
        minStudents: p.minStudents,
        maxStudents: p.maxStudents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.details.profile;
    final slots = widget.details.slots;
    final scheme = Theme.of(context).colorScheme;
    if (p.subjects.isEmpty || p.levels.isEmpty || slots.isEmpty) {
      return StateView.empty(
        icon: Icons.event_busy_rounded,
        title: context.tr('create.unavailable'),
        message: context.tr('create.unavailableHint'),
      );
    }
    final price = _level == null ? null : p.priceFor(_level!);
    return BlocConsumer<StudyGroupsBloc, StudyGroupsState>(
      listener: (context, state) {
        if (state is StudyGroupActionSucceeded && state.groupId != null) {
          showFeedback(context, context.tr('create.created'));
          Navigator.of(context).pushReplacementNamed(
            RouteNames.groupDetails,
            arguments: {'groupId': state.groupId},
          );
        } else if (state is StudyGroupActionFailed) {
          showFeedback(context, context.errorText(state.code, state.message), error: true);
        }
      },
      builder: (context, state) {
        final busy = state is StudyGroupsLoading;
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(name: p.name, imageUrl: p.imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
                SectionTitle(context.tr('create.subject')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in p.subjects)
                      ChoiceChip(
                        label: Text(s),
                        selected: _subject == s,
                        onSelected: (_) => setState(() => _subject = s),
                      ),
                  ],
                ),
                SectionTitle(context.tr('create.slot')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in slots)
                      ChoiceChip(
                        label: Text('${context.when(s.startAt)} · ${s.durationMinutes}′'),
                        selected: _slotId == s.id,
                        onSelected: (_) => setState(() => _slotId = s.id),
                      ),
                  ],
                ),
                SectionTitle(context.tr('create.level')),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      for (final l in p.levels)
                        ButtonSegment(value: l, label: Text(context.levelLabel(l))),
                    ],
                    selected: {?_level},
                    onSelectionChanged: (v) => setState(() => _level = v.first),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: scheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('create.pricePerStudent'),
                          style: TextStyle(color: scheme.onSecondaryContainer),
                        ),
                        Text(
                          price == null ? '—' : context.priceLabel(price),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SectionTitle(context.tr('create.capacity')),
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: context.tr('action.decrease'),
                      onPressed: _capacity > p.minStudents && _capacity > 2
                          ? () => setState(() => _capacity--)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('$_capacity', style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    IconButton.filledTonal(
                      tooltip: context.tr('action.increase'),
                      onPressed: _capacity < p.maxStudents ? () => setState(() => _capacity++) : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('create.capacityHint', {
                          'min': '${p.minStudents}',
                          'max': '${p.maxStudents}',
                        }),
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SectionTitle(context.tr('create.notes')),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(hintText: context.tr('create.notesHint')),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: context.tr('create.submit'),
                  loading: busy,
                  onPressed: () => _submit(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
