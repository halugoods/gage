import 'dart:convert';

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
  final String? merchantAvatar;
  final String? customerName;
  final String? customerPhone;
  final String? customerAvatar;
  final String? driverName;
  final String? driverPlate;
  final String? driverPhone;
  final String? driverAvatar;
  final String? driverVehicle;
  final double? driverRating;
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
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
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
  final String serviceType; // 'food' | 'shop' | 'farm' | 'build' | 'ride' | 'car' | 'send'
  final bool isPickup;
  final String deliveryOption;
  final Map<String, dynamic>? packageDetails;
  final int autoAcceptSecondsRemaining;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.merchantId,
    required this.merchantName,
    required this.merchantAddress,
    this.merchantPhone,
    this.merchantAvatar,
    this.customerName,
    this.customerPhone,
    this.customerAvatar,
    this.driverName,
    this.driverPlate,
    this.driverPhone,
    this.driverAvatar,
    this.driverVehicle,
    this.driverRating,
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
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
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
    this.serviceType = 'food',
    this.isPickup = false,
    this.deliveryOption = 'REGULER',
    this.packageDetails,
    this.autoAcceptSecondsRemaining = 180,
  });

  bool get isActive => !['COMPLETED', 'CANCELLED'].contains(status);

  bool get hasAssignedDriver => driverName != null && driverName!.trim().isNotEmpty;

  bool get isTransportService =>
      const {'ride', 'car', 'send'}.contains(serviceType.toLowerCase());

  String get stage => status;
  String? get kitchenNote => notes;

  MerchantDriverInfo? get driver => hasAssignedDriver
      ? MerchantDriverInfo(
          name: driverName!,
          phone: (driverPhone != null && driverPhone!.trim().isNotEmpty)
              ? driverPhone!.trim()
              : '-',
          plateNumber: (driverPlate != null && driverPlate!.trim().isNotEmpty)
              ? driverPlate!.trim()
              : '-',
          pin: orderNumber.replaceAll(RegExp(r'[^0-9]'), '').padLeft(4, '0').substring(0, 4),
          avatarUrl: driverAvatar,
        )
      : null;

  String get statusLabel {
    switch (status) {
      case 'PAYMENT_PENDING':
      case 'PENDING':
        return 'Menunggu Pembayaran';
      case 'NEW':
      case 'PAID':
        return isTransportService
            ? 'Mencari Driver Terdekat'
            : 'Menunggu Konfirmasi Merchant';
      case 'SEARCHING_DRIVER':
        return 'Mencari Driver Terdekat';
      case 'DRIVER_ASSIGNED':
        return isTransportService ? 'Driver Menuju Lokasi Jemput' : 'Driver Menuju Merchant';
      case 'AT_MERCHANT':
        return isTransportService ? 'Driver Tiba di Titik Jemput' : 'Driver di Lokasi Merchant';
      case 'COOKING':
        return serviceType.toLowerCase() == 'food'
            ? 'Sedang Disiapkan Dapur'
            : 'Sedang Disiapkan Toko';
      case 'READY_FOR_PICKUP':
        return isPickup ? 'Siap Diambil di Lokasi' : 'Siap Diambil Driver';
      case 'PICKED_UP':
      case 'ON_DELIVERY':
        if (serviceType.toLowerCase() == 'ride' || serviceType.toLowerCase() == 'car') {
          return 'Dalam Perjalanan';
        }
        return 'Sedang Diantar';
      case 'COMPLETED':
        return 'Pesanan Selesai';
      case 'CANCELLED':
        return 'Pesanan Dibatalkan';
      default:
        return 'Sedang Diproses';
    }
  }

  /// Memeriksa apakah pesanan dapat dibatalkan oleh pelanggan secara aman:
  /// - Transport (Ride, Car, Send): dapat dibatalkan sebelum mitra driver menerima
  /// - Merchant (Food, Shop, Farm, Build): dapat dibatalkan sebelum merchant konfirmasi/menyiapkan
  bool get canBeCancelledByCustomer {
    if (status == 'CANCELLED' || status == 'COMPLETED') return false;
    if (isTransportService) {
      if (hasAssignedDriver ||
          status == 'DRIVER_ASSIGNED' ||
          status == 'AT_MERCHANT' ||
          status == 'ON_DELIVERY') {
        return false;
      }
      return status == 'NEW' ||
          status == 'PAID' ||
          status == 'PENDING' ||
          status == 'PAYMENT_PENDING' ||
          status == 'SEARCHING_DRIVER';
    } else {
      if (status == 'COOKING' ||
          status == 'READY_FOR_PICKUP' ||
          status == 'PICKED_UP' ||
          status == 'ON_DELIVERY' ||
          status == 'DRIVER_ASSIGNED') {
        return false;
      }
      return status == 'NEW' ||
          status == 'PAID' ||
          status == 'PENDING' ||
          status == 'PAYMENT_PENDING' ||
          status == 'WAITING_MERCHANT';
    }
  }

  /// Resolves the best merchant/service avatar asset or URL, never leaving store markers empty.
  String resolveMerchantAvatarAsset([String? mName]) {
    if (merchantAvatar != null && merchantAvatar!.trim().isNotEmpty) {
      return merchantAvatar!.trim();
    }
    final svc = serviceType.toLowerCase();
    if (svc == 'ride') return 'assets/icons/ic_ride.png';
    if (svc == 'car') return 'assets/icons/ic_car.png';
    if (svc == 'send') return 'assets/icons/ic_send.png';
    final nameLower = (mName ?? merchantName).toLowerCase();
    if (nameLower.contains('rocket') || nameLower.contains('chicken')) {
      return 'assets/images/resto_rocket_chicken.png';
    } else if (nameLower.contains('titoti') || nameLower.contains('bakso')) {
      return 'assets/images/dish_bakso_urat.png';
    } else if (nameLower.contains('sayur') ||
        nameLower.contains('siti') ||
        nameLower.contains('shop') ||
        nameLower.contains('sembako')) {
      return 'assets/images/prod_beras.png';
    } else if (nameLower.contains('tani') || nameLower.contains('pupuk')) {
      return 'assets/images/prod_pupuk.png';
    } else if (nameLower.contains('ternak') || nameLower.contains('pakan')) {
      return 'assets/images/prod_pakan.png';
    }
    return 'assets/images/resto_dimsum_sewu.png';
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
    String? merchantAvatar,
    String? driverName,
    String? driverPlate,
    String? driverPhone,
    String? driverAvatar,
    String? driverVehicle,
    double? driverRating,
    String? customerName,
    String? customerPhone,
    String? customerAvatar,
    String? notes,
    String? cancellationReason,
    int? codAdjustment,
    int? refundAmount,
    int? autoAcceptSecondsRemaining,
    String? channel,
    String? serviceType,
    bool? isPickup,
    String? deliveryOption,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    double? deliveryLat,
    double? deliveryLng,
    Map<String, dynamic>? packageDetails,
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
      merchantAvatar: merchantAvatar ?? this.merchantAvatar,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      driverName: driverName ?? this.driverName,
      driverPlate: driverPlate ?? this.driverPlate,
      driverPhone: driverPhone ?? this.driverPhone,
      driverAvatar: driverAvatar ?? this.driverAvatar,
      driverVehicle: driverVehicle ?? this.driverVehicle,
      driverRating: driverRating ?? this.driverRating,
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
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
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
      serviceType: serviceType ?? this.serviceType,
      isPickup: isPickup ?? this.isPickup,
      deliveryOption: deliveryOption ?? this.deliveryOption,
      packageDetails: packageDetails ?? this.packageDetails,
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
      final createdAtRaw = json['created_at'];
      final createdAtSec = createdAtRaw is num ? createdAtRaw.toInt() : (createdAtRaw is String ? int.tryParse(createdAtRaw) ?? 0 : 0);
      final ts = createdAtSec > 0 ? DateTime.fromMillisecondsSinceEpoch(createdAtSec * 1000) : DateTime.now();
      final digits = ordNum.replaceAll(RegExp(r'[^0-9]'), '');
      final hashSuffix = digits.isNotEmpty ? digits.padLeft(4, '0') : '8821';
      final uId = (json['user_id'] as String?) ?? 'CUST';
      final uClean = uId.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
      final userTag = uClean.length >= 4 ? uClean.substring(0, 4) : 'CUST';
      final dStr = '${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}';
      ordNum = 'INV/GG/$dStr/FD/$userTag-$hashSuffix';
    }

    final rawStatus = (json['status'] ?? json['stage'] ?? 'PAID').toString().trim().toUpperCase();
    String normalizedStatus;
    switch (rawStatus) {
      case 'PAYMENT_PENDING':
        normalizedStatus = 'PAYMENT_PENDING';
        break;
      case 'PENDING':
        normalizedStatus = 'PENDING';
        break;
      case 'PAID':
        normalizedStatus = 'PAID';
        break;
      case 'NEW':
        normalizedStatus = 'NEW';
        break;
      case 'SEARCHING_DRIVER':
        normalizedStatus = 'SEARCHING_DRIVER';
        break;
      case 'DRIVER_ASSIGNED':
        normalizedStatus = 'DRIVER_ASSIGNED';
        break;
      case 'AT_MERCHANT':
        normalizedStatus = 'AT_MERCHANT';
        break;
      case 'COOKING':
      case 'PREPARING':
        normalizedStatus = 'COOKING';
        break;
      case 'READY_FOR_PICKUP':
      case 'READY':
        normalizedStatus = 'READY_FOR_PICKUP';
        break;
      case 'PICKED_UP':
        normalizedStatus = 'PICKED_UP';
        break;
      case 'ON_DELIVERY':
        normalizedStatus = 'ON_DELIVERY';
        break;
      case 'COMPLETED':
      case 'DELIVERED':
        normalizedStatus = 'COMPLETED';
        break;
      case 'CANCELLED':
      case 'REJECTED':
        normalizedStatus = 'CANCELLED';
        break;
      default:
        normalizedStatus = rawStatus.isEmpty ? 'PAID' : rawStatus;
    }

    final rawService = (json['service_type'] ?? json['channel'] ?? 'food').toString().trim().toLowerCase();
    final orderTypeStr = (json['order_type'] ?? '').toString().trim().toUpperCase();
    final bool isPickupVal = json['is_pickup'] == true ||
        json['is_pickup'] == 1 ||
        orderTypeStr == 'PICKUP' ||
        (json['delivery_option']?.toString().toUpperCase() == 'PICKUP');

    int toInt(dynamic v, [int fallback = 0]) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? fallback;
    double? toDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

    final int fareAmt = toInt(json['fare_amount']);
    final int parsedTotal = toInt(json['total_amount']) > 0
        ? toInt(json['total_amount'])
        : fareAmt;
    final int parsedSubtotal = toInt(json['items_subtotal'] ?? json['subtotal']) > 0
        ? toInt(json['items_subtotal'] ?? json['subtotal'])
        : (const {'ride', 'car', 'send'}.contains(rawService) ? fareAmt : 0);

    Map<String, dynamic>? parsedPkg;
    final rawPkg = json['package_details'] ?? json['package_details_json'];
    if (rawPkg is Map) {
      parsedPkg = Map<String, dynamic>.from(rawPkg);
    } else if (rawPkg is String && rawPkg.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(rawPkg);
        if (decoded is Map) parsedPkg = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: ordNum,
      userId: json['user_id']?.toString() ?? '',
      merchantId: json['merchant_id']?.toString() ?? '',
      merchantName: (json['merchant_name'] ?? '').toString().trim().isNotEmpty
          ? json['merchant_name'].toString()
          : (parsedItems.isNotEmpty && (parsedItems.first.merchantName ?? '').isNotEmpty
              ? parsedItems.first.merchantName!
              : 'Mitra GAGE'),
      merchantAddress: json['merchant_address']?.toString() ?? '',
      merchantPhone: json['merchant_phone']?.toString(),
      merchantAvatar: (json['merchant_avatar'] ?? json['merchantAvatar'])?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      customerAvatar: (json['customer_avatar'] ?? json['customerAvatar'])?.toString(),
      driverName: json['driver_name']?.toString(),
      driverPlate: json['driver_plate']?.toString(),
      driverPhone: json['driver_phone']?.toString(),
      driverAvatar: (json['driver_avatar'] ?? json['driverAvatar'])?.toString(),
      driverVehicle: (json['driver_vehicle'] ?? json['driverVehicle'])?.toString(),
      driverRating: toDouble(json['driver_rating'] ?? json['driverRating']),
      status: normalizedStatus,
      paymentMethod: json['payment_method']?.toString() ?? 'GAGEPAY',
      paymentStatus: json['payment_status']?.toString() ?? 'PAID',
      totalAmount: parsedTotal,
      itemsSubtotal: parsedSubtotal,
      shippingFee: toInt(json['shipping_fee']),
      shippingDiscount: toInt(json['shipping_discount']),
      adminFee: json['admin_fee'] != null ? toInt(json['admin_fee'], 1000) : 1000,
      driverTip: toInt(json['driver_tip']),
      deliveryAddress: (json['delivery_address'] ?? json['destination_address'] ?? '').toString(),
      pickupAddress: json['pickup_address']?.toString(),
      pickupLat: toDouble(json['pickup_lat']),
      pickupLng: toDouble(json['pickup_lng']),
      deliveryLat: toDouble(json['delivery_lat'] ?? json['dest_lat']),
      deliveryLng: toDouble(json['delivery_lng'] ?? json['dest_lng']),
      distanceKm: ((json['distance_km'] ?? 1.5) as num).toDouble(),
      trackingToken: json['tracking_token']?.toString() ?? '',
      qrisString: json['qris_string']?.toString(),
      qrisUniqueCode: (json['qris_unique_code'] as num?)?.toInt(),
      items: parsedItems,
      createdAt: toInt(json['created_at']),
      notes: json['notes']?.toString() ?? json['kitchen_note']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      codAdjustment: toInt(json['cod_adjustment']),
      refundAmount: toInt(json['refund_amount']),
      channel: (rawService.contains('shop') || rawService.contains('mart') || rawService == 'farm' || rawService == 'build')
          ? 'shop'
          : 'food',
      serviceType: rawService.isEmpty ? 'food' : rawService,
      isPickup: isPickupVal,
      deliveryOption: (json['delivery_option'] ?? (isPickupVal ? 'PICKUP' : 'REGULER'))
          .toString()
          .toUpperCase(),
      packageDetails: parsedPkg,
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
