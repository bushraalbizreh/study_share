import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:app_study_share/features/auth/presentation/widgets/role_card.dart';
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
          RoleCard(
            icon: Icons.menu_book_rounded,
            title: context.tr('role.student'),
            body: context.tr('role.studentBody'),
            selected: _role == 'student',
            onTap: () => setState(() => _role = 'student'),
          ),
          const SizedBox(height: 12),
          RoleCard(
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