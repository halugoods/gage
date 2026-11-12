import 'package:flutter/material.dart';
import 'package:gage_app/features/food/presentation/shop_favorite_screen.dart';

/// Halaman daftar resto & menu favorit pengguna GAGE Food.
/// Terhubung langsung ke mesin favorit terpadu ([ShopFavoriteScreen])
/// untuk sinkronisasi SharedPreferences dan pemisahan data Dev vs Produksi.
class FavoriteRestoScreen extends StatelessWidget {
  final int initialTabIndex;
  final String? filterMerchantId;
  final String? filterMerchantName;

  const FavoriteRestoScreen({
    super.key,
    this.initialTabIndex = 0,
    this.filterMerchantId,
    this.filterMerchantName,
  });

  @override
  Widget build(BuildContext context) {
    return ShopFavoriteScreen(
      domain: 'food',
      initialTabIndex: initialTabIndex,
      filterMerchantId: filterMerchantId,
      filterMerchantName: filterMerchantName,
    );
  }
}
