import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'models.dart';

/// Verify and parse incoming Achek Connect webhook events.
///
/// Achek signs every webhook delivery with HMAC-SHA256 using your webhook
/// secret. The signature is sent in the `X-Achek-Signature` HTTP header as
/// `sha256=<hex-digest>`.
///
/// **Add the `crypto` package to your `pubspec.yaml`:**
/// ```yaml
/// dependencies:
///   crypto: ^3.0.0
/// ```
///
/// **Example (shelf server):**
/// ```dart
/// import 'package:achekconnect/achekconnect.dart';
///
/// final helper = AchekWebhookHelper('your_webhook_secret');
///
/// Response webhookHandler(Request request) async {
///   final body = await request.readAsString();
///   final sig  = request.headers['x-achek-signature'] ?? '';
///   if (!helper.verify(sig, body)) {
///     return Response(400, body: 'Invalid signature');
///   }
///   final event = helper.parse(body);
///   print(event.event); // e.g. "otp.verified", "handoff.requested"
///   return Response.ok('');
/// }
/// ```
class AchekWebhookHelper {
  final List<int> _secretBytes;

  /// [webhookSecret] is the secret shown in your Achek dashboard.
  AchekWebhookHelper(String webhookSecret)
      : _secretBytes = utf8.encode(webhookSecret) {
    if (webhookSecret.isEmpty) {
      throw ArgumentError.value(webhookSecret, 'webhookSecret', 'must not be empty');
    }
  }

  /// Verify the HMAC-SHA256 signature from the `X-Achek-Signature` header.
  ///
  /// Uses a constant-time comparison via [Hmac] to prevent timing attacks.
  ///
  /// [signature] — value of the `X-Achek-Signature` header
  ///               (e.g. `"sha256=abc123..."`).
  /// [payload]   — raw request body as a [String].
  ///
  /// Returns `true` if the signature is valid.
  bool verify(String signature, String payload) {
    try {
      final sig      = signature.replaceFirst(RegExp(r'^sha256='), '');
      final hmac     = Hmac(sha256, _secretBytes);
      final digest   = hmac.convert(utf8.encode(payload));
      final expected = digest.toString();
      // Constant-time comparison: compare every character regardless of mismatch
      if (sig.length != expected.length) return false;
      var result = 0;
      for (var i = 0; i < sig.length; i++) {
        result |= sig.codeUnitAt(i) ^ expected.codeUnitAt(i);
      }
      return result == 0;
    } catch (_) {
      return false;
    }
  }

  /// Decode and return the raw webhook payload as an [AchekWebhookEvent].
  ///
  /// Throws [FormatException] on malformed JSON.
  AchekWebhookEvent parse(String payload) {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return AchekWebhookEvent(
      event:     map['event']     as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      raw:       map,
    );
  }
}
