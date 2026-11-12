import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Sheet terpadu rating mitra Toko/Restoran dan Driver GAGE.
/// Dipicu dari tap bintang di pesanan selesai atau dari invoice sukses.
class RatingReviewSheet extends StatefulWidget {
  final String orderId;
  final String? merchantId;
  final String serviceType;
  final String merchantName;
  final String? merchantAvatar;
  final String driverName;
  final String? driverAvatar;
  final String? driverVehicle;
  final int initialStar;
  final void Function(int merchantRating, int driverRating)? onSubmitted;

  const RatingReviewSheet({
    super.key,
    required this.orderId,
    this.merchantId,
    this.serviceType = 'food',
    required this.merchantName,
    this.merchantAvatar,
    required this.driverName,
    this.driverAvatar,
    this.driverVehicle,
    this.initialStar = 5,
    this.onSubmitted,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    String? merchantId,
    String serviceType = 'food',
    required String merchantName,
    String? merchantAvatar,
    required String driverName,
    String? driverAvatar,
    String? driverVehicle,
    int initialStar = 5,
    void Function(int merchantRating, int driverRating)? onSubmitted,
  }) {
    return GageFloatingSheet.show<bool>(
      context: context,
      title: 'Beri Penilaian',
      child: RatingReviewSheet(
        orderId: orderId,
        merchantId: merchantId,
        serviceType: serviceType,
        merchantName: merchantName,
        merchantAvatar: merchantAvatar,
        driverName: driverName,
        driverAvatar: driverAvatar,
        driverVehicle: driverVehicle,
        initialStar: initialStar,
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  State<RatingReviewSheet> createState() => _RatingReviewSheetState();
}

class _RatingReviewSheetState extends State<RatingReviewSheet> {
  late int _merchantStars;
  late int _driverStars;

  final Set<String> _selectedMerchantChips = {};
  final Set<String> _selectedDriverChips = {};

  final TextEditingController _merchantCommentCtrl = TextEditingController();
  final TextEditingController _driverCommentCtrl = TextEditingController();

  final List<String> _merchantChipOptions = [
    'Rasa Lezat 🍲',
    'Porsi Pas 👍',
    'Packing Rapi 📦',
    'Harga Bersahabat 💰',
    'Sesuai Pesanan ✔️',
    'Masih Hangat 🔥',
  ];

  final List<String> _driverChipOptions = [
    'Tepat Waktu ⚡',
    'Sopan & Ramah 😊',
    'Pengantaran Aman 🛵',
    'Hati-hati Berkendara 🛡️',
    'Komunikatif 💬',
  ];

  @override
  void initState() {
    super.initState();
    _merchantStars = widget.initialStar.clamp(1, 5);
    _driverStars = widget.initialStar.clamp(1, 5);
  }

  @override
  void dispose() {
    _merchantCommentCtrl.dispose();
    _driverCommentCtrl.dispose();
    super.dispose();
  }

  Widget _buildMerchantAvatar() {
    return GageAvatar(
      imageUrl: widget.merchantAvatar,
      fallbackName: widget.merchantName,
      radius: 20,
      backgroundColor: GageTheme.primaryLight,
    );
  }

  Widget _buildDriverAvatar() {
    return GageAvatar(
      imageUrl: widget.driverAvatar,
      fallbackName: widget.driverName.isNotEmpty ? widget.driverName : 'Driver GAGE',
      radius: 20,
      backgroundColor: const Color(0xFFEFF6FF),
    );
  }

  Widget _buildStarRow(int currentStars, ValueChanged<int> onStarTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= currentStars;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onStarTap(starIndex);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: AnimatedScale(
              scale: isFilled ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 36,
                color: isFilled ? const Color(0xFFF59E0B) : Colors.grey.shade400,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BAGIAN PENILAIAN TOKO / MITRA RESTO
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildMerchantAvatar(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.merchantName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          Text(
                            'Bagaimana kualitas makanan & kemasan toko?',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStarRow(_merchantStars, (val) => setState(() => _merchantStars = val)),
                const SizedBox(height: 8),

                // Quick Chips Toko
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: _merchantChipOptions.map((chip) {
                    final isSel = _selectedMerchantChips.contains(chip);
                    return FilterChip(
                      label: Text(chip),
                      selected: isSel,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      selectedColor: GageTheme.primaryLight,
                      side: BorderSide(
                        color: isSel ? GageTheme.primary : (isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      shape: const StadiumBorder(),
                      onSelected: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (val) {
                            _selectedMerchantChips.add(chip);
                          } else {
                            _selectedMerchantChips.remove(chip);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Komentar Toko
                TextField(
                  controller: _merchantCommentCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar untuk ${widget.merchantName}...',
                    hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                  ),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. BAGIAN PENILAIAN DRIVER / PENGANTAR
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDriverAvatar(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driverName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          Text(
                            widget.driverVehicle ?? 'Mitra Pengemudi GAGE',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStarRow(_driverStars, (val) => setState(() => _driverStars = val)),
                const SizedBox(height: 8),

                // Quick Chips Driver
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: _driverChipOptions.map((chip) {
                    final isSel = _selectedDriverChips.contains(chip);
                    return FilterChip(
                      label: Text(chip),
                      selected: isSel,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      selectedColor: const Color(0xFFDBEAFE),
                      side: BorderSide(
                        color: isSel ? const Color(0xFF2563EB) : (isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      shape: const StadiumBorder(),
                      onSelected: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (val) {
                            _selectedDriverChips.add(chip);
                          } else {
                            _selectedDriverChips.remove(chip);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Komentar Driver
                TextField(
                  controller: _driverCommentCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tulis apresiasi atau catatan untuk ${widget.driverName}...',
                    hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                  ),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Tombol Kirim Penilaian
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                final commentText = _merchantCommentCtrl.text.trim();
                final chipNotes = _selectedMerchantChips.join(', ');
                final fullComment = [
                  if (commentText.isNotEmpty) commentText,
                  if (chipNotes.isNotEmpty) chipNotes,
                ].join(' - ');
                MerchantStorefrontService.submitBuyerReview(
                  merchantId: widget.merchantId,
                  merchantName: widget.merchantName,
                  domain: widget.serviceType,
                  stars: _merchantStars,
                  comment: fullComment,
                );
                if (widget.onSubmitted != null) {
                  widget.onSubmitted!(_merchantStars, _driverStars);
                }
                Navigator.pop(context, true);
                GageToast.show(
                  context,
                  'Terima kasih! Ulasan Anda telah terkirim.',
                  type: GageToastType.success,
                );
              },
              child: const Text(
                'Kirim Penilaian',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
