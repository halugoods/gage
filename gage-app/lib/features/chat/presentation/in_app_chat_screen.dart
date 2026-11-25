import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/services/gage_audio_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/domain/chat_message.dart';
import 'package:gage_app/features/chat/presentation/widgets/gage_product_catalog_sheet.dart';
import 'package:gage_app/features/chat/presentation/widgets/gage_chat_input_bar.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class InAppChatScreen extends StatefulWidget {
  final String orderId;
  final String recipientName;
  final String recipientRole; // 'customer' | 'merchant' | 'driver' | 'support' | 'admin'
  final String recipientPhone;
  final String? recipientAvatar;
  final String currentRole; // 'driver' | 'merchant' | 'customer'

  const InAppChatScreen({
    super.key,
    required this.orderId,
    required this.recipientName,
    required this.recipientRole,
    required this.recipientPhone,
    this.recipientAvatar,
    this.currentRole = 'customer',
  });

  static bool isSupportRole(String role) {
    final lower = role.trim().toLowerCase();
    return lower == 'ai' || lower == 'support' || lower == 'admin';
  }

  static bool isSupportOrderId(String orderId) {
    final clean = orderId.trim();
    return clean.isEmpty ||
        clean == 'AI-SUPPORT' ||
        clean == 'cs-gage-support' ||
        clean == 'GAGE-CARE';
  }

  /// Membersihkan akhiran label redundant seperti "(Driver GAGE)", "(Driver)", plat kendaraan, dan "(24/7)".
  static String cleanDisplayName(String rawName, {String? role}) {
    var name = rawName.trim();
    if (name.isEmpty) return name;

    final lowerRole = role?.trim().toLowerCase() ?? '';
    if (isSupportRole(lowerRole)) {
      if (name.toLowerCase().contains('ai assistant') ||
          name.toLowerCase().contains('bantuan ai') ||
          RegExp(r'\bai\b', caseSensitive: false).hasMatch(name)) {
        return 'Pusat Bantuan';
      }
      name = name.replaceAll(RegExp(r'\s*\(24/7\)', caseSensitive: false), '').trim();
    }

    name = name
        .replaceAll(RegExp(r'\s*\((?:mitra\s+)?driver(?:\s+gage)?\)', caseSensitive: false), '')
        .trim();

    if (lowerRole == 'driver') {
      name = name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    }
    return name;
  }

  @override
  State<InAppChatScreen> createState() => _InAppChatScreenState();
}

class _InAppChatScreenState extends State<InAppChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // Interactive Voice Note Playback State
  String? _playingVoiceMsgId;
  int _voiceCurrentSeconds = 0;
  Timer? _voicePlaybackTimer;

  List<String> get _quickReplies {
    // Quick Replies Khusus Mitra Usaha (Dapur & Kasir Merchant)
    if (widget.currentRole == 'merchant') {
      if (widget.recipientRole.toLowerCase() == 'driver') {
        return [
          'Pesanan sedang disiapkan di dapur 👨‍🍳',
          'Pesanan sudah matang & siap diambil ya Mas Driver!',
          'Kira-kira tiba di kios berapa menit lagi mas?',
          'Mohon sebutkan PIN serah terima saat ambil barang ya.',
        ];
      } else if (widget.recipientRole.toLowerCase() == 'customer') {
        return [
          'Halo kak, pesanan segera kami masak dengan higienis!',
          'Saus dan sambal sudah dipisah di kemasan khusus ya kak.',
          'Mohon maaf, varian ini habis, apakah boleh diganti?',
          'Terima kasih banyak sudah memesan di resto kami!',
        ];
      } else {
        return [
          'Halo tim Bantuan GAGE, mohon panduan operasional kios.',
          'Bagaimana cara aktivasi banner Star Resto?',
          'Kendala sinkronisasi pencairan saldo GagePay toko.',
        ];
      }
    }

    switch (widget.recipientRole.toLowerCase()) {
      case 'driver':
        return [
          'Saya sudah di titik jemput',
          'Sesuai titik ya mas',
          'Mohon tunggu 2 menit',
          'Pagar depan rumah warna hitam',
        ];
      case 'merchant':
        return [
          'Apakah menu ini ready?',
          'Tolong jangan terlalu pedas ya',
          'Kira-kira berapa menit siap?',
          'Bisa minta sendok & sambal lebih?',
        ];
      case 'ai':
      case 'support':
      case 'admin':
        return [
          'Lacak status pesanan saya',
          'Cara pesan makanan',
          'Kendala pesanan',
        ];
      default:
        return [
          'Baik kak, ditunggu ya',
          'Sesuai pesanan ya',
          'Terima kasih banyak!',
        ];
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _voicePlaybackTimer?.cancel();
    GageAudioService.instance.stopVoiceNote();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _callPhone() async {
    final trimmed = widget.recipientPhone.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      GageToast.show(context, 'Nomor telepon belum tersedia', type: GageToastType.warning);
      return;
    }
    final uri = Uri.parse('tel:$trimmed');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _resolveSenderName() {
    if (widget.currentRole == 'customer') {
      try {
        final name = context.read<AuthProvider>().currentUser?.name;
        if (name != null && name.trim().isNotEmpty) return name.trim();
      } on ProviderNotFoundException {
        // Fallback aman saat widget test tanpa AuthProvider
      }
      return 'Pelanggan GAGE';
    }
    if (widget.currentRole == 'driver') return 'Mitra Driver GAGE';
    if (widget.currentRole == 'merchant') return 'Mitra Merchant GAGE';
    return 'Pengguna GAGE';
  }

  String _resolveSenderId() {
    try {
      final id = context.read<AuthProvider>().currentUser?.id;
      if (id != null && id.trim().isNotEmpty) return id.trim();
    } on ProviderNotFoundException {
      // Abaikan
    }
    return 'current-user-id';
  }

  void _sendMessage([String? textToSend]) {
    final text = textToSend ?? _textCtrl.text;
    if (text.trim().isEmpty) return;

    final chatProv = context.read<InAppChatProvider>();
    chatProv.sendMessage(
      orderId: widget.orderId,
      senderId: _resolveSenderId(),
      senderRole: widget.currentRole,
      senderName: _resolveSenderName(),
      text: text,
    );

    if (textToSend == null) {
      _textCtrl.clear();
    }
    _scrollToBottom();
  }

  void _sendVoiceMessage(int durationSeconds, [String? audioFilePath]) {
    final chatProv = context.read<InAppChatProvider>();
    chatProv.sendVoiceMessage(
      orderId: widget.orderId,
      senderId: _resolveSenderId(),
      senderRole: widget.currentRole,
      senderName: _resolveSenderName(),
      durationSeconds: durationSeconds,
      audioFilePath: audioFilePath,
    );
    _scrollToBottom();
    GageToast.show(context, 'Pesan suara ($durationSeconds d) terkirim', type: GageToastType.success);
  }

  void _sendMediaMessage({required String filePath, String? caption}) {
    final chatProv = context.read<InAppChatProvider>();
    chatProv.sendMediaMessage(
      orderId: widget.orderId,
      senderId: _resolveSenderId(),
      senderRole: widget.currentRole,
      senderName: _resolveSenderName(),
      filePath: filePath,
      caption: caption,
    );
    _scrollToBottom();
  }

  void _sendProductMessage({
    required String productName,
    required int price,
    required String image,
  }) {
    final chatProv = context.read<InAppChatProvider>();
    chatProv.sendProductMessage(
      orderId: widget.orderId,
      senderId: _resolveSenderId(),
      senderRole: widget.currentRole,
      senderName: _resolveSenderName(),
      productName: productName,
      productPrice: price,
      productImage: image,
    );
    _scrollToBottom();
  }

  Future<void> _handleCameraPick() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        _sendMediaMessage(filePath: picked.path, caption: 'Foto Langsung');
      }
    } catch (_) {}
  }

  Future<void> _handleGalleryPick() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        _sendMediaMessage(filePath: picked.path, caption: 'Gambar Galeri');
      }
    } catch (_) {}
  }

  void _handleFileCatalog() {
    GageProductCatalogSheet.show(
      context,
      merchantId: 'm-dimsum-sewu',
      onProductSelected: (name, price, image) {
        _sendProductMessage(
          productName: name,
          price: price,
          image: image,
        );
      },
    );
  }

  void _togglePlayVoice(ChatMessage msg) {
    HapticFeedback.lightImpact();
    final totalDuration = msg.voiceDurationSeconds ?? 4;

    if (_playingVoiceMsgId == msg.id) {
      // Pause
      _voicePlaybackTimer?.cancel();
    GageAudioService.instance.stopVoiceNote();
      setState(() {
        _playingVoiceMsgId = null;
        _voiceCurrentSeconds = 0;
      });
    } else {
      // Play
      _voicePlaybackTimer?.cancel();
      GageAudioService.instance.stopVoiceNote();
      setState(() {
        _playingVoiceMsgId = msg.id;
        _voiceCurrentSeconds = 0;
      });

      if (msg.mediaUrl != null &&
          msg.mediaUrl!.isNotEmpty &&
          (msg.mediaUrl!.endsWith('.m4a') || msg.mediaUrl!.endsWith('.aac') || msg.mediaUrl!.endsWith('.wav'))) {
        GageAudioService.instance.playVoiceNoteFile(
          voiceNoteId: msg.id,
          filePath: msg.mediaUrl!,
          onComplete: () {
            if (mounted) {
              setState(() {
                _playingVoiceMsgId = null;
                _voiceCurrentSeconds = 0;
              });
            }
          },
        );
      } else {
        GageAudioService.instance.playVoiceNote(
          voiceNoteId: msg.id,
          durationSeconds: totalDuration.toDouble(),
          onComplete: () {
            if (mounted) {
              setState(() {
                _playingVoiceMsgId = null;
                _voiceCurrentSeconds = 0;
              });
            }
          },
        );
      }

      _voicePlaybackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _voiceCurrentSeconds++;
          if (_voiceCurrentSeconds >= totalDuration) {
            timer.cancel();
            _playingVoiceMsgId = null;
            _voiceCurrentSeconds = 0;
            HapticFeedback.mediumImpact();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProv = context.watch<InAppChatProvider>();
    final messages = chatProv.getMessages(widget.orderId);
    final timeFormat = DateFormat('HH:mm');
    final displayName = InAppChatScreen.cleanDisplayName(
      widget.recipientName,
      role: widget.recipientRole,
    );
    final isSupport = InAppChatScreen.isSupportRole(widget.recipientRole);
    final hasOrderContext = !InAppChatScreen.isSupportOrderId(widget.orderId);
    final resolvedAvatar = (widget.recipientAvatar != null && widget.recipientAvatar!.trim().isNotEmpty)
        ? widget.recipientAvatar!.trim()
        : (isSupport ? 'assets/images/gage_icon.png' : null);

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            GageAvatar(
              imageUrl: resolvedAvatar,
              fallbackName: displayName,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSupport
                            ? 'Layanan Pelanggan GAGE'
                            : (widget.recipientRole.toLowerCase() == 'driver'
                                ? 'Mitra Driver GAGE'
                                : (widget.recipientRole.toLowerCase() == 'merchant'
                                    ? 'Mitra Toko GAGE'
                                    : 'Online')),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      if (hasOrderContext) ...[
                        Text(
                          ' • #${widget.orderId}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.recipientPhone.trim().isNotEmpty && widget.recipientPhone.trim() != '-')
            IconButton(
              icon: const Icon(Icons.phone_rounded, color: GageTheme.accentGreen, size: 22),
              tooltip: 'Telepon Seluler',
              onPressed: _callPhone,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Context Banner Pesanan Mini (Elegance & Utilitas Tinggi)
            if (hasOrderContext)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark ? GageTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 14, color: GageTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Pesanan #${widget.orderId}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3.5,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white38 : Colors.black26,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.recipientRole.toLowerCase() == 'driver'
                          ? 'Pengantaran Aktif'
                          : (widget.recipientRole.toLowerCase() == 'merchant'
                              ? 'Pesanan Toko'
                              : 'Chat Transaksi'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // List Chat
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada pesan.\nMulai percakapan dengan $displayName',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (ctx, idx) {
                        final msg = messages[idx];
                        final isMe = msg.senderRole == widget.currentRole;

                        final showDateSeparator = idx == 0 ||
                            msg.timestamp.day != messages[idx - 1].timestamp.day ||
                            msg.timestamp.month != messages[idx - 1].timestamp.month ||
                            msg.timestamp.year != messages[idx - 1].timestamp.year;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showDateSeparator)
                              _buildDateSeparator(msg.timestamp, isDark),
                            Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.78,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? GageTheme.primary
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 18),
                              ),
                              border: isMe
                                  ? null
                                  : Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      width: 0.8,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: isMe
                                      ? GageTheme.primary.withValues(alpha: 0.16)
                                      : Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      InAppChatScreen.cleanDisplayName(
                                        msg.senderName,
                                        role: msg.senderRole,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: GageTheme.primary,
                                      ),
                                    ),
                                  ),

                                // A. Gambar Dinamis (Natural Aspect Ratio & Fullscreen Viewer)
                                if (msg.isImage && msg.mediaUrl != null) ...[
                                  GestureDetector(
                                    onTap: () => _openFullScreenImage(context, msg.mediaUrl!),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        constraints: BoxConstraints(
                                          minWidth: 140,
                                          maxWidth: MediaQuery.of(context).size.width * 0.70,
                                          maxHeight: 320,
                                        ),
                                        child: msg.mediaUrl!.startsWith('http')
                                            ? Image.network(
                                                msg.mediaUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Container(
                                                  height: 120,
                                                  color: Colors.black12,
                                                  child: const Icon(Icons.broken_image_rounded, size: 36),
                                                ),
                                              )
                                            : Image.file(
                                                File(msg.mediaUrl!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Container(
                                                  height: 120,
                                                  color: Colors.black12,
                                                  child: const Icon(Icons.image_rounded, size: 36),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],

                                // B. Voice Note Player Interaktif
                                if (msg.isVoice) ...[
                                  _buildVoicePlayer(msg, isMe, isDark),
                                  const SizedBox(height: 4),
                                ],

                                // C. Product Card Snippet
                                if (msg.isProduct && msg.productName != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.16)
                                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: msg.productImage != null && msg.productImage!.isNotEmpty
                                              ? Image.asset(
                                                  msg.productImage!,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => const Icon(Icons.fastfood_rounded, size: 24),
                                                )
                                              : const Icon(Icons.storefront_rounded, size: 24),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                msg.productName!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (msg.productPrice != null)
                                                Text(
                                                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(msg.productPrice),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: isMe ? Colors.white70 : GageTheme.primary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // D. Teks Pesan
                                if (!msg.isVoice)
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: isMe
                                          ? Colors.white
                                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      height: 1.38,
                                    ),
                                  ),

                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      timeFormat.format(msg.timestamp),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: isMe ? Colors.white.withValues(alpha: 0.75) : Colors.grey.shade500,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.done_all_rounded,
                                        size: 14,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ),

            // Bar Quick Reply Pills
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickReplies.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final reply = _quickReplies[i];
                  return Center(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _sendMessage(reply);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 0.9,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          reply,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Input Bar Modern (Hint Ramping & Inline Physical Voice Recording)
            GageChatInputBar(
              controller: _textCtrl,
              hintText: 'Ketik pesan disini...',
              onSend: (text) => _sendMessage(text),
              onVoiceRecordedWithFile: (duration, path) => _sendVoiceMessage(duration, path),
              onCameraTap: _handleCameraPick,
              onGalleryTap: _handleGalleryPick,
              onFileTap: _handleFileCatalog,
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String mediaUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (ctx, anim, secAnim) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
              title: Text(
                InAppChatScreen.cleanDisplayName(
                  widget.recipientName,
                  role: widget.recipientRole,
                ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: mediaUrl.startsWith('http')
                    ? Image.network(
                        mediaUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                      )
                    : Image.file(
                        File(mediaUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.image_rounded, size: 64, color: Colors.white54),
                      ),
              ),
            ),
          );
        },
        transitionsBuilder: (ctx, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  Widget _buildDateSeparator(DateTime timestamp, bool isDark) {
    final now = DateTime.now();
    final isToday = timestamp.year == now.year && timestamp.month == now.month && timestamp.day == now.day;
    final isYesterday = timestamp.year == now.year && timestamp.month == now.month && timestamp.day == now.day - 1;
    final dateText = isToday ? 'Hari Ini' : (isYesterday ? 'Kemarin' : DateFormat('d MMM yyyy').format(timestamp));

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildVoicePlayer(ChatMessage msg, bool isMe, bool isDark) {
    final isPlaying = _playingVoiceMsgId == msg.id;
    final totalDuration = msg.voiceDurationSeconds ?? 4;
    final currentSec = isPlaying ? _voiceCurrentSeconds : totalDuration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.18)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol Play / Pause
          InkWell(
            onTap: () => _togglePlayVoice(msg),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isMe ? Colors.white : GageTheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isMe ? GageTheme.primary : Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Waveform Audio Bars
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(14, (i) {
              final barHeight = 8.0 + (i % 5) * 4.0;
              final activeThreshold = (i / 14.0) * totalDuration;
              final isBarActive = isPlaying && _voiceCurrentSeconds >= activeThreshold;

              return Container(
                width: 3,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: isMe
                      ? (isBarActive ? Colors.white : Colors.white.withValues(alpha: 0.45))
                      : (isBarActive ? GageTheme.primary : Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(width: 10),

          // Timer Durasi
          Text(
            '00:0$currentSec',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
