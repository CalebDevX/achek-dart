# achek — Dart / Flutter SDK

Official Dart SDK for [Achek](https://achek.com.ng) — WhatsApp & Telegram OTP, messaging, broadcasts, support tickets, and webhook utilities for Nigeria and Africa.

[![pub.dev](https://img.shields.io/pub/v/achek)](https://pub.dev/packages/achek)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  achek: ^2.0.0
  crypto: ^3.0.0   # required for AchekWebhookHelper
```

Then run:

```bash
dart pub get
# or for Flutter:
flutter pub get
```

## Quick Start

```dart
import 'package:achek/achek.dart';

final client = AchekClient(apiKey: 'your_api_key');

// Send WhatsApp OTP
final res = await client.otp.send('+2348012345678');

// Verify the code the user entered
final result = await client.otp.verify(res.requestId, '847291');
if (result.valid) {
  print('User verified!'); // ✅
}
```

> Get your API key from the [Achek dashboard](https://achek.com.ng/dashboard/api-keys).

---

## WhatsApp OTP

```dart
// Simple send
final res = await client.otp.send('+2348012345678');

// With custom template (Growth+ plans)
final res = await client.otp.send(
  '+2348012345678',
  template: 'Hi, your MyApp login code is {{code}}. Valid 10 mins.',
  length: 6,
  expiryMinutes: 10,
);

// Verify
final result = await client.otp.verify(res.requestId, '847291');
print(result.valid); // true
```

---

## WhatsApp Messaging

```dart
// Send a direct message
await client.messaging.sendMessage(
  '+2348012345678',
  'Your order #1234 has shipped! 🚚',
);

// Broadcast to multiple numbers (up to 100)
await client.messaging.sendBroadcast(
  ['+2348012345678', '+2349087654321'],
  '🎉 Flash sale — 40% off everything today!',
);
```

---

## Telegram OTP & Messaging

```dart
// User must have sent /start to your Telegram bot first
final tgRes = await client.telegram.sendOtp(
  '123456789', // Telegram chat_id
  appName: 'MyApp',
);

// Send a direct Telegram message
await client.telegram.sendMessage(
  '123456789',
  'Your account <b>Emeka</b> has been verified.',
);

// Broadcast to multiple Telegram users
await client.telegram.sendBroadcast(
  ['123456789', '987654321'],
  '📣 New update: version 2.0 is live!',
);
```

---

## Support Ticket Tracking

Create support tickets and keep customers updated on WhatsApp automatically:

```dart
// Create a ticket — customer gets a WhatsApp notification
final ticket = await client.tickets.create(
  phoneNumber: '+2348012345678',
  subject: 'Payment not reflecting',
  description: 'Paid ₦5,000 but order not updated',
  priority: 'high',
  notifyCustomer: true,
);
print(ticket.ticketId); // "TKT-1748000000000-AB12"

// Update status — customer gets a WhatsApp update
final updated = await client.tickets.update(
  ticket.ticketId,
  status: 'in_progress',
  notifyCustomer: true,
  notificationMessage: "We're investigating — resolution within 2 hours.",
);

// Resolve the ticket
await client.tickets.resolve(
  ticket.ticketId,
  message: 'Your issue has been fixed! Please check your account.',
);

// List open tickets
final openTickets = await client.tickets.list(status: 'open');
```

---

## AI Chatbot & Webhook Events

Achek includes a built-in AI chatbot that responds to WhatsApp messages automatically. Configure it from the dashboard — no extra API calls needed.

### Webhook events

Set a webhook URL in **AI Bot → Webhook URL** in your dashboard. Achek will POST to it on these events:

| Event | Fired when | Key fields |
|---|---|---|
| `message.incoming` | Customer sends a message to your bot | `phone`, `message`, `timestamp` |
| `message.outgoing` | Bot replies to the customer | `phone`, `message`, `timestamp` |
| `spam.quarantine` | Sender exceeded velocity limit | `phone`, `quarantined_until`, `message_count` |
| `handoff.requested` | Consecutive depth reached / human took over | `phone`, `reason`, `exchanges`, `bot_config_id` |
| `ticket.created` | Bot opens a support ticket | `ticket_id`, `phone`, `subject`, `priority` |
| `lead.captured` | Bot saves a customer lead | `ticket_id`, `phone`, `name`, `email` |

### Verifying webhook signatures

```dart
import 'package:achek/achek.dart';

final helper = AchekWebhookHelper(Platform.environment['ACHEK_WEBHOOK_SECRET']!);

// In your shelf / dart_frog / etc. handler:
final body = await request.readAsString();
final sig  = request.headers['x-achek-signature'] ?? '';

if (!helper.verify(sig, body)) {
  return Response(400, body: 'Invalid signature');
}

final event = helper.parse(body);

switch (event.event) {
  case 'handoff.requested':
    // Notify your support team
    break;
  case 'lead.captured':
    final phone = event['phone'];
    final name  = event['name'];
    // → sync to your backend, CRM, etc.
    break;
  case 'spam.quarantine':
    // Log for monitoring
    break;
}

return Response.ok('');
```

---

## Error Handling

```dart
try {
  await client.otp.send('+2348012345678');
} on AchekException catch (e) {
  print('Error ${e.statusCode}: ${e.message}');
  print('Rate limit? ${e.isRateLimit}');
  print('Server error? ${e.isServerError}');
}
```

---

## Configuration

```dart
final client = AchekClient(
  apiKey:       'your_api_key',
  baseUrl:      'https://api.achek.com.ng',       // override if self-hosted
  timeout:      const Duration(seconds: 15),       // default: 15 s
  maxAttempts:  3,                                  // total tries incl. first (default: 3)
  initialDelay: const Duration(milliseconds: 500), // first retry: 500 ms, then 1 000, 2 000…
);
```

---

## API Reference

| Module | Method | Description |
|---|---|---|
| `otp` | `send(phone, {...})` | Send WhatsApp OTP |
| `otp` | `verify(requestId, code)` | Verify OTP code |
| `messaging` | `sendMessage(phone, message)` | Send WhatsApp message |
| `messaging` | `sendBroadcast(phones, message)` | Broadcast via WhatsApp |
| `telegram` | `sendOtp(chatId, {appName})` | Send Telegram OTP |
| `telegram` | `sendMessage(chatId, message)` | Send Telegram message |
| `telegram` | `sendBroadcast(chatIds, message)` | Broadcast via Telegram |
| `tickets` | `create({phoneNumber, subject, ...})` | Create support ticket |
| `tickets` | `list({status?, limit?})` | List tickets |
| `tickets` | `get(ticketId)` | Get ticket by ID |
| `tickets` | `update(ticketId, {...})` | Update status/priority |
| `tickets` | `resolve(ticketId, {message?})` | Resolve and notify customer |
| `AchekWebhookHelper` | `verify(sig, payload)` | Verify HMAC-SHA256 signature |
| `AchekWebhookHelper` | `parse(payload)` | Parse raw webhook payload |

---

## Links

- Website: [achek.com.ng](https://achek.com.ng)
- Dashboard: [achek.com.ng/dashboard](https://achek.com.ng/dashboard)
- Docs: [achek.com.ng/docs](https://achek.com.ng/docs)
- Issues: [github.com/CalebDevX/achek-dart/issues](https://github.com/CalebDevX/achek-dart/issues)

## License

MIT — see [LICENSE](LICENSE)
