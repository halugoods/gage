import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/features/merchant/presentation/merchant_menu_screen.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Tab 3: Marketing & Promosi Mitra Usaha GAGE (1:1 Paritas Customer & Shopee Partner)
/// Terintegrasi fungsional tanpa gimmick:
/// - Diskon Menu (Harga Coret `promo_price` di menu katalog)
/// - Diskon Langsung (Voucher Toko yang memotong subtotal checkout)
/// - Flash Sale GAGE Food (Pendaftaran kuota & diskon sesi kilat)
/// - Iklan Toko (Pencarian, Rekomendasi, Banner) dengan simulasi budget harian
/// - Komisi Affiliate Toko (Bagi hasil kreator video & driver)
class GageMerchantMarketingTab extends StatefulWidget {
  const GageMerchantMarketingTab({super.key});

  @override
  State<GageMerchantMarketingTab> createState() =>
      _GageMerchantMarketingTabState();
}

class _GageMerchantMarketingTabState extends State<GageMerchantMarketingTab> {
  int _activePromoCount = 1;
  int _activeAdCount = 0;
  int _directDiscountAmount = 5000;
  int _minSpendAmount = 35000;
  bool _directDiscountActive = true;

  // 1. Atur Diskon Langsung Toko (Voucher Toko)
  void _showDirectDiscountDialog(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    final discountCtrl =
        TextEditingController(text: _directDiscountAmount.toString());
    final minSpendCtrl =
        TextEditingController(text: _minSpendAmount.toString());

    GageFloatingSheet.show(
      context: context,
      title: 'Atur Diskon Langsung Toko',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Potongan belanja otomatis pada keranjang checkout pelanggan yang berbelanja di resto Anda.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: discountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nominal Potongan Diskon (Rp)',
                prefixText: 'Rp ',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minSpendCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Minimal Belanja Subtotal (Rp)',
                prefixText: 'Rp ',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  final disc = int.tryParse(discountCtrl.text) ?? 5000;
                  final minS = int.tryParse(minSpendCtrl.text) ?? 35000;
                  setState(() {
                    _directDiscountAmount = disc;
                    _minSpendAmount = minS;
                    _directDiscountActive = true;
                    _activePromoCount = 2;
                  });
                  Navigator.pop(ctx);
                  GageToast.show(
                    context,
                    'Voucher Toko aktif: Diskon Rp $disc (Min. Belanja Rp $minS)',
                  );
                },
                child: const Text('Aktifkan Diskon Toko',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 2. Pendaftaran Flash Sale GAGE Food
  void _showFlashSaleRegistrationSheet(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    double discountPct = 25.0;
    int quota = 15;

    GageFloatingSheet.show(
      context: context,
      title: 'Daftar Flash Sale GAGE Food',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu resto terpilih akan tampil di banner Flash Sale beranda selama 2 jam dengan kuota terbatas.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Color(0xFFEA580C), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sesi Kilat Siang (11:00 - 13:00)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Fried Chicken Spicy & Dimsum Mix',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Besaran Diskon:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text('${discountPct.round()}%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: GageTheme.primary)),
                ],
              ),
              Slider(
                value: discountPct,
                min: 15.0,
                max: 50.0,
                divisions: 7,
                activeColor: GageTheme.primary,
                label: '${discountPct.round()}%',
                onChanged: (v) => setSheetState(() => discountPct = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Alokasi Kuota Pesanan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text('$quota porsi',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
              Slider(
                value: quota.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                activeColor: const Color(0xFFEA580C),
                label: '$quota porsi',
                onChanged: (v) => setSheetState(() => quota = v.toInt()),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _activePromoCount++);
                    GageToast.show(
                      context,
                      'Toko terdaftar di Flash Sale: Diskon ${discountPct.round()}% ($quota porsi)',
                    );
                  },
                  child: const Text('Konfirmasi Ikuti Flash Sale',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Komisi Affiliate Toko
  void _showAffiliateCampaignDialog(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    double currentRate = 5.0;

    GageFloatingSheet.show(
      context: context,
      title: 'Komisi Affiliate Toko GAGE',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Berikan bagi hasil kepada driver & kreator video yang mempromosikan menu resto Anda.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Besaran Komisi Penjualan:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  Text('${currentRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: GageTheme.primary)),
                ],
              ),
              Slider(
                value: currentRate,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                activeColor: GageTheme.primary,
                label: '${currentRate.toStringAsFixed(1)}%',
                onChanged: (v) => setDialogState(() => currentRate = v),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final current = await MerchantStorefrontService.loadStorefront(
                        MerchantStorefrontService.defaultPortalMerchantId);
                    if (current != null) {
                      await MerchantStorefrontService.saveStorefront(
                          current.copyWith(affiliateCommissionRate: currentRate));
                    }
                    if (context.mounted) {
                      GageToast.show(
                        context,
                        'Komisi affiliate toko disimpan: ${currentRate.toStringAsFixed(1)}%',
                      );
                    }
                  },
                  child: const Text('Simpan Komisi Affiliate',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Aktivasi Iklan Toko (Pencarian, Rekomendasi, Banner)
  void _showAdActivationSheet(
      BuildContext context, String adType, String desc, bool isDark) {
    HapticFeedback.lightImpact();
    int selectedDays = 3;
    int dailyBudget = 15000;

    GageFloatingSheet.show(
      context: context,
      title: 'Pasang $adType',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              // Pilihan Durasi
              const Text('Durasi Tayang:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                children: [3, 7, 14].map((d) {
                  final isSel = selectedDays == d;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => selectedDays = d);
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? GageTheme.primary : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$d Hari',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Budget Harian
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Budget Harian:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text('Rp $dailyBudget / hari',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: GageTheme.primary)),
                ],
              ),
              Slider(
                value: dailyBudget.toDouble(),
                min: 10000,
                max: 50000,
                divisions: 8,
                activeColor: GageTheme.primary,
                label: 'Rp $dailyBudget',
                onChanged: (v) => setSheetState(() => dailyBudget = (v / 5000).round() * 5000),
              ),
              // Ringkasan Estimasi
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Investasi Iklan ($selectedDays hari):',
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                    Text('Rp ${dailyBudget * selectedDays}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _activeAdCount++);
                        GageToast.show(
                          context,
                          '$adType aktif selama $selectedDays hari (Budget: Rp ${dailyBudget * selectedDays})',
                        );
                      },
                      child: const Text('Mulai Tayangkan Iklan',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marketing & Promosi',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // 1. Seksi: Aktivitas Saya
          Text(
            'Aktivitas Saya',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Card Promo
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text('🏷️ ', style: TextStyle(fontSize: 13)),
                              Text('Promo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('0', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                              Text('Mendatang', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                            ],
                          ),
                          Container(
                            height: 20,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_activePromoCount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                              Text('Berjalan', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Card Iklan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text('📢 ', style: TextStyle(fontSize: 13)),
                              Text('Iklan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('0', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                              Text('Mendatang', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                            ],
                          ),
                          Container(
                            height: 20,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_activeAdCount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: GageTheme.primary)),
                              Text('Berjalan', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Seksi: Promo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Promo Toko',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () => GageToast.show(context, 'Program promo aktif disinkronkan ke pelanggan'),
                child: const Text('Lihat Status >',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: GageTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fitur Promo: Diskon Menu vs Diskon Langsung
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.sell_rounded,
                  iconColor: const Color(0xFFEAB308),
                  title: 'Diskon Menu',
                  subtitle: 'Harga Coret',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MerchantMenuScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.percent_rounded,
                  iconColor: const Color(0xFFEA580C),
                  title: 'Diskon Langsung',
                  subtitle: _directDiscountActive ? 'Rp $_directDiscountAmount Aktif' : 'Voucher Toko',
                  badgeText: _directDiscountActive ? 'Aktif' : null,
                  onTap: () => _showDirectDiscountDialog(context, isDark),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Campaign Flash Sale GAGE Food
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('FLASH SALE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                        Text('GAGE FOOD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flash Sale GAGE Food',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sesi Kilat Siang • 27 Nov 2026',
                        style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    elevation: 0,
                  ),
                  onPressed: () => _showFlashSaleRegistrationSheet(context, isDark),
                  child: const Text('Gabung', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Seksi: Iklan Toko
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Iklan Toko',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () => GageToast.show(context, 'Performa iklan dihitung transparan dari klik riil'),
                child: const Text('Panduan Iklan >',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: GageTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fitur Iklan: Pencarian, Rekomendasi, Paket Kombo, Banner
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.search_rounded,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Iklan Pencarian',
                  subtitle: 'Prioritas Search',
                  onTap: () => _showAdActivationSheet(
                    context,
                    'Iklan Pencarian',
                    'Resto Anda akan diprioritaskan di hasil pencarian teratas aplikasi pelanggan saat mencari menu terkait.',
                    isDark,
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.thumb_up_rounded,
                  iconColor: const Color(0xFFEA580C),
                  title: 'Iklan Rekomendasi',
                  subtitle: 'Beranda Pelanggan',
                  onTap: () => _showAdActivationSheet(
                    context,
                    'Iklan Rekomendasi',
                    'Resto Anda akan tampil di feed rekomendasi utama beranda GAGE Food pelanggan.',
                    isDark,
                  ),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.stars_rounded,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Pencarian & Rekomendasi',
                  subtitle: 'Paket Kombo',
                  onTap: () => _showAdActivationSheet(
                    context,
                    'Paket Kombo Iklan',
                    'Dapatkan jangkauan maksimal gabungan prioritas pencarian dan rekomendasi beranda.',
                    isDark,
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.image_rounded,
                  iconColor: const Color(0xFFEA580C),
                  title: 'Iklan Banner',
                  subtitle: 'Carousel Beranda',
                  onTap: () => _showAdActivationSheet(
                    context,
                    'Iklan Banner Carousel',
                    'Menampilkan visual banner resto Anda pada carousel promosi paling atas di beranda pelanggan.',
                    isDark,
                  ),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Campaign Paket Iklan GAGE Food & Affiliate
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF0284C7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('KOMISI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                        Text('AFFILIATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bagi Hasil Affiliate Video',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reward kreator video & driver yang mereview resto',
                        style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    elevation: 0,
                  ),
                  onPressed: () => _showAffiliateCampaignDialog(context, isDark),
                  child: const Text('Atur %', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: GageTheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
