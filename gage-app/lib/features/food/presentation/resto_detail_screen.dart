import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'resto_info_screen.dart';
import 'favorite_resto_screen.dart';
import 'item_variant_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_digital_schedule_sheet.dart';
import 'package:gage_app/shared/widgets/switch_merchant_dialog.dart';
import 'package:gage_app/shared/widgets/gage_merchant_tier_badge.dart';
import 'package:gage_app/data/models/cart_item_model.dart';

/// Alias untuk mendukung navigasi generik lintas merchant domain (Food, Shop, Farm, Build)
typedef MerchantDetailScreen = RestoDetailScreen;

class RestoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> merchant;

  const RestoDetailScreen({
    super.key,
    required this.merchant,
  });

  @override
  State<RestoDetailScreen> createState() => _RestoDetailScreenState();
}

class _RestoDetailScreenState extends State<RestoDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isHeaderCollapsed = false;
  bool _isFavorite = false;
  final Map<String, String> _tempNotes = {};

  String get _serviceDomain {
    if (widget.merchant['domain'] != null && widget.merchant['domain'].toString().isNotEmpty) {
      return widget.merchant['domain'].toString().toLowerCase();
    }
    if (widget.merchant['serviceType'] != null && widget.merchant['serviceType'].toString().isNotEmpty) {
      return widget.merchant['serviceType'].toString().toLowerCase();
    }
    final raw = (widget.merchant['id'] ?? widget.merchant['category'] ?? widget.merchant['name'] ?? '').toString().toLowerCase();
    if (raw.contains('build') || raw.contains('tb-') || raw.contains('bangun') || raw.contains('material') || raw.contains('besi') || raw.contains('cat-')) {
      return 'build';
    }
    if (raw.contains('farm') || raw.contains('tani') || raw.contains('ternak') || raw.contains('pupuk') || raw.contains('pakan')) {
      return 'farm';
    }
    if (raw.contains('shop') || raw.contains('sembako') || raw.contains('toko') || raw.contains('kelontong') || raw.contains('minimarket') || raw.contains('mart')) {
      return 'shop';
    }
    return 'food';
  }

  String get _domainLabel {
    switch (_serviceDomain) {
      case 'build': return 'GAGE Build';
      case 'farm': return 'GAGE Farm';
      case 'shop': return 'GAGE Shop';
      default: return 'GAGE Food';
    }
  }

  String get _domainItemTerm {
    switch (_serviceDomain) {
      case 'build': return 'material & alat bangunan';
      case 'farm': return 'sarana tani & pakan';
      case 'shop': return 'produk belanjaan & sembako';
      default: return 'kuliner lezat';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMenus();
    _loadFavoriteStatus();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final id = widget.merchant['id'] ?? 'm-dimsum-sewu';
    if (mounted) {
      setState(() {
        _isFavorite = prefs.getBool('fav_resto_$id') ?? false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final id = widget.merchant['id'] ?? 'm-dimsum-sewu';
    final newVal = !_isFavorite;
    await prefs.setBool('fav_resto_$id', newVal);
    if (mounted) {
      setState(() => _isFavorite = newVal);
      GageToast.show(
        context,
        newVal ? '${_serviceDomain == 'food' ? 'Resto' : 'Toko'} ditambahkan ke Favorit' : '${_serviceDomain == 'food' ? 'Resto' : 'Toko'} dihapus dari Favorit',
        type: newVal ? GageToastType.success : GageToastType.info,
      );
    }
  }

  Future<void> _showSwitchMerchantDialog(
    BuildContext context,
    CartProvider cart,
    CartItemModel newItem,
  ) async {
    final currentStore = cart.merchantName ?? 'Resto Lain';
    final newStore = newItem.merchantName;
    final confirmed = await SwitchMerchantDialog.show(
      context,
      currentMerchantName: currentStore,
      newMerchantName: newStore,
    );
    if (confirmed == true) {
      cart.addItem(newItem, forceReplace: true);
    }
  }

  void _showShareBottomSheet(BuildContext context, String restoName, String restoAddress) {
    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: GageTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bagikan $restoName',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        restoAddress,
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareAction(
                  icon: Icons.chat_bubble_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final text = Uri.encodeComponent(
                      'Yuk pesan $_domainItemTerm di $restoName lewat $_domainLabel!\n📍 Alamat: $restoAddress\n🔗 https://gage.app/m/${widget.merchant['id'] ?? 'resto'}'
                    );
                    final waUri = Uri.parse('whatsapp://send?text=$text');
                    final webUri = Uri.parse('https://wa.me/?text=$text');
                    try {
                      if (await canLaunchUrl(waUri)) {
                        await launchUrl(waUri);
                      } else {
                        await launchUrl(webUri, mode: LaunchMode.externalApplication);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        GageToast.show(context, 'Membuka WhatsApp...', type: GageToastType.info);
                      }
                    }
                  },
                ),
                _buildShareAction(
                  icon: Icons.copy_rounded,
                  label: 'Salin Tautan',
                  color: const Color(0xFF3B82F6),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final link = 'https://gage.app/m/${widget.merchant['id'] ?? 'resto'} - $restoName ($restoAddress)';
                    await Clipboard.setData(ClipboardData(text: link));
                    if (context.mounted) {
                      GageToast.show(context, 'Tautan $restoName berhasil disalin ke clipboard!', type: GageToastType.success);
                    }
                  },
                ),
                _buildShareAction(
                  icon: Icons.share_location_rounded,
                  label: 'Bagikan Lokasi',
                  color: const Color(0xFFF97316),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final query = Uri.encodeComponent('$restoName, $restoAddress');
                    final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                    try {
                      if (await canLaunchUrl(mapsUrl)) {
                        await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
                      } else {
                        await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        GageToast.show(context, 'Membuka Google Maps...', type: GageToastType.info);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildShareAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final isCollapsed = offset > 140;
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = isCollapsed;
      });
    }
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);
    final merchantId = widget.merchant['id'] ?? 'm-dimsum-sewu';
    final items = await GageApiClient.getMerchantMenu(merchantId);
    if (!mounted) return;
    setState(() {
      _menuItems = items;
      _isLoading = false;
    });
  }

  int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(cleaned) ?? fallback;
    }
    return fallback;
  }

  List<Map<String, dynamic>> get _filteredMenus {
    var list = _menuItems;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((m) {
        final name = (m['name'] ?? '').toString().toLowerCase();
        final desc = (m['description'] ?? '').toString().toLowerCase();
        return name.contains(q) || desc.contains(q);
      }).toList();
    }
    return list;
  }

  void _showGroupOrderSheet(BuildContext context, CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGroupActive = cart.groupOrderId != null;
    final roomId = cart.groupOrderId ?? 'GAGE-8821';
    final restoName = widget.merchant['name'] ?? 'Resto';

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pesan Bareng (Group Order)',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.groups_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pesan Bareng ke 1 Alamat',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ajak teman atau keluarga pesan di $restoName sekaligus. Setiap orang bisa pilih menu masing-masing, bayar jadi 1 ongkir hemat!',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Room Code Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KODE RUANGAN PESANAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roomId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: GageTheme.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 14),
                        label: const Text('Bagi ke WA', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          GageToast.show(
                            context,
                            'Tautan Pesan Bareng $roomId disalin ke WhatsApp!',
                            type: GageToastType.success,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Anggota Pesan Bareng (2 Orang)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: GageTheme.primary,
                            child: Text('K', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Kamu (Host Pesanan)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Siap Order', style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blue.shade600,
                            child: const Text('B', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Budi (Anggota)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Memilih Menu...', style: TextStyle(color: Colors.amber.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGroupActive ? Colors.grey.shade700 : GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (isGroupActive) {
                        cart.deactivateGroupOrder();
                        GageToast.show(
                          context,
                          'Pesan Bareng dinonaktifkan',
                          type: GageToastType.info,
                        );
                      } else {
                        cart.activateGroupOrder(
                          roomId,
                          merchantId: widget.merchant['id'] ?? 'm-dimsum-sewu',
                          merchantName: widget.merchant['name'] ?? 'Dimsum Sewu by Halu Goods',
                        );
                        GageToast.show(
                          context,
                          'Pesan Bareng aktif ($roomId)! 2 Teman bergabung',
                          type: GageToastType.success,
                        );
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      isGroupActive ? 'Akhiri Pesan Bareng' : 'Mulai Pesan Bareng Sekarang',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showJadwalinSheet(BuildContext context, CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? selectedTime = cart.scheduledDeliveryTime;
    String scheduleMode = selectedTime == null ? 'now' : 'custom';

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final nowPlus1Hour = DateTime.now().add(const Duration(hours: 1));

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jadwalkan Pengantaran',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih kapan resto harus menyiapkan dan mengantar pesanan Anda.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                // 1. Kirim Sekarang (Full Rounded Pill 24px)
                _buildSchedulePillOption(
                  isDark: isDark,
                  isSelected: scheduleMode == 'now',
                  icon: Icons.bolt_rounded,
                  title: 'Kirim Sekarang',
                  subtitle: 'Estimasi tiba 20-30 menit',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setSheetState(() {
                      scheduleMode = 'now';
                      selectedTime = null;
                    });
                  },
                ),

                const SizedBox(height: 10),

                // 2. 1 Jam Lagi (Full Rounded Pill 24px)
                _buildSchedulePillOption(
                  isDark: isDark,
                  isSelected: scheduleMode == '1hour',
                  icon: Icons.schedule_rounded,
                  title: '1 Jam Lagi',
                  subtitle: "${DateFormat('HH:mm').format(nowPlus1Hour)} WIB",
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setSheetState(() {
                      scheduleMode = '1hour';
                      selectedTime = nowPlus1Hour;
                    });
                  },
                ),

                const SizedBox(height: 10),

                // 3. Atur Sendiri (Langsung Buka Digital Picker, Full Rounded Pill 24px)
                _buildSchedulePillOption(
                  isDark: isDark,
                  isSelected: scheduleMode == 'custom',
                  icon: Icons.edit_calendar_rounded,
                  title: 'Atur Sendiri',
                  subtitle: selectedTime != null && scheduleMode == 'custom'
                      ? "${DateFormat('dd MMM, HH:mm').format(selectedTime!)} WIB"
                      : 'Pilih tanggal & jam pengantaran bebas',
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final picked = await GageDigitalScheduleSheet.show(
                      context,
                      initialTime: selectedTime ?? DateTime.now().add(const Duration(hours: 2)),
                    );
                    if (picked != null) {
                      setSheetState(() {
                        scheduleMode = 'custom';
                        selectedTime = picked;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      cart.setScheduledDeliveryTime(selectedTime);
                      Navigator.pop(ctx);
                      GageToast.show(
                        context,
                        selectedTime != null
                            ? "Pengantaran dijadwalkan pukul ${DateFormat('HH:mm').format(selectedTime!)} WIB"
                            : 'Pengantaran diatur langsung (Kirim Sekarang)',
                        type: GageToastType.info,
                      );
                    },
                    child: const Text('Simpan Jadwal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSchedulePillOption({
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? GageTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GageTheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? GageTheme.primary.withValues(alpha: 0.14)
                    : (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? GageTheme.primary : Colors.grey.shade600,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? GageTheme.primary : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFallbackIcon(dynamic categoryVal) {
    final cat = (categoryVal ?? '').toString().toLowerCase();
    final mCat = (widget.merchant['category'] ?? '').toString().toLowerCase();
    final mId = (widget.merchant['id'] ?? '').toString().toLowerCase();
    if (cat.contains('bangun') || cat.contains('semen') || cat.contains('cat') || cat.contains('besi') ||
        mCat.contains('bangun') || mId.contains('build') || mId.contains('tb-')) {
      return Icons.construction_rounded;
    }
    if (cat.contains('tani') || cat.contains('pupuk') || cat.contains('benih') || cat.contains('pakan') ||
        mCat.contains('tani') || mCat.contains('ternak') || mId.contains('farm')) {
      return Icons.agriculture_rounded;
    }
    if (cat.contains('sembako') || cat.contains('beras') || cat.contains('kelontong') ||
        mCat.contains('sembako') || mId.contains('shop')) {
      return Icons.storefront_rounded;
    }
    return Icons.restaurant_rounded;
  }

  String _getMenuItemImage(Map<String, dynamic> item) {
    if (item['image'] != null && item['image'].toString().isNotEmpty) {
      return item['image'].toString();
    }
    final name = (item['name'] ?? '').toString().toLowerCase();
    final cat = (item['category'] ?? '').toString().toLowerCase();
    final mCat = (widget.merchant['category'] ?? '').toString().toLowerCase();
    final mId = (widget.merchant['id'] ?? '').toString().toLowerCase();

    // 1. Bahan Bangunan
    if (name.contains('semen')) return 'assets/images/prod_semen.png';
    if (name.contains('cat')) return 'assets/images/prod_cat.png';
    if (name.contains('besi') || name.contains('baja')) return 'assets/images/prod_besi.png';
    if (name.contains('pipa') || name.contains('kuas') || name.contains('pertukangan')) {
      return 'assets/images/prod_traktor.png';
    }

    // 2. Pertanian & Peternakan
    if (name.contains('pupuk') || name.contains('urea') || name.contains('npk')) return 'assets/images/prod_pupuk.png';
    if (name.contains('benih') || name.contains('bibit')) return 'assets/images/prod_benih.png';
    if (name.contains('pakan') || name.contains('konsentrat')) return 'assets/images/prod_pakan.png';
    if (name.contains('sprayer') || name.contains('insektisida')) return 'assets/images/prod_traktor.png';

    // 3. Sembako & Belanja
    if (name.contains('beras')) return 'assets/images/prod_beras.png';
    if (name.contains('minyak')) return 'assets/images/prod_minyak.png';
    if (name.contains('gula')) return 'assets/images/prod_gula.png';
    if (name.contains('telur')) return 'assets/images/prod_telur.png';
    if (name.contains('indomie') || name.contains('mie instan') || name.contains('terigu')) return 'assets/images/prod_indomie.png';
    if (name.contains('cabai') || name.contains('cabe') || name.contains('sayur') || name.contains('bayam')) {
      return 'assets/images/prod_cabai.png';
    }

    // 4. Makanan & Minuman
    if (name.contains('mentai')) return 'assets/images/dish_dimsum_mentai.png';
    if (name.contains('burger')) return 'assets/images/dish_chicken_burger.png';
    if (name.contains('kentang') || name.contains('fries')) return 'assets/images/dish_french_fries.png';
    if (name.contains('seblak')) return 'assets/images/dish_seblak_komplit.png';
    if (name.contains('cimol')) return 'assets/images/dish_cimol_bojot.png';
    if (name.contains('roti') && name.contains('keju')) return 'assets/images/dish_roti_keju.png';
    if (name.contains('roti')) return 'assets/images/dish_roti_cokelat.png';
    if (name.contains('kopi')) return 'assets/images/dish_kopi_susu.png';
    if (name.contains('sate')) return 'assets/images/dish_sate_ayam.png';
    if (name.contains('bakso')) return 'assets/images/dish_bakso_urat.png';
    if (name.contains('mie') || name.contains('pangsit')) return 'assets/images/dish_mie_ayam.png';
    if (name.contains('ayam') || name.contains('geprek') || name.contains('rocket') || name.contains('chicken')) {
      return 'assets/images/dish_rocket_1.png';
    }
    if (name.contains('teh') || name.contains('es') || name.contains('jeruk') || name.contains('minum') || cat.contains('minum')) {
      return 'assets/images/dish_es_teh.png';
    }

    // 5. Merchant Category Fallback (Tanpa Fallback Dimsum di Luar Resto Food)
    if (mId.contains('build') || mCat.contains('bangun')) return 'assets/images/prod_semen.png';
    if (mId.contains('farm') || mCat.contains('tani') || mCat.contains('ternak')) return 'assets/images/prod_pupuk.png';
    if (mId.contains('shop') || mCat.contains('sembako')) return 'assets/images/prod_beras.png';

    return 'assets/images/dish_dimsum_original.png';
  }

  List<Widget> _buildServiceVouchers(BuildContext context, CartProvider cart, bool isDark) {
    final mCat = (widget.merchant['category'] ?? '').toString().toLowerCase();
    final mId = (widget.merchant['id'] ?? '').toString().toLowerCase();

    if (mId.contains('build') || mCat.contains('bangun')) {
      return [
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'PROYEKHEMAT',
          title: 'Diskon material Rp 15.000',
          sub: 'Min. pembelian Rp 50.000',
          discount: 15000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'BANGUNRUMAH',
          title: 'Diskon material Rp 25.000',
          sub: 'Min. pembelian Rp 100.000',
          discount: 25000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'ONGKIRFREE',
          title: 'Gratis ongkir s/d 10rb',
          sub: 'Min. pembelian Rp 50.000',
          discount: 10000,
          isFood: false,
          isDark: isDark,
        ),
      ];
    } else if (mId.contains('farm') || mCat.contains('tani') || mCat.contains('ternak')) {
      return [
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'SUBSIDITANI',
          title: 'Diskon tani Rp 10.000',
          sub: 'Min. pembelian Rp 30.000',
          discount: 10000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'PETANISUKSES',
          title: 'Diskon tani Rp 15.000',
          sub: 'Min. pembelian Rp 50.000',
          discount: 15000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'ONGKIRFREE',
          title: 'Gratis ongkir s/d 7rb',
          sub: 'Min. pembelian Rp 25.000',
          discount: 7000,
          isFood: false,
          isDark: isDark,
        ),
      ];
    } else if (mId.contains('shop') || mCat.contains('sembako') || mCat.contains('kelontong')) {
      return [
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'BELANJAHEMAT',
          title: 'Diskon belanja Rp 8.000',
          sub: 'Min. pembelian Rp 25.000',
          discount: 8000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'SEMBAKOMURAH',
          title: 'Diskon sembako Rp 10.000',
          sub: 'Min. pembelian Rp 40.000',
          discount: 10000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'ONGKIRFREE',
          title: 'Gratis ongkir s/d 7rb',
          sub: 'Min. pembelian Rp 20.000',
          discount: 7000,
          isFood: false,
          isDark: isDark,
        ),
      ];
    } else {
      return [
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'GAGEHEMAT',
          title: 'Diskon makanan Rp 8.000',
          sub: 'Min. pembelian Rp 15.000',
          discount: 8000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'KULINER10',
          title: 'Diskon makanan Rp 10.000',
          sub: 'Min. pembelian Rp 30.000',
          discount: 10000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'ONGKIRFREE',
          title: 'Gratis ongkir s/d 7rb',
          sub: 'Min. pembelian Rp 20.000',
          discount: 7000,
          isFood: false,
          isDark: isDark,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = widget.merchant['name'] ?? 'Mie Ayam Mbak Linda, Maguhan';
    final category = widget.merchant['category'] ?? 'Bakmie, Jajanan, Minuman';
    final address = widget.merchant['address'] ?? 'Maguhan, Pracimantoro, Solo';
    final String imageAsset = widget.merchant['image'] ?? 'assets/images/resto_dimsum_sewu.png';
    final rating = (widget.merchant['rating'] ?? 4.1).toDouble();
    final ratingCount = widget.merchant['ratingCount'] ?? '50+';
    final distance = widget.merchant['distance'] ?? '8.56 km';
    final isPickup = cart.isPickup;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadMenus,
            color: GageTheme.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Sliver App Bar dengan Scroll Morphing Header (Gambar 1)
                SliverAppBar(
                expandedHeight: 180.0,
                pinned: true,
                backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
                foregroundColor: _isHeaderCollapsed ? (isDark ? Colors.white : Colors.black87) : Colors.white,
                elevation: _isHeaderCollapsed ? 1.0 : 0.0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _isHeaderCollapsed ? (isDark ? GageTheme.darkCard : Colors.white) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? GageTheme.darkBorder : Colors.black12,
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                titleSpacing: _isHeaderCollapsed ? 8 : NavigationToolbar.kMiddleSpacing,
                title: _isHeaderCollapsed
                    ? Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                              width: 0.8,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Cari menu di resto ini...',
                              hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: GageTheme.primary),
                              suffixIcon: _searchQuery.isNotEmpty
                                   ? IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                      )
                    : null,
                actions: _isHeaderCollapsed
                    ? const []
                    : [
                        Padding(
                          padding: const EdgeInsets.only(right: 14.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _scrollController.animateTo(
                                    145,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark ? GageTheme.darkCard : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? GageTheme.darkBorder : Colors.black12,
                                      width: 0.8,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: isDark ? Colors.white : Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => const FavoriteRestoScreen()),
                                  );
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark ? GageTheme.darkCard : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? GageTheme.darkBorder : Colors.black12,
                                      width: 0.8,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Icon(
                                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: _isFavorite ? GageTheme.primary : (isDark ? Colors.white : Colors.black87),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showShareBottomSheet(context, name, address),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark ? GageTheme.darkCard : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? GageTheme.darkBorder : Colors.black12,
                                      width: 0.8,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.share_outlined,
                                    color: isDark ? Colors.white : Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: GageTheme.primaryLight),
                  ),
                ),
              ),

              // 2. KARTU DETAIL RESTO OVERLAY (Persis Gambar 1 Gojek)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isDark ? GageTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Restoran & Tombol Favorit
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (widget.merchant['tier'] != null || (widget.merchant['id']?.toString().contains('rc') == true) || (widget.merchant['id']?.toString().contains('dimsum') == true)) ...[
                                    GageMerchantTierBadge(
                                      tier: (widget.merchant['tier'] as String?) ??
                                          (widget.merchant['id']?.toString().contains('rc') == true ? 'exclusive' : 'star'),
                                      height: 18,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: _isFavorite ? GageTheme.primary : (isDark ? Colors.white60 : Colors.black45),
                                size: 22,
                              ),
                              onPressed: _toggleFavorite,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Baris Rating (Klik -> Buka Gambar 5 RestoInfoScreen)
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => RestoInfoScreen(
                                  restoName: name,
                                  restoImage: imageAsset,
                                  address: address,
                                  distance: distance,
                                  rating: rating,
                                  ratingCount: ratingCount.toString(),
                                  category: category,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF97316), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '$rating ($ratingCount)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade500),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Jarak & Waktu (Gambar 1)
                        Text(
                          '50-60 min ($distance)',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 14),

                        // Switcher Delivery vs Pickup (Full Pill Capsule)
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              // Tab Delivery
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (cart.isPickup) {
                                      cart.setIsPickup(false);
                                      GageToast.show(
                                        context,
                                        'Mode: Pesan Antar (Delivery) aktif',
                                        type: GageToastType.info,
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(26),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !isPickup ? GageTheme.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Delivery',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: !isPickup ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Tab Pickup
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (!cart.isPickup) {
                                      cart.setIsPickup(true);
                                      GageToast.show(
                                        context,
                                        'Mode: Ambil Sendiri (Pickup - Bebas Ongkir) aktif',
                                        type: GageToastType.info,
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(26),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isPickup ? GageTheme.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Pickup',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isPickup ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tombol Bawah: Group Order & Jadwalin (Berfungsi Nyata, 10px Rounded)
                        Row(
                          children: [
                            // Group Order
                            InkWell(
                              onTap: () => _showGroupOrderSheet(context, cart),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: cart.groupOrderId != null
                                      ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
                                      : (isDark ? GageTheme.darkSurface : Colors.white),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: cart.groupOrderId != null ? GageTheme.primary : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                    width: cart.groupOrderId != null ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.group_rounded, size: 16, color: GageTheme.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      cart.groupOrderId != null ? 'Group: ${cart.groupOrderId}' : 'Group Order',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: cart.groupOrderId != null ? GageTheme.primary : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: GageTheme.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cart.groupOrderId != null ? 'AKTIF' : 'NEW',
                                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Jadwalin
                            InkWell(
                              onTap: () => _showJadwalinSheet(context, cart),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: cart.scheduledDeliveryTime != null
                                      ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
                                      : (isDark ? GageTheme.darkSurface : Colors.white),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: cart.scheduledDeliveryTime != null ? GageTheme.primary : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                    width: cart.scheduledDeliveryTime != null ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      size: 16,
                                      color: cart.scheduledDeliveryTime != null ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cart.scheduledDeliveryTime != null
                                          ? 'Jadwal: ${DateFormat('HH:mm').format(cart.scheduledDeliveryTime!)}'
                                          : 'Jadwalin',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: cart.scheduledDeliveryTime != null ? GageTheme.primary : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. PROMO CAROUSEL KARTU DISKON (Interaktif & Real Voucher)
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 3,
                        itemBuilder: (ctx, idx) => const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: GageSkeletonPromoVoucherCard(),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: _buildServiceVouchers(context, cart, isDark),
                      ),
                    ),
                  ),
                ),

              // 4. DAFTAR MENU MAKANAN (Persis Gambar 1 Gojek)
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const GageSkeletonMenuItem(),
                      childCount: 4,
                    ),
                  ),
                )
              else if (_filteredMenus.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Belum ada menu di kategori ini.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _filteredMenus[index];
                        final price = _parseInt(item['gage_price'] ?? item['price'] ?? item['offline_price'], 0);
                        final menuId = (item['id'] ?? 'item-$index').toString();
                        final cartItem = cart.items.where((i) => i.menuId == menuId).firstOrNull;
                        final inCartQty = cartItem?.quantity ?? 0;
                        final currentNote = cartItem?.notes ?? _tempNotes[menuId] ?? '';
                        final menuImage = _getMenuItemImage(item);
                        final bool hasVariants = item['variants'] != null ||
                            item['has_variants'] == true ||
                            (item['name'] != null && item['name'].toString().toLowerCase().contains('combo'));

                        return InkWell(
                          onTap: () => _showProductDetailModal(context, item, cart),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
                              ),
                            ),
                            child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // KIRI: Nama Menu, Deskripsi, Harga (Gambar 1)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        item['description'],
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      currencyFormatter.format(price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              // KANAN: Foto Makanan + Stepper / Tambah (Gambar 1)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 86,
                                          height: 86,
                                          child: Image.asset(
                                            menuImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: GageTheme.primaryLight,
                                              child: Icon(_getFallbackIcon(item['category']), color: GageTheme.primary),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            final favKey = 'fav_item_$menuId';
                                            final isFav = _tempNotes[favKey] == 'true';
                                            setState(() {
                                              _tempNotes[favKey] = isFav ? 'false' : 'true';
                                            });
                                            GageToast.show(
                                              context,
                                              !isFav ? '${item['name']} disukai!' : '${item['name']} dihapus dari favorit',
                                              type: !isFav ? GageToastType.success : GageToastType.info,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                                            ),
                                            child: Icon(
                                              _tempNotes['fav_item_$menuId'] == 'true' ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              size: 14,
                                              color: _tempNotes['fav_item_$menuId'] == 'true' ? GageTheme.primary : Colors.black45,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Stepper or Tambah button (Full Rounded 24px Capsule)
                                  if (inCartQty > 0) ...[
                                    Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: GageTheme.primary, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: GageTheme.primary.withValues(alpha: 0.15),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => cart.updateQuantity(menuId, -1),
                                            borderRadius: BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              child: Icon(Icons.remove, color: GageTheme.primary, size: 16),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            child: Text(
                                              '$inCartQty',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => cart.updateQuantity(menuId, 1),
                                            borderRadius: BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              child: Icon(Icons.add, color: GageTheme.primary, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (hasVariants) ...[
                                      const SizedBox(height: 6),
                                      // Tombol Catatan & Varian (Capsule 24px)
                                      InkWell(
                                        onTap: () => ItemVariantSheet.show(
                                          context,
                                          menuItem: item,
                                          merchant: widget.merchant,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.tune_rounded, size: 12, color: Colors.black54),
                                              const SizedBox(width: 4),
                                              Text(
                                                currentNote.isNotEmpty ? currentNote : 'Ubah Varian',
                                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87),
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ] else
                                    SizedBox(
                                      height: 32,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GageTheme.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          if (hasVariants) {
                                            ItemVariantSheet.show(
                                              context,
                                              menuItem: item,
                                              merchant: widget.merchant,
                                            );
                                          } else {
                                            final price = _parseInt(item['price'] ?? item['gage_price'] ?? item['offline_price'], 0);
                                            final model = CartItemModel(
                                              menuId: menuId,
                                              merchantId: widget.merchant['id'] ?? 'm-dimsum-sewu',
                                              merchantName: widget.merchant['name'] ?? 'Dimsum Sewu by Halu Goods',
                                              name: item['name'] ?? '',
                                              price: price,
                                              quantity: 1,
                                              category: item['category'] ?? 'Menu',
                                              imageUrl: _getMenuItemImage(item),
                                              serviceType: _serviceDomain,
                                            );
                                            final added = cart.addItem(model);
                                            if (!added) {
                                              _showSwitchMerchantDialog(context, cart, model);
                                            } else {
                                              HapticFeedback.lightImpact();
                                              GageToast.show(
                                                context,
                                                '${item['name']} ditambahkan ke keranjang',
                                                type: GageToastType.success,
                                              );
                                            }
                                          }
                                        },
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add, size: 15),
                                            SizedBox(width: 2),
                                            Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                      },
                      childCount: _filteredMenus.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),

          // Floating Cart Bar (Persis Gambar 1)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SeamlessFloatingCartBar(),
          ),
        ],
      ),
    );
  }

  void _showProductDetailModal(BuildContext context, Map<String, dynamic> item, CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final price = _parseInt(item['gage_price'] ?? item['price'] ?? item['offline_price'], 10000);
    final menuId = item['id'] ?? 'item-generic';
    final menuImage = _getMenuItemImage(item);

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final inCartQty = cart.getItemQuantity(menuId);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle & close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? 'Detail Menu',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Foto Produk 1:1 Square dengan Badge Kategori di Pojok Kanan Atas
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            menuImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              child: Icon(_getFallbackIcon(item['category']), size: 48, color: GageTheme.primary),
                            ),
                          ),
                        ),
                        if (item['category'] != null && item['category'].toString().isNotEmpty)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['category'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Baris: Harga di kiri, Tombol Tambah / Stepper di kanan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      currencyFormatter.format(price),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: GageTheme.primary,
                      ),
                    ),
                    if (inCartQty == 0)
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final newItem = CartItemModel(
                              menuId: menuId,
                              merchantId: widget.merchant['id'] ?? 'm-default',
                              merchantName: widget.merchant['name'] ?? 'Resto',
                              name: item['name'] ?? 'Menu',
                              price: price,
                              quantity: 1,
                              imageUrl: menuImage,
                              serviceType: _serviceDomain,
                            );
                            cart.addItem(newItem);
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'Tambah',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: GageTheme.primary, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                if (inCartQty > 0) {
                                  cart.updateQuantity(menuId, -1);
                                  setModalState(() {});
                                }
                              },
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.remove, size: 16, color: GageTheme.primary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$inCartQty',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final newItem = CartItemModel(
                                  menuId: menuId,
                                  merchantId: widget.merchant['id'] ?? 'm-default',
                                  merchantName: widget.merchant['name'] ?? 'Resto',
                                  name: item['name'] ?? 'Menu',
                                  price: price,
                                  quantity: 1,
                                  imageUrl: menuImage,
                                  serviceType: _serviceDomain,
                                );
                                cart.addItem(newItem);
                                setModalState(() {});
                              },
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.add, size: 16, color: GageTheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Deskripsi Produk
                Text(
                  item['description'] ?? 'Menu lezat disiapkan dengan bahan segar pilihan berkualitas khas resto.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildInteractiveVoucherCard({
    required BuildContext context,
    required CartProvider cart,
    required String code,
    required String title,
    required String sub,
    required int discount,
    required bool isFood,
    required bool isDark,
  }) {
    // Sunset Orange (#EA580C) for Food discount, Deep Teal (#0D9488) for Delivery discount
    final activeColor = isFood ? const Color(0xFFEA580C) : const Color(0xFF0D9488);
    final bgColor = isFood
        ? (isDark ? const Color(0xFF2A170A) : const Color(0xFFFFF7ED))
        : (isDark ? const Color(0xFF032726) : const Color(0xFFF0FDFA));
    final badgeTag = isFood ? '-${discount ~/ 1000}RB' : 'ONGKIR';
    final isApplied = isFood ? cart.foodPromoCode == code : cart.deliveryPromoCode == code;

    return GestureDetector(
      onTap: () {
        if (isApplied) {
          if (isFood) {
            cart.removeFoodPromo();
          } else {
            cart.removeDeliveryPromo();
          }
          GageToast.show(context, 'Voucher $code dilepas', type: GageToastType.info);
        } else {
          if (isFood) {
            cart.setFoodPromo(code, discount);
          } else {
            cart.setDeliveryPromo(code, discount);
          }
          GageToast.show(context, 'Voucher $code berhasil dipasang!', type: GageToastType.success);
        }
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isApplied ? activeColor : activeColor.withValues(alpha: 0.35),
            width: isApplied ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFood ? Icons.local_offer_rounded : Icons.delivery_dining_rounded,
                color: activeColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badgeTag,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.grey.shade400 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isApplied) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, color: activeColor, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
