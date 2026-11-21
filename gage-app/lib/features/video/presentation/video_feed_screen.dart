import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:gage_app/core/services/gage_sound_service.dart';
import 'package:gage_app/core/services/gage_video_feed_service.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/video/presentation/sound_detail_screen.dart';
import 'package:gage_app/features/video/presentation/video_editor_screen.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';

/// Layar GAGE Video Feed (Immersive Full-Screen Vertical Feed + Frosted Glass HUD)
class VideoFeedScreen extends StatefulWidget {
  final int initialIndex;

  const VideoFeedScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;

  /// Pool controller video (menjaga hanya indeks aktif & tetangga ±1 tetap di memori)
  final Map<int, VideoPlayerController> _controllers = {};
  final Set<int> _initializingIndices = {};

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Katalog Video Terhubung Langsung ke GageVideoFeedService (Reaktif terhadap Unggahan Kreator)
  List<GageVideoItem> get _videos => GageVideoFeedService.instance.videos;

  void _onFeedServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GageVideoFeedService.instance.addListener(_onFeedServiceChanged);
    final count = _videos.length;
    _currentIndex = count > 0 ? widget.initialIndex.clamp(0, count - 1) : 0;
    _pageController = PageController(initialPage: _currentIndex);
    if (count > 0) {
      _syncControllerPool(_currentIndex);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final activeController = _controllers[_currentIndex];
    if (activeController == null || !activeController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      activeController.pause();
    } else if (state == AppLifecycleState.resumed) {
      activeController.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GageVideoFeedService.instance.removeListener(_onFeedServiceChanged);
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  /// Mengelola pool controller agar memori efisien dan transisi antar video 60 FPS
  Future<void> _syncControllerPool(int centerIndex) async {
    final targetIndices = <int>{
      centerIndex,
      if (centerIndex - 1 >= 0) centerIndex - 1,
      if (centerIndex + 1 < _videos.length) centerIndex + 1,
    };

    // Buang controller yang jauh dari viewport aktif
    final toRemove = _controllers.keys
        .where((idx) => !targetIndices.contains(idx))
        .toList();
    for (final idx in toRemove) {
      await _controllers[idx]?.pause();
      await _controllers[idx]?.dispose();
      _controllers.remove(idx);
    }

    // Pause video tetangga dan putar video aktif
    for (final entry in _controllers.entries) {
      if (entry.key == centerIndex) {
        if (entry.value.value.isInitialized && !entry.value.value.isPlaying) {
          entry.value.play();
        }
      } else {
        if (entry.value.value.isInitialized && entry.value.value.isPlaying) {
          entry.value.pause();
          entry.value.seekTo(Duration.zero);
        }
      }
    }

    // Inisialisasi controller aktif terlebih dahulu, lalu preload tetangga
    await _initControllerAt(centerIndex, autoPlay: true);
    for (final idx in targetIndices) {
      if (idx != centerIndex) {
        _initControllerAt(idx, autoPlay: false);
      }
    }
  }

  Future<void> _initControllerAt(int index, {required bool autoPlay}) async {
    if (index < 0 || index >= _videos.length) return;
    if (_controllers.containsKey(index) || _initializingIndices.contains(index)) {
      if (autoPlay && _controllers[index]?.value.isInitialized == true) {
        _controllers[index]?.play();
      }
      return;
    }

    _initializingIndices.add(index);
    final videoPath = _videos[index].videoUrl;

    // Mendukung video lokal assets maupun network URL secara transparan
    final controller = videoPath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(videoPath))
        : VideoPlayerController.asset(videoPath);

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(1.0);
      _controllers[index] = controller;

      if (index == _currentIndex && autoPlay) {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      await controller.dispose();
    } finally {
      _initializingIndices.remove(index);
    }
  }

  void _onPageChanged(int newIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = newIndex;
    });
    _syncControllerPool(newIndex);
  }

  String _formatCompactCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      final val = count / 1000;
      return val % 1 == 0
          ? '${val.toInt()}K'
          : '${val.toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _openMerchantDetails(GageVideoItem item) {
    HapticFeedback.lightImpact();
    _controllers[_currentIndex]?.pause();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MerchantDetailSheet(
        item: item,
        currencyFormatter: currencyFormatter,
        onOrderTap: () {
          Navigator.pop(ctx);
          _openQuickOrderSheet(item);
        },
      ),
    ).whenComplete(() {
      if (mounted) _controllers[_currentIndex]?.play();
    });
  }

  void _openCommentsSheet(GageVideoItem item) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CommentBottomSheet(
        item: item,
        onCommentAdded: (newComment) {
          setState(() {
            item.sampleComments.insert(0, newComment);
            item.commentsCount += 1;
          });
        },
      ),
    );
  }

  void _openQuickOrderSheet(GageVideoItem item) {
    HapticFeedback.mediumImpact();
    _controllers[_currentIndex]?.pause();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _QuickOrderBottomSheet(
        item: item,
        currencyFormatter: currencyFormatter,
        onConfirmAddToCart: (int qty, String note) {
          final cart = context.read<CartProvider>();
          cart.addItem(
            CartItemModel(
              menuId: item.productId,
              merchantId: item.merchantId,
              merchantName: item.merchantName,
              name: item.productTitle,
              price: item.productPrice,
              quantity: qty,
              notes: note,
              imageUrl: item.thumbnailUrl,
              category: 'Kuliner',
              serviceType: 'food',
            ),
          );

          Navigator.pop(ctx);
          HapticFeedback.heavyImpact();

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Colors.white12),
              ),
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: GageTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$qty× ${item.productTitle} masuk keranjang!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      if (mounted) _controllers[_currentIndex]?.play();
    });
  }

  void _handleShare(GageVideoItem item) {
    HapticFeedback.lightImpact();
    setState(() {
      item.sharesCount += 1;
    });
    _openShareModal(item);
  }

  void _showVideoShareSheet(GageVideoItem item) {
    final cleanHandle = item.creatorHandle.startsWith('@') ? item.creatorHandle : '@${item.creatorHandle}';
    final shareUrl = 'https://gage.id/video/${item.id}';
    final shareText = 'Tonton video kuliner $cleanHandle di GAGE: $shareUrl';

    SharePlus.instance.share(ShareParams(
      text: shareText,
      subject: 'Video Kuliner GAGE',
    ));
  }

  void _openShareModal(GageVideoItem item) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            18 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bagikan Video',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Baris opsi berbagi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareSheetAction(
                    icon: Icons.link_rounded,
                    color: const Color(0xFF3B82F6),
                    label: 'Salin Tautan',
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final shareUrl = 'https://gage.id/video/${item.id}';
                      await Clipboard.setData(ClipboardData(text: shareUrl));
                      if (mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                            backgroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: Colors.white12),
                            ),
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                SizedBox(width: 10),
                                Text(
                                  'Tautan video berhasil disalin ke papan klip!',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildShareSheetAction(
                    icon: Icons.download_rounded,
                    color: const Color(0xFF10B981),
                    label: 'Unduh Video',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleDownloadWatermarkedVideo(item);
                    },
                  ),
                  _buildShareSheetAction(
                    icon: Icons.share_rounded,
                    color: GageTheme.primary,
                    label: 'Bagikan via...',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showVideoShareSheet(item);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareSheetAction({
    required IconData icon,
    required Color color,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDownloadWatermarkedVideo(GageVideoItem item) async {
    HapticFeedback.mediumImpact();
    final baseName = item.videoUrl.split('/').last.replaceAll('.mp4', '');
    String selectedAsset = 'assets/videos/watermarked/${baseName}_wm.mp4';
    try {
      await rootBundle.load(selectedAsset);
    } catch (_) {
      selectedAsset = 'assets/videos/watermarked/vt_rocket_chicken_wm.mp4';
    }

    final candidateDirs = [
      Directory('/storage/emulated/0/Movies/Gage by Halu Goods Indonesia'),
      Directory('/storage/emulated/0/DCIM/Gage by Halu Goods Indonesia'),
      Directory('/storage/emulated/0/Pictures/Gage by Halu Goods Indonesia'),
      Directory('/storage/emulated/0/Download/Gage by Halu Goods Indonesia'),
      Directory('/storage/emulated/0/Movies'),
      Directory('/storage/emulated/0/DCIM'),
    ];
    Directory? targetDir;
    for (final d in candidateDirs) {
      try {
        if (!await d.exists()) {
          await d.create(recursive: true);
        }
        targetDir = d;
        break;
      } catch (_) {}
    }

    if (targetDir != null) {
      try {
        final targetFile = File('${targetDir.path}/GAGE_${item.id}_wm.mp4');
        final byteData = await rootBundle.load(selectedAsset);
        await targetFile.writeAsBytes(byteData.buffer.asUint8List());

        // Mendaftarkan berkas ke MediaStore Android via MethodChannel
        try {
          const channel = MethodChannel('com.gage/media_scanner');
          await channel.invokeMethod('scanFile', {'path': targetFile.path});
        } catch (_) {}
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.white12),
          ),
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video berhasil disimpan di galeri album "Gage by Halu Goods Indonesia"',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Watermark: Property of GAGE / HaloGoods.Indonesia',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _openCreateVideoFlow() async {
    HapticFeedback.selectionClick();
    _controllers[_currentIndex]?.pause();
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
            ),
          ),
        ).whenComplete(() {
          if (mounted) _controllers[_currentIndex]?.play();
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const VideoEditorScreen(
            videoPath: '',
            videoName: 'video_sample.mp4',
          ),
        ),
      ).whenComplete(() {
        if (mounted) _controllers[_currentIndex]?.play();
      });
    }
  }

  void _openSoundDetail(GageVideoItem item) {
    HapticFeedback.selectionClick();
    _controllers[_currentIndex]?.pause();
    final sound = GageSoundService.instance.sounds.first;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoundDetailScreen(sound: sound),
      ),
    ).whenComplete(() {
      if (mounted) _controllers[_currentIndex]?.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSafeInset = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
        extendBody: true,
        body: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          itemCount: _videos.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final item = _videos[index];
            final controller = _controllers[index];

            return _VideoFeedPage(
              item: item,
              controller: controller,
              isActivePage: index == _currentIndex,
              bottomSafeInset: bottomSafeInset,
              currencyFormatter: currencyFormatter,
              formatCount: _formatCompactCount,
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              onMerchantTap: () => _openMerchantDetails(item),
              onFollowTap: () {
                HapticFeedback.mediumImpact();
                GageVideoFeedService.instance.toggleFollow(item.id);
                SocialProfileService.instance.toggleFollow(item.creatorHandle);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(milliseconds: 1400),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    content: Row(
                      children: [
                        Icon(
                          item.isFollowing
                              ? Icons.check_circle_rounded
                              : Icons.person_remove_rounded,
                          color: item.isFollowing
                              ? const Color(0xFF10B981)
                              : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.isFollowing
                              ? 'Mengikuti ${item.creatorHandle}'
                              : 'Batal mengikuti ${item.creatorHandle}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onLikeToggle: ({bool forceLike = false}) {
                HapticFeedback.mediumImpact();
                if (forceLike) {
                  if (!item.isLiked) {
                    GageVideoFeedService.instance.toggleLike(item.id);
                    SocialProfileService.instance.toggleLikeVideo(item.id);
                  }
                } else {
                  GageVideoFeedService.instance.toggleLike(item.id);
                  SocialProfileService.instance.toggleLikeVideo(item.id);
                }
              },
              onCommentTap: () => _openCommentsSheet(item),
              onBookmarkTap: () {
                HapticFeedback.selectionClick();
                GageVideoFeedService.instance.toggleBookmark(item.id);
                SocialProfileService.instance.toggleBookmarkVideo(item.id);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(milliseconds: 1400),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    content: Row(
                      children: [
                        Icon(
                          item.isBookmarked
                              ? Icons.bookmark_added_rounded
                              : Icons.bookmark_remove_rounded,
                          color: item.isBookmarked
                              ? const Color(0xFFF59E0B)
                              : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.isBookmarked
                              ? 'Video disimpan ke Bookmark profil'
                              : 'Video dihapus dari Bookmark',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onRepostTap: () {
                HapticFeedback.selectionClick();
                GageVideoFeedService.instance.toggleRepost(item.id);
                SocialProfileService.instance.toggleRepostVideo(item.id);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(milliseconds: 1400),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    content: Row(
                      children: [
                        Icon(
                          item.isReposted
                              ? Icons.repeat_rounded
                              : Icons.repeat_on_rounded,
                          color: item.isReposted
                              ? const Color(0xFF10B981)
                              : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.isReposted
                              ? 'Video berhasil diposting ulang ke profil Anda'
                              : 'Posting ulang video dibatalkan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onShareTap: () => _handleShare(item),
              onSoundTap: () => _openSoundDetail(item),
              onMakeVideoTap: _openCreateVideoFlow,
              onOrderTap: () => _openQuickOrderSheet(item),
            );
          },
        ),
        bottomNavigationBar: const GageBottomNavBar(currentIndex: 3),
      ),
    ),
  );
  }
}

/// Halaman Tunggal dalam Vertical Feed
class _VideoFeedPage extends StatefulWidget {
  final GageVideoItem item;
  final VideoPlayerController? controller;
  final bool isActivePage;
  final double bottomSafeInset;
  final NumberFormat currencyFormatter;
  final String Function(int) formatCount;
  final VoidCallback onMakeVideoTap;
  final VoidCallback onBackTap;
  final VoidCallback onMerchantTap;
  final VoidCallback onFollowTap;
  final void Function({bool forceLike}) onLikeToggle;
  final VoidCallback onCommentTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onRepostTap;
  final VoidCallback onShareTap;
  final VoidCallback onSoundTap;
  final VoidCallback onOrderTap;

  const _VideoFeedPage({
    required this.item,
    required this.controller,
    required this.isActivePage,
    required this.bottomSafeInset,
    required this.currencyFormatter,
    required this.formatCount,
    required this.onMakeVideoTap,
    required this.onBackTap,
    required this.onMerchantTap,
    required this.onFollowTap,
    required this.onLikeToggle,
    required this.onCommentTap,
    required this.onBookmarkTap,
    required this.onRepostTap,
    required this.onShareTap,
    required this.onSoundTap,
    required this.onOrderTap,
  });

  @override
  State<_VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<_VideoFeedPage>
    with TickerProviderStateMixin {
  bool _isPausedManually = false;
  bool _isCaptionExpanded = false;
  Offset? _doubleTapPosition;
  late AnimationController _heartBurstCtrl;
  late AnimationController _discRotateCtrl;
  late Animation<double> _heartScaleAnim;
  late Animation<double> _heartOpacityAnim;
  Timer? _shoppableTagTimer;
  bool _showShoppableTag = false;

  @override
  void initState() {
    super.initState();
    _startShoppableTimer();
    _heartBurstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _discRotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    if (widget.isActivePage && (widget.controller?.value.isPlaying ?? true)) {
      _discRotateCtrl.repeat();
    }

    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15),
        weight: 30,
      ),
    ]).animate(_heartBurstCtrl);

    _heartOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartBurstCtrl);
  }

  @override
  void didUpdateWidget(covariant _VideoFeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActivePage && _isPausedManually) {
      _isPausedManually = false;
    }
    if (widget.isActivePage != oldWidget.isActivePage) {
      if (widget.isActivePage) {
        if (!_isPausedManually && (widget.controller?.value.isPlaying ?? true)) {
          _discRotateCtrl.repeat();
        }
      } else {
        _discRotateCtrl.stop();
      }
    }
    if (oldWidget.item.id != widget.item.id || widget.isActivePage != oldWidget.isActivePage) {
      if (widget.isActivePage) {
        _startShoppableTimer();
      } else {
        _shoppableTagTimer?.cancel();
        _showShoppableTag = false;
      }
    }
  }

  void _startShoppableTimer() {
    _shoppableTagTimer?.cancel();
    _showShoppableTag = false;
    if (widget.isActivePage) {
      _shoppableTagTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showShoppableTag = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _shoppableTagTimer?.cancel();
    _heartBurstCtrl.dispose();
    _discRotateCtrl.dispose();
    super.dispose();
  }

  void _handleSingleTapVideo() {
    final ctrl = widget.controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    HapticFeedback.selectionClick();
    setState(() {
      if (ctrl.value.isPlaying) {
        ctrl.pause();
        _isPausedManually = true;
        _discRotateCtrl.stop();
      } else {
        ctrl.play();
        _isPausedManually = false;
        _discRotateCtrl.repeat();
      }
    });
  }

  void _handleDoubleTapVideo(TapDownDetails details) {
    setState(() {
      _doubleTapPosition = details.localPosition;
    });
    widget.onLikeToggle(forceLike: true);
    _heartBurstCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = widget.controller;
    final isInitialized = ctrl != null && ctrl.value.isInitialized;
    // Jarak melayang aman di atas floating bottom navbar GAGE
    final bottomCardOffset = 84.0 + widget.bottomSafeInset;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleSingleTapVideo,
      onDoubleTapDown: _handleDoubleTapVideo,
      onDoubleTap: () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. SEAMLESS RESPONSIVE VIDEO PLAYER (BoxFit.cover di semua rasio layar 9:16 vs 20:9)
          if (isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: const Alignment(0.0, -0.2),
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: ctrl.value.size.width > 0
                      ? ctrl.value.size.width
                      : 720,
                  height: ctrl.value.size.height > 0
                      ? ctrl.value.size.height
                      : 1280,
                  child: VideoPlayer(ctrl),
                ),
              ),
            )
          else
            // Thumbnail Ambient Backdrop saat Video Buffering
            Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.item.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF0A0D12)),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
                const Center(
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      color: GageTheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ],
            ),

          // 2. DUAL EDGE VIGNETTE OVERLAY (Top & Bottom Black54 -> Center Transparent)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black54,
                  ],
                  stops: const [0.0, 0.22, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 3. TACTILE PLAY/PAUSE INDICATOR SAAT VIDEO DIJEDA
          IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: _isPausedManually ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: AnimatedScale(
                  scale: _isPausedManually ? 1.0 : 0.75,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.48),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. DOUBLE-TAP HEART BURST ANIMATION
          if (_doubleTapPosition != null)
            Positioned(
              left: _doubleTapPosition!.dx - 48,
              top: _doubleTapPosition!.dy - 48,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _heartBurstCtrl,
                  builder: (context, child) {
                    if (_heartBurstCtrl.isDismissed) {
                      return const SizedBox.shrink();
                    }
                    return Opacity(
                      opacity: _heartOpacityAnim.value,
                      child: Transform.scale(
                        scale: _heartScaleAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: GageTheme.primary,
                    size: 96,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 18),
                    ],
                  ),
                ),
              ),
            ),

          // 5. TOP NAVIGATION LAYER (Unboxed Buat Video Camera Icon)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: InkWell(
              onTap: widget.onMakeVideoTap,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.video_call_rounded,
                  color: Colors.white,
                  size: 28,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 6. ACTION BAR VERTICAL (Right Floating Capsule)
          Positioned(
            right: 12,
            bottom: bottomCardOffset + 36,
            child: _RightVerticalActionBar(
              item: widget.item,
              isDark: isDark,
              formatCount: widget.formatCount,
              onFollowTap: () {
                setState(() {});
                widget.onFollowTap();
              },
              onLikeTap: () {
                setState(() {});
                widget.onLikeToggle(forceLike: false);
              },
              onCommentTap: widget.onCommentTap,
              onBookmarkTap: () {
                setState(() {});
                widget.onBookmarkTap();
              },
              onRepostTap: () {
                setState(() {});
                widget.onRepostTap();
              },
              onShareTap: widget.onShareTap,
              onSoundTap: widget.onSoundTap,
              discRotateAnimation: _discRotateCtrl,
            ),
          ),

          // 7. BOTTOM CONTENT OVERLAY (Caption, Creator Handle, and Delayed Shoppable Banner)
          Positioned(
            left: 16,
            right: 88,
            bottom: bottomCardOffset,
            child: _BottomContentOverlay(
              item: widget.item,
              isExpanded: _isCaptionExpanded,
              showShoppableTag: _showShoppableTag,
              currencyFormatter: widget.currencyFormatter,
              onToggleExpand: () {
                setState(() {
                  _isCaptionExpanded = !_isCaptionExpanded;
                });
              },
              onOrderTap: widget.onOrderTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sisi Kanan: Vertical Action Bar ala TikTok Klasik (Melayang Langsung di Atas Video)
class _RightVerticalActionBar extends StatelessWidget {
  final GageVideoItem item;
  final bool isDark;
  final String Function(int) formatCount;
  final VoidCallback onFollowTap;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onRepostTap;
  final VoidCallback onShareTap;
  final VoidCallback onSoundTap;
  final AnimationController discRotateAnimation;

  const _RightVerticalActionBar({
    required this.item,
    required this.isDark,
    required this.formatCount,
    required this.onFollowTap,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onBookmarkTap,
    required this.onRepostTap,
    required this.onShareTap,
    required this.onSoundTap,
    required this.discRotateAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Creator Avatar Profile with TikTok-Style Overlapping Follow Badge
        SizedBox(
          width: 48,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        initialCreatorHandle: item.creatorHandle,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      item.creatorAvatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF1E293B),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Tombol Follow Interaktif Overlapping Tepi Bawah Foto Profil
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onFollowTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: item.isFollowing
                          ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                          : GageTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        item.isFollowing ? Icons.check_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: item.isFollowing ? 13 : 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Like Button
        _ActionButtonTile(
          icon: Icons.favorite_rounded,
          color: item.isLiked ? const Color(0xFFEF4444) : Colors.white,
          label: formatCount(item.likesCount),
          onTap: onLikeTap,
        ),

        const SizedBox(height: 14),

        // 3. Comment Button
        _ActionButtonTile(
          icon: Icons.chat_bubble_rounded,
          color: Colors.white,
          label: formatCount(item.commentsCount),
          onTap: onCommentTap,
        ),

        const SizedBox(height: 14),

        // 4. Simpan / Bookmark Button (Sync ke Bookmark Profil)
        _ActionButtonTile(
          icon: Icons.bookmark_rounded,
          color: item.isBookmarked ? const Color(0xFFF59E0B) : Colors.white,
          label: formatCount(item.bookmarksCount),
          onTap: onBookmarkTap,
        ),

        const SizedBox(height: 14),

        // 5. Repost Button (Murni Icon Tanpa Label Teks, Berubah Warna Saat Aktif)
        _ActionButtonTile(
          icon: Icons.repeat_rounded,
          color: item.isReposted ? const Color(0xFF10B981) : Colors.white,
          onTap: onRepostTap,
        ),

        const SizedBox(height: 14),

        // 6. Share Button (TikTok Right-Curved Arrow)
        _ActionButtonTile(
          iconWidget: Transform.flip(
            flipX: true,
            child: const Icon(
              Icons.reply_rounded,
              color: Colors.white,
              size: 30,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          color: Colors.white,
          label: formatCount(item.sharesCount),
          onTap: onShareTap,
        ),

        const SizedBox(height: 16),

        // 7. Spinning Vinyl Disc (RotationTransition aktif saat video/audio diputar)
        GestureDetector(
          onTap: onSoundTap,
          child: RotationTransition(
            turns: discRotateAnimation,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                  stops: [0.3, 0.7, 1.0],
                ),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 5),
                ],
              ),
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: GageTheme.primary,
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtonTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Color color;
  final String? label;
  final VoidCallback onTap;

  const _ActionButtonTile({
    this.icon,
    this.iconWidget,
    required this.color,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ??
              Icon(
                icon,
                color: color,
                size: 30,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom Overlay: Keranjang Merah di ATAS Creator Handle dan Caption
class _BottomContentOverlay extends StatelessWidget {
  final GageVideoItem item;
  final bool isExpanded;
  final bool showShoppableTag;
  final NumberFormat currencyFormatter;
  final VoidCallback onToggleExpand;
  final VoidCallback onOrderTap;

  const _BottomContentOverlay({
    required this.item,
    required this.isExpanded,
    required this.showShoppableTag,
    required this.currencyFormatter,
    required this.onToggleExpand,
    required this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final captionText = item.caption;
    final isLongCaption = captionText.length > 70;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Kartu Keranjang Merah di ATAS Creator Handle & Caption (Muncul halus setelah video diputar 1,5 detik)
        if (item.productId.isNotEmpty && item.productTitle.isNotEmpty) ...[
          AnimatedOpacity(
            opacity: showShoppableTag ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: showShoppableTag
                ? _ShoppableProductBanner(
                    item: item,
                    currencyFormatter: currencyFormatter,
                    onOrderTap: onOrderTap,
                  )
                : const SizedBox.shrink(),
          ),
          if (showShoppableTag) const SizedBox(height: 10),
        ],

        // 2. Creator Handle (Direct text with shadow)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  initialCreatorHandle: item.creatorHandle,
                ),
              ),
            );
          },
          child: Text(
            item.creatorHandle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        // 3. Caption 2 Baris dengan Accordion Selengkapnya / Lebih Sedikit
        GestureDetector(
          onTap: isLongCaption ? onToggleExpand : null,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Text.rich(
              TextSpan(
                text: isExpanded
                    ? captionText
                    : (isLongCaption ? '${captionText.substring(0, 70)}...' : captionText),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                  ],
                ),
                children: [
                  if (isLongCaption)
                    TextSpan(
                      text: isExpanded ? ' Lebih sedikit' : ' Selengkapnya',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Solid High-Contrast Keranjang Merah Tag Banner (Afiliasi)
class _ShoppableProductBanner extends StatelessWidget {
  final GageVideoItem item;
  final NumberFormat currencyFormatter;
  final VoidCallback onOrderTap;

  const _ShoppableProductBanner({
    required this.item,
    required this.currencyFormatter,
    required this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onOrderTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.95),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Thumbnail Gambar Menu (48x48)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: item.thumbnailUrl.isNotEmpty
                        ? (item.thumbnailUrl.startsWith('assets/')
                            ? Image.asset(item.thumbnailUrl, fit: BoxFit.cover)
                            : Image.network(
                                item.thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                  child: Icon(
                                    Icons.restaurant_rounded,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                    size: 22,
                                  ),
                                ),
                              ))
                        : Container(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              size: 22,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.productTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (item.originalPrice != null && item.originalPrice! > item.productPrice) ...[
                            Text(
                              currencyFormatter.format(item.originalPrice),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            currencyFormatter.format(item.productPrice),
                            style: const TextStyle(
                              color: GageTheme.primary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Tombol Beli: Bersih teks murni tanpa ikon keranjang
                Material(
                  color: GageTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                  elevation: 2,
                  child: InkWell(
                    onTap: onOrderTap,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8.5),
                      child: Text(
                        'Beli',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom Sheet Detail Restoran / Merchant saat Pill Atas Ditekan
class _MerchantDetailSheet extends StatelessWidget {
  final GageVideoItem item;
  final NumberFormat currencyFormatter;
  final VoidCallback onOrderTap;

  const _MerchantDetailSheet({
    required this.item,
    required this.currencyFormatter,
    required this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: GageTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.merchantName,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Buka',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '★ ${item.merchantRating} • ${item.merchantLocation} • Estimasi ${item.deliveryEstimate}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.merchantAddress,
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.thumbnailUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56,
                      height: 56,
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      child: Icon(
                        Icons.fastfood,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productTitle,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currencyFormatter.format(item.productPrice),
                        style: const TextStyle(
                          color: GageTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestoDetailScreen(
                          merchant: {
                            'id': item.merchantId,
                            'name': item.merchantName,
                            'rating': item.merchantRating,
                            'location': item.merchantLocation,
                            'address': item.merchantAddress,
                            'image': item.thumbnailUrl,
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Kunjungi Resto',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Bottom Sheet Komentar Video
class _CommentBottomSheet extends StatefulWidget {
  final GageVideoItem item;
  final ValueChanged<GageVideoComment> onCommentAdded;

  const _CommentBottomSheet({
    required this.item,
    required this.onCommentAdded,
  });

  @override
  State<_CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<_CommentBottomSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyToUsername;
  GageVideoComment? _replyToParentComment;
  final Set<String> _likedCommentIds = {};

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _startReply({required GageVideoComment parent, required String targetUsername}) {
    HapticFeedback.lightImpact();
    setState(() {
      _replyToParentComment = parent;
      _replyToUsername = targetUsername;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToParentComment = null;
      _replyToUsername = null;
    });
  }

  void _submitComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();

    if (_replyToParentComment != null) {
      final targetUser = _replyToUsername ?? _replyToParentComment!.username;
      final fullText = text.startsWith(targetUser) ? text : '$targetUser $text';
      final reply = GageVideoComment(
        id: 'reply-${DateTime.now().millisecondsSinceEpoch}',
        username: '@pengguna_gage',
        text: fullText,
        timeAgo: 'Baru saja',
        likes: 0,
        replyToUsername: targetUser,
      );
      setState(() {
        _replyToParentComment!.replies.add(reply);
        widget.item.commentsCount += 1;
        _replyToParentComment = null;
        _replyToUsername = null;
      });
      GageVideoFeedService.instance.addComment(
        widget.item.id,
        reply,
        parentCommentId: _replyToParentComment?.id,
      );
    } else {
      final comment = GageVideoComment(
        id: 'c-${DateTime.now().millisecondsSinceEpoch}',
        username: '@pengguna_gage',
        text: text,
        timeAgo: 'Baru saja',
        likes: 0,
      );
      widget.onCommentAdded(comment);
      GageVideoFeedService.instance.addComment(widget.item.id, comment);
    }
    _commentCtrl.clear();
    setState(() {
      _replyToParentComment = null;
      _replyToUsername = null;
    });
  }

  Widget _buildCommentTextWithTag(String text, bool isDark) {
    if (text.startsWith('@')) {
      final spaceIdx = text.indexOf(' ');
      if (spaceIdx != -1) {
        final tag = text.substring(0, spaceIdx);
        final rest = text.substring(spaceIdx);
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: tag,
                style: const TextStyle(
                  color: GageTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              TextSpan(
                text: rest,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF334155),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      }
    }
    return Text(
      text,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF334155),
        fontSize: 12,
        height: 1.35,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.58,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.item.commentsCount} Komentar',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            Expanded(
              child: widget.item.sampleComments.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada komentar. Jadilah yang pertama!',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                          fontSize: 12.5,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: widget.item.sampleComments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, idx) {
                        final c = widget.item.sampleComments[idx];
                        final isCommentLiked = _likedCommentIds.contains(c.id);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Komentar Induk (Parent Comment)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      GageTheme.primary.withValues(alpha: 0.16),
                                  child: Text(
                                    c.username.replaceAll('@', '')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: GageTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c.username,
                                            style: TextStyle(
                                              color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            c.timeAgo,
                                            style: TextStyle(
                                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        c.text,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF334155),
                                          fontSize: 12.5,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Tombol Balas Komentar
                                      InkWell(
                                        onTap: () => _startReply(parent: c, targetUsername: c.username),
                                        child: Text(
                                          'Balas',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Tombol Like Komentar Induk
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (isCommentLiked) {
                                        _likedCommentIds.remove(c.id);
                                        c.likes = (c.likes - 1).clamp(0, 99999);
                                      } else {
                                        _likedCommentIds.add(c.id);
                                        c.likes += 1;
                                      }
                                    });
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isCommentLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 16,
                                        color: isCommentLiked
                                            ? const Color(0xFFEF4444)
                                            : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                      ),
                                      if (c.likes > 0) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          '${c.likes}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // 2. Threaded Replies (Nested & Indented under parent comment)
                            if (c.replies.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 42, top: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: c.replies.map((reply) {
                                    final isReplyLiked = _likedCommentIds.contains(reply.id);

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: GageTheme.primary.withValues(alpha: 0.14),
                                            child: Text(
                                              reply.username.replaceAll('@', '')[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: GageTheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      reply.username,
                                                      style: TextStyle(
                                                        color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      reply.timeAgo,
                                                      style: TextStyle(
                                                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                // RichText highlighting tagged @username
                                                _buildCommentTextWithTag(reply.text, isDark),
                                                const SizedBox(height: 3),
                                                InkWell(
                                                  onTap: () => _startReply(parent: c, targetUsername: reply.username),
                                                  child: Text(
                                                    'Balas',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                if (isReplyLiked) {
                                                  _likedCommentIds.remove(reply.id);
                                                  reply.likes = (reply.likes - 1).clamp(0, 99999);
                                                } else {
                                                  _likedCommentIds.add(reply.id);
                                                  reply.likes += 1;
                                                }
                                              });
                                            },
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isReplyLiked
                                                      ? Icons.favorite_rounded
                                                      : Icons.favorite_border_rounded,
                                                  size: 14,
                                                  color: isReplyLiked
                                                      ? const Color(0xFFEF4444)
                                                      : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                                ),
                                                if (reply.likes > 0)
                                                  Text(
                                                    '${reply.likes}',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
            ),
            // Banner Membalas Komentar
            if (_replyToUsername != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, size: 16, color: GageTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Membalas $_replyToUsername',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: GageTheme.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _cancelReply,
                      child: const Icon(Icons.close_rounded, size: 16, color: GageTheme.primary),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    focusNode: _commentFocusNode,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                    decoration: InputDecoration(
                      hintText: _replyToUsername != null
                          ? 'Tulis balasan untuk $_replyToUsername...'
                          : 'Tulis komentar tentang menu ini...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        fontSize: 12.5,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: GageTheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _submitComment,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick Order / Keranjang Kuning Sheet terintegrasi dengan CartProvider
class _QuickOrderBottomSheet extends StatefulWidget {
  final GageVideoItem item;
  final NumberFormat currencyFormatter;
  final void Function(int quantity, String note) onConfirmAddToCart;

  const _QuickOrderBottomSheet({
    required this.item,
    required this.currencyFormatter,
    required this.onConfirmAddToCart,
  });

  @override
  State<_QuickOrderBottomSheet> createState() => _QuickOrderBottomSheetState();
}

class _QuickOrderBottomSheetState extends State<_QuickOrderBottomSheet> {
  int _quantity = 1;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPrice = widget.item.productPrice * _quantity;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.item.merchantName,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestoDetailScreen(
                          merchant: {
                            'id': widget.item.merchantId,
                            'name': widget.item.merchantName,
                            'rating': widget.item.merchantRating,
                            'location': widget.item.merchantLocation,
                            'image': widget.item.thumbnailUrl,
                            'category': 'Kuliner',
                          },
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buka Toko',
                        style: TextStyle(
                          color: GageTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_new_rounded, size: 14, color: GageTheme.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    widget.item.thumbnailUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 64,
                      height: 64,
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.productTitle,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.currencyFormatter.format(widget.item.productPrice),
                        style: const TextStyle(
                          color: GageTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Stepper Kuantitas di Kanan Kartu Produk
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.remove_rounded,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          size: 16,
                        ),
                        onPressed: _quantity > 1
                            ? () {
                                HapticFeedback.selectionClick();
                                setState(() => _quantity--);
                              }
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$_quantity',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.add_rounded,
                          color: GageTheme.primary,
                          size: 16,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _quantity++);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteCtrl,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 12.5,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.edit_note_rounded,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  size: 20,
                ),
                hintText: 'Catatan pesanan (opsional, misal: sambal dipisah)',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Tombol Ikon Keranjang Bulat di Kiri
                InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onConfirmAddToCart(
                      _quantity,
                      _noteCtrl.text.trim(),
                    );
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: GageTheme.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Pesan Langsung Besar di Kanan
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: () {
                        widget.onConfirmAddToCart(
                          _quantity,
                          _noteCtrl.text.trim(),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(serviceType: 'food'),
                          ),
                        );
                      },
                      child: Text(
                        'Pesan Langsung • ${widget.currencyFormatter.format(totalPrice)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
