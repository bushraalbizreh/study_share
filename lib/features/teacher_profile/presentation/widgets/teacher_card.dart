import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/utils/ui_helpers.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/teacher_profile/domain/entities/teacher_profile.dart';
import 'package:flutter/material.dart';

class TeacherCard extends StatelessWidget {
  const TeacherCard({super.key, required this.teacher, this.onTap});

  final TeacherProfile teacher;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prices = teacher.prices.values.where((p) => p > 0);
    final from = prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatar(name: teacher.name, imageUrl: teacher.imageUrl, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      teacher.specialization,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (teacher.subjects.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        teacher.subjects.take(3).join(' · '),
                        style: TextStyle(color: scheme.primary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (from != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.tr('teacher.from'),
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                    ),
                    Text(
                      context.priceLabel(from),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
