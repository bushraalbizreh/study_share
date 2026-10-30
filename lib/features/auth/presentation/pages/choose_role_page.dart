import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

class ChooseRolePage extends StatefulWidget {
  const ChooseRolePage({super.key});

  @override
  State<ChooseRolePage> createState() => _ChooseRolePageState();
}

class _ChooseRolePageState extends State<ChooseRolePage> {
  String _role = 'student';

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: context.tr('role.title'),
      subtitle: context.tr('role.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoleCard(
            icon: Icons.menu_book_rounded,
            title: context.tr('role.student'),
            body: context.tr('role.studentBody'),
            selected: _role == 'student',
            onTap: () => setState(() => _role = 'student'),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: Icons.school_rounded,
            title: context.tr('role.teacher'),
            body: context.tr('role.teacherBody'),
            selected: _role == 'teacher',
            onTap: () => setState(() => _role = 'teacher'),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: context.tr('action.continue'),
            onPressed: () => Navigator.of(context).pushNamed(
              RouteNames.register,
              arguments: {'role': _role},
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: selected ? scheme.primary : scheme.secondaryContainer,
                foregroundColor: selected ? scheme.onPrimary : scheme.primary,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(body, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
