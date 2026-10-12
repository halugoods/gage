import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/food/presentation/tani_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';

import 'package:gage_app/features/babe/presentation/babe_screen.dart';

class ServiceGridClay extends StatelessWidget {
  final VoidCallback onFoodTap;

  const ServiceGridClay({
    super.key,
    required this.onFoodTap,
  });

  static final List<Map<String, dynamic>> services = [
    {
      'id': 'ride',
      'name': 'GAGE Ride',
      'icon': 'assets/icons/ic_ride.png',
      'desc': 'Antar jemput motor cepat & praktis',
    },
    {
      'id': 'car',
      'name': 'GAGE Car',
      'icon': 'assets/icons/ic_car.png',
      'desc': 'Mobil nyaman rombongan & keluarga',
    },
    {
      'id': 'food',
      'name': 'GAGE Food',
      'icon': 'assets/icons/ic_food.png',
      'desc': 'Pesan kuliner Dimsum & resto lokal',
    },
    {
      'id': 'shop',
      'name': 'GAGE Shop',
      'icon': 'assets/icons/ic_mart.png',
      'desc': 'Belanja sembako & kebutuhan harian',
    },
    {
      'id': 'send',
      'name': 'GAGE Send',
      'icon': 'assets/icons/ic_send.png',
      'desc': 'Kirim paket & barang dagangan kilat',
    },
    {
      'id': 'tani',
      'name': 'GAGE Tani',
      'icon': 'assets/icons/ic_tani.png',
      'desc': 'Pupuk, bibit, pakan & hasil panen warga',
    },
    {
      'id': 'babe',
      'name': 'GAGE BaBe',
      'icon': 'assets/icons/ic_babe.png',
      'desc': 'Lapak resmi jual beli barang bekas terkurasi GAGE',
    },
    {
      'id': 'cuan',
      'name': 'GAGE Cuan',
      'icon': 'assets/icons/ic_bonus.png',
      'desc': 'Affiliate TikTok komisi 10% & referral',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 0.0),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.90,
        ),
        itemBuilder: (context, index) {
          final item = services[index];

          return InkWell(
            onTap: () {
              final id = item['id'];
              if (id == 'food') {
                onFoodTap();
              } else if (id == 'ride') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const RideBookingScreen(initialTab: 'ride')),
                );
              } else if (id == 'car') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const RideBookingScreen(initialTab: 'car')),
                );
              } else if (id == 'send') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const SendBookingScreen()),
                );
              } else if (id == 'shop') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const ShopScreen()),
                );
              } else if (id == 'tani') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const TaniScreen()),
                );
              } else if (id == 'cuan') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const AffiliateHubScreen()),
                );
              } else if (id == 'babe') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const BabeScreen()),
                );
              } else {
                _showServiceInfo(context, item);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikon Organik 3D Clay (100% Transparan Murni Tanpa Card, Border, Maupun Background)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Image.asset(
                    item['icon'],
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, _, error) => Container(
                      decoration: const BoxDecoration(
                        color: GageTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delivery_dining, color: GageTheme.primary, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: GageTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  void _showServiceInfo(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset(item['icon'], fit: BoxFit.contain),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item['name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(item['desc'], style: const TextStyle(fontSize: 13, color: GageTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text('Buka ${item['name']}'),
            ),
          ],
        ),
      ),
    );
  }
}
