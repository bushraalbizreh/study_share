import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/utils/ui_helpers.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/study_groups/domain/entities/study_group.dart';
import 'package:flutter/material.dart';

/// Shared study group card used by Home, Explore, My Groups and Teacher views.
class StudyGroupCard extends StatelessWidget {
  const StudyGroupCard({super.key, required this.group, this.onTap, this.footer});

  final StudyGroup group;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final capacity = group.capacity;
    final joined = capacity == 0 ? 0 : group.currentMembers.clamp(0, capacity);
    // Keep gaps readable even when the group has many seats.
    final gap = capacity > 24 ? 1.0 : 3.0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.subject,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(group.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${group.teacherName} · ${context.levelLabel(group.gradeLevel)}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.event_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(context.when(group.startAt))),
                ],
              ),
              const SizedBox(height: 10),
              // One segment per seat: filled = students already joined.
              if (capacity == 0)
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )
              else
                Row(
                  children: [
                    for (var i = 0; i < capacity; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: i < joined
                                ? scheme.secondary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('group.members', {
                      'n': '${group.currentMembers}',
                      'm': '${group.capacity}',
                    }),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    context.priceLabel(group.pricePerStudent),
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (footer != null) ...[const SizedBox(height: 12), footer!],
            ],
          ),
        ),
      ),
    );
  }
}
