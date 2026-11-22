import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Android 14 / One UI Photo Picker for GAGE Merchant Portal.
/// Modeled after the production-grade zero-slop photo picker in NUSA Kasir.
/// Supports Camera, Phone Gallery, and Multi-Vertical Presets (Food, Shop, Farm).
class MerchantPhotoPickerSheet extends StatefulWidget {
  final String? initialCategory;

  const MerchantPhotoPickerSheet({
    super.key,
    this.initialCategory,
  });

  /// Opens the photo picker sheet and returns the selected image path (asset or file).
  static Future<String?> show(BuildContext context, {String? initialCategory}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MerchantPhotoPickerSheet(initialCategory: initialCategory),
    );
  }

  @override
  State<MerchantPhotoPickerSheet> createState() => _MerchantPhotoPickerSheetState();
}

class _MerchantPhotoPickerSheetState extends State<MerchantPhotoPickerSheet> {
  int _activeCategory = 0; // 0: Kuliner, 1: Sembako, 2: Tani & Ternak
  String? _tappedId;
  bool _isLoading = false;

  static const List<Map<String, String>> _categories = [
    {'id': 'food', 'name': 'Kuliner'},
    {'id': 'shop', 'name': 'Sembako'},
    {'id': 'farm', 'name': 'Tani & Ternak'},
  ];

  static const Map<String, List<Map<String, String>>> _presets = {
    'food': [
      {'id': 'dish_dimsum_original', 'name': 'Dimsum Original', 'asset': 'assets/images/dish_dimsum_original.png'},
      {'id': 'dish_dimsum_mentai', 'name': 'Dimsum Mentai', 'asset': 'assets/images/dish_dimsum_mentai.png'},
      {'id': 'dish_ayam_geprek', 'name': 'Ayam Geprek', 'asset': 'assets/images/dish_ayam_geprek.png'},
      {'id': 'dish_mie_ayam', 'name': 'Mie Ayam Bakso', 'asset': 'assets/images/dish_mie_ayam.png'},
      {'id': 'dish_sate_ayam', 'name': 'Sate Ayam Madura', 'asset': 'assets/images/dish_sate_ayam.png'},
      {'id': 'dish_chicken_burger', 'name': 'Chicken Burger', 'asset': 'assets/images/dish_chicken_burger.png'},
      {'id': 'dish_french_fries', 'name': 'French Fries Crispy', 'asset': 'assets/images/dish_french_fries.png'},
      {'id': 'dish_es_teh', 'name': 'Es Teh Manis', 'asset': 'assets/images/dish_es_teh.png'},
      {'id': 'dish_kopi_susu', 'name': 'Kopi Susu Gula Aren', 'asset': 'assets/images/dish_kopi_susu.png'},
      {'id': 'dish_roti_cokelat', 'name': 'Roti Bakar Cokelat', 'asset': 'assets/images/dish_roti_cokelat.png'},
      {'id': 'dish_seblak_komplit', 'name': 'Seblak Komplit', 'asset': 'assets/images/dish_seblak_komplit.png'},
    ],
    'shop': [
      {'id': 'prod_beras', 'name': 'Beras Premium 5kg', 'asset': 'assets/images/prod_beras.png'},
      {'id': 'prod_minyak', 'name': 'Minyak Goreng 2L', 'asset': 'assets/images/prod_minyak.png'},
      {'id': 'prod_gula', 'name': 'Gula Pasir 1kg', 'asset': 'assets/images/prod_gula.png'},
      {'id': 'prod_telur', 'name': 'Telur Ayam 1kg', 'asset': 'assets/images/prod_telur.png'},
      {'id': 'prod_indomie', 'name': 'Mi Instan Goreng', 'asset': 'assets/images/prod_indomie.png'},
      {'id': 'prod_cabai', 'name': 'Cabai Rawit Segar', 'asset': 'assets/images/prod_cabai.png'},
      {'id': 'prod_semen', 'name': 'Semen Bangunan', 'asset': 'assets/images/prod_semen.png'},
      {'id': 'prod_cat', 'name': 'Cat Dinding Kaleng', 'asset': 'assets/images/prod_cat.png'},
    ],
    'farm': [
      {'id': 'prod_pakan', 'name': 'Pakan Ternak Unggas', 'asset': 'assets/images/prod_pakan.png'},
      {'id': 'prod_pupuk', 'name': 'Pupuk Organik NPK', 'asset': 'assets/images/prod_pupuk.png'},
      {'id': 'prod_benih', 'name': 'Benih Tanaman Unggul', 'asset': 'assets/images/prod_benih.png'},
      {'id': 'prod_telur_farm', 'name': 'Telur Bebek Omega', 'asset': 'assets/images/prod_telur.png'},
      {'id': 'prod_traktor', 'name': 'Alat Tani Traktor', 'asset': 'assets/images/prod_traktor.png'},
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      final cat = widget.initialCategory!.toLowerCase();
      if (cat.contains('shop') || cat.contains('sembako') || cat.contains('kelontong')) {
        _activeCategory = 1;
      } else if (cat.contains('farm') || cat.contains('tani') || cat.contains('ternak')) {
        _activeCategory = 2;
      }
    }
  }

  Future<void> _pickFromDevice(ImageSource source) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        Navigator.of(context).pop(picked.path);
      }
    } catch (e) {
      debugPrint('Error picking image from device: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectPreset(String assetPath, String id) {
    if (_isLoading) return;
    setState(() => _tappedId = id);
    HapticFeedback.selectionClick();

    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        Navigator.of(context).pop(assetPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final catKey = _categories[_activeCategory]['id']!;
    final photos = _presets[catKey] ?? _presets['food']!;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Android 14 Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Top Bar
          Row(
            children: [
              Text(
                'Pilih Foto Produk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textColor, size: 22),
                onPressed: () => Navigator.of(context).pop(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Pills (Capsule 999)
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: List.generate(_categories.length, (idx) {
                final isSelected = _activeCategory == idx;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_activeCategory != idx) {
                        HapticFeedback.selectionClick();
                        setState(() => _activeCategory = idx);
                      }
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? GageTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _categories[idx]['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : subColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Date / Source Subtitle
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'Preset Resmi Toko & Kamera Fisik',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: subColor,
              ),
            ),
          ),

          // Photo Grid (Native Android 14 Style)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: photos.length + 2, // 0: Kamera, 1: Galeri, 2..N: Presets
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                // Tile 0: Kamera
                if (index == 0) {
                  return InkWell(
                    onTap: () => _pickFromDevice(ImageSource.camera),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: GageTheme.primary,
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kamera',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Tile 1: Galeri HP
                if (index == 1) {
                  return InkWell(
                    onTap: () => _pickFromDevice(ImageSource.gallery),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Galeri HP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Preset Tiles
                final item = photos[index - 2];
                final id = item['id']!;
                final assetPath = item['asset']!;
                final isSelected = _tappedId == id;

                return InkWell(
                  onTap: () => _selectPreset(assetPath, id),
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? GageTheme.primary
                                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: subColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Label nama produk di bagian bawah
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                          ),
                          child: Text(
                            item['name']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Checkmark Indicator Biru (Android 14 Photo Picker Style)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFF1A73E8)
                                : Colors.black.withValues(alpha: 0.35),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 13,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
