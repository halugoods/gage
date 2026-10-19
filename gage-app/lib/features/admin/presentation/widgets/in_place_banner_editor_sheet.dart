import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Scope penanda bahwa aplikasi sedang dijalankan di dalam Live App Sandbox (Admin Mode)
class LiveAppEditScope extends InheritedWidget {
  final bool isEditMode;

  /// Global flag agar tetap aktif meskipun layar dipush lewat Navigator.push
  static bool globalEditMode = false;

  const LiveAppEditScope({
    super.key,
    this.isEditMode = true,
    required super.child,
  });

  static LiveAppEditScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LiveAppEditScope>();
  }

  static bool isEditModeActive(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LiveAppEditScope>();
    return (scope != null && scope.isEditMode) || globalEditMode;
  }

  @override
  bool updateShouldNotify(LiveAppEditScope oldWidget) =>
      isEditMode != oldWidget.isEditMode;
}

/// Modal In-Place Banner CRUD Editor (WYSIWYG)
/// Dipanggil langsung ketika admin mengetuk banner apapun di dalam Live App Sandbox.
class InPlaceBannerEditorSheet extends StatefulWidget {
  final String screenTarget;
  final String? bannerId;
  final String initialTitle;
  final String initialSubtitle;
  final String initialBadge;
  final String initialImageUrl;
  final String initialActionUrl;
  final double aspectRatio;
  final VoidCallback? onSaved;

  const InPlaceBannerEditorSheet({
    super.key,
    required this.screenTarget,
    this.bannerId,
    required this.initialTitle,
    required this.initialSubtitle,
    required this.initialBadge,
    required this.initialImageUrl,
    this.initialActionUrl = '',
    this.aspectRatio = 16 / 9,
    this.onSaved,
  });

  /// Method statis untuk menampilkan dialog pop-up konfirmasi lalu membuka sheet
  static Future<void> showConfirmationAndOpen({
    required BuildContext context,
    required String screenTarget,
    String? bannerId,
    required String title,
    required String subtitle,
    required String badge,
    required String imageUrl,
    String actionUrl = '',
    double aspectRatio = 16 / 9,
    VoidCallback? onSaved,
  }) async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pop-up dialog konfirmasi (Edit vs Batal)
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mode_edit_rounded, color: GageTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Kelola Banner Ini?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Layar: $screenTarget',
              style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              '"$title"',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text('Batal', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit Banner Ini', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, 'edit'),
          ),
        ],
      ),
    );

    if (choice == 'edit' && context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => InPlaceBannerEditorSheet(
          screenTarget: screenTarget,
          bannerId: bannerId,
          initialTitle: title,
          initialSubtitle: subtitle,
          initialBadge: badge,
          initialImageUrl: imageUrl,
          initialActionUrl: actionUrl,
          aspectRatio: aspectRatio,
          onSaved: onSaved,
        ),
      );
    }
  }

  @override
  State<InPlaceBannerEditorSheet> createState() => _InPlaceBannerEditorSheetState();
}

class _InPlaceBannerEditorSheetState extends State<InPlaceBannerEditorSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _badgeCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _actionCtrl;
  bool _isSaving = false;
  bool _showManualUrl = false;

  final List<Map<String, String>> _presetImages = [
    {'label': 'SuperApp Beranda', 'path': 'assets/images/home_hero_banner.png'},
    {'label': 'GAGE Food Kuliner', 'path': 'assets/images/food_hero_banner.png'},
    {'label': 'GAGE Shop Sembako', 'path': 'assets/images/shop_hero_banner.png'},
    {'label': 'GAGE Send Kurir', 'path': 'assets/images/send_hero_banner.png'},
    {'label': 'GAGE BaBe Bekas', 'path': 'assets/images/babe_hero_banner.png'},
    {'label': 'GAGE Ride & Mobil', 'path': 'assets/images/ride_hero_banner.png'},
    {'label': 'GAGE Tani Agro', 'path': 'assets/images/tani_hero_banner.png'},
    {'label': 'GAGE Ternak Hewan', 'path': 'assets/images/ternak_hero_banner.png'},
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _subtitleCtrl = TextEditingController(text: widget.initialSubtitle);
    _badgeCtrl = TextEditingController(text: widget.initialBadge);
    _imageCtrl = TextEditingController(text: widget.initialImageUrl);
    _actionCtrl = TextEditingController(text: widget.initialActionUrl);

    _titleCtrl.addListener(_onFieldChanged);
    _subtitleCtrl.addListener(_onFieldChanged);
    _badgeCtrl.addListener(_onFieldChanged);
    _imageCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onFieldChanged);
    _subtitleCtrl.removeListener(_onFieldChanged);
    _badgeCtrl.removeListener(_onFieldChanged);
    _imageCtrl.removeListener(_onFieldChanged);

    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _badgeCtrl.dispose();
    _imageCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      HapticFeedback.lightImpact();
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 88,
      );
      if (picked != null) {
        setState(() {
          _imageCtrl.text = picked.path;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Gagal memilih gambar dari galeri: $e', type: GageToastType.error);
      }
    }
  }

  Future<void> _handleSave() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      GageToast.show(context, 'Judul banner tidak boleh kosong', type: GageToastType.warning);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final payload = {
      if (widget.bannerId != null) 'id': widget.bannerId,
      'title': title,
      'subtitle': _subtitleCtrl.text.trim(),
      'badge': _badgeCtrl.text.trim(),
      'image_url': _imageCtrl.text.trim(),
      'action_url': _actionCtrl.text.trim(),
      'screen_target': widget.screenTarget,
      'is_active': 1,
    };

    bool success = false;
    try {
      if (widget.bannerId != null && widget.bannerId!.isNotEmpty) {
        success = await GageApiClient.updateBanner(widget.bannerId!, payload);
      } else {
        final res = await GageApiClient.createBanner(
          screenTarget: widget.screenTarget,
          title: title,
          subtitle: _subtitleCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim(),
          actionUrl: _actionCtrl.text.trim(),
          isActive: 1,
        );
        success = (res != null && res['success'] == true);
      }
    } catch (_) {}

    // Selalu perbarui BannerManagerService lokal agar Sandbox langsung berubah instan
    await BannerManagerService.instance.updateBanner(
      widget.screenTarget,
      BannerConfig(
        menuKey: widget.screenTarget,
        menuName: widget.screenTarget,
        title: title,
        subtitle: _subtitleCtrl.text.trim(),
        badge: _badgeCtrl.text.trim().isNotEmpty ? _badgeCtrl.text.trim() : 'PROMO',
        imagePath: _imageCtrl.text.trim().isNotEmpty ? _imageCtrl.text.trim() : 'assets/images/home_hero_banner.png',
        ctaText: _actionCtrl.text.trim().isNotEmpty ? _actionCtrl.text.trim() : 'Lihat Promo',
        isActive: true,
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    HapticFeedback.heavyImpact();
    widget.onSaved?.call();
    Navigator.pop(context);
    GageToast.show(
      context,
      success ? 'Banner tersimpan di Cloud D1!' : 'Banner diperbarui di perangkat!',
      type: GageToastType.success,
    );
  }

  Future<void> _handleDelete() async {
    if (widget.bannerId == null) {
      Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Banner?'),
        content: const Text('Banner ini akan dihapus permanen dari Cloudflare D1.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      final ok = await GageApiClient.deleteBanner(widget.bannerId!);
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (ok) {
        HapticFeedback.heavyImpact();
        BannerManagerService.instance.loadFromPrefs();
        widget.onSaved?.call();
        if (mounted) {
          Navigator.pop(context);
          GageToast.show(context, 'Banner dihapus dari Cloudflare!', type: GageToastType.success);
        }
      }
    }
  }

  Widget _buildLivePreview(BuildContext context, bool isDark) {
    final currentImg = _imageCtrl.text.trim();
    final badge = _badgeCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final subtitle = _subtitleCtrl.text.trim();

    Widget imgWidget;
    if (currentImg.startsWith('http://') || currentImg.startsWith('https://')) {
      imgWidget = Image.network(currentImg, fit: BoxFit.cover, errorBuilder: (c, err, stack) => _buildFallbackPreview());
    } else if (currentImg.startsWith('assets/')) {
      imgWidget = Image.asset(currentImg, fit: BoxFit.cover, errorBuilder: (c, err, stack) => _buildFallbackPreview());
    } else if (currentImg.isNotEmpty && File(currentImg).existsSync()) {
      imgWidget = Image.file(File(currentImg), fit: BoxFit.cover, errorBuilder: (c, err, stack) => _buildFallbackPreview());
    } else {
      imgWidget = _buildFallbackPreview();
    }

    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imgWidget,
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: GageTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                Text(
                  title.isNotEmpty ? title : 'Judul Banner Promosi',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 10, shadows: [Shadow(color: Colors.black, blurRadius: 3)]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('PREVIEW LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackPreview() {
    return Container(
      color: GageTheme.primary,
      child: const Center(
        child: Text('GAGE BANNER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildPresetGallery(BuildContext context, bool isDark) {
    final currentPath = _imageCtrl.text.trim();
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _presetImages.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          final item = _presetImages[idx];
          final isSelected = currentPath == item['path'];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _imageCtrl.text = item['path']!);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? GageTheme.primary : (isDark ? Colors.white24 : Colors.grey.shade300),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: GageTheme.primary.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(item['path']!, fit: BoxFit.cover),
                      if (isSelected)
                        Container(
                          color: GageTheme.primary.withValues(alpha: 0.3),
                          child: const Center(
                            child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 110,
                  child: Text(
                    item['label']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.fromLTRB(20, 16, 20, keyboardSpace + 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.art_track_rounded, color: GageTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola Banner Terpadu (WYSIWYG)',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      Text(
                        'Target: ${widget.screenTarget}',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. LIVE PREVIEW BANNER REALTIME
            _buildLivePreview(context, isDark),
            const SizedBox(height: 16),

            // 2. GANTI GAMBAR BANNER (VISUAL GALLERY + GALERI HP)
            _buildFieldLabel('PILIH FOTO BANNER:'),
            const SizedBox(height: 4),

            // Tombol Pilih dari Galeri HP
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: GageTheme.primary,
                  side: const BorderSide(color: GageTheme.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                ),
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: const Text('Pilih Foto Baru dari Galeri HP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                onPressed: _pickImageFromGallery,
              ),
            ),
            const SizedBox(height: 12),

            // Thumbnail Carousel Preset Layanan
            _buildFieldLabel('Atau Pilih Preset Gambar Layanan:'),
            const SizedBox(height: 6),
            _buildPresetGallery(context, isDark),
            const SizedBox(height: 12),

            // Toggle Input Manual
            InkWell(
              onTap: () => setState(() => _showManualUrl = !_showManualUrl),
              child: Row(
                children: [
                  Icon(_showManualUrl ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _showManualUrl ? 'Sembunyikan URL Gambar Manual' : 'Atur URL Gambar Manual (Opsional)',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (_showManualUrl) ...[
              const SizedBox(height: 8),
              _buildCleanTextField(_imageCtrl, 'assets/images/... atau https://...'),
            ],
            const SizedBox(height: 16),

            // 3. FORM TEXT FIELDS (iOS Inset Style)
            _buildFieldLabel('Judul Promosi / Teks Utama:'),
            _buildCleanTextField(_titleCtrl, 'Masukkan judul promo...'),
            const SizedBox(height: 12),

            _buildFieldLabel('Subjudul / Deskripsi Singkat:'),
            _buildCleanTextField(_subtitleCtrl, 'Masukkan keterangan...'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Badge Tag:'),
                      _buildCleanTextField(_badgeCtrl, 'PROMO UTAMA'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Aksi / Route (Opsional):'),
                      _buildCleanTextField(_actionCtrl, 'food / send / ride'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                if (widget.bannerId != null) ...[
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      foregroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Hapus Banner',
                    onPressed: _isSaving ? null : _handleDelete,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Simpan ke Cloudflare D1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  Widget _buildCleanTextField(TextEditingController ctrl, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 12.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.black38),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
