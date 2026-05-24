import 'client.dart';
import 'models.dart';

/// Manage support tickets with WhatsApp customer notifications.
///
/// ```dart
/// final ticket = await client.tickets.create(
///   phoneNumber: '+2348XXXXXXXXX',
///   subject: 'Payment not reflecting',
///   description: 'Paid ₦5,000 but order not updated',
///   priority: 'high',
///   notifyCustomer: true,
/// );
/// print(ticket.ticketId);
/// ```
class TicketsModule {
  final AchekClient _client;
  TicketsModule(this._client);

  /// Create a new support ticket.
  ///
  /// Set [notifyCustomer] to `true` (default) to send the customer an
  /// opening WhatsApp message when the ticket is created.
  Future<Ticket> create({
    required String phoneNumber,
    required String subject,
    String? description,
    String priority = 'normal',
    Map<String, dynamic>? metadata,
    bool notifyCustomer = true,
    String? notificationMessage,
  }) async {
    final data = await _client.request('POST', '/tickets', body: {
      'phoneNumber': phoneNumber,
      'subject': subject,
      'priority': priority,
      'notifyCustomer': notifyCustomer,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
      if (notificationMessage != null)
        'notificationMessage': notificationMessage,
    });
    return Ticket.fromJson(data);
  }

  /// List all tickets, optionally filtered by [status].
  Future<List<Ticket>> list({String? status, int limit = 50}) async {
    final params = <String, String>{'limit': '$limit'};
    if (status != null) params['status'] = status;
    final qs = Uri(queryParameters: params).query;
    final data = await _client.request('GET', '/tickets?$qs');
    final list = data['tickets'] as List<dynamic>? ?? [data];
    return list
        .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific ticket by its ID.
  Future<Ticket> get(String ticketId) async {
    final data = await _client.request('GET', '/tickets/$ticketId');
    return Ticket.fromJson(data);
  }

  /// Update a ticket's status or priority. Optionally notify the customer.
  Future<Ticket> update(
    String ticketId, {
    String? status,
    String? priority,
    bool notifyCustomer = false,
    String? notificationMessage,
  }) async {
    final data = await _client.request('PATCH', '/tickets/$ticketId', body: {
      'notifyCustomer': notifyCustomer,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (notificationMessage != null)
        'notificationMessage': notificationMessage,
    });
    return Ticket.fromJson(data);
  }

  /// Convenience: resolve a ticket and send the customer a closing message.
  Future<Ticket> resolve(String ticketId, {String? message}) {
    return update(
      ticketId,
      status: 'resolved',
      notifyCustomer: true,
      notificationMessage: message,
    );
  }
}
