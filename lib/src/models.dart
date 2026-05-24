// ─── Error ────────────────────────────────────────────────────────────────────

class AchekException implements Exception {
  final String message;
  final int? statusCode;

  const AchekException(this.message, [this.statusCode]);

  bool get isRateLimit   => statusCode == 429;
  bool get isServerError => (statusCode ?? 0) >= 500;
  bool get isClientError => (statusCode ?? 0) >= 400 && (statusCode ?? 0) < 500;

  @override
  String toString() => 'AchekException($statusCode): $message';
}

// ─── OTP ─────────────────────────────────────────────────────────────────────

class OtpResponse {
  final String requestId;
  final String? expiresAt;
  final String? message;

  const OtpResponse({required this.requestId, this.expiresAt, this.message});

  factory OtpResponse.fromJson(Map<String, dynamic> json) => OtpResponse(
        requestId: json['requestId'] as String,
        expiresAt: json['expiresAt'] as String?,
        message:   json['message']   as String?,
      );
}

class VerifyResponse {
  final bool valid;
  final String? message;

  const VerifyResponse({required this.valid, this.message});

  factory VerifyResponse.fromJson(Map<String, dynamic> json) => VerifyResponse(
        valid:   json['valid'] as bool? ?? false,
        message: json['message'] as String?,
      );
}

// ─── Tickets ──────────────────────────────────────────────────────────────────

class Ticket {
  final String ticketId;
  final String phoneNumber;
  final String subject;
  final String? description;
  final String status;
  final String priority;
  final Map<String, dynamic>? metadata;
  final String createdAt;
  final String updatedAt;

  const Ticket({
    required this.ticketId,
    required this.phoneNumber,
    required this.subject,
    this.description,
    required this.status,
    required this.priority,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        ticketId:    json['ticketId']    as String,
        phoneNumber: json['phoneNumber'] as String,
        subject:     json['subject']     as String,
        description: json['description'] as String?,
        status:      json['status']      as String,
        priority:    json['priority']    as String,
        metadata:    json['metadata']    as Map<String, dynamic>?,
        createdAt:   json['createdAt']   as String,
        updatedAt:   json['updatedAt']   as String,
      );
}

// ─── Webhook ──────────────────────────────────────────────────────────────────

class AchekWebhookEvent {
  final String event;
  final String timestamp;
  final Map<String, dynamic> raw;

  const AchekWebhookEvent({
    required this.event,
    required this.timestamp,
    required this.raw,
  });

  /// Access any field from the raw webhook payload.
  dynamic operator [](String key) => raw[key];

  @override
  String toString() => 'AchekWebhookEvent(event: $event, timestamp: $timestamp)';
}
