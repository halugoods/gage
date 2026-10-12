import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  String? _merchantId;
  String? _merchantName;
  double _distanceKm = 1.8;
  String _deliveryAddress = 'Jl. Wates Km 3, Kadipiro, Kasihan';
  String? _promoCode;
  String _paymentMethod = 'GAGEPAY'; // 'GAGEPAY', 'QRIS', 'CASH_COD'

  List<CartItemModel> get items => List.unmodifiable(_items);
  List<String> get merchantIds => _items.map((i) => i.merchantId).where((id) => id.isNotEmpty).toSet().toList();
  int get merchantCount => merchantIds.isEmpty ? 1 : merchantIds.length;
  List<String> get merchantNames => _items.map((i) => i.merchantName).where((name) => name.isNotEmpty).toSet().toList();
  
  String? get merchantId => _merchantId ?? (merchantIds.isNotEmpty ? merchantIds.first : null);
  String? get merchantName {
    if (merchantNames.isEmpty) return _merchantName;
    if (merchantNames.length == 1) return merchantNames.first;
    return '${merchantNames.length} Merchant (${merchantNames.join(", ")})';
  }
  double get distanceKm => _distanceKm;
  String get deliveryAddress => _deliveryAddress;
  String? get promoCode => _promoCode;
  String get paymentMethod => _paymentMethod;

  CartProvider() {
    _loadSavedCart();
  }

  // Muat keranjang tersimpan dari disk
  Future<void> _loadSavedCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('gage_saved_cart');
      if (cartJson != null) {
        final Map<String, dynamic> data = jsonDecode(cartJson);
        _merchantId = data['merchant_id'];
        _merchantName = data['merchant_name'];
        _distanceKm = (data['distance_km'] ?? 1.8).toDouble();
        _deliveryAddress = data['delivery_address'] ?? 'Jl. Wates Km 3, Kadipiro';
        _promoCode = data['promo_code'];
        final rawList = data['items'];
        if (rawList is List) {
          _items.clear();
          for (var i in rawList) {
            _items.add(CartItemModel.fromJson(i));
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved cart: $e');
    }
  }

  // Simpan keranjang ke disk
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'merchant_id': _merchantId,
        'merchant_name': _merchantName,
        'distance_km': _distanceKm,
        'delivery_address': _deliveryAddress,
        'promo_code': _promoCode,
        'items': _items.map((i) => i.toJson()).toList(),
      };
      await prefs.setString('gage_saved_cart', jsonEncode(data));
    } catch (_) {}
  }

  // Grouping item per Merchant untuk tampilan checkout & ringkasan lintas menu
  Map<String, List<CartItemModel>> get itemsByMerchant {
    final map = <String, List<CartItemModel>>{};
    for (final item in _items) {
      map.putIfAbsent(item.merchantId, () => []).add(item);
    }
    return map;
  }

  int getItemQuantity(String menuId) {
    final idx = _items.indexWhere((i) => i.menuId == menuId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }

  // Tambah item ke keranjang (Mendukung Universal Multi-Merchant: Food + Shop + Tani)
  bool addItem(CartItemModel newItem, {bool forceReplace = false}) {
    if (forceReplace) {
      _items.clear();
    } else {
      // Cek batas maksimal 3 merchant berbeda dalam 1 pengantaran
      final currentMerchants = merchantIds;
      if (!currentMerchants.contains(newItem.merchantId) && currentMerchants.length >= 3) {
        return false; // Maksimal 3 merchant berbeda dalam satu kali jalan
      }
    }

    _merchantId = newItem.merchantId;
    _merchantName = newItem.merchantName;

    final existingIdx = _items.indexWhere((i) => i.menuId == newItem.menuId);
    if (existingIdx >= 0) {
      _items[existingIdx].quantity += newItem.quantity;
      if (newItem.notes != null && newItem.notes!.isNotEmpty) {
        _items[existingIdx].notes = newItem.notes;
      }
    } else {
      _items.add(newItem);
    }

    _saveCart();
    notifyListeners();
    return true;
  }

  void updateQuantity(String menuId, int delta) {
    final idx = _items.indexWhere((i) => i.menuId == menuId);
    if (idx >= 0) {
      final newQty = _items[idx].quantity + delta;
      if (newQty <= 0) {
        _items.removeAt(idx);
        if (_items.isEmpty) {
          _merchantId = null;
          _merchantName = null;
        }
      } else {
        _items[idx].quantity = newQty;
      }
      _saveCart();
      notifyListeners();
    }
  }

  void setNotes(String menuId, String notes) {
    final idx = _items.indexWhere((i) => i.menuId == menuId);
    if (idx >= 0) {
      _items[idx].notes = notes;
      _saveCart();
      notifyListeners();
    }
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setDeliveryAddress(String address, double distance) {
    _deliveryAddress = address;
    _distanceKm = distance;
    _saveCart();
    notifyListeners();
  }

  String? _foodPromoCode;
  int _foodPromoDiscount = 0;
  String? _deliveryPromoCode;
  int _deliveryPromoDiscount = 0;

  String? get foodPromoCode => _foodPromoCode;
  int get foodPromoDiscount => _foodPromoDiscount;
  String? get deliveryPromoCode => _deliveryPromoCode;
  int get deliveryPromoDiscount => _deliveryPromoDiscount;

  void setFoodPromo(String? code, int discount) {
    _foodPromoCode = code?.trim().toUpperCase();
    _foodPromoDiscount = discount;
    _saveCart();
    notifyListeners();
  }

  void setDeliveryPromo(String? code, int discount) {
    _deliveryPromoCode = code?.trim().toUpperCase();
    _deliveryPromoDiscount = discount;
    _saveCart();
    notifyListeners();
  }

  void removeFoodPromo() {
    _foodPromoCode = null;
    _foodPromoDiscount = 0;
    _saveCart();
    notifyListeners();
  }

  void removeDeliveryPromo() {
    _deliveryPromoCode = null;
    _deliveryPromoDiscount = 0;
    _saveCart();
    notifyListeners();
  }

  void setPromoCode(String? code) {
    final c = code?.trim().toUpperCase();
    _promoCode = c;
    if (c == 'DISKON50' || c == 'HEMATAJI' || c == 'KULINER10') {
      setFoodPromo(c, c == 'DISKON50' ? (subtotal * 0.5).round().clamp(0, 15000) : (c == 'HEMATAJI' ? 8000 : 10000));
    } else if (c == 'ONGKIRGRATIS' || c == 'ONGKIR5RB' || c == 'GAGERATIH') {
      setDeliveryPromo(c, c == 'ONGKIRGRATIS' ? 7000 : (c == 'ONGKIR5RB' ? 5000 : 2000));
    }
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _merchantId = null;
    _merchantName = null;
    _promoCode = null;
    _foodPromoCode = null;
    _foodPromoDiscount = 0;
    _deliveryPromoCode = null;
    _deliveryPromoDiscount = 0;
    _saveCart();
    notifyListeners();
  }

  // ── Hitungan Keuangan Otomatis Dual-Tier Vouchers ──
  int get totalItemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  int get subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);

  int get totalFoodDiscount => _foodPromoDiscount.clamp(0, subtotal);

  // Ongkir Customer dengan pembulatan kelipatan Rp 500 & kompensasi multi-merchant stop
  int get rawShippingFee => GagePricingService.calculateCustomerShippingFee(
        distanceKm: _distanceKm,
        merchantCount: merchantCount,
      );

  int get totalShippingDiscount => _deliveryPromoDiscount.clamp(0, rawShippingFee);

  int get finalShippingFee => (rawShippingFee - totalShippingDiscount).clamp(0, 50000);

  // Biaya Layanan & Penanganan per Merchant (Cashless: 1rb x toko | COD: 3rb + 1rb x toko tambahan)
  int get adminFee => GagePricingService.calculateAdminFee(
        paymentMethod: _paymentMethod,
        merchantCount: merchantCount,
      );

  int get grandTotal => (subtotal - totalFoodDiscount).clamp(0, 99999999) + finalShippingFee + adminFee;
}
