import 'package:achek/achek.dart';

Future<void> main() async {
  final client = AchekClient(apiKey: 'watp_live_your_key_here');

  // ── WhatsApp OTP ──────────────────────────────────────────
  final otpRes = await client.otp.send(
    '+2348XXXXXXXXX',
    template: 'Your login code is {{code}}. Valid for 10 minutes.',
  );
  print('OTP sent. Request ID: ${otpRes.requestId}');

  final verification = await client.otp.verify(otpRes.requestId, '847291');
  print('Valid: ${verification.valid}');

  // ── WhatsApp messaging ────────────────────────────────────
  await client.messaging.sendMessage(
    '+2348XXXXXXXXX',
    'Your order #1234 has shipped!',
  );

  // ── Telegram OTP ──────────────────────────────────────────
  final tgOtp = await client.telegram.sendOtp(
    '123456789',
    appName: 'MyApp',
  );
  print('Telegram OTP sent: ${tgOtp['otp']}');

  // ── Telegram broadcast ────────────────────────────────────
  await client.telegram.sendBroadcast(
    ['123456789', '987654321'],
    '🎉 Flash sale — 40% off everything today!',
  );
}
