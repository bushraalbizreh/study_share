import 'package:app_study_share/core/di/injection.dart';
import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/routing/route_names.dart';
import 'package:app_study_share/core/widgets/app_widgets.dart';
import 'package:app_study_share/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_study_share/features/auth/presentation/bloc/auth_event.dart';
import 'package:app_study_share/features/auth/presentation/bloc/auth_state.dart';
import 'package:app_study_share/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key, this.initialRole});

  final String? initialRole;

  @override
  Widget build(BuildContext context) => BlocProvider<AuthBloc>(
    create: (_) => getIt<AuthBloc>(),
    child: _RegisterView(role: initialRole == 'teacher' ? 'teacher' : 'student'),
  );
}

class _RegisterView extends StatefulWidget {
  const _RegisterView({required this.role});

  final String role;

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthUserSignedUp(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim(),
          role: widget.role,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteNames.homeFor(state.user.role),
            (_) => false,
          );
        } else if (state is AuthError) {
          showFeedback(context, context.errorText(state.code, state.message), error: true);
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return AuthScaffold(
          showBack: true,
          title: context.tr('register.title'),
          subtitle: context.tr(
            widget.role == 'teacher' ? 'register.asTeacher' : 'register.asStudent',
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: context.tr('field.name')),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? context.tr('validation.required')
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: context.tr('field.email')),
                  validator: (v) => emailValidator(context, v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: context.tr('field.password')),
                  validator: (v) => (v == null || v.length < 8)
                      ? context.tr('validation.password')
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  onFieldSubmitted: (_) => _submit(context),
                  decoration: InputDecoration(labelText: context.tr('field.confirmPassword')),
                  validator: (v) => v != _password.text
                      ? context.tr('validation.passwordMatch')
                      : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: context.tr('register.submit'),
                  loading: loading,
                  onPressed: () => _submit(context),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteNames.login,
                          (_) => false,
                        ),
                  child: Text(context.tr('register.haveAccount')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
