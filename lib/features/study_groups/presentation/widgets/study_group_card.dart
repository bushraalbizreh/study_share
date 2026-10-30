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
    final progress = group.capacity == 0 ? 0.0 : group.currentMembers / group.capacity;
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
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1).toDouble(),
                  minHeight: 6,
                  backgroundColor: scheme.outlineVariant,
                ),
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
