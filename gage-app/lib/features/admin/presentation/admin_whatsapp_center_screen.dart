import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';

/// Screen Pusat Chat & Multi-WhatsApp Gateway - Tab 2
/// Menghubungkan 2 Kanal Komunikasi Inti:
/// 1. Chat In-App (Pelanggan, Driver, Merchant dalam ekosistem GAGE)
/// 2. Multi-WhatsApp Gateway (Multi-Session logins dengan Mastra-style Autonomous AI Agents & D1 Context Memory)
class AdminWhatsappCenterScreen extends StatefulWidget {
  const AdminWhatsappCenterScreen({super.key});

  @override
  State<AdminWhatsappCenterScreen> createState() => _AdminWhatsappCenterScreenState();
}

class _AdminWhatsappCenterScreenState extends State<AdminWhatsappCenterScreen> {
  int _activeChannelIndex = 0; // 0: Chat In-App, 1: Multi-WhatsApp Gateway
  int _selectedWaSessionIndex = 0; // 0: CS Support, 1: Dispatcher, 2: Merchant, 3: BaBe

  // Sesi Multi-WhatsApp Aktif (Masing-masing memiliki AI Agent & Tanggung Jawab Khusus)
  final List<Map<String, dynamic>> _waSessions = [
    {
      'id': 'session-cs',
      'roleTitle': 'CS & Layanan Warga',
      'phone': '+62 812-3456-7890',
      'status': 'Terhubung',
      'agentName': 'GageCare-Agent',
      'agentModel': 'Workers AI • Llama 3.1 8B',
      'responsibility': 'Menangani komplain, refund, panduan order warga Pracimantoro, info promo & bantuan umum.',
      'memoryThreads': 48,
      'isAutonomous': true,
      'tools': ['Query Order Status (D1)', 'Voucher Lookup', 'Eskalasi Admin'],
      'contacts': [
        {
          'name': 'Ibu Nurhayati',
          'phone': '+62 857-8899-0011',
          'avatar': 'N',
          'lastMsg': 'Mba, pesanan sayur saya sudah jalan belum ya?',
          'time': '12:48',
          'status': 'AI Membalas',
          'memoryContext': 'Pelanggan setia Kios Bu Slamet. Selalu minta sayur segar pagi & bayar via QRIS.',
          'aiThought': 'Mengecek order ID ORD-9019 di D1. Driver Mas Agus sedang perjalanan ke alamat pengantaran.',
          'conversation': [
            {'sender': 'user', 'text': 'Halo admin, selamat siang.', 'time': '12:46'},
            {'sender': 'agent', 'text': 'Selamat siang Bu Nurhayati! Ada yang bisa kami bantu hari ini? 😊', 'time': '12:47'},
            {'sender': 'user', 'text': 'Mba, pesanan sayur saya sudah jalan belum ya?', 'time': '12:48'},
            {'sender': 'agent', 'text': 'Pesanan sayur Ibu dari Kios Bu Slamet sudah dibawa oleh Mas Agus Setiawan (Yamaha NMAX) dan estimasi tiba 8 menit lagi nggih Bu. 🛵', 'time': '12:48'},
          ],
        },
        {
          'name': 'Pak Haji Marwan',
          'phone': '+62 812-3344-5566',
          'avatar': 'M',
          'lastMsg': 'Matur nuwun mas, semen sudah sampai aman.',
          'time': '11:30',
          'status': 'Selesai',
          'memoryContext': 'Pemilik Toko Berkah Jaya. Sering kirim bahan bangunan via GAGE Send ke desa Tubokarto.',
          'aiThought': 'Transaksi pengiriman semen tuntas, menandai riwayat kepuasan di memori D1.',
          'conversation': [
            {'sender': 'user', 'text': 'Mas titip semen 1 sak bisa langsung antar?', 'time': '10:55'},
            {'sender': 'agent', 'text': 'Bisa Pak Marwan! Kurir kami sudah meluncur ke lokasi jemput nggih.', 'time': '10:56'},
            {'sender': 'user', 'text': 'Matur nuwun mas, semen sudah sampai aman.', 'time': '11:30'},
            {'sender': 'agent', 'text': 'Sami-sami Pak Marwan. Senang bisa membantu kelancaran proyek Bapak. 🙏', 'time': '11:31'},
          ],
        },
      ],
    },
    {
      'id': 'session-dispatch',
      'roleTitle': 'Dispatcher Logistik Armada',
      'phone': '+62 857-1234-5678',
      'status': 'Terhubung',
      'agentName': 'Dispatch-Agent',
      'agentModel': 'Workers AI • Mistral 7B',
      'responsibility': 'Alokasi order tertunda, koordinasi pangkalan driver (Pasar/Terminal/Giribelah), monitoring cuaca & rute.',
      'memoryThreads': 24,
      'isAutonomous': true,
      'tools': ['Driver Proximity (GPS)', 'Assign Dispatch', 'Broadcast Pangkalan'],
      'contacts': [
        {
          'name': 'Mas Budi Santoso (Driver Motor)',
          'phone': '+62 812-3456-7890',
          'avatar': 'B',
          'lastMsg': 'Siap min, meluncur ke resto Dimsum Sewu sekarang.',
          'time': '12:42',
          'status': 'Otomatis',
          'memoryContext': 'Driver pangkalan Pasar Praci. Rating 4.96, responsif order makanan & antaran cepat.',
          'aiThought': 'Menugaskan ORD-9021 karena jarak driver hanya 300m dari Dimsum Sewu.',
          'conversation': [
            {'sender': 'agent', 'text': 'Mas Budi, ada order ORD-9021 Dimsum Sewu arah Gebang Kulon. Bisa ambil?', 'time': '12:41'},
            {'sender': 'user', 'text': 'Siap min, meluncur ke resto Dimsum Sewu sekarang.', 'time': '12:42'},
          ],
        },
        {
          'name': 'Pak Joko Purnomo (Driver Mobil)',
          'phone': '+62 857-1234-5678',
          'avatar': 'J',
          'lastMsg': 'Terminal posisi aman, ada 2 mobil siaga carter.',
          'time': '12:15',
          'status': 'Standby',
          'memoryContext': 'Driver mobil Avanza pangkalan terminal. Spesialis carter luar kota & bandara/stasiun.',
          'aiThought': 'Mencatat ketersediaan mobil siaga di terminal ke status armada D1.',
          'conversation': [
            {'sender': 'agent', 'text': 'Pak Joko, bagaimana kondisi antrean di Terminal Praci siang ini?', 'time': '12:14'},
            {'sender': 'user', 'text': 'Terminal posisi aman, ada 2 mobil siaga carter.', 'time': '12:15'},
          ],
        },
      ],
    },
    {
      'id': 'session-merchant',
      'roleTitle': 'Merchant Onboarding & Dapur',
      'phone': '+62 898-7654-3210',
      'status': 'Terhubung',
      'agentName': 'Merchant-Agent',
      'agentModel': 'Workers AI • Llama 3.1 8B',
      'responsibility': 'Membantu resto update menu, cek printer dapur KDS, pendampingan promo & validasi order membludak.',
      'memoryThreads': 32,
      'isAutonomous': true,
      'tools': ['Menu Stock Toggle', 'KDS Heartbeat', 'Store Hours'],
      'contacts': [
        {
          'name': 'Dimsum Sewu Mas Agus',
          'phone': '+62 899-1122-3344',
          'avatar': 'D',
          'lastMsg': 'Min, menu pangsit goreng sudah habis ya tolong dimatikan.',
          'time': '12:35',
          'status': 'AI Membalas',
          'memoryContext': 'Mitra resto paling ramai jam makan siang. Menggunakan printer kasir bluetooth SPP 58mm.',
          'aiThought': 'Menonaktifkan menu Pangsit Goreng di D1 catalog secara otomatis.',
          'conversation': [
            {'sender': 'user', 'text': 'Min, menu pangsit goreng sudah habis ya tolong dimatikan.', 'time': '12:35'},
            {'sender': 'agent', 'text': 'Siap Mas Agus! Menu Pangsit Goreng sudah dinonaktifkan di aplikasi Pelanggan. 👍', 'time': '12:36'},
          ],
        },
      ],
    },
    {
      'id': 'session-babe',
      'roleTitle': 'BaBe Inspector & Titip Jual',
      'phone': '+62 813-9988-7766',
      'status': 'Standby (Pairing)',
      'agentName': 'BaBeCurator-Agent',
      'agentModel': 'Workers AI • Llama 3.1 8B',
      'responsibility': 'Kurasi barang bekas warga, verifikasi kondisi fisik, estimasi harga wajar & jadwal survey kurir.',
      'memoryThreads': 18,
      'isAutonomous': true,
      'tools': ['BaBe Catalog CRUD', 'Photo Verification', 'Schedule Survey'],
      'contacts': [
        {
          'name': 'Pak Joko (Titip iPad)',
          'phone': '+62 812-3311-2233',
          'avatar': 'P',
          'lastMsg': 'Kelengkapan charger ori masih ada semua mas.',
          'time': '10:20',
          'status': 'Verifikasi',
          'memoryContext': 'Menitipkan iPad Gen 9 mulus di desa Gedong. Butuh verifikasi fisik kurir.',
          'aiThought': 'Menganalisis deskripsi barang dan mencocokkan rentang harga pasar wajar Rp 3.200.000.',
          'conversation': [
            {'sender': 'user', 'text': 'Kelengkapan charger ori masih ada semua mas.', 'time': '10:20'},
            {'sender': 'agent', 'text': 'Baik Pak Joko, data sudah kami catat. Tim kurir kami akan survey fisik sore ini nggih. 🙏', 'time': '10:21'},
          ],
        },
      ],
    },
  ];

  // Data Percakapan Chat In-App (Real-Time Order Interaction)
  final List<Map<String, dynamic>> _inAppChats = [
    {
      'orderId': 'ORD-9021',
      'service': 'GageFood',
      'customerName': 'Siti Rahmawati',
      'driverName': 'Budi Santoso (Driver)',
      'merchantName': 'Dimsum Sewu Mas Agus',
      'lastMsg': 'Siap kak, sambal cocol ekstra sudah kami siapkan di pouch terpisah.',
      'time': '12:45',
      'status': 'Aktif Berjalan',
      'unread': 2,
      'messages': [
        {'role': 'Pelanggan', 'name': 'Siti Rahmawati', 'text': 'Halo mas, tolong sambalnya agak banyak yaa. Makasih!', 'time': '12:40'},
        {'role': 'Driver', 'name': 'Budi Santoso', 'text': 'Siap mbak Siti, saya pesankan ke kasir resto sekarang.', 'time': '12:42'},
        {'role': 'Resto', 'name': 'Dimsum Sewu', 'text': 'Siap kak, sambal cocol ekstra sudah kami siapkan di pouch terpisah.', 'time': '12:45'},
      ],
    },
    {
      'orderId': 'ORD-8804',
      'service': 'GageSend',
      'customerName': 'Pak Haji Marwan',
      'driverName': 'Belum Ditugaskan',
      'merchantName': 'Toko Bangunan Berkah Jaya',
      'lastMsg': 'Semen 1 sak sudah siap di depan toko ya.',
      'time': '12:38',
      'status': 'Menunggu Driver',
      'unread': 1,
      'messages': [
        {'role': 'Pelanggan', 'name': 'Pak Haji Marwan', 'text': 'Semen 1 sak sudah siap di depan toko ya.', 'time': '12:38'},
      ],
    },
    {
      'orderId': 'RIDE-8812',
      'service': 'GageRide',
      'customerName': 'Mas Wahyu Hidayat',
      'driverName': 'Pak Joko Purnomo',
      'merchantName': '-',
      'lastMsg': 'Saya sudah di depan pintu keluar barat ya mas.',
      'time': '12:10',
      'status': 'Selesai',
      'unread': 0,
      'messages': [
        {'role': 'Pelanggan', 'name': 'Mas Wahyu Hidayat', 'text': 'Pak, saya pakai jaket hitam bawa koper.', 'time': '12:05'},
        {'role': 'Driver', 'name': 'Pak Joko Purnomo', 'text': 'Saya sudah di depan pintu keluar barat ya mas.', 'time': '12:10'},
      ],
    },
  ];

  void _showInterveneChatModal(Map<String, dynamic> inAppChat) {
    HapticFeedback.lightImpact();
    final interveneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final messages = inAppChat['messages'] as List<dynamic>;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${inAppChat['orderId']} • ${inAppChat['service']}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: GageTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  inAppChat['status'] as String,
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: GageTheme.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pelanggan: ${inAppChat['customerName']} • Driver: ${inAppChat['driverName']}',
                            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final m = messages[i] as Map<String, dynamic>;
                        final role = m['role'] as String;
                        final isCustomer = role == 'Pelanggan';
                        final isDriver = role == 'Driver';
                        final isAdmin = role == 'Admin';

                        Color bubbleColor;
                        Color textColor;
                        if (isAdmin) {
                          bubbleColor = GageTheme.primary;
                          textColor = Colors.white;
                        } else if (isCustomer) {
                          bubbleColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF);
                          textColor = isDark ? Colors.white : const Color(0xFF1E3A8A);
                        } else if (isDriver) {
                          bubbleColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
                          textColor = isDark ? Colors.white : const Color(0xFF065F46);
                        } else {
                          bubbleColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);
                          textColor = isDark ? Colors.white : const Color(0xFF92400E);
                        }

                        return Align(
                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isAdmin ? Colors.transparent : Colors.grey.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${m['name']} ($role)',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isAdmin ? Colors.white70 : textColor.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      m['time'] as String,
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        color: isAdmin ? Colors.white60 : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  m['text'] as String,
                                  style: TextStyle(fontSize: 12, color: textColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: interveneCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Kirim pesan intervensi atas nama Admin/GAGE Care...',
                              hintStyle: TextStyle(fontSize: 11.5),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: GageTheme.primary, size: 20),
                          onPressed: () {
                            final text = interveneCtrl.text.trim();
                            if (text.isEmpty) return;
                            HapticFeedback.lightImpact();
                            setModalState(() {
                              messages.add({
                                'role': 'Admin',
                                'name': 'GAGE Command Tower',
                                'text': text,
                                'time': DateFormat('HH:mm').format(DateTime.now()),
                              });
                            });
                            setState(() {
                              inAppChat['lastMsg'] = text;
                              inAppChat['time'] = DateFormat('HH:mm').format(DateTime.now());
                            });
                            interveneCtrl.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWaContactInspectorModal(Map<String, dynamic> session, Map<String, dynamic> contact) {
    HapticFeedback.lightImpact();
    final replyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final conversation = contact['conversation'] as List<dynamic>;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.9,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF00AA13).withValues(alpha: 0.15),
                            child: Text(
                              contact['avatar'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text('${contact['phone']} • Sesi: ${session['roleTitle']}', style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(modalCtx)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Kotak Memori Kontekstual AI (Mastra/Workers AI Context Memory)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00AA13).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology_rounded, size: 14, color: Color(0xFF00AA13)),
                            SizedBox(width: 5),
                            Text(
                              'STANDALONE AI CONTEXT MEMORY (CLOUDFLARE D1)',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF00AA13), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact['memoryContext'] as String,
                          style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('AI Thought: ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blue)),
                            Expanded(
                              child: Text(
                                contact['aiThought'] as String,
                                style: const TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: Colors.blue),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 16),

                  // WhatsApp Chat Stream
                  Expanded(
                    child: ListView.separated(
                      itemCount: conversation.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final msg = conversation[i] as Map<String, dynamic>;
                        final isUser = msg['sender'] == 'user';

                        return Align(
                          alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? (isDark ? const Color(0xFF334155) : Colors.grey.shade200)
                                  : const Color(0xFF00AA13),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Text(
                                  msg['text'] as String,
                                  style: TextStyle(fontSize: 12, color: isUser ? (isDark ? Colors.white : Colors.black87) : Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  msg['time'] as String,
                                  style: TextStyle(fontSize: 8.5, color: isUser ? Colors.grey.shade600 : Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Balas Manual / Override AI
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: replyCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Kirim pesan WA manual (Override AI)...',
                              hintStyle: TextStyle(fontSize: 11.5),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF00AA13), size: 20),
                          onPressed: () {
                            final text = replyCtrl.text.trim();
                            if (text.isEmpty) return;
                            HapticFeedback.lightImpact();
                            setModalState(() {
                              conversation.add({
                                'sender': 'agent',
                                'text': text,
                                'time': DateFormat('HH:mm').format(DateTime.now()),
                              });
                            });
                            setState(() {
                              contact['lastMsg'] = text;
                              contact['time'] = DateFormat('HH:mm').format(DateTime.now());
                              contact['status'] = 'Admin Override';
                            });
                            replyCtrl.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
              'Pusat Chat & AI Gateway',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'Chat In-App Warga & Multi-WhatsApp Autonomous Agents',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Segmented Top Switcher (Gojek / iOS Inset Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeChannelIndex = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeChannelIndex == 0 ? GageTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeChannelIndex == 0
                                ? [BoxShadow(color: GageTheme.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_rounded, size: 15, color: _activeChannelIndex == 0 ? Colors.white : Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  'Chat In-App (${_inAppChats.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _activeChannelIndex == 0 ? FontWeight.bold : FontWeight.w600,
                                    color: _activeChannelIndex == 0 ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeChannelIndex = 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeChannelIndex == 1 ? const Color(0xFF00AA13) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeChannelIndex == 1
                                ? [BoxShadow(color: const Color(0xFF00AA13).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hub_rounded, size: 15, color: _activeChannelIndex == 1 ? Colors.white : Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  'Multi-WhatsApp (${_waSessions.length} Sesi)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _activeChannelIndex == 1 ? FontWeight.bold : FontWeight.w600,
                                    color: _activeChannelIndex == 1 ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Area
            Expanded(
              child: _activeChannelIndex == 0
                  ? _buildInAppChatView(isDark)
                  : _buildMultiWaGatewayView(isDark),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2),
    );
  }

  // --- VIEW 1: CHAT IN-APP (LIVE INTERACTION HUB) ---
  Widget _buildInAppChatView(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _inAppChats.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final chat = _inAppChats[i];
        final unread = chat['unread'] as int;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showInterveneChatModal(chat),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: GageTheme.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.forum_rounded, color: GageTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${chat['orderId']} • ${chat['service']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            chat['time'] as String,
                            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${chat['customerName']} ➔ ${chat['driverName']}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GageTheme.primary.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat['lastMsg'] as String,
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (unread > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: GageTheme.primary, shape: BoxShape.circle),
                    child: Text(
                      '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- VIEW 2: MULTI-WHATSAPP GATEWAY (MASTRA-STYLE AI AGENT FLEET) ---
  Widget _buildMultiWaGatewayView(bool isDark) {
    final currentSession = _waSessions[_selectedWaSessionIndex];
    final contacts = currentSession['contacts'] as List<dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pemilih Sesi WhatsApp (Pill Selector)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_waSessions.length, (idx) {
              final s = _waSessions[idx];
              final isSelected = _selectedWaSessionIndex == idx;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedWaSessionIndex = idx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00AA13)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00AA13) : (isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: s['status'] == 'Terhubung' ? const Color(0xFF22C55E) : Colors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s['roleTitle'] as String,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
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

        const SizedBox(height: 14),

        // Profil AI Agent Sesi Terpilih (Mastra-Style Agent Architecture)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00AA13).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AA13).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF00AA13), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSession['agentName'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${currentSession['phone']} • ${currentSession['agentModel']}',
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00AA13).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      currentSession['status'] as String,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF00AA13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currentSession['responsibility'] as String,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.memory_rounded, size: 14, color: Colors.blue),
                        const SizedBox(width: 5),
                        Text(
                          '${currentSession['memoryThreads']} Thread Terisolasi di D1',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const Text('Autonomous Active', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF00AA13))),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Daftar Chat Kontak Terisolasi untuk Sesi Ini
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Percakapan Kontak Standalone',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            Text(
              '${contacts.length} Kontak',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final c = contacts[idx] as Map<String, dynamic>;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showWaContactInspectorModal(currentSession, c),
              child: Container(
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
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF00AA13).withValues(alpha: 0.12),
                              child: Text(
                                c['avatar'] as String,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00AA13)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                        Text(
                          c['time'] as String,
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c['lastMsg'] as String,
                      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Pill Context Memory Kontak
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology_rounded, size: 11, color: Colors.blue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c['memoryContext'] as String,
                              style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : Colors.black54),
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
        ),
      ],
    );
  }
}
