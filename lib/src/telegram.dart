import 'client.dart';

class TelegramModule {
  final AchekClient _client;
  TelegramModule(this._client);

  /// Send an OTP via Telegram to [chatId].
  ///
  /// The user must have sent /start to your bot first.
  Future<Map<String, dynamic>> sendOtp(
    String chatId, {
    String? appName,
    int length = 6,
  }) async {
    return _client.request('POST', '/telegram/send-otp', body: {
      'chat_id': chatId,
      if (appName != null) 'app_name': appName,
      'length': length,
    });
  }

  /// Send a custom message via Telegram to [chatId].
  Future<Map<String, dynamic>> sendMessage(
    String chatId,
    String message, {
    String parseMode = 'HTML',
  }) async {
    return _client.request('POST', '/telegram/send', body: {
      'chat_id': chatId,
      'message': message,
      'parse_mode': parseMode,
    });
  }

  /// Broadcast [message] to up to 100 Telegram [chatIds].
  Future<Map<String, dynamic>> sendBroadcast(
    List<String> chatIds,
    String message, {
    String parseMode = 'HTML',
  }) async {
    return _client.request('POST', '/telegram/send-broadcast', body: {
      'chat_ids': chatIds,
      'message': message,
      'parse_mode': parseMode,
    });
  }
}
