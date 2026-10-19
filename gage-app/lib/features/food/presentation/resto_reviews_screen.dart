import 'package:flutter/material.dart';
import '../../../../core/theme/gage_theme.dart';
import '../../../../shared/widgets/gage_shimmer.dart';

class RestoReviewsScreen extends StatefulWidget {
  final String restoName;
  final double rating;
  final String ratingCount;

  const RestoReviewsScreen({
    super.key,
    required this.restoName,
    this.rating = 4.8,
    this.ratingCount = '50+',
  });

  @override
  State<RestoReviewsScreen> createState() => _RestoReviewsScreenState();
}

class _RestoReviewsScreenState extends State<RestoReviewsScreen> {
  int _selectedStarFilter = 0; // 0 = Semua, 5 = 5 star, dst
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      setState(() => _isLoading = false);
    }
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

  final List<Map<String, dynamic>> _mockReviews = [
    {
      'userName': 'Dimas Prasetyo',
      'userAvatar': 'D',
      'avatarColor': Colors.indigo,
      'date': 'Kemarin',
      'stars': 5,
      'comment': 'Porsi mantap, sambalnya nendang pol! Pengemasan rapi dan masih hangat saat sampai. Recommended!',
      'orderedItems': ['Paket Nasi Ayam Geprek', 'Es Teh Jumbo'],
      'reply': 'Terima kasih banyak kak Dimas sudah berlangganan! Ditunggu orderan selanjutnya ya 😊',
    },
    {
      'userName': 'Siti Nurhaliza',
      'userAvatar': 'S',
      'avatarColor': Colors.teal,
      'date': '2 hari lalu',
      'stars': 5,
      'comment': 'Rasanya enak konsisten dari dulu. Pilihan level pedasnya pas sesuai request catatan.',
      'orderedItems': ['Nasi Goreng Spesial Telur Ceplok'],
      'reply': null,
    },
    {
      'userName': 'Budi Santoso',
      'userAvatar': 'B',
      'avatarColor': Colors.deepOrange,
      'date': '4 hari lalu',
      'stars': 4,
      'comment': 'Enak dan porsi cukup kenyang. Cuma waktu penyiapan agak sedikit lama mungkin karena jam makan siang ramai.',
      'orderedItems': ['Mie Goreng Jawa Mas Bro', 'Kerupuk Kaleng'],
      'reply': 'Mohon maaf atas waktu tunggunya kak Budi saat jam sibuk. Tim dapur kami terus tingkatkan kecepatannya 🙏',
    },
    {
      'userName': 'Anisa Rahmawati',
      'userAvatar': 'A',
      'avatarColor': Colors.purple,
      'date': '1 minggu lalu',
      'stars': 5,
      'comment': 'Packaging ramah lingkungan, ada segel higienisnya. Makanan bersih dan fresh!',
      'orderedItems': ['Ayam Bakar Madu', 'Nasi Uduk Gurih'],
      'reply': null,
    },
    {
      'userName': 'Rendra Kurnia',
      'userAvatar': 'R',
      'avatarColor': Colors.blueGrey,
      'date': '2 minggu lalu',
      'stars': 3,
      'comment': 'Rasa oke standar, cuma sambalnya kurang banyak menurut saya. Semoga bisa ditambah opsi extra sambal.',
      'orderedItems': ['Bebek Goreng Crispy'],
      'reply': 'Siap kak Rendra, saran sudah kami catat untuk sediakan opsi extra sambal di menu. Terima kasih masukkannya!',
    },
    {
      'userName': 'Fitri Handayani',
      'userAvatar': 'F',
      'avatarColor': Colors.pink,
      'date': '3 minggu lalu',
      'stars': 5,
      'comment': 'Langganan keluarga kalau lagi mager masak. Semua menu enak gak ada yang gagal!',
      'orderedItems': ['Paket Family 4 Orang', 'Tahu Tempe Goreng'],
      'reply': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _selectedStarFilter == 0
        ? _mockReviews
        : _mockReviews.where((r) => r['stars'] == _selectedStarFilter).toList();

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
            // 1. Rating Summary Header
            if (_isLoading)
              const GageSkeletonReviewSummary()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Big score
                    Column(
                      children: [
                        Text(
                          widget.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, height: 1.0),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(
                            5,
                            (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.ratingCount} rating',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Breakdown progress bars
                    Expanded(
                      child: Column(
                        children: [
                          _buildRatingBar(5, 0.85, isDark),
                          _buildRatingBar(4, 0.10, isDark),
                          _buildRatingBar(3, 0.03, isDark),
                          _buildRatingBar(2, 0.01, isDark),
                          _buildRatingBar(1, 0.01, isDark),
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
                    _buildFilterChip('Semua (${_mockReviews.length})', 0, isDark),
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

            // 3. List of Reviews (Skeleton Shimmer saat loading)
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
                        'Belum ada ulasan untuk rating $_selectedStarFilter bintang.',
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
                          backgroundColor: r['avatarColor'] as Color,
                          child: Text(
                            r['userAvatar'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['userName'] as String,
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
                                        color: i < (r['stars'] as int) ? Colors.amber : Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    r['date'] as String,
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
                      r['comment'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade200 : const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                    if (r['orderedItems'] != null) ...[
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
                              '🍽️ $item',
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
                                const Icon(Icons.storefront_rounded, size: 14, color: GageTheme.primary),
                                const SizedBox(width: 5),
                                const Text(
                                  'Respon Penjual',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: GageTheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r['reply'] as String,
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
      onTap: () => _onFilterChanged(starValue),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? GageTheme.primary : (isDark ? Colors.grey.shade900 : Colors.white),
          borderRadius: BorderRadius.circular(20),
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
