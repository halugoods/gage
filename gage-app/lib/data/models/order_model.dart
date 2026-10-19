class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final String merchantId;
  final String merchantName;
  final String merchantAddress;
  final String? merchantPhone;
  final String? driverName;
  final String? driverPlate;
  final String? driverPhone;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final int totalAmount;
  final int itemsSubtotal;
  final int shippingFee;
  final int shippingDiscount;
  final int adminFee;
  final int driverTip;
  final String deliveryAddress;
  final double distanceKm;
  final String trackingToken;
  final String? qrisString;
  final List<OrderItemModel> items;
  final int createdAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.merchantId,
    required this.merchantName,
    required this.merchantAddress,
    this.merchantPhone,
    this.driverName,
    this.driverPlate,
    this.driverPhone,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.itemsSubtotal,
    required this.shippingFee,
    required this.shippingDiscount,
    required this.adminFee,
    this.driverTip = 0,
    required this.deliveryAddress,
    required this.distanceKm,
    required this.trackingToken,
    this.qrisString,
    this.items = const [],
    required this.createdAt,
  });

  bool get isActive => !['COMPLETED', 'CANCELLED'].contains(status);

  String get statusLabel {
    switch (status) {
      case 'PAYMENT_PENDING':
        return 'Menunggu Pembayaran';
      case 'PAID':
        return 'Pesanan Diterima';
      case 'COOKING':
        return 'Sedang Disiapkan';
      case 'READY_FOR_PICKUP':
        return 'Siap Dijemput';
      case 'ON_DELIVERY':
        return 'Sedang Diantar';
      case 'COMPLETED':
        return 'Pesanan Selesai';
      case 'CANCELLED':
        return 'Pesanan Dibatalkan';
      default:
        return 'Sedang Diproses';
    }
  }

  List<String> get merchantNamesList {
    final list = <String>[];
    for (final it in items) {
      if (it.merchantName != null && it.merchantName!.isNotEmpty) {
        if (!list.contains(it.merchantName!)) list.add(it.merchantName!);
      }
    }
    if (list.isEmpty && merchantName.isNotEmpty) {
      if (merchantName.contains(',')) {
        list.addAll(merchantName.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
      } else {
        list.add(merchantName);
      }
    }
    return list;
  }

  static String generateUniqueInvoice({
    required String serviceType,
    required String userName,
    DateTime? timestamp,
  }) {
    final time = timestamp ?? DateTime.now();
    final dateStr = '${time.year}${time.month.toString().padLeft(2, '0')}${time.day.toString().padLeft(2, '0')}';
    final userClean = userName.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final userCode = userClean.length >= 4 ? userClean.substring(0, 4) : userClean.padRight(4, 'X');
    final hash = time.millisecondsSinceEpoch.toString().substring(8);
    final sCode = serviceType.toUpperCase();
    return 'INV/GG/$dateStr/$sCode/$userCode-$hash';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((i) => OrderItemModel.fromJson(i)).toList();
    }

    String ordNum = (json['order_number'] as String?) ?? '';
    if (ordNum.isEmpty || ordNum.startsWith('GAGE-') || ordNum.startsWith('#GAGE')) {
      final ts = (json['created_at'] != null && (json['created_at'] as int) > 0)
          ? DateTime.fromMillisecondsSinceEpoch((json['created_at'] as int) * 1000)
          : DateTime.now();
      final digits = ordNum.replaceAll(RegExp(r'[^0-9]'), '');
      final hashSuffix = digits.isNotEmpty ? digits.padLeft(4, '0') : '8821';
      final uId = (json['user_id'] as String?) ?? 'CUST';
      final uClean = uId.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
      final userTag = uClean.length >= 4 ? uClean.substring(0, 4) : 'CUST';
      final dStr = '${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}';
      ordNum = 'INV/GG/$dStr/FD/$userTag-$hashSuffix';
    }

    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: ordNum,
      userId: json['user_id'] ?? '',
      merchantId: json['merchant_id'] ?? '',
      merchantName: json['merchant_name'] ?? 'Lapak Mitra GAGE Pracimantoro',
      merchantAddress: json['merchant_address'] ?? 'Kecamatan Pracimantoro',
      merchantPhone: json['merchant_phone'],
      driverName: json['driver_name'],
      driverPlate: json['driver_plate'],
      driverPhone: json['driver_phone'],
      status: json['status'] ?? 'PAID',
      paymentMethod: json['payment_method'] ?? 'GAGEPAY',
      paymentStatus: json['payment_status'] ?? 'PAID',
      totalAmount: (json['total_amount'] ?? 0) as int,
      itemsSubtotal: (json['items_subtotal'] ?? 0) as int,
      shippingFee: (json['shipping_fee'] ?? 0) as int,
      shippingDiscount: (json['shipping_discount'] ?? 0) as int,
      adminFee: (json['admin_fee'] ?? 1000) as int,
      driverTip: (json['driver_tip'] ?? 0) as int,
      deliveryAddress: json['delivery_address'] ?? 'Alamat Antar',
      distanceKm: ((json['distance_km'] ?? 1.5) as num).toDouble(),
      trackingToken: json['tracking_token'] ?? '',
      qrisString: json['qris_string'],
      items: parsedItems,
      createdAt: (json['created_at'] ?? 0) as int,
    );
  }
}

class OrderItemModel {
  final String id;
  final String name;
  final int price;
  final int quantity;
  final int subtotal;
  final String? notes;
  final String? imageUrl;
  final String? merchantName;

  const OrderItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.notes,
    this.imageUrl,
    this.merchantName,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0) as int,
      quantity: (json['quantity'] ?? 1) as int,
      subtotal: (json['subtotal'] ?? 0) as int,
      notes: json['notes'],
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? json['image'],
      merchantName: json['merchant_name'] ?? json['merchantName'],
    );
  }
}
