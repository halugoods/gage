import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:gage_app/core/services/gage_video_feed_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';

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
                      color: Color(0xFFFFB703),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(0xFF0F172A),
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
    Clipboard.setData(
      ClipboardData(
        text:
            'Cek review ${item.productTitle} di ${item.merchantName} (${item.merchantLocation}) lewat GAGE Video! https://gage.id/video/${item.id}',
      ),
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
        content: const Text(
          'Tautan video & menu merchant disalin ke clipboard',
          style: TextStyle(color: Colors.white, fontSize: 12.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSafeInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                setState(() {
                  item.isFollowing = !item.isFollowing;
                });
              },
              onLikeToggle: ({bool forceLike = false}) {
                HapticFeedback.mediumImpact();
                setState(() {
                  if (forceLike) {
                    if (!item.isLiked) {
                      item.isLiked = true;
                      item.likesCount += 1;
                    }
                  } else {
                    item.isLiked = !item.isLiked;
                    item.likesCount += item.isLiked ? 1 : -1;
                  }
                });
              },
              onCommentTap: () => _openCommentsSheet(item),
              onShareTap: () => _handleShare(item),
              onOrderTap: () => _openQuickOrderSheet(item),
            );
          },
        ),
        bottomNavigationBar: const GageBottomNavBar(currentIndex: 3),
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
  final VoidCallback onBackTap;
  final VoidCallback onMerchantTap;
  final VoidCallback onFollowTap;
  final void Function({bool forceLike}) onLikeToggle;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onOrderTap;

  const _VideoFeedPage({
    required this.item,
    required this.controller,
    required this.isActivePage,
    required this.bottomSafeInset,
    required this.currencyFormatter,
    required this.formatCount,
    required this.onBackTap,
    required this.onMerchantTap,
    required this.onFollowTap,
    required this.onLikeToggle,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onOrderTap,
  });

  @override
  State<_VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<_VideoFeedPage>
    with SingleTickerProviderStateMixin {
  bool _isPausedManually = false;
  bool _isCaptionExpanded = false;
  Offset? _doubleTapPosition;
  late AnimationController _heartBurstCtrl;
  late Animation<double> _heartScaleAnim;
  late Animation<double> _heartOpacityAnim;

  @override
  void initState() {
    super.initState();
    _heartBurstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

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
  }

  @override
  void dispose() {
    _heartBurstCtrl.dispose();
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
      } else {
        ctrl.play();
        _isPausedManually = false;
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

          // 5. TOP NAVIGATION LAYER (Back | Merchant Capsule | GAGE Video Watermark)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Left: Frosted Glass Back Button
                _FrostedGlassBox(
                  borderRadius: BorderRadius.circular(999),
                  sigma: 12,
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.85),
                  borderColor: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.6),
                  child: InkWell(
                    onTap: widget.onBackTap,
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        size: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Center Top: Frosted Glass Merchant Pill
                Expanded(
                  child: Center(
                    child: _FrostedGlassBox(
                      borderRadius: BorderRadius.circular(999),
                      sigma: 12,
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.38)
                          : Colors.white.withValues(alpha: 0.85),
                      borderColor: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.6),
                      child: InkWell(
                        onTap: widget.onMerchantTap,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.item.merchantName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB703),
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.item.merchantRating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '${widget.item.merchantLocation} 📍',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF475569),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Right: Subtle "GAGE Video" Watermark Text
                Text(
                  'GAGE Video',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : const Color(0xFF0F172A).withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(
                        color: isDark ? Colors.black54 : Colors.white.withValues(alpha: 0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 6. ACTION BAR VERTICAL (Right Floating Capsule)
          Positioned(
            right: 12,
            bottom: bottomCardOffset + 8,
            child: _RightVerticalActionBar(
              item: widget.item,
              isDark: isDark,
              formatCount: widget.formatCount,
              onFollowTap: widget.onFollowTap,
              onLikeTap: () => widget.onLikeToggle(forceLike: false),
              onCommentTap: widget.onCommentTap,
              onShareTap: widget.onShareTap,
            ),
          ),

          // 7. BOTTOM SHOPPABLE CARD (Left Floating Capsule - Zero Collision with Right Action Bar!)
          Positioned(
            left: 12,
            right: 76,
            bottom: bottomCardOffset,
            child: _BottomShoppableCard(
              item: widget.item,
              isDark: isDark,
              isExpanded: _isCaptionExpanded,
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

/// Reusable Frosted Glass Container
class _FrostedGlassBox extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double sigma;
  final Color color;
  final Color borderColor;

  const _FrostedGlassBox({
    required this.child,
    required this.borderRadius,
    this.sigma = 10,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: child,
        ),
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
  final VoidCallback onShareTap;

  const _RightVerticalActionBar({
    required this.item,
    required this.isDark,
    required this.formatCount,
    required this.onFollowTap,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Creator Avatar + Red '+' Follow Badge
        SizedBox(
          width: 44,
          height: 50,
          child: Stack(
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
                  width: 42,
                  height: 42,
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
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  onTap: onFollowTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: item.isFollowing
                          ? const Color(0xFF10B981)
                          : GageTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Icon(
                      item.isFollowing
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Like Button
        _ActionButtonTile(
          icon: item.isLiked
              ? Icons.favorite_rounded
              : Icons.favorite_rounded,
          color: item.isLiked ? const Color(0xFFEF4444) : Colors.white,
          label: formatCount(item.likesCount),
          onTap: onLikeTap,
        ),

        const SizedBox(height: 16),

        // Comment Button
        _ActionButtonTile(
          icon: Icons.chat_bubble_rounded,
          color: Colors.white,
          label: formatCount(item.commentsCount),
          onTap: onCommentTap,
        ),

        const SizedBox(height: 16),

        // Share Button
        _ActionButtonTile(
          icon: Icons.share_rounded,
          color: Colors.white,
          label: formatCount(item.sharesCount),
          onTap: onShareTap,
        ),

        const SizedBox(height: 18),

        // Spinning Vinyl Disc / Music Note
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E293B),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _ActionButtonTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButtonTile({
    required this.icon,
    required this.color,
    required this.label,
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
          Icon(
            icon,
            color: color,
            size: 30,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Floating Glassmorphic Card (Creator + Caption + "Belanja dari Video" Sub-Card)
class _BottomShoppableCard extends StatelessWidget {
  final GageVideoItem item;
  final bool isDark;
  final bool isExpanded;
  final NumberFormat currencyFormatter;
  final VoidCallback onToggleExpand;
  final VoidCallback onOrderTap;

  const _BottomShoppableCard({
    required this.item,
    required this.isDark,
    required this.isExpanded,
    required this.currencyFormatter,
    required this.onToggleExpand,
    required this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FrostedGlassBox(
      borderRadius: BorderRadius.circular(22),
      sigma: 12,
      color: isDark
          ? Colors.black.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.88),
      borderColor: isDark ? Colors.white12 : Colors.white.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator Handle
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
              child: Row(
                children: [
                  Text(
                    item.creatorHandle,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (item.isCreatorVerified) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF38BDF8),
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Expandable Caption
            GestureDetector(
              onTap: onToggleExpand,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Text(
                  item.caption,
                  maxLines: isExpanded ? 5 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF334155),
                    fontSize: 11.8,
                    height: 1.35,
                  ),
                ),
              ),
            ),

            if (item.productId.isNotEmpty && item.productTitle.isNotEmpty) ...[
              const SizedBox(height: 8),

              // "Belanja dari Video" Sub-Card
              Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belanja dari Video',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Food Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Image.network(
                            item.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Product Title, Price, & Merchant Delivery Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currencyFormatter.format(item.productPrice),
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFFE52320),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(
                                      initialMerchantId: item.merchantId,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                '${item.merchantName} 🛵 ${item.deliveryEstimate}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.72)
                                      : const Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Yellow Pill CTA Button (#FFB703)
                      Material(
                        color: const Color(0xFFFFB703),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: onOrderTap,
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_bag_rounded,
                                  color: Color(0xFF0F172A),
                                  size: 15,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'PESAN',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ],
          ],
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
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFFB703) : const Color(0xFFE52320),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB703),
                    foregroundColor: const Color(0xFF0F172A),
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

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();

    final comment = GageVideoComment(
      username: '@pengguna_gage',
      text: text,
      timeAgo: 'Baru saja',
      likes: 1,
    );
    widget.onCommentAdded(comment);
    _commentCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.56,
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
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, idx) {
                        final c = widget.item.sampleComments[idx];
                        return Row(
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
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar tentang menu ini...',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.item.thumbnailUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.merchantName,
                        style: const TextStyle(
                          color: Color(0xFFFFB703),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.productTitle,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.productDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  vertical: 12,
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
            const SizedBox(height: 18),
            Row(
              children: [
                // Quantity Stepper
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
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
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.remove_rounded,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          size: 18,
                        ),
                        onPressed: _quantity > 1
                            ? () {
                                HapticFeedback.selectionClick();
                                setState(() => _quantity--);
                              }
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_quantity',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFFFFB703),
                          size: 18,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _quantity++);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // CTA Tambah ke Keranjang Kuning
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB703),
                        foregroundColor: const Color(0xFF0F172A),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                      label: Text(
                        'Pesan • ${widget.currencyFormatter.format(totalPrice)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      onPressed: () => widget.onConfirmAddToCart(
                        _quantity,
                        _noteCtrl.text.trim(),
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
