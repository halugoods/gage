import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';

/// Screen Pusat Chat & Multi-WhatsApp Gateway - Tab 2
/// Mengintegrasikan 2 Saluran Komunikasi Operasional:
/// 1. Chat In-App (Live Hub antara Pelanggan, Pengemudi, Merchant & Admin)
/// 2. Multi-WhatsApp Gateway (4 Profil Sesi dengan Mekanisme Pairing Code 8-Digit & QR ala Nusa Kasir + AI Agent Antigravity)
class AdminWhatsappCenterScreen extends StatefulWidget {
  const AdminWhatsappCenterScreen({super.key});

  @override
  State<AdminWhatsappCenterScreen> createState() => _AdminWhatsappCenterScreenState();
}

class _AdminWhatsappCenterScreenState extends State<AdminWhatsappCenterScreen> {
  int _activeChannelIndex = 0; // 0: Chat In-App, 1: Multi-WhatsApp Gateway
  int _selectedWaSessionIndex = 0; // 0: CS, 1: Dispatcher, 2: Merchant, 3: BaBe

  // WhatsApp Pairing State (ala Nusa Kasir)
  int _loginMethodTab = 0; // 0: Pairing Code, 1: Scan QR
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _requestingPairCode = false;
  String? _pairCode;
  final String _qrData = '2@gage-admin-mock-qr-payload';

  // 4 Profil WhatsApp Resmi GAGE
  final List<Map<String, dynamic>> _waProfiles = [
    {
      'id': 'gage-cs',
      'title': 'Customer Service',
      'icon': Icons.support_agent_rounded,
      'color': const Color(0xFF00AA13),
      'connected': true,
      'phone': '+62 812-3456-7890',
      'accountName': 'GAGE Customer Care',
      'agentName': 'GageCare AI',
      'agentModel': 'Antigravity CLI • Gemini 2.5 Flash',
      'agentDescription': 'Menjawab keluhan pelanggan, panduan belanja, voucher diskon & eskalasi kasus penting.',
      'aiEnabled': true,
      'activeThreads': 34,
      'recentChats': [
        {
          'name': 'Ibu Nurhayati',
          'phone': '+62 857-8899-0011',
          'lastMsg': 'Mba, pesanan sayur saya sudah jalan belum ya?',
          'time': '12:48',
          'aiHandled': true,
          'memoryContext': 'Pelanggan rutin Kios Sayur Bu Slamet. Selalu pesan pagi & metode QRIS.',
          'aiReply': 'Pesanan sayur Ibu dari Kios Bu Slamet sudah dibawa oleh Mas Agus Setiawan (Yamaha NMAX) dan estimasi tiba 8 menit lagi nggih Bu. 🛵',
        },
        {
          'name': 'Pak Haji Marwan',
          'phone': '+62 812-3344-5566',
          'lastMsg': 'Matur nuwun mas, semen sudah sampai aman.',
          'time': '11:30',
          'aiHandled': true,
          'memoryContext': 'Pemilik Toko Bangunan Berkah Jaya. Rutin kirim via GAGE Send ke Tubokarto.',
          'aiReply': 'Sami-sami Pak Marwan. Senang bisa membantu kelancaran proyek Bapak. 🙏',
        },
      ],
    },
    {
      'id': 'gage-dispatcher',
      'title': 'Dispatcher',
      'icon': Icons.two_wheeler_rounded,
      'color': GageTheme.primary,
      'connected': true,
      'phone': '+62 857-1234-5678',
      'accountName': 'GAGE Dispatcher Center',
      'agentName': 'GageDispatch AI',
      'agentModel': 'Antigravity CLI • Gemini 2.5 Flash',
      'agentDescription': 'Membantu driver di lapangan, alokasi order tertunda, pengawasan rute & pangkalan.',
      'aiEnabled': true,
      'activeThreads': 18,
      'recentChats': [
        {
          'name': 'Mas Budi Santoso (Driver Motor)',
          'phone': '+62 812-3456-7890',
          'lastMsg': 'Siap min, meluncur ke resto Dimsum Sewu sekarang.',
          'time': '12:42',
          'aiHandled': true,
          'memoryContext': 'Driver pangkalan Pasar Praci. Rating 4.96, responsif order makanan & antaran cepat.',
          'aiReply': 'Hati-hati di jalan Mas Budi, estimasi jemput 4 menit.',
        },
        {
          'name': 'Pak Joko Purnomo (Driver Mobil)',
          'phone': '+62 857-1234-5678',
          'lastMsg': 'Terminal posisi aman, ada 2 mobil standby carter.',
          'time': '10:15',
          'aiHandled': false,
          'memoryContext': 'Driver mobil pangkalan Terminal Praci.',
          'aiReply': '',
        },
      ],
    },
    {
      'id': 'gage-merchant',
      'title': 'Merchant Support',
      'icon': Icons.storefront_rounded,
      'color': Colors.orange.shade800,
      'connected': false,
      'phone': '',
      'accountName': '',
      'agentName': 'GageMerchant AI',
      'agentModel': 'Antigravity CLI • Gemini 2.5 Flash',
      'agentDescription': 'Panduan resto & kios kelontong, update harga/menu, kendala dapur & pencairan dana payout.',
      'aiEnabled': true,
      'activeThreads': 0,
      'recentChats': [],
    },
    {
      'id': 'gage-babe',
      'title': 'Kurasi BaBe',
      'icon': Icons.verified_rounded,
      'color': Colors.blue.shade700,
      'connected': false,
      'phone': '',
      'accountName': '',
      'agentName': 'GageCuration AI',
      'agentModel': 'Antigravity CLI • Gemini 2.5 Flash',
      'agentDescription': 'Verifikasi keaslian barang bekas, inspeksi kondisi fisik, negosiasi harga wajar & persetujuan tayang.',
      'aiEnabled': true,
      'activeThreads': 0,
      'recentChats': [],
    },
  ];

  // Data Percakapan Chat In-App Live
  final List<Map<String, dynamic>> _inAppConversations = [
    {
      'orderId': 'ORD-9021',
      'customerName': 'Siti Rahmawati',
      'serviceType': 'GAGE Food (Dimsum Sewu)',
      'driverName': 'Budi Santoso (Driver)',
      'merchantName': 'Dimsum Sewu Mas Agus',
      'lastMsg': 'Halo mas Budi, sambalnya minta tolong dipisah yaa.',
      'lastSender': 'Siti Rahmawati',
      'time': '12:44',
      'unread': 1,
      'status': 'Sedang Diantar',
    },
    {
      'orderId': 'ORD-9019',
      'customerName': 'Pak Hendro',
      'serviceType': 'GAGE Shop (Apotek)',
      'driverName': 'Agus Setiawan (Driver)',
      'merchantName': 'Apotek Kimia Farma',
      'lastMsg': 'Obat resep sudah saya tebus di kasir apotek nggih Pak.',
      'lastSender': 'Agus Setiawan (Driver)',
      'time': '12:35',
      'unread': 0,
      'status': 'Sedang Diantar',
    },
    {
      'orderId': 'RIDE-8812',
      'customerName': 'Nurul Khotimah',
      'serviceType': 'GAGE Ride (Motor)',
      'driverName': 'Bambang Triyono (Driver)',
      'merchantName': '-',
      'lastMsg': 'Saya sudah di depan gerbang kantor pos.',
      'lastSender': 'Nurul Khotimah',
      'time': '11:20',
      'unread': 0,
      'status': 'Menunggu Jemputan',
    },
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _requestPairingCode() {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor WhatsApp terlebih dahulu')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _requestingPairCode = true);

    // Simulasi respons RPC engine ezpzpay (350ms)
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _requestingPairCode = false;
        // Format kode 8 digit pairing: ABCD-EFGH
        _pairCode = 'GAGE-${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
      });
    });
  }

  void _copyPairCode() {
    if (_pairCode == null) return;
    Clipboard.setData(ClipboardData(text: _pairCode!));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode pairing berhasil disalin ke clipboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _disconnectSession(Map<String, dynamic> session) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Putuskan Tautan WhatsApp?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Sesi "${session['title']}" akan terputus dari server WhatsApp.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                session['connected'] = false;
                session['phone'] = '';
                session['accountName'] = '';
                session['recentChats'] = [];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tautan WhatsApp berhasil diputuskan.')),
              );
            },
            child: const Text('Putuskan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat & WhatsApp Gateway',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'Live Hub In-App & Multi-Akun WhatsApp Terpadu',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Tab Channel: Chat In-App vs Multi-WhatsApp Gateway
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildChannelTab(
                      index: 0,
                      label: 'Chat In-App (Live Hub)',
                      icon: Icons.forum_rounded,
                      badgeCount: _inAppConversations.where((c) => (c['unread'] as int? ?? 0) > 0).length,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildChannelTab(
                      index: 1,
                      label: 'Multi-WhatsApp Gateway',
                      icon: Icons.chat_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: _activeChannelIndex == 0
                  ? _buildInAppChatList(isDark)
                  : _buildMultiWhatsAppGateway(isDark),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildChannelTab({
    required int index,
    required String label,
    required IconData icon,
    int badgeCount = 0,
    required bool isDark,
  }) {
    final isSelected = _activeChannelIndex == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeChannelIndex = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? GageTheme.primary : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GageTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. CHAT IN-APP LIVE HUB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInAppChatList(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _inAppConversations.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final conv = _inAppConversations[idx];
        final orderId = conv['orderId'] as String;
        final unread = conv['unread'] as int? ?? 0;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InAppChatScreen(
                  orderId: orderId,
                  recipientName: conv['customerName'] as String? ?? 'Pelanggan',
                  recipientRole: 'customer',
                  recipientPhone: '+62 812-0000-0000',
                  currentRole: 'merchant',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unread > 0 ? GageTheme.primary.withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.grey.shade200),
                width: unread > 0 ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        orderId,
                        style: const TextStyle(color: GageTheme.primary, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                    Row(
                      children: [
                        Text(conv['time'] as String, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                        if (unread > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: GageTheme.primary, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  conv['customerName'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Text(
                  conv['serviceType'] as String,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${conv['lastSender']}: ${conv['lastMsg']}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. MULTI-WHATSAPP GATEWAY (ALA NUSA KASIR & EZPZAI)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMultiWhatsAppGateway(bool isDark) {
    final currentProfile = _waProfiles[_selectedWaSessionIndex];
    final bool isConnected = currentProfile['connected'] == true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Horizontal Profile Selector (4 WhatsApp Roles)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_waProfiles.length, (idx) {
              final prof = _waProfiles[idx];
              final isSel = _selectedWaSessionIndex == idx;
              final connected = prof['connected'] == true;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedWaSessionIndex = idx;
                      _pairCode = null;
                      _phoneCtrl.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (isDark ? const Color(0xFF334155) : Colors.white)
                          : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
                        width: isSel ? 1.5 : 1,
                      ),
                      boxShadow: isSel
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(prof['icon'] as IconData, size: 16, color: prof['color'] as Color),
                        const SizedBox(width: 8),
                        Text(
                          prof['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: connected ? const Color(0xFF00AA13) : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        // Session Status & Connection Card
        if (isConnected)
          _buildConnectedSessionCard(currentProfile, isDark)
        else
          _buildLoginPairingCard(currentProfile, isDark),

        const SizedBox(height: 20),

        // AI Agent Persona & Memori Kontak
        if (isConnected) ...[
          _buildSectionHeader('AI AGENT & MEMORI PER-KONTAK'),
          _buildAiAgentControlCard(currentProfile, isDark),
          const SizedBox(height: 16),
          _buildSectionHeader('RIWAYAT INTERAKSI KONTAK TERAKHIR'),
          _buildRecentChatsList(currentProfile, isDark),
        ],
      ],
    );
  }

  // Card Status Sesi Terhubung
  Widget _buildConnectedSessionCard(Map<String, dynamic> prof, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00AA13).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00AA13).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AA13).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF00AA13), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prof['accountName'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(
                      '${prof['phone']} • Sesi: ${prof['id']}',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.link_off_rounded, size: 14),
                label: const Text('Putus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _disconnectSession(prof),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card Login / Penautan Akun (Pairing Code & QR Code ala Nusa Kasir)
  Widget _buildLoginPairingCard(Map<String, dynamic> prof, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, color: GageTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tautkan Akun WhatsApp (${prof['title']})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih metode penautan akun WhatsApp resmi untuk sesi operasional ini.',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 14),

          // Sub-Tab Penautan: Pairing Code 8-Digit vs Scan Barcode QR
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildLoginMethodTabItem(0, 'Kode Pairing (1 HP)', Icons.key_rounded, isDark),
                ),
                Expanded(
                  child: _buildLoginMethodTabItem(1, 'Scan Barcode QR', Icons.qr_code_2_rounded, isDark),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_loginMethodTab == 0)
            _buildPairingCodeView(isDark)
          else
            _buildQrScanView(isDark),
        ],
      ),
    );
  }

  Widget _buildLoginMethodTabItem(int index, String label, IconData icon, bool isDark) {
    final isSel = _loginMethodTab == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _loginMethodTab = index);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? (isDark ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSel ? const Color(0xFF00AA13) : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tampilan Login Metode 0: Pairing Code 8-Digit
  Widget _buildPairingCodeView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nomor WhatsApp Aktif',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: '081234567890',
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text('+62', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.grey)),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00AA13),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _requestingPairCode
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.key_rounded, size: 16),
            label: Text(_requestingPairCode ? 'Meminta Kode Pairing...' : 'Dapatkan Kode Pairing (8-Digit)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            onPressed: _requestingPairCode ? null : _requestPairingCode,
          ),
        ),

        // Display Kode 8 Digit Besar
        if (_pairCode != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00AA13).withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Text(
                  'KODE TAUTAN WHATSAPP ANDA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF00AA13)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _pairCode!.split('').map((char) {
                    if (char == '-') {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AA13))),
                      );
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 28,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00AA13)),
                      ),
                      child: Text(
                        char,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF00AA13)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00AA13),
                      side: const BorderSide(color: Color(0xFF00AA13)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Salin Kode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: _copyPairCode,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Buka WhatsApp di HP Anda > Perangkat Tertaut > Tautkan dengan nomor telepon saja > Masukkan 8 karakter di atas.',
                  style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54, height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Tampilan Login Metode 1: Scan Barcode QR
  Widget _buildQrScanView(bool isDark) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 180,
              gapless: true,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan barcode QR di atas dari menu Perangkat Tertaut di HP WhatsApp Anda.',
            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Card Kontrol AI Agent Persona
  Widget _buildAiAgentControlCard(Map<String, dynamic> prof, bool isDark) {
    final bool aiEnabled = prof['aiEnabled'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.smart_toy_rounded, size: 18, color: GageTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'AI Persona: ${prof['agentName']}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
              Switch.adaptive(
                value: aiEnabled,
                activeTrackColor: GageTheme.primary,
                activeThumbColor: Colors.white,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  setState(() => prof['aiEnabled'] = val);
                },
              ),
            ],
          ),
          Text(
            prof['agentModel'] as String,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            prof['agentDescription'] as String,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Konteks Memori Kontak:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('${prof['activeThreads']} Kontak Tersimpan Mandiri', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // Daftar Chat Terbaru WhatsApp dengan Penjelasan AI Context
  Widget _buildRecentChatsList(Map<String, dynamic> prof, bool isDark) {
    final List chats = (prof['recentChats'] as List?) ?? [];
    if (chats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('Belum ada pesan masuk di profil ini.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chats.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final c = chats[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text(c['time'] as String, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pesan: "${c['lastMsg']}"',
                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87),
              ),
              if (c['aiReply'] != null && (c['aiReply'] as String).isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.smart_toy_rounded, size: 12, color: Color(0xFF00AA13)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Respon AI: ${c['aiReply']}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF00AA13), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5),
      ),
    );
  }
}
