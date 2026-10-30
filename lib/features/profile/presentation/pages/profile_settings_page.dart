import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/localization/locale_bloc.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/theme/theme_bloc.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_study_share/features/auth/presentation/bloc/auth_event.dart';
import 'package:app_study_share/features/auth/presentation/bloc/auth_state.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_study_share/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:app_study_share/features/profile/domain/entities/profile.dart';
import 'package:app_study_share/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:app_study_share/features/profile/presentation/bloc/profile_event.dart';
import 'package:app_study_share/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<ProfileBloc>(create: (_) => getIt<ProfileBloc>()..add(const ProfileRequested())),
      BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()),
    ],
    child: Scaffold(
      appBar: AppBar(title: Text(context.tr('profile.title'))),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProfileBloc, ProfileState>(
            listenWhen: (_, c) => c is ProfileActionDone || c is ProfileActionFailed,
            listener: (context, state) {
              if (state is ProfileActionDone) {
                showFeedback(context, context.tr('profile.done.${state.action}'));
              } else if (state is ProfileActionFailed) {
                showFeedback(context, context.errorText(state.code, state.message), error: true);
              }
            },
          ),
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                context.read<NotificationsBloc>().add(const NotificationsStopped());
                Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
              } else if (state is AuthError) {
                showFeedback(context, context.errorText(state.code, state.message), error: true);
              }
            },
          ),
        ],
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileError) {
              return StateView.error(
                message: context.errorText(state.code, state.message),
                onAction: () => context.read<ProfileBloc>().add(const ProfileRequested()),
              );
            }
            if (state is! ProfileLoaded) return const StateView.loading();
            return _ProfileForm(key: ValueKey(state.profile.uid), profile: state.profile, busy: state.busy);
          },
        ),
      ),
    ),
  );
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({super.key, required this.profile, required this.busy});

  final Profile profile;
  final bool busy;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _specialization;
  late final TextEditingController _subjects;
  late final TextEditingController _bio;
  late final Map<String, TextEditingController> _prices;
  late int _min;
  late int _max;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.name);
    _specialization = TextEditingController(text: p.specialization);
    _subjects = TextEditingController(text: p.subjects.join(', '));
    _bio = TextEditingController(text: p.biography);
    _prices = {
      for (final l in kLevels) l: TextEditingController(text: (p.prices[l] ?? 0) == 0 ? '' : '${p.prices[l]}'),
    };
    _min = p.minStudents;
    _max = p.maxStudents;
  }

  @override
  void dispose() {
    for (final c in [_name, _specialization, _subjects, _bio, ..._prices.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final bloc = context.read<ProfileBloc>();
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 80);
    if (file != null) bloc.add(ProfileImageSelected(imagePath: file.path));
  }

  void _imageMenu(BuildContext context) {
    final bloc = context.read<ProfileBloc>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(context.tr('profile.gallery')),
              onTap: () {
                Navigator.pop(sheet);
                _pick(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(context.tr('profile.camera')),
              onTap: () {
                Navigator.pop(sheet);
                _pick(context, ImageSource.camera);
              },
            ),
            if (widget.profile.imageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(context.tr('profile.removePhoto')),
                onTap: () {
                  Navigator.pop(sheet);
                  bloc.add(const ProfileImageRemoved());
                },
              ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final subjects = _subjects.text
        .split(RegExp('[,،]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    context.read<ProfileBloc>().add(
      ProfileUpdated(
        profile: widget.profile.copyWith(
          name: _name.text.trim(),
          specialization: _specialization.text.trim(),
          subjects: subjects,
          biography: _bio.text.trim(),
          prices: {for (final e in _prices.entries) e.key: int.tryParse(e.value.text.trim()) ?? 0},
          minStudents: _min,
          maxStudents: _max,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ResponsiveBody(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    UserAvatar(name: p.name, imageUrl: p.imageUrl, radius: 52),
                    if (widget.busy)
                      const Positioned.fill(child: CircularProgressIndicator()),
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        tooltip: context.tr('profile.changePhoto'),
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.secondary,
                          foregroundColor: scheme.onSecondary,
                        ),
                        onPressed: widget.busy ? null : () => _imageMenu(context),
                        icon: const Icon(Icons.photo_camera_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text(p.email, style: TextStyle(color: scheme.onSurfaceVariant))),
              Center(child: Chip(label: Text(context.tr(p.isTeacher ? 'role.teacher' : 'role.student')))),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: context.tr('field.name')),
                validator: (v) => (v == null || v.trim().length < 2) ? context.tr('validation.required') : null,
              ),
              if (p.isTeacher) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _specialization,
                  decoration: InputDecoration(labelText: context.tr('profile.specialization')),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subjects,
                  decoration: InputDecoration(
                    labelText: context.tr('profile.subjects'),
                    helperText: context.tr('profile.subjectsHint'),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bio,
                  maxLines: 4,
                  maxLength: 600,
                  decoration: InputDecoration(labelText: context.tr('profile.bio')),
                ),
                SectionTitle(context.tr('profile.prices')),
                for (final l in kLevels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _prices[l],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr('level.$l'),
                        suffixText: context.tr('currency'),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        return (n == null || n < 0) ? context.tr('validation.number') : null;
                      },
                    ),
                  ),
                SectionTitle(context.tr('profile.groupSize')),
                Row(
                  children: [
                    Expanded(child: _Stepper(label: context.tr('profile.min'), value: _min, lo: 2, hi: _max, onChanged: (v) => setState(() => _min = v))),
                    const SizedBox(width: 12),
                    Expanded(child: _Stepper(label: context.tr('profile.max'), value: _max, lo: _min, hi: 30, onChanged: (v) => setState(() => _max = v))),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(label: context.tr('action.save'), loading: widget.busy, onPressed: () => _save(context)),
              SectionTitle(context.tr('settings.language')),
              BlocBuilder<LocaleBloc, LocaleState>(
                builder: (context, s) => SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                  ],
                  selected: {s is LocaleLoaded ? s.locale.languageCode : 'en'},
                  onSelectionChanged: (v) => context.read<LocaleBloc>().add(LocaleChanged(Locale(v.first))),
                ),
              ),
              SectionTitle(context.tr('settings.theme')),
              BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, s) => SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(context.tr('theme.system'))),
                    ButtonSegment(value: ThemeMode.light, label: Text(context.tr('theme.light'))),
                    ButtonSegment(value: ThemeMode.dark, label: Text(context.tr('theme.dark'))),
                  ],
                  selected: {s is ThemeLoaded ? s.mode : ThemeMode.system},
                  onSelectionChanged: (v) => context.read<ThemeBloc>().add(ThemeModeChanged(v.first)),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error, side: BorderSide(color: scheme.error)),
                icon: const Icon(Icons.logout_rounded),
                label: Text(context.tr('settings.logout')),
                onPressed: () async {
                  final bloc = context.read<AuthBloc>();
                  final ok = await confirmDialog(
                    context,
                    title: context.tr('settings.logout'),
                    message: context.tr('settings.logoutConfirm'),
                    confirmLabel: context.tr('settings.logout'),
                  );
                  if (ok) bloc.add(const AuthUserSignedOut());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.lo, required this.hi, required this.onChanged});

  final String label;
  final int value;
  final int lo;
  final int hi;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: context.tr('action.decrease'),
          onPressed: value > lo ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        Text('$value', style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          tooltip: context.tr('action.increase'),
          onPressed: value < hi ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
  );
}
