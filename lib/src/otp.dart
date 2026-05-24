import 'client.dart';

class OtpModule {
  final AchekClient _client;
  OtpModule(this._client);

  /// Send a WhatsApp OTP to [phoneNumber].
  ///
  /// [template] — custom message, use `{{code}}` as placeholder.
  /// [length] — number of digits (default 6).
  /// [expiryMinutes] — how long the code is valid (default 10).
  Future<OtpResponse> send(
    String phoneNumber, {
    String? template,
    int? length,
    int? expiryMinutes,
  }) async {
    final data = await _client.request('POST', '/otp/send', body: {
      'phoneNumber': phoneNumber,
      if (template != null) 'template': template,
      if (length != null) 'length': length,
      if (expiryMinutes != null) 'expiryMinutes': expiryMinutes,
    });
    return OtpResponse.fromJson(data);
  }

  /// Verify a [code] entered by the user against [requestId].
  Future<VerifyResponse> verify(String requestId, String code) async {
    final data = await _client.request('POST', '/otp/verify', body: {
      'requestId': requestId,
      'code': code,
    });
    return VerifyResponse.fromJson(data);
  }
}
