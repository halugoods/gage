import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/data/mock/gage_voucher_data.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  String? _merchantId;
  String? _merchantName;
  double _distanceKm = 1.8;
  String _deliveryAddress = '';
  LatLng? _deliveryLocation;
  String _addressNotes = '';
  String? _promoCode;
  String _paymentMethod = 'GAGEPAY'; // 'GAGEPAY', 'QRIS', 'CASH_COD'
  bool _isPickup = false;
  String _deliveryOption = 'REGULER'; // 'REGULER', 'HEMAT'
  DateTime? _scheduledDeliveryTime;
  String? _groupOrderId;

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
  String get deliveryAddress => _isPickup ? 'Ambil di Toko / Resto Mitra' : _deliveryAddress;
  LatLng? get deliveryLocation => _deliveryLocation;
  bool get hasCustomDeliveryLocation => _deliveryLocation != null;
  String get addressNotes => _addressNotes;
  String? get promoCode => _promoCode;
  String get paymentMethod => _paymentMethod;
  bool get isPickup => _isPickup;
  String get deliveryOption => _deliveryOption;
  DateTime? get scheduledDeliveryTime => _scheduledDeliveryTime;
  String? get groupOrderId => _groupOrderId;

  void setIsPickup(bool value) {
    _isPickup = value;
    if (_autoDeliverySyncActive) {
      syncAutoDeliveryPromo(serviceType: _autoDeliveryServiceOverride, notify: false);
    }
    if (_autoOrderSyncActive) {
      syncAutoOrderPromo(serviceType: _autoDeliveryServiceOverride, notify: false);
    }
    notifyListeners();
  }

  void setAddressNotes(String notes) {
    _addressNotes = notes;
    notifyListeners();
  }

  void setDeliveryOption(String option) {
    _deliveryOption = option;
    notifyListeners();
  }

  void setScheduledDeliveryTime(DateTime? time) {
    _scheduledDeliveryTime = time;
    notifyListeners();
  }

  void setGroupOrderId(String? id) {
    _groupOrderId = id;
    notifyListeners();
  }

  void activateGroupOrder(String roomId, {required String merchantId, required String merchantName}) {
    _groupOrderId = roomId;
    if (!_items.any((i) => i.menuId == 'g-budi-01')) {
      _items.add(
        CartItemModel(
          menuId: 'g-budi-01',
          merchantId: merchantId,
          merchantName: merchantName,
          name: 'Siomay Ayam Original 4 Pcs',
          price: 12000,
          quantity: 1,
          notes: 'Pesanan Budi',
          category: 'Dimsum',
          imageUrl: 'assets/images/dish_dimsum_original.png',
          serviceType: 'food',
        ),
      );
    }
    if (!_items.any((i) => i.menuId == 'g-siti-01')) {
      _items.add(
        CartItemModel(
          menuId: 'g-siti-01',
          merchantId: merchantId,
          merchantName: merchantName,
          name: 'Es Teh Solo Segar Jumbo',
          price: 4000,
          quantity: 1,
          notes: 'Pesanan Siti',
          category: 'Minuman',
          imageUrl: 'assets/images/dish_es_teh.png',
          serviceType: 'food',
        ),
      );
    }
    _saveCart();
    notifyListeners();
  }

  void deactivateGroupOrder() {
    _groupOrderId = null;
    _items.removeWhere((i) => i.menuId.startsWith('g-'));
    _saveCart();
    notifyListeners();
  }

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
        final savedLat = (data['delivery_lat'] as num?)?.toDouble();
        final savedLng = (data['delivery_lng'] as num?)?.toDouble();
        if (savedLat != null && savedLng != null) {
          _deliveryLocation = LatLng(savedLat, savedLng);
        }
        final rawAddr = data['delivery_address']?.toString() ?? '';
        // Clear legacy Yogyakarta placeholder when no coordinate was stored.
        _deliveryAddress = (savedLat == null && rawAddr.contains('Jl. Wates')) ? '' : rawAddr;
        _promoCode = data['promo_code'];
        final rawList = data['items'];
        if (rawList is List) {
          _items.clear();
          for (var i in rawList) {
            _items.add(CartItemModel.fromJson(i));
          }
          _syncToMultiMerchantCartService();
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
        if (_deliveryLocation != null) 'delivery_lat': _deliveryLocation!.latitude,
        if (_deliveryLocation != null) 'delivery_lng': _deliveryLocation!.longitude,
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

  /// Sinkronisasi otomatis ke MultiMerchantCartService (1:1 state mirror)
  void _syncToMultiMerchantCartService() {
    final mmCart = MultiMerchantCartService.instance;
    mmCart.clearCart();
    for (final i in _items) {
      mmCart.addItem(
        CartItem(
          id: i.menuId,
          name: i.name,
          price: i.price,
          quantity: i.quantity,
          storeId: i.merchantId,
          storeName: i.merchantName,
          category: i.category,
          image: i.imageUrl ?? '',
          note: i.notes,
          menuOrigin: i.serviceType,
        ),
      );
    }
  }

  // Tambah item ke keranjang (Mendukung Universal Single-Merchant: Food, Shop, Farm, Build)
  bool addItem(CartItemModel newItem, {bool forceReplace = false}) {
    if (forceReplace) {
      _items.clear();
      MultiMerchantCartService.instance.clearCart();
    } else {
      // Cek aturan Single Merchant: 1 pengantaran = 1 toko
      final currentMerchants = merchantIds;
      if (!currentMerchants.contains(newItem.merchantId) && currentMerchants.isNotEmpty) {
        return false; // 1 pesanan eksklusif untuk 1 merchant
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

    if (forceReplace || _items.length == 1) {
      _deliveryPromoManuallyDismissed = false;
      _isDeliveryPromoManual = false;
      _foodPromoManuallyDismissed = false;
      _isFoodPromoManual = false;
    }
    if (_autoDeliverySyncActive) {
      syncAutoDeliveryPromo(serviceType: _autoDeliveryServiceOverride, notify: false);
    }
    if (_autoOrderSyncActive) {
      syncAutoOrderPromo(serviceType: _autoDeliveryServiceOverride, notify: false);
    }
    _syncToMultiMerchantCartService();
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
          _foodPromoCode = null;
          _foodPromoDiscount = 0;
          _foodPromoManuallyDismissed = false;
          _isFoodPromoManual = false;
          _autoOrderSyncActive = false;
          _deliveryPromoCode = null;
          _deliveryPromoDiscount = 0;
          _deliveryPromoManuallyDismissed = false;
          _isDeliveryPromoManual = false;
          _autoDeliverySyncActive = false;
          _autoDeliveryServiceOverride = null;
        }
      } else {
        _items[idx].quantity = newQty;
      }
      if (_items.isNotEmpty && _autoDeliverySyncActive) {
        syncAutoDeliveryPromo(serviceType: _autoDeliveryServiceOverride, notify: false);
      }
      if (_items.isNotEmpty && _autoOrderSyncActive) {
        syncAutoOrderPromo(serviceType: _autoDeliveryServiceOverride, notify: false);
      }
      _syncToMultiMerchantCartService();
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

  void updateItemVariants(String menuId, {required List<String> variants, required int variantPrice, String? notes}) {
    final idx = _items.indexWhere((i) => i.menuId == menuId);
    if (idx >= 0) {
      final old = _items[idx];
      _items[idx] = CartItemModel(
        menuId: old.menuId,
        merchantId: old.merchantId,
        merchantName: old.merchantName,
        name: old.name,
        price: old.price,
        quantity: old.quantity,
        notes: notes ?? old.notes,
        category: old.category,
        imageUrl: old.imageUrl,
        serviceType: old.serviceType,
        selectedVariants: variants,
        variantPrice: variantPrice,
      );
      _syncToMultiMerchantCartService();
      _saveCart();
      notifyListeners();
    }
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setDeliveryAddress(String address, double distance, {LatLng? location}) {
    _deliveryAddress = address;
    _distanceKm = distance;
    if (location != null) {
      _deliveryLocation = location;
    }
    _saveCart();
    notifyListeners();
  }

  String? _foodPromoCode;
  int _foodPromoDiscount = 0;
  bool _foodPromoManuallyDismissed = false;
  bool _isFoodPromoManual = false;
  bool _autoOrderSyncActive = false;
  String? _deliveryPromoCode;
  int _deliveryPromoDiscount = 0;
  bool _deliveryPromoManuallyDismissed = false;
  bool _isDeliveryPromoManual = false;
  bool _autoDeliverySyncActive = false;
  String? _autoDeliveryServiceOverride;

  String? get foodPromoCode => _foodPromoCode;
  int get foodPromoDiscount => _foodPromoDiscount;
  String? get merchantDiscountCode => _foodPromoCode;
  int get merchantDiscountAmount => _foodPromoDiscount;
  String? get deliveryPromoCode => _deliveryPromoCode;
  int get deliveryPromoDiscount => _deliveryPromoDiscount;

  bool get isFoodCart => _items.isEmpty || _items.any((i) => i.serviceType == 'food');
  String get primaryServiceType => _items.isNotEmpty ? _items.first.serviceType : 'food';
  String get itemQuantityLabel => isFoodCart ? 'Menu' : 'Produk';

  void setFoodPromo(String? code, int discount, {bool isManual = true}) {
    final normalized = code?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      removeFoodPromo(manual: isManual);
      return;
    }
    _foodPromoCode = normalized;
    _foodPromoDiscount = discount;
    _foodPromoManuallyDismissed = false;
    _isFoodPromoManual = isManual;
    _saveCart();
    notifyListeners();
  }

  void setMerchantDiscount(String? code, int discount) => setFoodPromo(code, discount);

  void setDeliveryPromo(String? code, int discount, {bool isManual = true}) {
    final normalized = code?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      removeDeliveryPromo(manual: isManual);
      return;
    }
    _deliveryPromoCode = normalized;
    _deliveryPromoDiscount = discount;
    _deliveryPromoManuallyDismissed = false;
    _isDeliveryPromoManual = isManual;
    _saveCart();
    notifyListeners();
  }

  /// Auto-applies the best eligible delivery ("gratis ongkir") voucher when order
  /// conditions are met, and clears ineligible promos when below minOrder or pickup.
  void syncAutoDeliveryPromo({String? serviceType, bool notify = true}) {
    _autoDeliverySyncActive = true;
    if (serviceType != null && serviceType.trim().isNotEmpty) {
      _autoDeliveryServiceOverride = serviceType.trim().toLowerCase();
    }
    final activeService = _autoDeliveryServiceOverride ?? primaryServiceType;
    bool changed = false;

    if (_items.isEmpty) {
      if (_deliveryPromoCode != null || _deliveryPromoDiscount != 0) {
        _deliveryPromoCode = null;
        _deliveryPromoDiscount = 0;
        changed = true;
      }
      _deliveryPromoManuallyDismissed = false;
      _isDeliveryPromoManual = false;
    } else if (_isPickup) {
      if (_deliveryPromoCode != null || _deliveryPromoDiscount != 0) {
        _deliveryPromoCode = null;
        _deliveryPromoDiscount = 0;
        _isDeliveryPromoManual = false;
        changed = true;
      }
    } else {
      if (_deliveryPromoCode != null) {
        final existingVoucher = GageVoucherData.findByCode(_deliveryPromoCode!);
        final expectedService = GageVoucherData.serviceNameForType(activeService);
        final invalidExisting = existingVoucher == null ||
            existingVoucher['type'] != 'delivery' ||
            existingVoucher['service'] != expectedService ||
            !GageVoucherData.isVoucherEligible(existingVoucher, subtotal);
        if (invalidExisting) {
          _deliveryPromoCode = null;
          _deliveryPromoDiscount = 0;
          _isDeliveryPromoManual = false;
          changed = true;
        }
      }

      if (!_deliveryPromoManuallyDismissed && !_isDeliveryPromoManual) {
        final best = GageVoucherData.bestEligibleDeliveryVoucher(
          serviceType: activeService,
          subtotal: subtotal,
        );
        if (best != null) {
          final nextCode = best['code'] as String;
          final nextDiscount = (best['discountAmount'] as num?)?.toInt() ?? 0;
          if (_deliveryPromoCode != nextCode || _deliveryPromoDiscount != nextDiscount) {
            _deliveryPromoCode = nextCode;
            _deliveryPromoDiscount = nextDiscount;
            changed = true;
          }
        } else if (_deliveryPromoCode != null) {
          _deliveryPromoCode = null;
          _deliveryPromoDiscount = 0;
          changed = true;
        }
      }
    }

    if (changed) {
      _saveCart();
      if (notify) {
        notifyListeners();
      }
    }
  }

  /// Auto-applies the best eligible order discount voucher from [GageVoucherData]
  /// and removes stale, cross-service, or ineligible order promo codes.
  void syncAutoOrderPromo({String? serviceType, bool notify = true}) {
    _autoOrderSyncActive = true;
    if (serviceType != null && serviceType.trim().isNotEmpty) {
      _autoDeliveryServiceOverride = serviceType.trim().toLowerCase();
    }
    final activeService = _autoDeliveryServiceOverride ?? primaryServiceType;
    bool changed = false;

    if (_items.isEmpty) {
      if (_foodPromoCode != null || _foodPromoDiscount != 0) {
        _foodPromoCode = null;
        _foodPromoDiscount = 0;
        changed = true;
      }
      _foodPromoManuallyDismissed = false;
      _isFoodPromoManual = false;
    } else {
      if (_foodPromoCode != null) {
        final existingVoucher = GageVoucherData.findByCode(_foodPromoCode!);
        final expectedService = GageVoucherData.serviceNameForType(activeService);
        final invalidExisting = existingVoucher == null ||
            existingVoucher['type'] != 'order' ||
            existingVoucher['service'] != expectedService ||
            !GageVoucherData.isVoucherEligible(existingVoucher, subtotal);
        if (invalidExisting) {
          _foodPromoCode = null;
          _foodPromoDiscount = 0;
          _isFoodPromoManual = false;
          changed = true;
        } else if (_isFoodPromoManual) {
          final updatedDiscount = GageVoucherData.calculateDiscount(existingVoucher, subtotal);
          if (_foodPromoDiscount != updatedDiscount) {
            _foodPromoDiscount = updatedDiscount;
            changed = true;
          }
        }
      }

      if (!_foodPromoManuallyDismissed && !_isFoodPromoManual) {
        final best = GageVoucherData.bestEligibleOrderVoucher(
          serviceType: activeService,
          subtotal: subtotal,
        );
        if (best != null) {
          final nextCode = best['code'] as String;
          final nextDiscount = GageVoucherData.calculateDiscount(best, subtotal);
          if (_foodPromoCode != nextCode || _foodPromoDiscount != nextDiscount) {
            _foodPromoCode = nextCode;
            _foodPromoDiscount = nextDiscount;
            changed = true;
          }
        } else if (_foodPromoCode != null) {
          _foodPromoCode = null;
          _foodPromoDiscount = 0;
          changed = true;
        }
      }
    }

    if (changed) {
      _saveCart();
      if (notify) {
        notifyListeners();
      }
    }
  }

  /// Synchronizes both order discount and delivery discount promos with
  /// [GageVoucherData] eligibility rules in a single notification pass.
  void syncAutoPromos({String? serviceType, bool notify = true}) {
    final prevFoodCode = _foodPromoCode;
    final prevFoodDisc = _foodPromoDiscount;
    final prevDelCode = _deliveryPromoCode;
    final prevDelDisc = _deliveryPromoDiscount;

    syncAutoOrderPromo(serviceType: serviceType, notify: false);
    syncAutoDeliveryPromo(serviceType: serviceType, notify: false);

    final anyChanged = prevFoodCode != _foodPromoCode ||
        prevFoodDisc != _foodPromoDiscount ||
        prevDelCode != _deliveryPromoCode ||
        prevDelDisc != _deliveryPromoDiscount;
    if (anyChanged && notify) {
      notifyListeners();
    }
  }

  void removeFoodPromo({bool manual = true}) {
    _foodPromoCode = null;
    _foodPromoDiscount = 0;
    if (manual) {
      _foodPromoManuallyDismissed = true;
      _isFoodPromoManual = false;
    }
    _saveCart();
    notifyListeners();
  }

  void removeMerchantDiscount() => removeFoodPromo();

  void removeDeliveryPromo({bool manual = true}) {
    _deliveryPromoCode = null;
    _deliveryPromoDiscount = 0;
    if (manual) {
      _deliveryPromoManuallyDismissed = true;
      _isDeliveryPromoManual = false;
    }
    _saveCart();
    notifyListeners();
  }

  void setPromoCode(String? code) {
    final c = code?.trim().toUpperCase();
    _promoCode = c;
    if (c != null && c.isNotEmpty) {
      final voucher = GageVoucherData.findByCode(c);
      final expectedService = GageVoucherData.serviceNameForType(primaryServiceType);
      if (voucher != null &&
          voucher['service'] == expectedService &&
          GageVoucherData.isVoucherEligible(voucher, subtotal)) {
        final disc = GageVoucherData.calculateDiscount(voucher, subtotal);
        if (voucher['type'] == 'delivery') {
          setDeliveryPromo(c, disc);
        } else {
          setFoodPromo(c, disc);
        }
        return;
      }
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
    _foodPromoManuallyDismissed = false;
    _isFoodPromoManual = false;
    _autoOrderSyncActive = false;
    _deliveryPromoCode = null;
    _deliveryPromoDiscount = 0;
    _deliveryPromoManuallyDismissed = false;
    _isDeliveryPromoManual = false;
    _autoDeliverySyncActive = false;
    _autoDeliveryServiceOverride = null;
    _scheduledDeliveryTime = null;
    _groupOrderId = null;
    MultiMerchantCartService.instance.clearCart();
    _saveCart();
    notifyListeners();
  }

  // ── Hitungan Keuangan Otomatis Dual-Tier Vouchers & Decoy Effect ──
  int get totalItemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  int get subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);

  int get totalFoodDiscount => _foodPromoDiscount.clamp(0, subtotal);

  // 1. Opsi Prioritas (Express Direct: Reguler + Rp 4.000)
  int get prioritasShippingFee => regulerShippingFee + 4000;

  // 2. Opsi Reguler (Decoy Standar: 0-3km Rp 12.000)
  int get regulerShippingFee => GagePricingService.calculateCustomerShippingFee(
        distanceKm: _distanceKm,
        deliveryOption: 'REGULER',
        merchantCount: merchantCount,
      );

  // 3. Opsi Hemat (Tarif Dasar Saver Batch: 0-3km Rp 9.000)
  int get hematShippingFee => GagePricingService.calculateCustomerShippingFee(
        distanceKm: _distanceKm,
        deliveryOption: 'HEMAT',
        merchantCount: merchantCount,
      );

  // Syarat Opsi Hemat: Hanya aktif jika jarak >= 2.5 km (untuk melindungi upah minimum driver)
  bool get isHematAvailable => _distanceKm >= 2.5;

  // Ongkir Customer Terpilih (Sesuai Opsi Aktif Tanpa Mengubah Getter Masing-Masing)
  int get rawShippingFee {
    final opt = _deliveryOption.toUpperCase();
    if (opt == 'PRIORITAS') {
      return prioritasShippingFee;
    } else if (opt == 'HEMAT') {
      return isHematAvailable ? hematShippingFee : regulerShippingFee;
    } else {
      return regulerShippingFee;
    }
  }

  int get totalShippingDiscount => _deliveryPromoDiscount.clamp(0, rawShippingFee);

  int get finalShippingFee {
    if (_isPickup) return 0;
    return (rawShippingFee - totalShippingDiscount).clamp(0, 99999999);
  }

  // Biaya Layanan: Cashless Rp 1.000 | COD Rp 3.000
  int get adminFee => GagePricingService.calculateAdminFee(
        paymentMethod: _paymentMethod,
        merchantCount: merchantCount,
      );

  int get grandTotal => (subtotal - totalFoodDiscount).clamp(0, 99999999) + finalShippingFee + adminFee;
}
