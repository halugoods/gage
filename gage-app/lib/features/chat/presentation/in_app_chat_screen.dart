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
  final String recipientRole; // 'customer' | 'merchant' | 'driver' | 'ai'
  final String recipientPhone;
  final String currentRole; // 'driver' | 'merchant' | 'customer'

  const InAppChatScreen({
    super.key,
    required this.orderId,
    required this.recipientName,
    required this.recipientRole,
    required this.recipientPhone,
    this.currentRole = 'customer',
  });

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
        return [
          'Tanya promo hari ini',
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
              imageUrl: null,
              fallbackName: widget.recipientName,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.recipientName,
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.recipientRole.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: GageTheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '#${widget.orderId}',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
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
                            'Belum ada pesan.\nMulai percakapan dengan ${widget.recipientName}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (ctx, idx) {
                        final msg = messages[idx];
                        final isMe = msg.senderRole == widget.currentRole;

                        return Align(
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
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
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
                                      msg.senderName,
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
                                      color: isMe
                                          ? Colors.white
                                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      height: 1.35,
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
                                        color: isMe ? Colors.white70 : Colors.grey.shade500,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
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
                      onTap: () => _sendMessage(reply),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                          ),
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
                widget.recipientName,
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
        borderRadius: BorderRadius.circular(24),
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
