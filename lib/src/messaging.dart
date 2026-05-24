import 'client.dart';

class MessagingModule {
  final AchekClient _client;
  MessagingModule(this._client);

  /// Send a WhatsApp message to [phoneNumber].
  Future<Map<String, dynamic>> sendMessage(
    String phoneNumber,
    String message,
  ) async {
    return _client.request('POST', '/messaging/send', body: {
      'phoneNumber': phoneNumber,
      'message': message,
    });
  }

  /// Broadcast [message] to up to 100 [phoneNumbers] at once.
  Future<Map<String, dynamic>> sendBroadcast(
    List<String> phoneNumbers,
    String message,
  ) async {
    return _client.request('POST', '/messaging/broadcast', body: {
      'phoneNumbers': phoneNumbers,
      'message': message,
    });
  }
}
