import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/features/driver/presentation/driver_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_activity_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_earnings_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_chat_list_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_account_screen.dart';
import 'package:gage_app/features/driver/presentation/active_trip_screen.dart';
import 'package:gage_app/features/driver/presentation/widgets/incoming_offer_sheet.dart';
import 'package:gage_app/features/driver/presentation/widgets/driver_bottom_nav_bar.dart';

/// Workstation Kurir & Entrypoint Utama Mitra Pengemudi (com.gage.driver)
/// Unit: GAGE Pracimantoro
class DriverRootScreen extends StatefulWidget {
  final int initialIndex;

  const DriverRootScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DriverRootScreen> createState() => _DriverRootScreenState();
}

class _DriverRootScreenState extends State<DriverRootScreen> {
  late int _currentIndex;
  String? _lastAcceptedTripId;

  final List<Widget> _screens = const [
    DriverScreen(),
    DriverActivityScreen(),
    DriverEarningsScreen(),
    DriverChatListScreen(),
    DriverAccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleAcceptOffer(DriverOrderProvider orderProv) async {
    HapticFeedback.heavyImpact();
    final accepted = await orderProv.acceptIncomingOffer();
    if (!mounted) return;
    if (accepted && orderProv.activeTrip != null) {
      _lastAcceptedTripId = orderProv.activeTrip!.id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ActiveTripScreen(trip: orderProv.activeTrip!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<DriverOrderProvider>();

    // Deteksi jika orderan diterima via Autobid di latar belakang
    if (orderProv.activeTrip != null && orderProv.activeTrip!.id != _lastAcceptedTripId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastAcceptedTripId = orderProv.activeTrip!.id;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ActiveTripScreen(trip: orderProv.activeTrip!),
          ),
        );
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. TAMPILAN SCREEN SESUAI TAB AKTIF
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // 2. BANNER PERJALANAN AKTIF (JIKA SEDANG JALAN & BERADA DI TAB LAIN)
          if (orderProv.activeTrip != null && _currentIndex != 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 14,
              right: 14,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ActiveTripScreen(trip: orderProv.activeTrip!),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: GageTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pesanan Sedang Berlangsung',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            Text(
                              'Toko: ${orderProv.activeTrip!.storeName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BUKA PETA',
                          style: TextStyle(
                            color: GageTheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. RADAR TAWARAN PESANAN MASUK (GLOBAL INCOMING OFFER SHEET OVERLAY UNTUK TAB 1-4)
          if (orderProv.incomingOffer != null && _currentIndex != 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IncomingOfferSheet(
                offer: orderProv.incomingOffer!,
                countdown: orderProv.offerCountdown,
                onAccept: () => _handleAcceptOffer(orderProv),
                onDecline: () => orderProv.declineIncomingOffer(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: DriverBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabChanged,
      ),
    );
  }
}
