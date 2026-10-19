import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/api/errors.dart';
import '../../core/domain/country.dart';
import '../../core/domain/preferences.dart';
import '../../core/domain/register_rules.dart';
import '../../core/domain/session.dart';
import '../../core/providers/platform_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../design_system/primitives/app_icon_button.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../../design_system/tokens/trading_tokens.dart';

/// Email registration (v1 /uc/register/email). A successful register is
/// followed by the regular login + identity confirmation, so the session
/// guard then redirects to /account. Failures show the backend message and
/// never fake success.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _referral = TextEditingController();

  List<Country>? _countries;
  Country? _country;
  bool _countriesFailed = false;
  bool _agreeTerms = false;
  bool _agreeRisk = false;
  bool _submitting = false;
  String? _error;
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    for (final c in [
      _email,
      _code,
      _username,
      _password,
      _confirm,
      _phone,
      _referral,
    ]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [
      _email,
      _code,
      _username,
      _password,
      _confirm,
      _phone,
      _referral,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _countries = null;
      _countriesFailed = false;
    });
    try {
      final countries = await ref.read(platformApiProvider).auth.countries();
      if (mounted) setState(() => _countries = countries);
    } catch (_) {
      if (mounted) setState(() => _countriesFailed = true);
    }
  }

  String _countryLabel(Country country) {
    final language = AppLocalizations.of(context).language;
    return language == AppLanguage.enUs ? country.enName : country.zhName;
  }

  bool get _canSubmit {
    if (_submitting || _country == null) return false;
    return isValidEmail(_email.text) &&
        isValidEmailCode(_code.text) &&
        isValidUsername(_username.text) &&
        checkPasswordRules(_password.text).allOk &&
        _password.text == _confirm.text &&
        isValidPhone(_phone.text) &&
        _agreeTerms &&
        _agreeRisk;
  }

  Future<void> _sendCode() async {
    if (_countdown > 0 || !isValidEmail(_email.text)) return;
    final strings = AppLocalizations.of(context);
    try {
      await ref
          .read(platformApiProvider)
          .auth
          .sendRegisterCode(email: _email.text.trim());
      if (!mounted) return;
      showFToast(
        context: context,
        title: Text(strings.text(AppText.codeSent)),
      );
      setState(() => _countdown = 60);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _countdown -= 1;
          if (_countdown <= 0) {
            _countdown = 0;
            timer.cancel();
          }
        });
      });
    } catch (error) {
      if (!mounted) return;
      showFToast(
        context: context,
        title: Text(_errorText(strings, error)),
      );
    }
  }

  String _errorText(AppLocalizations strings, Object error) {
    if (error is PlatformError) {
      if (error.code == PlatformErrorCode.serverError &&
          error.diagnosticMessage.trim().isNotEmpty) {
        return error.diagnosticMessage;
      }
      if (error.code == PlatformErrorCode.backendNotConfigured) {
        return strings.text(AppText.disconnected);
      }
    }
    return strings.text(AppText.registerFailed);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final strings = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = ref.read(platformApiProvider);
      final input = RegisterInput(
        email: _email.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
        code: _code.text.trim(),
        country: _country!.zhName,
        phone: _phone.text.trim(),
        promotion: _referral.text.trim(),
      );
      await api.auth.register(input);
      // Registration succeeded: sign in with the same credentials so the
      // route guard moves the user to /account.
      await ref
          .read(sessionManagerProvider)
          .signIn(
            () => api.auth.login(
              username: input.email,
              password: input.password,
            ),
            api.auth.me,
          );
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(strings, error));
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
    final rules = checkPasswordRules(_password.text);
    return SingleChildScrollView(
      key: const Key('registerScreen'),
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGap.v24,
          Text(
            strings.text(AppText.createAccount),
            style: AppTextStyle.display(colors.foreground),
          ),
          AppGap.v24,
          if (_countriesFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: FAlert(
                key: const Key('countriesError'),
                variant: FAlertVariant.destructive,
                title: Text(strings.text(AppText.countriesUnavailable)),
                subtitle: TextButton(
                  key: const Key('countriesRetry'),
                  onPressed: _loadCountries,
                  child: Text(strings.text(AppText.retry)),
                ),
              ),
            ),
          if (_countries == null && !_countriesFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          if (_countries != null)
            FSelect<Country>.rich(
              key: const Key('registerCountry'),
              control: FSelectControl.managed(
                initial: _country,
                onChange: (value) => setState(() => _country = value),
              ),
              format: (country) => _countryLabel(country),
              label: Text(strings.text(AppText.country)),
              children: [
                for (final country in _countries!)
                  FSelectItem.item(
                    key: ValueKey('country.${country.zhName}'),
                    title: Text(_countryLabel(country)),
                    value: country,
                  ),
              ],
            ),
          AppGap.v16,
          FTextField(
            key: const Key('registerPhone'),
            control: FTextFieldControl.managed(controller: _phone),
            label: Text(strings.text(AppText.phone)),
            hint: _country == null ? null : '${_country!.areaCode} ',
            keyboardType: TextInputType.phone,
            enabled: !_submitting,
          ),
          AppGap.v16,
          FTextField(
            key: const Key('registerEmail'),
            control: FTextFieldControl.managed(controller: _email),
            label: const Text('Email'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enabled: !_submitting,
          ),
          AppGap.v24,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FTextField(
                  key: const Key('registerCode'),
                  control: FTextFieldControl.managed(controller: _code),
                  label: Text(strings.text(AppText.verificationCode)),
                  autocorrect: false,
                  enabled: !_submitting,
                  maxLength: 6,
                ),
              ),
              AppGap.h12,
              FButton(
                key: const Key('sendCode'),
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                onPress: _countdown > 0 || !isValidEmail(_email.text)
                    ? null
                    : _sendCode,
                child: Text(
                  _countdown > 0
                      ? '${strings.text(AppText.resend)} (${_countdown}s)'
                      : strings.text(AppText.sendCode),
                ),
              ),
            ],
          ),
          AppGap.v24,
          FTextField(
            key: const Key('registerUsername'),
            control: FTextFieldControl.managed(controller: _username),
            label: Text(strings.text(AppText.username)),
            description: Text(strings.text(AppText.usernameRule)),
            autocorrect: false,
            enabled: !_submitting,
          ),
          AppGap.v16,
          FTextField(
            key: const Key('registerPassword'),
            control: FTextFieldControl.managed(controller: _password),
            label: Text(strings.text(AppText.password)),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !_submitting,
          ),
          AppGap.v8,
          _RuleChecklist(strings: strings, rules: rules),
          AppGap.v16,
          FTextField(
            key: const Key('registerConfirm'),
            control: FTextFieldControl.managed(controller: _confirm),
            label: Text(strings.text(AppText.confirmPassword)),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !_submitting,
          ),
          if (_confirm.text.isNotEmpty && _confirm.text != _password.text)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                strings.text(AppText.passwordsNoMatch),
                key: const Key('passwordsNoMatch'),
                style: AppTextStyle.caption(colors.destructive),
              ),
            ),
          AppGap.v16,
          FTextField(
            key: const Key('registerReferral'),
            control: FTextFieldControl.managed(controller: _referral),
            label: Text(strings.text(AppText.referral)),
            autocorrect: false,
            enabled: !_submitting,
          ),
          AppGap.v24,
          _AgreementRow(
            checkboxKey: const Key('agreeTerms'),
            linkKey: const Key('termsLink'),
            label: strings.text(AppText.agreeTerms),
            value: _agreeTerms,
            onChange: (value) => setState(() => _agreeTerms = value),
            onLink: _comingSoon,
          ),
          AppGap.v4,
          _AgreementRow(
            checkboxKey: const Key('agreeRisk'),
            linkKey: const Key('riskLink'),
            label: strings.text(AppText.agreeRisk),
            value: _agreeRisk,
            onChange: (value) => setState(() => _agreeRisk = value),
            onLink: _comingSoon,
          ),
          if (_error != null) ...[
            AppGap.v16,
            FAlert(
              key: const Key('registerError'),
              variant: FAlertVariant.destructive,
              title: Text(_error!),
            ),
          ],
          AppGap.v24,
          FButton(
            key: const Key('registerSubmit'),
            onPress: _canSubmit ? _submit : null,
            child: Text(
              strings.text(
                _submitting ? AppText.working : AppText.createAccount,
              ),
            ),
          ),
          AppGap.v16,
          Center(
            child: TextButton(
              key: const Key('loginLink'),
              onPressed: _submitting ? null : () => context.go('/login'),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                textStyle: AppTextStyle.label(colors.primary),
              ),
              child: Text(strings.text(AppText.haveAccount)),
            ),
          ),
          AppGap.v24,
        ],
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.checkboxKey,
    required this.linkKey,
    required this.label,
    required this.value,
    required this.onChange,
    required this.onLink,
  });

  final Key checkboxKey;
  final Key linkKey;
  final String label;
  final bool value;
  final ValueChanged<bool> onChange;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(
            child: FCheckbox(
              key: checkboxKey,
              value: value,
              onChange: onChange,
              label: Text(label, style: AppTextStyle.caption(colors.foreground)),
            ),
          ),
          AppIconButton(
            key: linkKey,
            icon: FLucideIcons.fileText,
            iconSize: 20,
            onPressed: onLink,
          ),
        ],
      ),
    );
  }
}

class _RuleChecklist extends StatelessWidget {
  const _RuleChecklist({required this.strings, required this.rules});

  final AppLocalizations strings;
  final PasswordRuleCheck rules;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final trading = TradingColors.of(context);
    final entries = [
      (strings.text(AppText.passwordRuleLength), rules.lengthOk),
      (strings.text(AppText.passwordRuleLower), rules.hasLower),
      (strings.text(AppText.passwordRuleUpper), rules.hasUpper),
      (strings.text(AppText.passwordRuleDigit), rules.hasDigit),
      (strings.text(AppText.passwordRuleSpecial), rules.hasSpecial),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gutter = AppSpacing.lg;
        final itemWidth = (constraints.maxWidth - gutter) / 2;
        return Wrap(
          key: const Key('passwordRules'),
          spacing: gutter,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (label, ok) in entries)
              SizedBox(
                width: itemWidth,
                child: Row(
                  children: [
                    Icon(
                      ok ? FLucideIcons.check : FLucideIcons.circle,
                      size: 16,
                      color: ok ? trading.up : colors.mutedForeground,
                    ),
                    AppGap.h8,
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyle.caption(
                          ok ? trading.up : colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
