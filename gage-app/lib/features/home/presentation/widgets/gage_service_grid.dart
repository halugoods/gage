import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/food/presentation/farm_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';
import 'package:gage_app/features/running/presentation/pacu_screen.dart';
import 'package:gage_app/core/services/dynamic_asset_service.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

class GageServiceGrid extends StatelessWidget {
  final VoidCallback onFoodTap;

  const GageServiceGrid({
    super.key,
    required this.onFoodTap,
  });

  static final List<Map<String, dynamic>> services = [
    {
      'id': 'ride',
      'name': 'G-Ride',
      'icon': 'assets/icons/ic_ride.png',
      'desc': 'Antar jemput motor cepat & hemat se-Pracimantoro',
    },
    {
      'id': 'car',
      'name': 'G-Car',
      'icon': 'assets/icons/ic_car.png',
      'desc': 'Perjalanan nyaman mobil se-Pracimantoro',
    },
    {
      'id': 'food',
      'name': 'G-Food',
      'icon': 'assets/icons/ic_food.png',
      'desc': 'Pesan kuliner Dimsum & resto lokal',
    },
    {
      'id': 'shop',
      'name': 'G-Shop',
      'icon': 'assets/icons/ic_shop.png',
      'desc': 'Belanja sembako & kebutuhan harian',
    },
    {
      'id': 'send',
      'name': 'G-Send',
      'icon': 'assets/icons/ic_send.png',
      'desc': 'Kirim paket & barang dagangan kilat',
    },
    {
      'id': 'farm',
      'name': 'G-Farm',
      'icon': 'assets/icons/ic_farm.png',
      'desc': 'Kios pertanian & pakan peternakan',
    },
    {
      'id': 'cuan',
      'name': 'G-Cuan',
      'icon': 'assets/icons/ic_bonus.png',
      'desc': 'Bagikan kode referral & raih komisi 10%',
    },
    {
      'id': 'pacu',
      'name': 'G-Fit',
      'icon': 'assets/icons/ic_build.png',
      'desc': 'Tracking lari, olahraga & misi voucher berhadiah',
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final item = services[index];

          return InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
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
              } else if (id == 'farm') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const FarmScreen()),
                );
              } else if (id == 'cuan') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const AffiliateHubScreen()),
                );
              } else if (id == 'pacu') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const PacuScreen()),
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
                  child: DynamicAssetIcon(
                    slotKey: 'grid_menu_${item['id']}',
                    defaultAsset: item['icon'] as String,
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['name'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showServiceInfo(BuildContext context, Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    GageFloatingSheet.show(
      context: context,
      title: item['name'] as String,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DynamicAssetIcon(
                slotKey: 'sheet_info_${item['id']}',
                defaultAsset: item['icon'] as String,
                width: 48,
                height: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['desc'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
