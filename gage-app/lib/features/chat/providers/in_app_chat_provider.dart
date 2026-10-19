import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/features/chat/domain/chat_message.dart';

class InAppChatProvider with ChangeNotifier {
  final Map<String, List<ChatMessage>> _messagesByOrder = {};

  InAppChatProvider() {
    _seedInitialConversations();
  }

  void _seedInitialConversations() {
    // Seed initial mock conversations for active orders
    const orderId = 'ORD-88219';
    _messagesByOrder[orderId] = [
      ChatMessage(
        id: 'msg-01',
        orderId: orderId,
        senderId: 'usr-cust-01',
        senderRole: 'customer',
        senderName: 'Siti Rahmawati',
        text: 'Halo mas, tolong sambalnya agak banyak yaa. Makasih!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        status: 'read',
      ),
      ChatMessage(
        id: 'msg-02',
        orderId: orderId,
        senderId: 'mch-dimsum-01',
        senderRole: 'merchant',
        senderName: 'Dimsum Sewu Mas Agus',
        text: 'Siap kak Siti, sambal cocol ekstra sudah kami siapkan di pouch terpisah.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        status: 'read',
      ),
      ChatMessage(
        id: 'msg-03',
        orderId: orderId,
        senderId: 'drv-01',
        senderRole: 'driver',
        senderName: 'Syamsul Maarif (Driver)',
        text: 'Siap kak, saya sudah di resto menunggu makanan selesai dikemas ya.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        status: 'read',
      ),
    ];
  }

  List<ChatMessage> getMessages(String orderId) {
    return _messagesByOrder[orderId] ?? [];
  }

  void sendMessage({
    required String orderId,
    required String senderId,
    required String senderRole,
    required String senderName,
    required String text,
  }) {
    if (text.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    final newMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      text: text.trim(),
      timestamp: DateTime.now(),
      status: 'delivered',
    );

    _messagesByOrder.putIfAbsent(orderId, () => []).add(newMsg);
    notifyListeners();
  }
}
