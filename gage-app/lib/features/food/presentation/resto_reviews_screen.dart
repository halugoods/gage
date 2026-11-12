import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';

class RestoReviewsScreen extends StatefulWidget {
  final String restoName;
  final double rating;
  final String ratingCount;
  final String domain;
  final String? merchantId;
  final String? merchantImage;

  const RestoReviewsScreen({
    super.key,
    required this.restoName,
    this.rating = 4.8,
    this.ratingCount = '50+',
    this.domain = 'food',
    this.merchantId,
    this.merchantImage,
  });

  @override
  State<RestoReviewsScreen> createState() => _RestoReviewsScreenState();
}

class _RestoReviewsScreenState extends State<RestoReviewsScreen> {
  int _selectedStarFilter = 0; // 0 = Semua, 5 = 5 star, dst
  bool _isLoading = true;
  late MerchantRatingSummary _summary;
  String? _effectiveMerchantImage;

  String get _normalizedDomain => widget.domain.trim().toLowerCase();

  String get _itemBadgePrefix {
    switch (_normalizedDomain) {
      case 'shop':
        return '🛒';
      case 'farm':
        return '🌱';
      case 'build':
        return '🧱';
      default:
        return '🍽️';
    }
  }

  String get _merchantNoun {
    switch (_normalizedDomain) {
      case 'shop':
        return 'toko';
      case 'farm':
        return 'kios';
      case 'build':
        return 'toko bangunan';
      default:
        return 'resto';
    }
  }

  @override
  void initState() {
    super.initState();
    _effectiveMerchantImage = widget.merchantImage;
    final initialSeeds = MerchantStorefrontService.seedReviewsForDomain(_normalizedDomain);
    if (initialSeeds.isEmpty) {
      _summary = const MerchantRatingSummary(averageRating: 0.0, totalReviews: 0, reviews: []);
    } else {
      final sum = initialSeeds.fold<int>(0, (acc, r) => acc + ((r['stars'] as int?) ?? 5));
      _summary = MerchantRatingSummary(
        averageRating: double.parse((sum / initialSeeds.length).toStringAsFixed(1)),
        totalReviews: initialSeeds.length,
        reviews: initialSeeds,
      );
    }
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final summaryFuture = MerchantStorefrontService.loadRatingSummary(
      merchantId: widget.merchantId,
      merchantName: widget.restoName,
      domain: _normalizedDomain,
    );
    final storefrontFuture = MerchantStorefrontService.loadStorefront(
      widget.merchantId,
      merchantName: widget.restoName,
    );
    final results = await Future.wait([summaryFuture, storefrontFuture]);
    final loadedSummary = results[0] as MerchantRatingSummary;
    final storefront = results[1] as MerchantStorefrontData?;
    if (!mounted) return;
    setState(() {
      _summary = loadedSummary;
      final storedLogo = storefront?.logoPhoto?.trim();
      if (storedLogo != null && storedLogo.isNotEmpty) {
        _effectiveMerchantImage = storedLogo;
      }
      _isLoading = false;
    });
  }

  void _onFilterChanged(int stars) {
    if (_selectedStarFilter == stars) return;
    setState(() {
      _selectedStarFilter = stars;
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  double _starFraction(int stars, List<Map<String, dynamic>> all) {
    if (all.isEmpty) return 0.0;
    final count = all.where((r) => r['stars'] == stars).length;
    return count / all.length;
  }

  Widget _buildMerchantReplyAvatar() {
    final imgPath = (_effectiveMerchantImage ?? '').trim();
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GageTheme.primary.withValues(alpha: 0.12),
        border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: ClipOval(
        child: imgPath.isNotEmpty
            ? StorefrontImage(
                path: imgPath,
                fit: BoxFit.cover,
                fallback: const Icon(Icons.storefront_rounded, size: 12, color: GageTheme.primary),
              )
            : const Icon(Icons.storefront_rounded, size: 12, color: GageTheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allReviews = _summary.reviews;
    final actualAvg = _summary.averageRating;
    final actualCountText = _summary.formattedCount;

    final filteredList = _selectedStarFilter == 0
        ? allReviews
        : allReviews.where((r) => r['stars'] == _selectedStarFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ulasan ${widget.restoName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        color: GageTheme.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // 1. Rating Summary Header (aktual dari ulasan pembeli)
            if (_isLoading)
              const GageSkeletonReviewSummary()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          actualAvg.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, height: 1.0),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < actualAvg.floor()
                                  ? Icons.star_rounded
                                  : (index < actualAvg ? Icons.star_half_rounded : Icons.star_outline_rounded),
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$actualCountText rating',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildRatingBar(5, _starFraction(5, allReviews), isDark),
                          _buildRatingBar(4, _starFraction(4, allReviews), isDark),
                          _buildRatingBar(3, _starFraction(3, allReviews), isDark),
                          _buildRatingBar(2, _starFraction(2, allReviews), isDark),
                          _buildRatingBar(1, _starFraction(1, allReviews), isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 2. Star Filter Chips
            if (_isLoading)
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 6,
                  itemBuilder: (ctx, idx) => const GageSkeletonCategoryPill(),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('Semua (${allReviews.length})', 0, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('5 ★', 5, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('4 ★', 4, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('3 ★', 3, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('2 ★', 2, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('1 ★', 1, isDark),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 3. List of Reviews
            if (_isLoading)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                itemBuilder: (ctx, idx) => const GageSkeletonReviewTile(),
              )
            else if (filteredList.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        allReviews.isEmpty
                            ? 'Belum ada ulasan pembeli untuk $_merchantNoun ini.'
                            : 'Belum ada ulasan untuk rating $_selectedStarFilter bintang.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredList.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 24),
                itemBuilder: (ctx, idx) {
                  final r = filteredList[idx];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: (r['avatarColor'] as Color?) ?? Colors.indigo,
                            child: Text(
                              (r['userAvatar'] ?? 'P').toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (r['userName'] ?? 'Pelanggan GAGE').toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: i < ((r['stars'] as int?) ?? 5) ? Colors.amber : Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      (r['date'] ?? '').toString(),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        (r['comment'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade200 : const Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                      if (r['orderedItems'] != null && (r['orderedItems'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: (r['orderedItems'] as List<String>).map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$_itemBadgePrefix $item',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (r['reply'] != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildMerchantReplyAvatar(),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Respon Penjual',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: GageTheme.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r['reply'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int star, double percent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              '$star',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int starValue, bool isDark) {
    final isSel = _selectedStarFilter == starValue;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _onFilterChanged(starValue);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? GageTheme.primary : (isDark ? Colors.grey.shade900 : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSel ? GageTheme.primary : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
            color: isSel ? Colors.white : (isDark ? Colors.white : GageTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}
