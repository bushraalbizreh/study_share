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

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<AuthBloc>(
    create: (_) => getIt<AuthBloc>(),
    child: const _LoginView(),
  );
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthUserSignedIn(email: _email.text.trim(), password: _password.text),
      );
    }
  }

  void _reset(BuildContext context) {
    if (emailValidator(context, _email.text) != null) {
      showFeedback(context, context.tr('login.enterEmailFirst'), error: true);
      return;
    }
    context.read<AuthBloc>().add(AuthPasswordResetRequested(email: _email.text.trim()));
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
        } else if (state is AuthResetEmailSent) {
          showFeedback(context, context.tr('login.resetSent', {'email': state.email}));
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return AuthScaffold(
          title: context.tr('login.title'),
          subtitle: context.tr('login.subtitle'),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: context.tr('field.email')),
                  validator: (v) => emailValidator(context, v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(context),
                  decoration: InputDecoration(
                    labelText: context.tr('field.password'),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => requiredValidator(context, v),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: loading ? null : () => _reset(context),
                    child: Text(context.tr('login.forgot')),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: context.tr('login.submit'),
                  loading: loading,
                  onPressed: () => _submit(context),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.tr('login.noAccount')),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).pushNamed(RouteNames.chooseRole),
                      child: Text(context.tr('login.create')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
