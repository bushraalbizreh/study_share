import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Centers content and caps its width so layouts stay readable on tablets.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Consistent loading / empty / error views.
class StateView extends StatelessWidget {
  const StateView.loading({super.key})
    : icon = null,
      title = null,
      message = null,
      onAction = null,
      actionLabel = null,
      isError = false;

  const StateView.empty({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onAction,
    this.actionLabel,
  }) : isError = false;

  const StateView.error({super.key, required this.message, this.onAction})
    : icon = Icons.cloud_off_rounded,
      title = null,
      actionLabel = null,
      isError = true;

  final IconData? icon;
  final String? title;
  final String? message;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: isError
                  ? scheme.error.withValues(alpha: 0.12)
                  : scheme.secondaryContainer,
              child: Icon(icon, size: 34, color: isError ? scheme.error : scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? context.tr('state.error'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(160, 46)),
                onPressed: onAction,
                child: Text(actionLabel ?? context.tr('action.retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Filled/outlined button with a built-in busy state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    final action = loading ? null : onPressed;
    return outlined
        ? OutlinedButton(onPressed: action, child: child)
        : FilledButton(onPressed: action, child: child);
  }
}

/// Status chip for Open / Pending / Accepted / Rejected.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = Theme.of(context).extension<StatusColors>()!.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        context.tr('status.${status.toLowerCase()}'),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

/// Round avatar showing the profile image or the name's initial.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.imageUrl, this.radius = 22});

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primary,
      foregroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: Text(
        name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first).toUpperCase(),
        style: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

/// Label on one side, value on the other.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.emphasis = false});

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: emphasis ? scheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: Theme.of(context).textTheme.titleLarge),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

void showFeedback(BuildContext context, String message, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : null,
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.tr('action.cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

const List<String> kLevels = ['elementary', 'middle', 'high'];
