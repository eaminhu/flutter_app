/// A v1 country/region entry from POST /uc/support/country?isReg=1.
/// The backend matches registration on [zhName]; [enName] is the display
/// label for non-Chinese locales and [areaCode] the phone dial prefix.
class Country {
  const Country({
    required this.zhName,
    required this.enName,
    required this.areaCode,
  });

  final String zhName;
  final String enName;
  final String areaCode;
}

/// Email-registration input for POST /uc/register/email.
/// [country] carries the backend-matched zhName; [promotion] is the optional
/// referral code (server trims it, so empty is sent as '').
class RegisterInput {
  const RegisterInput({
    required this.email,
    required this.username,
    required this.password,
    required this.code,
    required this.country,
    required this.phone,
    this.promotion = '',
  });

  final String email;
  final String username;
  final String password;
  final String code;
  final String country;
  final String phone;
  final String promotion;
}
