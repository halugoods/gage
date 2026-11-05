class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderRole; // 'customer' | 'driver' | 'merchant' | 'admin'
  final String senderName;
  final String text;
  final String? mediaUrl;
  final String messageType; // 'text' | 'image' | 'product' | 'voice'
  final String? productName;
  final int? productPrice;
  final String? productImage;
  final int? voiceDurationSeconds;
  final DateTime timestamp;
  final String status; // 'sending' | 'sent' | 'delivered' | 'read'

  const ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    this.mediaUrl,
    this.messageType = 'text',
    this.productName,
    this.productPrice,
    this.productImage,
    this.voiceDurationSeconds,
    required this.timestamp,
    this.status = 'sent',
  });

  bool get isFromDriver => senderRole == 'driver';
  bool get isFromCustomer => senderRole == 'customer';
  bool get isFromMerchant => senderRole == 'merchant';
  bool get isFromAdmin => senderRole == 'admin';
  bool get isImage => messageType == 'image' || (mediaUrl != null && mediaUrl!.isNotEmpty);
  bool get isProduct => messageType == 'product' || productName != null;
  bool get isVoice => messageType == 'voice';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'text': text,
      'mediaUrl': mediaUrl,
      'messageType': messageType,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'voiceDurationSeconds': voiceDurationSeconds,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderRole: json['senderRole'] as String? ?? 'customer',
      senderName: json['senderName'] as String? ?? 'Pengguna',
      text: json['text'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String?,
      messageType: json['messageType'] as String? ?? 'text',
      productName: json['productName'] as String?,
      productPrice: json['productPrice'] as int?,
      productImage: json['productImage'] as String?,
      voiceDurationSeconds: json['voiceDurationSeconds'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      status: json['status'] as String? ?? 'sent',
    );
  }
}
