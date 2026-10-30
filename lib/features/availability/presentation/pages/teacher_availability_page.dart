import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/theme/app_theme.dart';
import 'package:app_study_share/core/utils/formatters.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/availability/domain/entities/availability_slot.dart';
import 'package:app_study_share/features/availability/presentation/bloc/availability_bloc.dart';
import 'package:app_study_share/features/availability/presentation/bloc/availability_event.dart';
import 'package:app_study_share/features/availability/presentation/bloc/availability_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherAvailabilityPage extends StatelessWidget {
  const TeacherAvailabilityPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<AvailabilityBloc>(
    create: (_) => getIt<AvailabilityBloc>()..add(const AvailabilityRequested()),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _add(BuildContext context) async {
    final bloc = context.read<AvailabilityBloc>();
    final result = await showModalBottomSheet<(DateTime, int)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddSlotSheet(),
    );
    if (result != null) {
      bloc.add(AvailabilitySlotCreated(startAt: result.$1, durationMinutes: result.$2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('availability.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('availability.add')),
      ),
      body: BlocConsumer<AvailabilityBloc, AvailabilityState>(
        listenWhen: (_, c) => c is AvailabilityActionDone || c is AvailabilityActionFailed,
        listener: (context, state) {
          if (state is AvailabilityActionDone) {
            showFeedback(context, context.tr('availability.done.${state.action}'));
          } else if (state is AvailabilityActionFailed) {
            showFeedback(context, context.errorText(state.code, state.message), error: true);
          }
        },
        builder: (context, state) {
          if (state is AvailabilityError) {
            return StateView.error(
              message: context.errorText(state.code, state.message),
              onAction: () => context.read<AvailabilityBloc>().add(const AvailabilityRequested()),
            );
          }
          if (state is! AvailabilityLoaded) return const StateView.loading();
          return RefreshIndicator(
            onRefresh: () async => context.read<AvailabilityBloc>().add(const AvailabilityRequested()),
            child: state.slots.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      StateView.empty(
                        icon: Icons.event_available_rounded,
                        title: context.tr('availability.empty'),
                        message: context.tr('availability.emptyHint'),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                    itemCount: state.slots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _SlotTile(slot: state.slots[i]),
                  ),
          );
        },
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot});

  final AvailabilitySlot slot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StatusColors>()!;
    final (bg, fg) = colors.of(slot.isAvailable ? 'Accepted' : 'Pending');
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Formatters.dayLabel(context, slot.startAt), style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${Formatters.timeLabel(context, slot.startAt)} – ${Formatters.timeLabel(context, slot.endAt)}',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
              child: Text(
                context.tr(slot.isAvailable ? 'slot.available' : 'slot.booked'),
                style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            if (slot.isAvailable)
              IconButton(
                tooltip: context.tr('action.delete'),
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  final bloc = context.read<AvailabilityBloc>();
                  final ok = await confirmDialog(
                    context,
                    title: context.tr('availability.deleteTitle'),
                    message: context.tr('availability.deleteConfirm'),
                    confirmLabel: context.tr('action.delete'),
                  );
                  if (ok) bloc.add(AvailabilitySlotDeleted(slot.id));
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AddSlotSheet extends StatefulWidget {
  const _AddSlotSheet();

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  DateTime? _date;
  TimeOfDay? _time;
  int _duration = 60;

  DateTime? get _start => (_date == null || _time == null)
      ? null
      : DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

  @override
  Widget build(BuildContext context) {
    final start = _start;
    final valid = start != null && start.isAfter(DateTime.now());
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('availability.add'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(_date == null ? context.tr('availability.pickDate') : Formatters.dayLabel(context, _date!)),
            onPressed: () async {
              final now = DateTime.now();
              final d = await showDatePicker(
                context: context,
                initialDate: _date ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule_rounded),
            label: Text(_time == null ? context.tr('availability.pickTime') : _time!.format(context)),
            onPressed: () async {
              final t = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
              if (t != null) setState(() => _time = t);
            },
          ),
          const SizedBox(height: 16),
          Text(context.tr('availability.duration')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in const [30, 45, 60, 90, 120])
                ChoiceChip(
                  label: Text('$m′'),
                  selected: _duration == m,
                  onSelected: (_) => setState(() => _duration = m),
                ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: context.tr('action.add'),
            onPressed: valid ? () => Navigator.pop(context, (start, _duration)) : null,
          ),
        ],
      ),
    );
  }
}
