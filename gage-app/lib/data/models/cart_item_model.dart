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
  final String serviceType; // 'food', 'shop', 'tani'

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
  });

  int get subtotal => price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      menuId: json['menu_id'] ?? json['id'] ?? '',
      merchantId: json['merchant_id'] ?? '',
      merchantName: json['merchant_name'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? json['gage_price'] ?? 0) as int,
      quantity: (json['quantity'] ?? 1) as int,
      notes: json['notes'],
      category: json['category'] ?? 'Makanan',
      imageUrl: json['image_url'],
      serviceType: json['service_type'] ?? 'food',
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
    };
  }
}
