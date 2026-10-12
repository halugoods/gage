import 'package:flutter/foundation.dart';

/// Model item keranjang belanja multi-merchant dan multi-menu (Food, Shop, Tani)
class CartItem {
  final String id;
  final String name;
  final int price;
  int quantity;
  final String storeId;
  final String storeName;
  final String category;
  final String image;
  String? note;
  /// Menu asal barang ('food' | 'shop' | 'tani')
  final String menuOrigin;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.storeId,
    required this.storeName,
    this.category = '',
    this.image = '',
    this.note,
    this.menuOrigin = 'shop',
  });

  /// Total harga untuk item ini (harga satuan * kuantitas)
  int get totalPrice => price * quantity;

  CartItem copyWith({
    String? id,
    String? name,
    int? price,
    int? quantity,
    String? storeId,
    String? storeName,
    String? category,
    String? image,
    String? note,
    String? menuOrigin,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      category: category ?? this.category,
      image: image ?? this.image,
      note: note ?? this.note,
      menuOrigin: menuOrigin ?? this.menuOrigin,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'storeId': storeId,
    'storeName': storeName,
    'category': category,
    'image': image,
    'note': note,
    'menuOrigin': menuOrigin,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: (json['id'] ?? json['menu_id']) as String? ?? '',
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toInt() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    storeId: (json['storeId'] ?? json['merchant_id'] ?? json['store_id']) as String? ?? '',
    storeName: (json['storeName'] ?? json['merchant_name'] ?? json['store_name']) as String? ?? '',
    category: json['category'] as String? ?? '',
    image: (json['image'] ?? json['imageUrl'] ?? json['image_url']) as String? ?? '',
    note: (json['note'] ?? json['notes']) as String?,
    menuOrigin: (json['menuOrigin'] ?? json['serviceType'] ?? json['service_type'] ?? json['menu_origin']) as String? ?? 'shop',
  );
}

/// Service keranjang belanja multi-merchant untuk GAGE
/// Mendukung belanja di lebih dari 1 merchant (hingga 3 toko) lintas menu (Food, Shop, Tani).
class MultiMerchantCartService extends ChangeNotifier {
  static final MultiMerchantCartService _instance = MultiMerchantCartService._internal();
  factory MultiMerchantCartService() => _instance;
  static MultiMerchantCartService get instance => _instance;
  MultiMerchantCartService._internal();

  /// Batas maksimal merchant berbeda dalam satu order lintas menu
  static const int maxMerchants = 3;

  /// Pesan error / status terakhir jika penambahan gagal
  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Data keranjang belanja dikelompokkan berdasarkan `storeId`
  final Map<String, List<CartItem>> _itemsByStore = {};

  /// Getter unmodifiable map keranjang belanja per store
  Map<String, List<CartItem>> get itemsByStore => _itemsByStore;

  /// Seluruh list item tanpa dikelompokkan
  List<CartItem> get allItems => _itemsByStore.values.expand((items) => items).toList();

  /// Total jumlah seluruh barang di keranjang
  int get totalItemCount {
    int count = 0;
    for (final items in _itemsByStore.values) {
      for (final item in items) {
        count += item.quantity;
      }
    }
    return count;
  }

  /// Subtotal harga seluruh barang di keranjang
  int get totalItemsPrice {
    int total = 0;
    for (final items in _itemsByStore.values) {
      for (final item in items) {
        total += item.totalPrice;
      }
    }
    return total;
  }

  /// Jumlah merchant unik yang ada di keranjang
  int get merchantCount => _itemsByStore.keys.length;

  /// Daftar ID merchant unik di keranjang
  List<String> get uniqueStoreIds => _itemsByStore.keys.toList();

  /// Daftar nama toko unik di keranjang
  List<String> get uniqueStoreNames {
    final names = <String>[];
    for (final items in _itemsByStore.values) {
      if (items.isNotEmpty) {
        final name = items.first.storeName;
        if (!names.contains(name)) {
          names.add(name);
        }
      }
    }
    return names;
  }

  /// Daftar menu yang ada di cart (misal ['food', 'tani', 'shop'])
  List<String> get activeMenuOrigins {
    final origins = <String>{};
    for (final items in _itemsByStore.values) {
      for (final item in items) {
        if (item.menuOrigin.isNotEmpty) {
          origins.add(item.menuOrigin);
        }
      }
    }
    return origins.toList();
  }

  /// Status apakah ada belanja lintas menu di keranjang (misal Food + Shop)
  bool get isCrossMenu => activeMenuOrigins.length > 1;

  /// Cek apakah suatu menu origin tertentu ada dalam keranjang
  bool hasMenuOrigin(String origin) => activeMenuOrigins.contains(origin);

  /// Status apakah keranjang kosong
  bool get isEmpty => _itemsByStore.isEmpty;

  /// Status apakah keranjang ada isinya
  bool get isNotEmpty => _itemsByStore.isNotEmpty;

  /// Ambil list item untuk toko tertentu
  List<CartItem> getItemsForStore(String storeId) {
    return List<CartItem>.unmodifiable(_itemsByStore[storeId] ?? const []);
  }

  /// Subtotal belanja untuk toko tertentu
  int getStoreSubtotal(String storeId) {
    final items = _itemsByStore[storeId];
    if (items == null) return 0;
    return items.fold<int>(0, (sum, item) => sum + item.totalPrice);
  }

  /// Cek kuantitas item spesifik di keranjang
  int getItemQuantity(String storeId, String itemId) {
    final items = _itemsByStore[storeId];
    if (items == null) return 0;
    final item = items.cast<CartItem?>().firstWhere(
      (i) => i?.id == itemId,
      orElse: () => null,
    );
    return item?.quantity ?? 0;
  }

  /// Menambahkan item ke keranjang belanja lintas menu & merchant.
  /// Jika toko berbeda sudah mencapai 3 dan item dari toko baru mau ditambah,
  /// mengembalikan `false` dan mencatat pesan limit 3 toko di `lastErrorMessage`.
  bool addItem(CartItem item) {
    if (!_itemsByStore.containsKey(item.storeId)) {
      if (_itemsByStore.keys.length >= maxMerchants) {
        _lastErrorMessage = 'Maksimal $maxMerchants toko berbeda dalam satu keranjang belanja.';
        debugPrint('[MultiMerchantCart] Limit reached: $_lastErrorMessage');
        return false;
      }
      _lastErrorMessage = null;
      _itemsByStore[item.storeId] = [item.copyWith()];
    } else {
      _lastErrorMessage = null;
      final storeItems = _itemsByStore[item.storeId]!;
      final idx = storeItems.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        storeItems[idx].quantity += item.quantity;
        if (item.note != null && item.note!.trim().isNotEmpty) {
          storeItems[idx].note = item.note;
        }
      } else {
        storeItems.add(item.copyWith());
      }
    }
    notifyListeners();
    return true;
  }

  /// Menambahkan item atau melempar exception jika kuota merchant penuh
  void addItemOrThrow(CartItem item) {
    final success = addItem(item);
    if (!success) {
      throw StateError(_lastErrorMessage ?? 'Maksimal $maxMerchants toko berbeda dalam satu keranjang.');
    }
  }

  /// Menghapus item dari keranjang berdasarkan storeId dan itemId
  void removeItem(String storeId, String itemId) {
    if (_itemsByStore.containsKey(storeId)) {
      _itemsByStore[storeId]!.removeWhere((i) => i.id == itemId);
      if (_itemsByStore[storeId]!.isEmpty) {
        _itemsByStore.remove(storeId);
      }
      notifyListeners();
    }
  }

  /// Update kuantitas item
  void updateQuantity(String storeId, String itemId, int quantity) {
    if (!_itemsByStore.containsKey(storeId)) return;
    if (quantity <= 0) {
      removeItem(storeId, itemId);
      return;
    }
    final storeItems = _itemsByStore[storeId]!;
    final idx = storeItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      storeItems[idx].quantity = quantity;
      notifyListeners();
    }
  }

  /// Update catatan untuk item
  void updateNote(String storeId, String itemId, String note) {
    if (!_itemsByStore.containsKey(storeId)) return;
    final storeItems = _itemsByStore[storeId]!;
    final idx = storeItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      storeItems[idx].note = note;
      notifyListeners();
    }
  }

  /// Mengosongkan seluruh item dari toko tertentu
  void clearStore(String storeId) {
    if (_itemsByStore.containsKey(storeId)) {
      _itemsByStore.remove(storeId);
      notifyListeners();
    }
  }

  /// Mengosongkan seluruh keranjang belanja
  void clearCart() {
    _itemsByStore.clear();
    _lastErrorMessage = null;
    notifyListeners();
  }

  /// Ambil seluruh item berdasarkan menu origin (misal: 'food', 'shop', 'tani')
  List<CartItem> getItemsByMenuOrigin(String menuOrigin) {
    return allItems.where((i) => i.menuOrigin == menuOrigin).toList();
  }

  /// Subtotal belanja untuk menu origin tertentu
  int getMenuSubtotal(String menuOrigin) {
    return allItems
        .where((i) => i.menuOrigin == menuOrigin)
        .fold<int>(0, (sum, item) => sum + item.totalPrice);
  }
}
