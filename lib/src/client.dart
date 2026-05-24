import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'otp.dart';
import 'messaging.dart';
import 'telegram.dart';
import 'tickets.dart';

export 'models.dart';

/// HTTP status codes that are safe to retry (transient server-side errors).
const _retryableStatuses = {429, 500, 502, 503, 504};

class AchekClient {
  final String apiKey;
  final String baseUrl;

  /// Request timeout (default: 15 seconds).
  final Duration timeout;

  /// Maximum total attempts per request, including the first try.
  /// Retries use exponential back-off starting at [initialDelay].
  final int maxAttempts;

  /// Initial back-off delay before the first retry.
  final Duration initialDelay;

  late final OtpModule otp;
  late final MessagingModule messaging;
  late final TelegramModule telegram;
  late final TicketsModule tickets;

  AchekClient({
    required this.apiKey,
    this.baseUrl = 'https://api.achek.com.ng',
    this.timeout = const Duration(seconds: 15),
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
  }) {
    otp       = OtpModule(this);
    messaging = MessagingModule(this);
    telegram  = TelegramModule(this);
    tickets   = TicketsModule(this);
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final uri = Uri.parse('$baseUrl/api$path');
    final headers = <String, String>{
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
      'User-Agent': 'achekconnect-dart/2.0.0',
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
    };
    final encoded = body != null ? jsonEncode(body) : null;

    AchekException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      http.Response response;

      try {
        response = await _send(method, uri, headers, encoded)
            .timeout(timeout, onTimeout: () {
          throw AchekException('Request timed out', 408);
        });
      } on AchekException {
        rethrow;
      } catch (e) {
        final err = AchekException('Network error: $e', 0);
        if (attempt >= maxAttempts) throw err;
        lastError = err;
        await _backoff(attempt);
        continue;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw AchekException('Unexpected response format', response.statusCode);
      }

      if (response.statusCode < 400) return data;

      final err = AchekException(
        data['error'] as String? ?? 'Request failed',
        response.statusCode,
      );

      if (!_retryableStatuses.contains(response.statusCode) ||
          attempt >= maxAttempts) {
        throw err;
      }
      lastError = err;
      await _backoff(attempt);
    }

    throw lastError ?? AchekException('Max retries exceeded', 0);
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    switch (method.toUpperCase()) {
      case 'POST':
        return http.post(uri, headers: headers, body: body);
      case 'GET':
        return http.get(uri, headers: headers);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: body);
      case 'PUT':
        return http.put(uri, headers: headers, body: body);
      case 'DELETE':
        return http.delete(uri, headers: headers, body: body);
      default:
        throw AchekException('Unsupported HTTP method: $method', 0);
    }
  }

  Future<void> _backoff(int attempt) =>
      Future<void>.delayed(initialDelay * (1 << (attempt - 1)));
}
