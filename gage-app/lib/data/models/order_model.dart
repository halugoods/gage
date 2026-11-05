typedef MerchantOrder = OrderModel;
typedef MerchantOrderItem = OrderItemModel;

class MerchantDriverInfo {
  final String name;
  final String phone;
  final String plateNumber;
  final String pin;
  final String? avatarUrl;

  const MerchantDriverInfo({
    required this.name,
    required this.phone,
    required this.plateNumber,
    required this.pin,
    this.avatarUrl,
  });
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final String merchantId;
  final String merchantName;
  final String merchantAddress;
  final String? merchantPhone;
  final String? customerName;
  final String? customerPhone;
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
  final int? qrisUniqueCode;
  final List<OrderItemModel> items;
  final int createdAt;
  final String? notes;
  final String? cancellationReason;
  final int codAdjustment;
  final int refundAmount;
  final String channel; // 'food' | 'shop'
  final int autoAcceptSecondsRemaining;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.merchantId,
    required this.merchantName,
    required this.merchantAddress,
    this.merchantPhone,
    this.customerName,
    this.customerPhone,
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
    this.qrisUniqueCode,
    this.items = const [],
    required this.createdAt,
    this.notes,
    this.cancellationReason,
    this.codAdjustment = 0,
    this.refundAmount = 0,
    this.channel = 'food',
    this.autoAcceptSecondsRemaining = 180,
  });

  bool get isActive => !['COMPLETED', 'CANCELLED'].contains(status);

  String get stage => status;
  String? get kitchenNote => notes;

  MerchantDriverInfo? get driver => (driverName != null && driverName!.isNotEmpty)
      ? MerchantDriverInfo(
          name: driverName!,
          phone: driverPhone ?? '081234567890',
          plateNumber: driverPlate ?? 'AD 4120 U',
          pin: orderNumber.replaceAll(RegExp(r'[^0-9]'), '').padLeft(4, '0').substring(0, 4),
        )
      : null;

  String get statusLabel {
    switch (status) {
      case 'PAYMENT_PENDING':
        return 'Menunggu Pembayaran';
      case 'NEW':
      case 'PAID':
        return 'Pesanan Baru';
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

  OrderModel copyWith({
    String? status,
    String? paymentStatus,
    int? totalAmount,
    int? itemsSubtotal,
    int? shippingFee,
    int? shippingDiscount,
    int? adminFee,
    int? driverTip,
    List<OrderItemModel>? items,
    String? driverName,
    String? driverPlate,
    String? driverPhone,
    String? customerName,
    String? customerPhone,
    String? notes,
    String? cancellationReason,
    int? codAdjustment,
    int? refundAmount,
    int? autoAcceptSecondsRemaining,
    String? channel,
    int? qrisUniqueCode,
  }) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      userId: userId,
      merchantId: merchantId,
      merchantName: merchantName,
      merchantAddress: merchantAddress,
      merchantPhone: merchantPhone,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      driverName: driverName ?? this.driverName,
      driverPlate: driverPlate ?? this.driverPlate,
      driverPhone: driverPhone ?? this.driverPhone,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      itemsSubtotal: itemsSubtotal ?? this.itemsSubtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      shippingDiscount: shippingDiscount ?? this.shippingDiscount,
      adminFee: adminFee ?? this.adminFee,
      driverTip: driverTip ?? this.driverTip,
      deliveryAddress: deliveryAddress,
      distanceKm: distanceKm,
      trackingToken: trackingToken,
      qrisString: qrisString,
      qrisUniqueCode: qrisUniqueCode ?? this.qrisUniqueCode,
      items: items ?? this.items,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      codAdjustment: codAdjustment ?? this.codAdjustment,
      refundAmount: refundAmount ?? this.refundAmount,
      channel: channel ?? this.channel,
      autoAcceptSecondsRemaining: autoAcceptSecondsRemaining ?? this.autoAcceptSecondsRemaining,
    );
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
      parsedItems = rawItems.map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>)).toList();
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

    final rawStatus = (json['status'] ?? json['stage'] ?? 'PAID').toString().toUpperCase();
    String normalizedStatus = 'NEW';
    if (rawStatus == 'PAID' || rawStatus == 'NEW' || rawStatus == 'PENDING') {
      normalizedStatus = 'NEW';
    } else if (rawStatus == 'COOKING' || rawStatus == 'PREPARING') {
      normalizedStatus = 'COOKING';
    } else if (rawStatus == 'READY_FOR_PICKUP' || rawStatus == 'READY') {
      normalizedStatus = 'READY_FOR_PICKUP';
    } else if (rawStatus == 'ON_DELIVERY') {
      normalizedStatus = 'ON_DELIVERY';
    } else if (rawStatus == 'COMPLETED' || rawStatus == 'DELIVERED') {
      normalizedStatus = 'COMPLETED';
    } else if (rawStatus == 'CANCELLED' || rawStatus == 'REJECTED') {
      normalizedStatus = 'CANCELLED';
    }

    final channelStr = (json['service_type'] ?? json['channel'] ?? 'food').toString().toLowerCase();

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: ordNum,
      userId: json['user_id']?.toString() ?? '',
      merchantId: json['merchant_id']?.toString() ?? '',
      merchantName: json['merchant_name']?.toString() ?? 'Dimsum Sewu Pracimantoro',
      merchantAddress: json['merchant_address']?.toString() ?? 'Pracimantoro, Wonogiri',
      merchantPhone: json['merchant_phone']?.toString(),
      customerName: json['customer_name']?.toString() ?? 'Pelanggan GAGE',
      customerPhone: json['customer_phone']?.toString() ?? '081234567890',
      driverName: json['driver_name']?.toString(),
      driverPlate: json['driver_plate']?.toString(),
      driverPhone: json['driver_phone']?.toString(),
      status: normalizedStatus,
      paymentMethod: json['payment_method']?.toString() ?? 'GAGEPAY',
      paymentStatus: json['payment_status']?.toString() ?? 'PAID',
      totalAmount: (json['total_amount'] ?? 0) is num ? (json['total_amount'] ?? 0).toInt() : int.tryParse(json['total_amount'].toString()) ?? 0,
      itemsSubtotal: (json['items_subtotal'] ?? json['subtotal'] ?? 0) is num ? (json['items_subtotal'] ?? json['subtotal'] ?? 0).toInt() : int.tryParse((json['items_subtotal'] ?? json['subtotal'] ?? 0).toString()) ?? 0,
      shippingFee: (json['shipping_fee'] ?? 0) is num ? (json['shipping_fee'] ?? 0).toInt() : int.tryParse(json['shipping_fee'].toString()) ?? 0,
      shippingDiscount: (json['shipping_discount'] ?? 0) is num ? (json['shipping_discount'] ?? 0).toInt() : int.tryParse(json['shipping_discount'].toString()) ?? 0,
      adminFee: (json['admin_fee'] ?? 1000) is num ? (json['admin_fee'] ?? 1000).toInt() : int.tryParse(json['admin_fee'].toString()) ?? 1000,
      driverTip: (json['driver_tip'] ?? 0) is num ? (json['driver_tip'] ?? 0).toInt() : int.tryParse(json['driver_tip'].toString()) ?? 0,
      deliveryAddress: json['delivery_address']?.toString() ?? 'Alamat Antar',
      distanceKm: ((json['distance_km'] ?? 1.5) as num).toDouble(),
      trackingToken: json['tracking_token']?.toString() ?? '',
      qrisString: json['qris_string']?.toString(),
      qrisUniqueCode: (json['qris_unique_code'] as num?)?.toInt(),
      items: parsedItems,
      createdAt: (json['created_at'] ?? 0) is num ? (json['created_at'] ?? 0).toInt() : int.tryParse(json['created_at'].toString()) ?? 0,
      notes: json['notes']?.toString() ?? json['kitchen_note']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      codAdjustment: (json['cod_adjustment'] ?? 0) is num ? (json['cod_adjustment'] ?? 0).toInt() : int.tryParse(json['cod_adjustment'].toString()) ?? 0,
      refundAmount: (json['refund_amount'] ?? 0) is num ? (json['refund_amount'] ?? 0).toInt() : int.tryParse(json['refund_amount'].toString()) ?? 0,
      channel: channelStr.contains('shop') || channelStr.contains('mart') ? 'shop' : 'food',
      autoAcceptSecondsRemaining: (json['auto_accept_seconds'] ?? 180) is num ? (json['auto_accept_seconds'] ?? 180).toInt() : 180,
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
  final bool isPicked;

  const OrderItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.notes,
    this.imageUrl,
    this.merchantName,
    this.isPicked = true,
  });

  String? get variant => notes;

  OrderItemModel copyWith({
    String? id,
    String? name,
    int? price,
    int? quantity,
    int? subtotal,
    String? notes,
    String? imageUrl,
    String? merchantName,
    bool? isPicked,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      merchantName: merchantName ?? this.merchantName,
      isPicked: isPicked ?? this.isPicked,
    );
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] ?? 1) is num ? (json['quantity'] ?? 1).toInt() : int.tryParse(json['quantity'].toString()) ?? 1;
    final prc = (json['price'] ?? 0) is num ? (json['price'] ?? 0).toInt() : int.tryParse(json['price'].toString()) ?? 0;
    final sub = (json['subtotal'] ?? (prc * qty)) is num ? (json['subtotal'] ?? (prc * qty)).toInt() : int.tryParse(json['subtotal'].toString()) ?? (prc * qty);

    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Item Pesanan',
      price: prc,
      quantity: qty,
      subtotal: sub,
      notes: json['notes']?.toString() ?? json['variant']?.toString(),
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? json['image'])?.toString(),
      merchantName: (json['merchant_name'] ?? json['merchantName'])?.toString(),
      isPicked: json['is_picked'] == true || json['is_picked'] == 1 || json['is_picked'] == null,
    );
  }
}
