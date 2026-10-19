import 'package:flutter/material.dart';

/// Widget Shimmer Animation 60 FPS berkecepatan tinggi tanpa dependensi eksternal.
/// Menggunakan AnimationController native dan LinearGradient shader mask yang halus,
/// otomatis beradaptasi dengan Light Mode dan Dark Mode.
class GageShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const GageShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<GageShimmer> createState() => _GageShimmerState();
}

class _GageShimmerState extends State<GageShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBase = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final defaultHighlight = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    final base = widget.baseColor ?? defaultBase;
    final highlight = widget.highlightColor ?? defaultHighlight;

    return _GageShimmerScope(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [base, highlight, base],
                stops: const [0.0, 0.5, 1.0],
                transform: _SlidingGradientTransform(_controller.value),
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _GageShimmerScope extends InheritedWidget {
  const _GageShimmerScope({required super.child});

  @override
  bool updateShouldNotify(_GageShimmerScope oldWidget) => false;
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// 1. Primitive: Kotak Skeleton universal berujung tumpul
class GageSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GageSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );

    final hasParentShimmer = context.dependOnInheritedWidgetOfExactType<_GageShimmerScope>() != null;
    if (hasParentShimmer) {
      return box;
    }
    return GageShimmer(child: box);
  }
}

/// 2. Primitive: Lingkaran Skeleton (untuk avatar / icon button)
class GageSkeletonCircle extends StatelessWidget {
  final double size;

  const GageSkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
    );

    final hasParentShimmer = context.dependOnInheritedWidgetOfExactType<_GageShimmerScope>() != null;
    if (hasParentShimmer) {
      return circle;
    }
    return GageShimmer(child: circle);
  }
}

/// 3. Skeleton Menu Item Presisi 1-to-1 (Resto Detail Screen & Katalog Menu)
/// Mengikuti struktur nyata: Judul, 2 Baris Deskripsi, Harga, Foto Produk, dan Stepper Button [-] 0 [+]
class GageSkeletonMenuItem extends StatelessWidget {
  const GageSkeletonMenuItem({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KIRI: Judul Menu, Deskripsi 2 Baris, Harga
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GageSkeletonBox(width: 150, height: 16),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 4),
                  GageSkeletonBox(width: 140, height: 12),
                  SizedBox(height: 12),
                  GageSkeletonBox(width: 80, height: 16),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // KANAN: Foto Produk (86x86) + Stepper Button [-] 0 [+] Presisi
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const GageSkeletonBox(
                  width: 86,
                  height: 86,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                const SizedBox(height: 8),
                // Stepper Button [-] 0 [+] skeleton terstruktur
                Container(
                  width: 86,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 14, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                      GageSkeletonBox(width: 18, height: 14, borderRadius: BorderRadius.all(Radius.circular(3))),
                      GageSkeletonBox(width: 14, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                    ],
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

/// 3b. Skeleton Card Katalog Menu Merchant (dengan Foto, Judul, Deskripsi, Harga, Status & Switch)
class GageSkeletonMerchantMenuCard extends StatelessWidget {
  const GageSkeletonMerchantMenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GageShimmer(
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GageSkeletonBox(
                width: 58,
                height: 58,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GageSkeletonBox(width: 160, height: 15),
                    SizedBox(height: 5),
                    GageSkeletonBox(width: 120, height: 12),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        GageSkeletonBox(width: 80, height: 11),
                        SizedBox(width: 8),
                        GageSkeletonBox(width: 50, height: 12, borderRadius: BorderRadius.all(Radius.circular(4))),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              GageSkeletonBox(width: 44, height: 26, borderRadius: BorderRadius.all(Radius.circular(14))),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3c. Skeleton Card Item Barang Bekas (BaBe Screen & Detail)
class GageSkeletonBabeItemCard extends StatelessWidget {
  const GageSkeletonBabeItemCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GageSkeletonBox(width: 96, height: 96, borderRadius: BorderRadius.all(Radius.circular(12))),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GageSkeletonBox(width: double.infinity, height: 15),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: 90, height: 11),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      GageSkeletonBox(width: 55, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                      SizedBox(width: 6),
                      GageSkeletonBox(width: 65, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 80, height: 16),
                      GageSkeletonBox(width: 60, height: 26, borderRadius: BorderRadius.all(Radius.circular(8))),
                    ],
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

/// 4. Skeleton Card untuk daftar Resto / Toko Mitra
class GageSkeletonRestoCard extends StatelessWidget {
  const GageSkeletonRestoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            GageSkeletonBox(width: 80, height: 80, borderRadius: BorderRadius.all(Radius.circular(14))),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GageSkeletonBox(width: 160, height: 16),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: 100, height: 12),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      GageSkeletonBox(width: 48, height: 15, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(width: 6),
                      GageSkeletonBox(width: 55, height: 15, borderRadius: BorderRadius.all(Radius.circular(6))),
                    ],
                  ),
                  SizedBox(height: 8),
                  GageSkeletonBox(width: 110, height: 14, borderRadius: BorderRadius.all(Radius.circular(6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5. Skeleton Card untuk Grid Produk (Shop / Sembako / Tani / Lapak BaBe)
class GageSkeletonProductGridCard extends StatelessWidget {
  const GageSkeletonProductGridCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GageSkeletonBox(width: double.infinity, height: 110, borderRadius: BorderRadius.all(Radius.circular(12))),
            SizedBox(height: 10),
            GageSkeletonBox(width: 120, height: 14),
            SizedBox(height: 6),
            GageSkeletonBox(width: 75, height: 11),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GageSkeletonBox(width: 65, height: 16),
                GageSkeletonBox(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(8))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Alias kompatibilitas
typedef GageSkeletonProductCard = GageSkeletonProductGridCard;

/// 6. Skeleton Box untuk metrik/stat kartu Cuan & Ringkasan Performa
class GageSkeletonStatBox extends StatelessWidget {
  const GageSkeletonStatBox({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            GageSkeletonBox(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(10))),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GageSkeletonBox(width: 65, height: 10),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: 50, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 7. Skeleton Card Tiket Riwayat Pesanan (Orders Screen) - Presisi 1-to-1
class GageSkeletonOrderTicket extends StatelessWidget {
  const GageSkeletonOrderTicket({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Chip Invoice Unik + Badge Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                GageSkeletonBox(width: 120, height: 26, borderRadius: BorderRadius.all(Radius.circular(20))),
                GageSkeletonBox(width: 85, height: 22, borderRadius: BorderRadius.all(Radius.circular(20))),
              ],
            ),
            const SizedBox(height: 12),

            // Baris 2: Nama Resto / Merchant & Tanggal Transaksi
            const GageSkeletonBox(width: 180, height: 16),
            const SizedBox(height: 5),
            const GageSkeletonBox(width: 110, height: 11),
            const SizedBox(height: 12),

            // Baris 3: Gallery Thumbnail Foto Produk (54x54) & Ringkasan Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: const [
                    GageSkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(10))),
                    SizedBox(width: 6),
                    GageSkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(10))),
                  ],
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GageSkeletonBox(width: double.infinity, height: 13),
                      SizedBox(height: 4),
                      GageSkeletonBox(width: 90, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Baris 4: Total Belanja & Tombol Aksi ('Lacak Pesanan' / 'Beli Lagi')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GageSkeletonBox(width: 65, height: 11),
                    SizedBox(height: 4),
                    GageSkeletonBox(width: 100, height: 17),
                  ],
                ),
                GageSkeletonBox(width: 95, height: 34, borderRadius: BorderRadius.all(Radius.circular(10))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 8. Skeleton Card Tiket Dapur Merchant (Kitchen Order Ticket)
class GageSkeletonKitchenOrderCard extends StatelessWidget {
  const GageSkeletonKitchenOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GageSkeletonBox(width: 110, height: 16),
                GageSkeletonBox(width: 90, height: 22, borderRadius: BorderRadius.all(Radius.circular(6))),
              ],
            ),
            SizedBox(height: 12),
            GageSkeletonBox(width: 180, height: 13),
            SizedBox(height: 6),
            GageSkeletonBox(width: 140, height: 13),
            SizedBox(height: 6),
            GageSkeletonBox(width: 160, height: 13),
            SizedBox(height: 12),
            GageSkeletonBox(width: 120, height: 16),
            Divider(height: 20),
            GageSkeletonBox(width: double.infinity, height: 42, borderRadius: BorderRadius.all(Radius.circular(10))),
          ],
        ),
      ),
    );
  }
}

/// 9. Skeleton Kartu Dompet Floating Wallet (Home Screen)
class GageSkeletonWalletCard extends StatelessWidget {
  const GageSkeletonWalletCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            // Kiri: Saldo & Poin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GageSkeletonBox(width: 75, height: 13),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: 120, height: 20),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: 65, height: 11),
                ],
              ),
            ),
            SizedBox(width: 10),
            // Kanan: 4 Tombol Aksi Cepat
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniActionSkeleton(),
                SizedBox(width: 8),
                _MiniActionSkeleton(),
                SizedBox(width: 8),
                _MiniActionSkeleton(),
                SizedBox(width: 8),
                _MiniActionSkeleton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniActionSkeleton extends StatelessWidget {
  const _MiniActionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GageSkeletonCircle(size: 32),
        SizedBox(height: 4),
        GageSkeletonBox(width: 32, height: 9),
      ],
    );
  }
}

/// 10. Skeleton Banner Promo (16:9 Carousel)
class GageSkeletonBanner extends StatelessWidget {
  const GageSkeletonBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const GageSkeletonBox(
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );
  }
}

/// 11. Skeleton Service Grid 8/10 Layanan (Home Screen)
class GageSkeletonServiceGrid extends StatelessWidget {
  const GageSkeletonServiceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GageShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          children: List.generate(
            8,
            (index) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GageSkeletonCircle(size: 52),
                SizedBox(height: 6),
                GageSkeletonBox(width: 48, height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 12. Skeleton Card untuk Toko Mitra Belanja / Sembako / Tani / Ternak (Shop & Tani Screen)
class GageSkeletonStoreCard extends StatelessWidget {
  const GageSkeletonStoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GageSkeletonBox(width: 80, height: 80, borderRadius: BorderRadius.all(Radius.circular(14))),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 140, height: 15),
                      GageSkeletonBox(width: 24, height: 24, borderRadius: BorderRadius.all(Radius.circular(12))),
                    ],
                  ),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: 90, height: 11),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      GageSkeletonBox(width: 48, height: 16, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(width: 6),
                      GageSkeletonBox(width: 58, height: 16, borderRadius: BorderRadius.all(Radius.circular(6))),
                    ],
                  ),
                  SizedBox(height: 8),
                  GageSkeletonBox(width: 180, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 13. Skeleton Tile untuk Pencarian Alamat & Tempat (Location Picker & Ride Booking)
class GageSkeletonLocationTile extends StatelessWidget {
  const GageSkeletonLocationTile({super.key});

  @override
  Widget build(BuildContext context) {
    return GageShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const GageSkeletonCircle(size: 36),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GageSkeletonBox(width: 140, height: 14),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: 200, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GageSkeletonBox(
              width: 52,
              height: 22,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      ),
    );
  }
}

/// 14. Skeleton Tile Riwayat Transaksi Dompet GagePay (GagePay Screen)
class GageSkeletonTransactionTile extends StatelessWidget {
  const GageSkeletonTransactionTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            GageSkeletonCircle(size: 38),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GageSkeletonBox(width: 150, height: 14),
                  SizedBox(height: 5),
                  GageSkeletonBox(width: 110, height: 11),
                ],
              ),
            ),
            SizedBox(width: 10),
            GageSkeletonBox(width: 75, height: 16),
          ],
        ),
      ),
    );
  }
}

/// 15. Skeleton Card Kupon & Voucher Diskon (Voucher Selection & Promo Screen)
class GageSkeletonVoucherCard extends StatelessWidget {
  const GageSkeletonVoucherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            GageSkeletonBox(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(12))),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GageSkeletonBox(width: 60, height: 15, borderRadius: BorderRadius.all(Radius.circular(4))),
                      SizedBox(width: 6),
                      GageSkeletonBox(width: 70, height: 11),
                    ],
                  ),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: 160, height: 15),
                  SizedBox(height: 4),
                  GageSkeletonBox(width: 120, height: 11),
                ],
              ),
            ),
            SizedBox(width: 10),
            GageSkeletonBox(width: 60, height: 32, borderRadius: BorderRadius.all(Radius.circular(8))),
          ],
        ),
      ),
    );
  }
}

/// 16. Skeleton Pill Kategori Horizontal
class GageSkeletonCategoryPill extends StatelessWidget {
  const GageSkeletonCategoryPill({super.key});

  @override
  Widget build(BuildContext context) {
    return const GageShimmer(
      child: Padding(
        padding: EdgeInsets.only(right: 8),
        child: GageSkeletonBox(width: 80, height: 36, borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
    );
  }
}

/// 17. Skeleton Ulasan Review Pelanggan Resto / Toko
class GageSkeletonReviewTile extends StatelessWidget {
  const GageSkeletonReviewTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GageSkeletonCircle(size: 32),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GageSkeletonBox(width: 90, height: 13),
                    SizedBox(height: 4),
                    GageSkeletonBox(width: 60, height: 10),
                  ],
                ),
                Spacer(),
                GageSkeletonBox(width: 48, height: 14),
              ],
            ),
            SizedBox(height: 10),
            GageSkeletonBox(width: double.infinity, height: 12),
            SizedBox(height: 4),
            GageSkeletonBox(width: 180, height: 12),
          ],
        ),
      ),
    );
  }
}

/// 18. Skeleton Rating & Review Summary Header (Resto Reviews Screen)
class GageSkeletonReviewSummary extends StatelessWidget {
  const GageSkeletonReviewSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return GageShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Column(
              children: [
                GageSkeletonBox(width: 60, height: 42, borderRadius: BorderRadius.all(Radius.circular(8))),
                SizedBox(height: 8),
                Row(
                  children: [
                    GageSkeletonCircle(size: 14),
                    SizedBox(width: 3),
                    GageSkeletonCircle(size: 14),
                    SizedBox(width: 3),
                    GageSkeletonCircle(size: 14),
                    SizedBox(width: 3),
                    GageSkeletonCircle(size: 14),
                    SizedBox(width: 3),
                    GageSkeletonCircle(size: 14),
                  ],
                ),
                SizedBox(height: 6),
                GageSkeletonBox(width: 70, height: 11),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      children: [
                        const GageSkeletonBox(width: 14, height: 11),
                        const SizedBox(width: 6),
                        const GageSkeletonCircle(size: 10),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GageSkeletonBox(
                            width: double.infinity,
                            height: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 19. Skeleton Grid Kategori Kuliner (All Categories Screen)
class GageSkeletonCategoryGrid extends StatelessWidget {
  final int itemCount;
  const GageSkeletonCategoryGrid({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return GageShimmer(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 18,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (ctx, idx) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GageSkeletonCircle(size: 56),
            SizedBox(height: 8),
            GageSkeletonBox(width: 52, height: 11),
          ],
        ),
      ),
    );
  }
}

/// 20. Skeleton Halaman Checkout Perjalanan / Pengiriman (Ride & Send Checkout)
class GageSkeletonRideCheckout extends StatelessWidget {
  const GageSkeletonRideCheckout({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estimasi Waktu Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  GageSkeletonCircle(size: 38),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GageSkeletonBox(width: 140, height: 14),
                        SizedBox(height: 5),
                        GageSkeletonBox(width: 180, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Rute Jemput & Antar Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      GageSkeletonCircle(size: 14),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GageSkeletonBox(width: 100, height: 13),
                            SizedBox(height: 4),
                            GageSkeletonBox(width: double.infinity, height: 11),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      GageSkeletonCircle(size: 14),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GageSkeletonBox(width: 100, height: 13),
                            SizedBox(height: 4),
                            GageSkeletonBox(width: double.infinity, height: 11),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Pilihan Armada Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  GageSkeletonCircle(size: 42),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GageSkeletonBox(width: 120, height: 15),
                        SizedBox(height: 5),
                        GageSkeletonBox(width: 160, height: 11),
                      ],
                    ),
                  ),
                  GageSkeletonBox(width: 70, height: 18),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Rincian Biaya Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 90, height: 12),
                      GageSkeletonBox(width: 70, height: 12),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 110, height: 12),
                      GageSkeletonBox(width: 60, height: 12),
                    ],
                  ),
                  Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 80, height: 16),
                      GageSkeletonBox(width: 95, height: 20),
                    ],
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

/// 21. Skeleton Halaman Detail Pesanan (Order Detail Screen)
class GageSkeletonOrderDetail extends StatelessWidget {
  const GageSkeletonOrderDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice & Status Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 130, height: 16),
                      GageSkeletonBox(width: 80, height: 22, borderRadius: BorderRadius.all(Radius.circular(6))),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 100, height: 11),
                      GageSkeletonBox(width: 120, height: 11),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Timeline Stepper Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GageSkeletonCircle(size: 28),
                  GageSkeletonBox(width: 40, height: 3),
                  GageSkeletonCircle(size: 28),
                  GageSkeletonBox(width: 40, height: 3),
                  GageSkeletonCircle(size: 28),
                  GageSkeletonBox(width: 40, height: 3),
                  GageSkeletonCircle(size: 28),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Merchant / Toko Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  GageSkeletonCircle(size: 42),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GageSkeletonBox(width: 150, height: 15),
                        SizedBox(height: 5),
                        GageSkeletonBox(width: 200, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Rincian Menu Items Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 160, height: 13),
                      GageSkeletonBox(width: 65, height: 13),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 140, height: 13),
                      GageSkeletonBox(width: 55, height: 13),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Rincian Pembayaran Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 80, height: 12),
                      GageSkeletonBox(width: 70, height: 12),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 100, height: 12),
                      GageSkeletonBox(width: 55, height: 12),
                    ],
                  ),
                  Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 90, height: 16),
                      GageSkeletonBox(width: 100, height: 20),
                    ],
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

/// 22. Skeleton Header Restoran & Warung (Resto Detail Screen)
class GageSkeletonRestoHeader extends StatelessWidget {
  const GageSkeletonRestoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Foto Resto
          const GageSkeletonBox(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.zero,
          ),
          // Info Metadata Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const GageSkeletonBox(width: 180, height: 18),
                    Row(
                      children: const [
                        GageSkeletonCircle(size: 32),
                        SizedBox(width: 8),
                        GageSkeletonCircle(size: 32),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const GageSkeletonBox(width: 130, height: 12),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    GageSkeletonBox(width: 48, height: 16, borderRadius: BorderRadius.all(Radius.circular(6))),
                    SizedBox(width: 8),
                    GageSkeletonBox(width: 58, height: 16, borderRadius: BorderRadius.all(Radius.circular(6))),
                    SizedBox(width: 8),
                    GageSkeletonBox(width: 65, height: 16, borderRadius: BorderRadius.all(Radius.circular(6))),
                  ],
                ),
                const SizedBox(height: 12),
                const GageSkeletonBox(width: 170, height: 20, borderRadius: BorderRadius.all(Radius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 23. Skeleton Halaman Checkout Lengkap (Checkout Screen)
class GageSkeletonCheckout extends StatelessWidget {
  const GageSkeletonCheckout({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alamat Pengantaran Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GageSkeletonCircle(size: 28),
                      SizedBox(width: 10),
                      GageSkeletonBox(width: 130, height: 14),
                      Spacer(),
                      GageSkeletonBox(width: 48, height: 14),
                    ],
                  ),
                  SizedBox(height: 10),
                  GageSkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 4),
                  GageSkeletonBox(width: 180, height: 12),
                  SizedBox(height: 10),
                  GageSkeletonBox(width: double.infinity, height: 32, borderRadius: BorderRadius.all(Radius.circular(8))),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Daftar Item Pesanan Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 140, height: 15),
                      GageSkeletonBox(width: 60, height: 14),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: const [
                      GageSkeletonBox(width: 50, height: 50, borderRadius: BorderRadius.all(Radius.circular(10))),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GageSkeletonBox(width: 140, height: 14),
                            SizedBox(height: 4),
                            GageSkeletonBox(width: 90, height: 12),
                          ],
                        ),
                      ),
                      GageSkeletonBox(width: 65, height: 14),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      GageSkeletonBox(width: 50, height: 50, borderRadius: BorderRadius.all(Radius.circular(10))),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GageSkeletonBox(width: 120, height: 14),
                            SizedBox(height: 4),
                            GageSkeletonBox(width: 80, height: 12),
                          ],
                        ),
                      ),
                      GageSkeletonBox(width: 60, height: 14),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Voucher & Promo Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  GageSkeletonCircle(size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GageSkeletonBox(width: 130, height: 14),
                        SizedBox(height: 4),
                        GageSkeletonBox(width: 170, height: 11),
                      ],
                    ),
                  ),
                  GageSkeletonBox(width: 50, height: 26, borderRadius: BorderRadius.all(Radius.circular(8))),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Ringkasan Pembayaran Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 90, height: 12),
                      GageSkeletonBox(width: 70, height: 12),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 80, height: 12),
                      GageSkeletonBox(width: 55, height: 12),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 95, height: 12),
                      GageSkeletonBox(width: 50, height: 12),
                    ],
                  ),
                  Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 90, height: 16),
                      GageSkeletonBox(width: 100, height: 20),
                    ],
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

/// 24. Skeleton Halaman Profil Pengguna (Profile Screen)
class GageSkeletonProfile extends StatelessWidget {
  const GageSkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Box
            const GageSkeletonBox(width: double.infinity, height: 140, borderRadius: BorderRadius.zero),
            // User Info Floating Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      GageSkeletonCircle(size: 60),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GageSkeletonBox(width: 150, height: 16),
                            SizedBox(height: 6),
                            GageSkeletonBox(width: 120, height: 12),
                            SizedBox(height: 6),
                            GageSkeletonBox(width: 75, height: 16, borderRadius: BorderRadius.all(Radius.circular(6))),
                          ],
                        ),
                      ),
                      GageSkeletonCircle(size: 32),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const GageSkeletonBox(width: double.infinity, height: 38, borderRadius: BorderRadius.all(Radius.circular(10))),
                ],
              ),
            ),
            // Dompet Saldo Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GageSkeletonBox(width: 65, height: 11),
                      SizedBox(height: 5),
                      GageSkeletonBox(width: 110, height: 18),
                    ],
                  ),
                  Row(
                    children: [
                      GageSkeletonBox(width: 65, height: 32, borderRadius: BorderRadius.all(Radius.circular(8))),
                      SizedBox(width: 8),
                      GageSkeletonBox(width: 65, height: 32, borderRadius: BorderRadius.all(Radius.circular(8))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Menu Settings Tiles
            for (int i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      GageSkeletonCircle(size: 34),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GageSkeletonBox(width: 140, height: 14),
                            SizedBox(height: 4),
                            GageSkeletonBox(width: 90, height: 11),
                          ],
                        ),
                      ),
                      GageSkeletonBox(width: 16, height: 16, borderRadius: BorderRadius.all(Radius.circular(4))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 25. Skeleton Card Item Produk Tani & Pakan Ternak (Tani Screen & Ternak Screen)
class GageSkeletonTaniItem extends StatelessWidget {
  const GageSkeletonTaniItem({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kolom Kiri: Kategori Badge, Judul 2 Baris, Deskripsi 2 Baris, Harga
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  GageSkeletonBox(width: 80, height: 16, borderRadius: BorderRadius.all(Radius.circular(6))),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: double.infinity, height: 14),
                  SizedBox(height: 4),
                  GageSkeletonBox(width: 140, height: 14),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: double.infinity, height: 11),
                  SizedBox(height: 4),
                  GageSkeletonBox(width: 110, height: 11),
                  SizedBox(height: 10),
                  GageSkeletonBox(width: 90, height: 16),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Kolom Kanan: Foto 88x88 + Tombol Tambah/Stepper
            Column(
              children: const [
                GageSkeletonBox(width: 88, height: 88, borderRadius: BorderRadius.all(Radius.circular(12))),
                SizedBox(height: 8),
                GageSkeletonBox(width: 88, height: 32, borderRadius: BorderRadius.all(Radius.circular(10))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 26. Skeleton Barisan Chips Kategori Horizontal
class GageSkeletonCategoryPillsRow extends StatelessWidget {
  final int count;
  const GageSkeletonCategoryPillsRow({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return GageShimmer(
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: count,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (_, idx) => GageSkeletonBox(
            width: (idx % 2 == 0) ? 80 : 100,
            height: 34,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
    );
  }
}

/// 27. Skeleton Halaman Membership (Membership Screen)
class GageSkeletonMembership extends StatelessWidget {
  const GageSkeletonMembership({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // VIP Header Card
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
            ),
            const SizedBox(height: 16),
            // Duration selector pills
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                GageSkeletonBox(width: 80, height: 34, borderRadius: BorderRadius.all(Radius.circular(12))),
                SizedBox(width: 8),
                GageSkeletonBox(width: 80, height: 34, borderRadius: BorderRadius.all(Radius.circular(12))),
                SizedBox(width: 8),
                GageSkeletonBox(width: 80, height: 34, borderRadius: BorderRadius.all(Radius.circular(12))),
              ],
            ),
            const SizedBox(height: 16),
            // Tier Cards 1
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  GageSkeletonBox(width: 120, height: 18),
                  SizedBox(height: 8),
                  GageSkeletonBox(width: 160, height: 12),
                  SizedBox(height: 14),
                  GageSkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 6),
                  GageSkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 16),
                  GageSkeletonBox(width: double.infinity, height: 42, borderRadius: BorderRadius.all(Radius.circular(12))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 28. Skeleton Promo Voucher Card (Resto Detail Screen Carousel)
class GageSkeletonPromoVoucherCard extends StatelessWidget {
  const GageSkeletonPromoVoucherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        width: 240,
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            GageSkeletonBox(width: 38, height: 38, borderRadius: BorderRadius.all(Radius.circular(10))),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GageSkeletonBox(width: 120, height: 13),
                  SizedBox(height: 5),
                  GageSkeletonBox(width: 140, height: 10),
                ],
              ),
            ),
            SizedBox(width: 8),
            GageSkeletonBox(width: 32, height: 22, borderRadius: BorderRadius.all(Radius.circular(6))),
          ],
        ),
      ),
    );
  }
}

/// 29. Skeleton Kategori Melingkar Horizontal (Food Explore & Shop Screen)
class GageSkeletonCircularCategoriesRow extends StatelessWidget {
  final int count;
  const GageSkeletonCircularCategoriesRow({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return GageShimmer(
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: count,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (_, idx) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GageSkeletonCircle(size: 58),
              SizedBox(height: 6),
              GageSkeletonBox(width: 52, height: 11),
            ],
          ),
        ),
      ),
    );
  }
}

/// 30. Skeleton Top Bar Header Driver (Driver Screen)
class GageSkeletonDriverHeader extends StatelessWidget {
  const GageSkeletonDriverHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const GageShimmer(
      child: Row(
        children: [
          GageSkeletonCircle(size: 40),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GageSkeletonBox(width: 110, height: 14),
                SizedBox(height: 6),
                Row(
                  children: [
                    GageSkeletonBox(width: 58, height: 12),
                    SizedBox(width: 6),
                    GageSkeletonBox(width: 44, height: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 31. Skeleton Kartu Autobid (Driver Screen)
class GageSkeletonAutobidCard extends StatelessWidget {
  const GageSkeletonAutobidCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GageShimmer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            GageSkeletonCircle(size: 36),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GageSkeletonBox(width: 140, height: 14),
                  SizedBox(height: 4),
                  GageSkeletonBox(width: double.infinity, height: 11),
                ],
              ),
            ),
            SizedBox(width: 12),
            GageSkeletonBox(width: 44, height: 26, borderRadius: BorderRadius.all(Radius.circular(14))),
          ],
        ),
      ),
    );
  }
}

