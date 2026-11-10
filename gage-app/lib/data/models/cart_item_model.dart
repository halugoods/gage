// [PRODUCTION_CONTRACT: Merchant Portal Variant & Add-on Synchronization]
// Terhubung ke konfigurasi varian & topping yang ditentukan merchant pada Merchant Portal
class CartItemModel {
  final String menuId;
  final String merchantId;
  final String merchantName;
  final String name;
  final int price;
  int quantity;
  String? notes;
  final String category;
  final String? imageUrl;
  final String serviceType; // 'food', 'shop', 'farm', 'build'
  final List<String> selectedVariants;
  final int variantPrice;

  CartItemModel({
    required this.menuId,
    required this.merchantId,
    required this.merchantName,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.notes,
    this.category = 'Makanan',
    this.imageUrl,
    this.serviceType = 'food',
    this.selectedVariants = const [],
    this.variantPrice = 0,
  });

  int get subtotal => (price + variantPrice) * quantity;

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(cleaned) ?? fallback;
    }
    return fallback;
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      menuId: (json['menu_id'] ?? json['id'] ?? '').toString(),
      merchantId: (json['merchant_id'] ?? '').toString(),
      merchantName: (json['merchant_name'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: _parseInt(json['price'] ?? json['gage_price'], 0),
      quantity: _parseInt(json['quantity'], 1),
      notes: json['notes']?.toString(),
      category: (json['category'] ?? 'Makanan').toString(),
      imageUrl: json['image_url']?.toString(),
      serviceType: () {
        final raw = (json['service_type'] ?? json['serviceType'] ?? 'food').toString().toLowerCase();
        if (raw == 'tani') return 'farm';
        return raw;
      }(),
      selectedVariants: (json['selected_variants'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      variantPrice: _parseInt(json['variant_price'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_id': menuId,
      'merchant_id': merchantId,
      'merchant_name': merchantName,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
      'category': category,
      'image_url': imageUrl,
      'service_type': serviceType,
      'selected_variants': selectedVariants,
      'variant_price': variantPrice,
    };
  }
}
