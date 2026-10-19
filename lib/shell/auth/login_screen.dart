import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/api/errors.dart';
import '../../core/domain/session.dart';
import '../../core/providers/platform_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../design_system/primitives/app_icon_button.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  PlatformError? _error;
  bool _submitting = false;
  bool _obscurePassword = true;
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(
        () => _error = const PlatformError(
          PlatformErrorCode.responseMalformed,
          'Login fields are required.',
        ),
      );
      return;
    }
    final username = _username.text.trim();
    final password = _password.text;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = ref.read(platformApiProvider);
      await ref
          .read(sessionManagerProvider)
          .signIn(
            () => api.auth.login(username: username, password: password),
            api.auth.me,
          );
      if (mounted) {
        _password.clear();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is PlatformError
              ? error
              : const PlatformError(
                  PlatformErrorCode.unexpected,
                  'Sign-in failed.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _comingSoon() {
    showFToast(
      context: context,
      title: Text(AppLocalizations.of(context).text(AppText.comingSoon)),
    );
  }

  String _errorMessage(AppLocalizations strings, PlatformError error) {
    // Backend messages are shown verbatim; local copy is the fallback.
    if (error.code == PlatformErrorCode.serverError &&
        error.diagnosticMessage.trim().isNotEmpty) {
      return error.diagnosticMessage;
    }
    return strings.text(
      error.code == PlatformErrorCode.unsupported
          ? AppText.mfaRequired
          : error.code == PlatformErrorCode.storageFailed
          ? AppText.storageFailed
          : AppText.signInFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final session = ref.watch(sessionStateProvider);
    if (session.status == SessionStatus.restoring) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    final colors = context.theme.colors;
    final busy = _submitting || session.status == SessionStatus.authenticating;
    final error = _error ?? session.error;
    return SingleChildScrollView(
      key: const Key('loginScreen'),
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGap.v24,
          Text(
            strings.text(AppText.signIn),
            style: AppTextStyle.display(colors.foreground),
          ),
          AppGap.v24,
          if (error != null) ...[
            FAlert(
              key: const Key('loginError'),
              variant: FAlertVariant.destructive,
              title: Text(_errorMessage(strings, error)),
            ),
            AppGap.v16,
          ],
          FTextField(
            key: const Key('loginUsername'),
            control: FTextFieldControl.managed(controller: _username),
            label: Text(strings.text(AppText.username)),
            autocorrect: false,
            enabled: !busy,
            textInputAction: TextInputAction.next,
          ),
          AppGap.v16,
          FTextField(
            key: const Key('loginPassword'),
            control: FTextFieldControl.managed(controller: _password),
            label: Text(strings.text(AppText.password)),
            obscureText: _obscurePassword,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !busy,
            textInputAction: TextInputAction.done,
            onSubmit: (_) => _submit(),
            suffixBuilder: (context, style, variants) => AppIconButton(
              key: const Key('passwordVisibility'),
              icon: _obscurePassword ? FLucideIcons.eye : FLucideIcons.eyeOff,
              iconSize: 20,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          AppGap.v24,
          FButton(
            key: const Key('loginSubmit'),
            onPress: busy ? null : _submit,
            child: Text(strings.text(busy ? AppText.working : AppText.signIn)),
          ),
          AppGap.v16,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.lg,
            children: [
              TextButton(
                key: const Key('forgotPassword'),
                onPressed: busy ? null : _comingSoon,
                style: TextButton.styleFrom(
                  foregroundColor: colors.mutedForeground,
                  textStyle: AppTextStyle.label(colors.mutedForeground),
                ),
                child: Text(strings.text(AppText.forgotPassword)),
              ),
              TextButton(
                key: const Key('registerLink'),
                onPressed: busy ? null : () => context.go('/register'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  textStyle: AppTextStyle.label(colors.primary),
                ),
                child: Text(strings.text(AppText.noAccount)),
              ),
            ],
          ),
          AppGap.v24,
          Row(
            children: [
              const Expanded(child: FDivider()),
              Padding(
                padding: AppInsets.h(AppSpacing.md),
                child: Text(
                  strings.text(AppText.orContinueWith),
                  style: AppTextStyle.caption(colors.mutedForeground),
                ),
              ),
              const Expanded(child: FDivider()),
            ],
          ),
          AppGap.v16,
          FButton(
            key: const Key('googleSignIn'),
            variant: FButtonVariant.outline,
            onPress: busy ? null : _comingSoon,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FLucideIcons.globe, size: 20, color: colors.foreground),
                AppGap.h8,
                Text(strings.text(AppText.continueWithGoogle)),
              ],
            ),
          ),
          AppGap.v24,
        ],
      ),
    );
  }
}
