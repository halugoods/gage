import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/merchant_discount_tier_service.dart';
import 'package:gage_app/core/services/pracimantoro_places_database.dart';
import 'package:gage_app/core/services/user_address_service.dart';
import 'package:gage_app/data/mock/gage_voucher_data.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';
import 'package:gage_app/shared/widgets/gage_cart_sheet.dart';

/// Floating Cart Bar Seamless & Multi-Tier Diskon Bertahap (Standar Superapp GAGE)
/// - Clean capsule design with backdrop blur 16px
/// - Dynamic label: Menu vs Produk based on store vertical
/// - Saved green badge: 'Hemat 5RB' + '+5RB lagi disc 10RB' (tanpa '[ ]')
/// - Progress bar dinamis tanpa kilatan: Merah (<35%), Kuning (<70%), Hijau (>=70%)
class SeamlessFloatingCartBar extends StatefulWidget {
  final double bottomPadding;
  final bool useSafeArea;

  const SeamlessFloatingCartBar({
    super.key,
    this.bottomPadding = 8.0,
    this.useSafeArea = true,
  });

  @override
  State<SeamlessFloatingCartBar> createState() => _SeamlessFloatingCartBarState();
}

class _SeamlessFloatingCartBarState extends State<SeamlessFloatingCartBar> {
  Future<void> _onBuyPressed(CartProvider cart) async {
    HapticFeedback.lightImpact();
    if (!cart.isPickup) {
      final result = await FullScreenMapPicker.open(
        context,
        title: 'Pilih Titik Antar',
        initialLocation: cart.deliveryLocation,
        initialTitle: cart.deliveryLocationLabel ??
            (cart.deliveryAddress.isNotEmpty ? cart.deliveryAddress : null),
        selectedFavoriteId: cart.deliveryFavoriteId,
        confirmLabel: 'Lanjut ke Checkout',
      );
      if (!mounted || result == null) return;

      LatLng merchantLoc = PracimantoroPlacesDatabase.centerPracimantoro;
      final merchantName = cart.merchantName;
      if (merchantName != null && merchantName.trim().isNotEmpty) {
        final matches = PracimantoroPlacesDatabase.searchLocalPlaces(merchantName);
        if (matches.isNotEmpty) {
          merchantLoc = matches.first.location;
        }
      }
      final meters = const Distance().as(LengthUnit.Meter, merchantLoc, result.location);
      final distKm = double.parse((meters / 1000.0).clamp(0.8, 25.0).toStringAsFixed(1));
      final matchedFav = result.matchedFavorite ??
          await UserAddressService.findMatchingFavorite(
            location: result.location,
            preferredName: result.title,
          );
      if (!mounted) return;
      final resolvedAddress =
          result.fullAddress.isNotEmpty ? result.fullAddress : result.title;
      cart.setDeliveryAddress(
        resolvedAddress,
        distKm,
        location: result.location,
        locationLabel:
            matchedFav?.name ?? (result.title.isNotEmpty ? result.title : null),
        favoriteId: matchedFav?.id,
      );
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.totalItemCount <= 0) return const SizedBox.shrink();

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtotal = cart.subtotal;

    final activeTiers = GageVoucherData.orderVouchersForService(cart.primaryServiceType).map((v) {
      final minSpend = GageVoucherData.minOrderFor(v);
      final evalAmount = subtotal > minSpend ? subtotal : minSpend;
      final disc = GageVoucherData.calculateDiscount(v, evalAmount);
      return MerchantDiscountTier(
        minSpend: minSpend,
        discountAmount: disc,
        voucherCode: v['code'] as String?,
        label: (v['title'] as String?) ?? 'Diskon ${MerchantDiscountTierService.formatRb(disc)}',
      );
    }).toList();

    // Kalkulasi multi-tier diskon dinamis berbasis voucher resmi per layanan
    final discountProgress = MerchantDiscountTierService.calculateProgress(
      subtotal: subtotal,
      merchantId: cart.merchantId,
      serviceType: cart.primaryServiceType,
      customTiers: activeTiers,
    );

    // Sinkronisasi otomatis kedua jenis voucher (order + delivery) secara aman pasca-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartProvider>().syncAutoPromos(serviceType: cart.primaryServiceType);
    });

    Widget cartWidget = Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.68)
              : Colors.white.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                GageCartSheet.show(context);
              },
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
                child: Row(
                  children: [
                    // Kiri: Icon Keranjang HITAM + Badge Qty Merah
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          GageCartSheet.show(context);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.shopping_bag_rounded,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              size: 26,
                            ),
                            if (cart.totalItemCount > 0)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: const BoxDecoration(
                                    color: GageTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      cart.totalItemCount > 9 ? '9+' : '${cart.totalItemCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Tengah: Nominal Harga, Harga Coret, Status Target & Diskon
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                            children: [
                              Text(
                                '${cart.totalItemCount} ${cart.itemQuantityLabel}',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 3.5,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (discountProgress.hasDiscount) ...[
                                // Harga Asli Dicoret
                                Text(
                                  currencyFormatter.format(discountProgress.originalSubtotal),
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: isDark ? Colors.white38 : Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                // Harga Setelah Diskon
                                Text(
                                  currencyFormatter.format(discountProgress.discountedSubtotal),
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF34D399) : GageTheme.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ] else ...[
                                // Harga Normal
                                Text(
                                  currencyFormatter.format(subtotal),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          ),
                          const SizedBox(height: 2),

                          // Status Target Diskon: Badge Hijau Hemat + Detail Target Diskon
                          Row(
                            children: [
                              if (discountProgress.savedBadgeText != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    discountProgress.savedBadgeText!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Expanded(
                                child: Text(
                                  discountProgress.nextTierDetailText.isNotEmpty
                                      ? discountProgress.nextTierDetailText
                                      : discountProgress.compactSummaryText,
                                  style: TextStyle(
                                    color: discountProgress.hasDiscount
                                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                        : (isDark ? Colors.amber.shade300 : const Color(0xFFD97706)),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Progress Bar Horizontal Bersih Tanpa Kilatan:
                          // Merah (<35%), Kuning (<70%), Hijau (>=70%)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Container(
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: LayoutBuilder(
                                builder: (context, barConstraints) {
                                  final progressVal = (discountProgress.isMaxTier
                                          ? 1.0
                                          : discountProgress.progress)
                                      .clamp(0.0, 1.0);

                                  final Color progressBarColor = progressVal < 0.35
                                      ? const Color(0xFFEF4444) // Merah (<35%)
                                      : (progressVal < 0.70
                                          ? const Color(0xFFEAB308) // Kuning (<70%)
                                          : const Color(0xFF10B981)); // Hijau (>=70%)

                                  final fillWidth = (barConstraints.maxWidth * progressVal)
                                      .clamp(0.0, barConstraints.maxWidth);

                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      width: fillWidth,
                                      decoration: BoxDecoration(
                                        color: progressBarColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Kanan: Tombol Beli Merah Menonjol
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onBuyPressed(cart),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          height: 38,
                          constraints: const BoxConstraints(minWidth: 80),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            color: GageTheme.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: GageTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Beli',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.useSafeArea) {
      return SafeArea(
        top: false,
        child: cartWidget,
      );
    }
    return cartWidget;
  }
}
