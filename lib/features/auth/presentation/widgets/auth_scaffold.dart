import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';

/// Brand mark: a tile with a highlighter underline.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'S',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: scheme.onPrimary,
              fontSize: size * 0.5,
            ),
          ),
          Positioned(
            bottom: size * 0.2,
            child: Container(
              width: size * 0.36,
              height: size * 0.07,
              decoration: BoxDecoration(
                color: scheme.secondary,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared layout for Login / Register / Choose Role.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ResponsiveBody(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(),
                const SizedBox(height: 24),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? requiredValidator(BuildContext context, String? v) =>
    (v == null || v.trim().isEmpty) ? context.tr('validation.required') : null;

String? emailValidator(BuildContext context, String? v) {
  if (v == null || v.trim().isEmpty) return context.tr('validation.required');
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
  return ok ? null : context.tr('validation.email');
}
