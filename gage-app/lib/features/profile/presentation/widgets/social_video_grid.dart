import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/services/gage_video_feed_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/video/presentation/video_feed_screen.dart';

/// SocialVideoGrid
/// Grid Video 3-Kolom ala TikTok / Instagram Reels
/// Menampilkan thumbnail vertikal, jumlah views, dan pin Keranjang Kuning untuk shoppable video.
class SocialVideoGrid extends StatelessWidget {
  final List<GageVideoItem> videos;
  final String emptyMessage;
  final VoidCallback? onUploadTap;

  const SocialVideoGrid({
    super.key,
    required this.videos,
    this.emptyMessage = 'Belum ada video yang diposting',
    this.onUploadTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (videos.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.movie_creation_outlined,
                size: 36,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            if (onUploadTap != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onUploadTap!();
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Upload Video Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(3),
      itemCount: videos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62, // Aspek rasio video vertikal TikTok
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemBuilder: (context, index) {
        final item = videos[index];
        final hasKerkun = item.productId.isNotEmpty;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Cari indeks di katalog utama feed agar sinkron
            final allVideos = GageVideoFeedService.instance.videos;
            final feedIdx = allVideos.indexWhere((v) => v.id == item.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoFeedScreen(
                  initialIndex: feedIdx >= 0 ? feedIdx : 0,
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail Video
              Container(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                child: item.thumbnailUrl.startsWith('assets/')
                    ? Image.asset(item.thumbnailUrl, fit: BoxFit.cover)
                    : Image.network(
                        item.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 32),
                          ),
                        ),
                      ),
              ),

              // Gradient halus di bagian bawah untuk teks views
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              // Badge Jumlah Views di sudut kiri bawah
              Positioned(
                left: 6,
                bottom: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatCount(item.likesCount > 0 ? item.likesCount : 1240),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Badge Keranjang Kuning (Kerkun) di sudut kanan atas
              if (hasKerkun)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24), // Vibrant Yellow
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.black,
                      size: 11,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }
}
