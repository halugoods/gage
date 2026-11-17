import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gage_app/core/services/gage_sound_service.dart';
import 'package:gage_app/core/services/gage_video_feed_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/features/video/presentation/video_editor_screen.dart';
import 'package:gage_app/features/video/presentation/video_feed_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Layar Detail Sound / Musik ala TikTok & Instagram Reels
class SoundDetailScreen extends StatefulWidget {
  final GageSound sound;

  const SoundDetailScreen({
    super.key,
    required this.sound,
  });

  @override
  State<SoundDetailScreen> createState() => _SoundDetailScreenState();
}

class _SoundDetailScreenState extends State<SoundDetailScreen>
    with SingleTickerProviderStateMixin {
  late bool _isSaved;
  bool _isPlayingPreview = false;
  late AnimationController _discRotCtrl;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.sound.isSaved;
    _discRotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _discRotCtrl.dispose();
    super.dispose();
  }

  void _toggleSave() {
    HapticFeedback.selectionClick();
    final nowSaved = GageSoundService.instance.toggleSaveSound(widget.sound.id);
    setState(() {
      _isSaved = nowSaved;
    });
    GageToast.show(
      context,
      nowSaved ? 'Musik disimpan ke Favorit' : 'Musik dihapus dari Favorit',
      type: GageToastType.success,
    );
  }

  void _shareSound() {
    HapticFeedback.selectionClick();
    final text = 'Dengarkan suara "${widget.sound.title}" oleh ${widget.sound.artist} di GAGE Video: https://gage.id/sound/${widget.sound.id}';
    SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _handleUseSound() async {
    HapticFeedback.selectionClick();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (!mounted) return;
      if (picked != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoEditorScreen(
              videoPath: picked.path,
              videoName: picked.name,
              initialSound: widget.sound,
            ),
          ),
        );
        return;
      }
    } catch (_) {}

    if (mounted) {
      // Fallback jika tidak memilih file langsung buka editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditorScreen(
            videoPath: '',
            videoName: 'video_sample.mp4',
            initialSound: widget.sound,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final videos = GageVideoFeedService.instance.videos;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sound.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: _shareSound,
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Sound Header Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Spinning Vinyl Disc with Album Art
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _discRotCtrl,
                            child: Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E293B),
                                border: Border.all(color: Colors.white24, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: ClipOval(
                                  child: Image.network(
                                    widget.sound.albumArtUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.music_note_rounded, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Mini Play / Pause Icon
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPlayingPreview = !_isPlayingPreview;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.7),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Icon(
                                _isPlayingPreview
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      // Title, Artist, & Stats
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.sound.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(
                                      initialCreatorHandle: widget.sound.artist,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                widget.sound.artist,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: GageTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${widget.sound.videoCount} video dibuat dengan suara ini',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Tombol Simpan Musik
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _isSaved
                                      ? GageTheme.primary
                                      : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                ),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                              onPressed: _toggleSave,
                              icon: Icon(
                                _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                size: 16,
                                color: _isSaved ? GageTheme.primary : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              label: Text(
                                _isSaved ? 'Tersimpan' : 'Simpan Musik',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isSaved ? GageTheme.primary : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Divider(height: 1, indent: 16, endIndent: 16),
              ),

              // 2. Video Grid Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Text(
                    'Video Terkait',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),

              // 3. 3-Column Video Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = videos[index % videos.length];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoFeedScreen(
                                initialIndex: index % videos.length,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item.thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: const Color(0xFF1E293B)),
                              ),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 14,
                                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${item.likesCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
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
                    childCount: videos.length * 2,
                  ),
                ),
              ),
            ],
          ),

          // 4. Bottom Sticky Full-Width CTA "Gunakan Suara Ini"
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 4,
                  shadowColor: GageTheme.primary.withValues(alpha: 0.45),
                ),
                onPressed: _handleUseSound,
                icon: const Icon(Icons.videocam_rounded, size: 20),
                label: const Text(
                  'Gunakan Suara Ini',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
