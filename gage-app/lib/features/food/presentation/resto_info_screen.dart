import 'package:flutter/material.dart';
import '../../../../core/theme/gage_theme.dart';
import 'resto_reviews_screen.dart';

class RestoInfoScreen extends StatelessWidget {
  final String restoName;
  final String? restoImage;
  final String address;
  final String distance;
  final double rating;
  final String ratingCount;
  final String openHours;
  final String category;

  const RestoInfoScreen({
    super.key,
    required this.restoName,
    this.restoImage,
    this.address = 'Maguhan, Pracimantoro, Solo',
    this.distance = '8.56 km',
    this.rating = 4.1,
    this.ratingCount = '50+',
    this.openHours = '23:59',
    this.category = 'Bakmie, Jajanan, Minuman',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? GageTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Back Button + Title & Subtitle (Gambar 5)
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.black87),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48.0),
                        child: Text(
                          restoName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Section: Info resto (Gambar 5)
              const Text(
                'Info resto',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Card Info Resto (Gambar 5)
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Row: Alamat & Map Thumbnail (Gambar 5)
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 15, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$distance • 50-60 min',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Thumbnail Visual Google Maps (Gambar 5)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 76,
                              height: 76,
                              color: const Color(0xFFE8ECEF),
                              child: Stack(
                                children: [
                                  // Road grid texture
                                  Positioned(
                                    left: -10,
                                    top: 36,
                                    right: -10,
                                    child: Container(height: 10, color: const Color(0xFFCBD5E1)),
                                  ),
                                  Positioned(
                                    left: 32,
                                    top: -10,
                                    bottom: -10,
                                    child: Container(width: 8, color: const Color(0xFFCBD5E1)),
                                  ),
                                  // Red food pin
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: GageTheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black26, blurRadius: 4),
                                        ],
                                      ),
                                      child: const Icon(Icons.restaurant_rounded, size: 15, color: Colors.white),
                                    ),
                                  ),
                                  // Google logo text at bottom
                                  Positioned(
                                    left: 4,
                                    bottom: 3,
                                    child: Text(
                                      'Google',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: borderColor),

                    // Bottom Row: Jam Buka (Gambar 5)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 17, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Buka sampai $openHours',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Section: Ulasan dan rating (Gambar 5)
              const Text(
                'Ulasan dan rating',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Card Rating (Gambar 5)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Skor & Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.info_outline_rounded, size: 15, color: Colors.grey.shade500),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$ratingCount rating',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // 5 Bintang Oranye (Gambar 5)
                    Row(
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Icon(
                            index < rating.floor()
                                ? Icons.star_rounded
                                : (index < rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                            color: const Color(0xFFF97316), // Oranye Gojek
                            size: 22,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tombol [Lihat semua] (Gambar 5)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GageTheme.primary,
                    side: const BorderSide(color: GageTheme.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => RestoReviewsScreen(
                          restoName: restoName,
                          rating: rating,
                          ratingCount: ratingCount,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Lihat semua',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
