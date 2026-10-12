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
        return 'Pesanan Diterima Resto';
      case 'COOKING':
        return 'Dapur Menyiapkan Pesanan';
      case 'READY_FOR_PICKUP':
        return 'Makanan Siap Dijemput';
      case 'ON_DELIVERY':
        return 'Driver Sedang Mengantar';
      case 'COMPLETED':
        return 'Pesanan Selesai';
      case 'CANCELLED':
        return 'Pesanan Dibatalkan';
      default:
        return 'Sedang Diproses';
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((i) => OrderItemModel.fromJson(i)).toList();
    }

    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '#GAGE-ORD',
      userId: json['user_id'] ?? '',
      merchantId: json['merchant_id'] ?? '',
      merchantName: json['merchant_name'] ?? 'Dimsum Sewu by Halu Goods',
      merchantAddress: json['merchant_address'] ?? 'Kecamatan',
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

  const OrderItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.notes,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0) as int,
      quantity: (json['quantity'] ?? 1) as int,
      subtotal: (json['subtotal'] ?? 0) as int,
      notes: json['notes'],
    );
  }
}
