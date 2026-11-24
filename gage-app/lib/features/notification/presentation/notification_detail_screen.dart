import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/notification_service.dart';

/// Layar Penuh Detail Notifikasi & Pengumuman Resmi GAGE
/// Mendukung lampiran media gambar (admin broadcasts / promo banner) dan tautan aksi kontekstual.
class NotificationDetailScreen extends StatelessWidget {
  final GageNotification notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  String _formatFullDate(DateTime dt) {
    return DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(dt);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'promo':
        return const Color(0xFFE52320);
      case 'transaksi':
      case 'order':
        return const Color(0xFF059669);
      case 'dompet':
      case 'wallet':
        return const Color(0xFFEA580C);
      case 'sistem':
      case 'admin':
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'promo':
        return Icons.local_offer_rounded;
      case 'transaksi':
      case 'order':
        return Icons.receipt_long_rounded;
      case 'dompet':
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'sistem':
      case 'admin':
      default:
        return Icons.campaign_rounded;
    }
  }

  Widget _buildMediaAttachment(String url, bool isDark) {
    Widget imageWidget;
    if (url.startsWith('assets/')) {
      imageWidget = Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackMedia(isDark),
      );
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackMedia(isDark),
      );
    } else {
      imageWidget = _buildFallbackMedia(isDark);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: imageWidget,
      ),
    );
  }

  Widget _buildFallbackMedia(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 38,
        color: isDark ? Colors.white24 : Colors.grey.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(notification.category);
    final catIcon = _getCategoryIcon(notification.category);

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Pemberitahuan',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Lampiran Media Gambar (jika dikirim oleh Admin Pusat)
              if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) ...[
                _buildMediaAttachment(notification.imageUrl!, isDark),
                const SizedBox(height: 16),
              ],

              // 2. Kategori Pill & Tanggal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: isDark ? 0.22 : 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(catIcon, size: 13, color: catColor),
                        const SizedBox(width: 5),
                        Text(
                          notification.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: catColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('d MMM, HH:mm', 'id_ID').format(notification.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Judul Notifikasi
              Text(
                notification.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                _formatFullDate(notification.timestamp),
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(
                  height: 1,
                  thickness: 0.8,
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),

              // 4. Isi Pesan Lengkap
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // 5. Tombol Aksi Kontekstual
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
