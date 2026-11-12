import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/routing/portal_routes.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';
import 'resto_reviews_screen.dart';

class RestoInfoScreen extends StatefulWidget {
  final String restoName;
  final String? restoImage;
  final String address;
  final String distance;
  final double rating;
  final String ratingCount;
  final String openHours;
  final String category;
  final String domain;
  final String? merchantId;
  final String? eta;
  final double? latitude;
  final double? longitude;
  final String? locationPhoto;

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
    this.domain = 'food',
    this.merchantId,
    this.eta,
    this.latitude,
    this.longitude,
    this.locationPhoto,
  });

  @override
  State<RestoInfoScreen> createState() => _RestoInfoScreenState();
}

class _RestoInfoScreenState extends State<RestoInfoScreen> {
  MerchantStorefrontData? _storefront;
  late MerchantRatingSummary _ratingSummary;

  String get _normalizedDomain => widget.domain.trim().toLowerCase();

  String get _infoSectionTitle {
    switch (_normalizedDomain) {
      case 'shop':
        return 'Info toko';
      case 'farm':
        return 'Info kios';
      case 'build':
        return 'Info toko bangunan';
      default:
        return 'Info resto';
    }
  }

  IconData get _pinIcon {
    switch (_normalizedDomain) {
      case 'shop':
        return Icons.storefront_rounded;
      case 'farm':
        return Icons.agriculture_rounded;
      case 'build':
        return Icons.construction_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  String get _resolvedEta => (widget.eta != null && widget.eta!.trim().isNotEmpty)
      ? widget.eta!.trim()
      : (_normalizedDomain == 'food' ? '25-35 min' : '15-25 min');

  String get _effectiveName {
    final s = _storefront?.name?.trim();
    return (s != null && s.isNotEmpty) ? s : widget.restoName;
  }

  String get _effectiveAddress {
    final s = _storefront?.address?.trim();
    return (s != null && s.isNotEmpty) ? s : widget.address;
  }

  String? get _effectiveProfileImage {
    final s = _storefront?.logoPhoto?.trim();
    if (s != null && s.isNotEmpty) return s;
    final r = widget.restoImage?.trim();
    return (r != null && r.isNotEmpty) ? r : null;
  }

  String? get _effectiveLocationPhoto {
    final s = _storefront?.locationPhoto?.trim();
    if (s != null && s.isNotEmpty) return s;
    final l = widget.locationPhoto?.trim();
    if (l != null && l.isNotEmpty) return l;
    return _effectiveProfileImage;
  }

  MerchantOperatingSchedule get _effectiveSchedule {
    if (_storefront?.schedule != null) return _storefront!.schedule!;
    return MerchantOperatingSchedule.fromFallbackOpenHours(widget.openHours);
  }

  LatLng get _resolvedLocation => MerchantStorefrontService.resolveCoordinate(
        merchantId: widget.merchantId,
        overrideLat: _storefront?.latitude,
        overrideLng: _storefront?.longitude,
        merchantLat: widget.latitude,
        merchantLng: widget.longitude,
      );

  @override
  void initState() {
    super.initState();
    final initialSeeds = MerchantStorefrontService.seedReviewsForDomain(_normalizedDomain);
    if (initialSeeds.isEmpty) {
      _ratingSummary = const MerchantRatingSummary(averageRating: 0.0, totalReviews: 0, reviews: []);
    } else {
      final sum = initialSeeds.fold<int>(0, (acc, r) => acc + ((r['stars'] as int?) ?? 5));
      _ratingSummary = MerchantRatingSummary(
        averageRating: double.parse((sum / initialSeeds.length).toStringAsFixed(1)),
        totalReviews: initialSeeds.length,
        reviews: initialSeeds,
      );
    }
    _loadDynamicStoreData();
  }

  Future<void> _loadDynamicStoreData() async {
    final storefrontFuture = MerchantStorefrontService.loadStorefront(
      widget.merchantId,
      merchantName: widget.restoName,
    );
    final ratingFuture = MerchantStorefrontService.loadRatingSummary(
      merchantId: widget.merchantId,
      merchantName: widget.restoName,
      domain: _normalizedDomain,
    );
    final results = await Future.wait([storefrontFuture, ratingFuture]);
    if (!mounted) return;
    setState(() {
      _storefront = results[0] as MerchantStorefrontData?;
      _ratingSummary = results[1] as MerchantRatingSummary;
    });
  }

  void _openReviews(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => RestoReviewsScreen(
          restoName: _effectiveName,
          rating: _ratingSummary.averageRating,
          ratingCount: _ratingSummary.formattedCount,
          domain: _normalizedDomain,
          merchantId: widget.merchantId,
          merchantImage: _effectiveProfileImage,
        ),
      ),
    ).then((_) => _loadDynamicStoreData());
  }

  void _openMerchantSchedulePortal(BuildContext context) {
    final materialApp = context.findAncestorWidgetOfExactType<MaterialApp>();
    final routes = materialApp?.routes;
    final args = {
      'merchantId': (widget.merchantId ?? '').trim().isNotEmpty
          ? widget.merchantId!.trim()
          : MerchantStorefrontService.defaultPortalMerchantId,
      'merchantName': _effectiveName,
    };

    if (routes != null && routes.containsKey(MerchantRoutes.profile)) {
      Navigator.pushNamed(context, MerchantRoutes.profile, arguments: args)
          .then((_) => _loadDynamicStoreData());
      return;
    }
    if (routes != null && routes.containsKey(MerchantRoutes.root)) {
      Navigator.pushNamed(context, MerchantRoutes.root, arguments: args)
          .then((_) => _loadDynamicStoreData());
      return;
    }
    GageToast.show(
      context,
      'Silakan atur jam operasional di Portal Merchant.',
      type: GageToastType.info,
    );
  }

  void _showScheduleBottomSheet(BuildContext context) {
    final schedule = _effectiveSchedule;
    final today = DateTime.now().weekday;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Jam Operasional (Senin - Minggu)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                schedule.infoSummary(),
                style: const TextStyle(fontSize: 12, color: GageTheme.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...MerchantOperatingSchedule.orderedWeekdays.map((dayInt) {
                final info = schedule.forWeekday(dayInt);
                final isToday = dayInt == today;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isToday
                        ? GageTheme.primary.withValues(alpha: 0.08)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday ? Border.all(color: GageTheme.primary.withValues(alpha: 0.35)) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            MerchantOperatingSchedule.weekdayLabel(dayInt),
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                              color: isToday ? GageTheme.primary : null,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 6),
                            const Text('(Hari ini)', style: TextStyle(fontSize: 11, color: GageTheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                      Text(
                        info.isOpen ? '${info.openTime} - ${info.closeTime} WIB' : 'Tutup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: info.isOpen ? (isDark ? Colors.white : Colors.black87) : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: const Text('Atur di Portal Merchant', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openMerchantSchedulePortal(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLocationPhotoDialog(BuildContext context) {
    final photo = _effectiveLocationPhoto;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: StorefrontImage(
                path: photo,
                fit: BoxFit.cover,
                fallback: Container(
                  color: Colors.grey.shade200,
                  child: Icon(_pinIcon, size: 52, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foto Lapak $_effectiveName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _effectiveAddress,
                          style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openExpandedMapModal(BuildContext context) {
    final target = _resolvedLocation;
    final profileImg = _effectiveProfileImage;
    final locPhoto = _effectiveLocationPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.82,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                child: Row(
                  children: [
                    const Icon(Icons.location_pin, color: GageTheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peta Lokasi $_effectiveName',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: target,
                    initialZoom: 17.0,
                    minZoom: 12.0,
                    maxZoom: 21.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
                      subdomains: const ['0', '1', '2', '3'],
                      tileDimension: 256,
                      maxZoom: 21.0,
                      userAgentPackageName: 'com.gagepracimantoro.customer',
                      fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: target,
                          width: 48,
                          height: 56,
                          alignment: Alignment.topCenter,
                          child: MerchantLocationPin(
                            imagePath: profileImg,
                            fallbackIcon: _pinIcon,
                            size: 46,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (locPhoto != null && locPhoto.isNotEmpty)
                      InkWell(
                        onTap: () => _openLocationPhotoDialog(ctx),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: StorefrontImage(
                                    path: locPhoto,
                                    fit: BoxFit.cover,
                                    fallback: Icon(_pinIcon, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Foto Lokasi / Lapak Merchant',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _effectiveAddress,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.zoom_in_rounded, color: GageTheme.primary),
                            ],
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Buka Rute di Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _openGoogleMaps(context, target),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? GageTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final displayRating = _ratingSummary.averageRating;
    final displayCount = _ratingSummary.formattedCount;
    final targetLocation = _resolvedLocation;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Back Button + Title & Subtitle
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
                        child: Icon(Icons.arrow_back_rounded, size: 20, color: primaryTextColor),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48.0),
                        child: Text(
                          _effectiveName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: primaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.category,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: mutedTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Section: Info merchant sesuai domain
              Text(
                _infoSectionTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),

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
                    // Top Row: Alamat & Real Interactive MiniMap (Pin profil merchant + klik untuk expand)
                    InkWell(
                      onTap: () => _openExpandedMapModal(context),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _effectiveAddress,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 15, color: mutedTextColor),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${widget.distance} • $_resolvedEta',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _openGoogleMaps(context, targetLocation),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.map_rounded, size: 13, color: Color(0xFF0284C7)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Buka di Google Maps ↗',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF0284C7),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            MiniLocationPreviewMap(
                              location: targetLocation,
                              width: 82,
                              height: 82,
                              borderRadius: 12,
                              zoom: 16.5,
                              markerImagePath: _effectiveProfileImage,
                              markerFallbackIcon: _pinIcon,
                              useMerchantPin: true,
                              onTap: () => _openExpandedMapModal(context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Divider(height: 1, color: borderColor),

                    // Middle Row: Jam Operasional (Dinamis + Rute ke Portal Merchant)
                    InkWell(
                      onTap: () => _showScheduleBottomSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded, size: 17, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _effectiveSchedule.infoSummary(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    'Lihat jadwal Senin - Minggu & kelola di Portal Merchant',
                                    style: TextStyle(fontSize: 11, color: GageTheme.primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),

                    Divider(height: 1, color: borderColor),

                    // Bottom Row: Foto lokasi merchant (tombol teks ringkas tanpa preview image)
                    InkWell(
                      onTap: () => _openLocationPhotoDialog(context),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 15, color: GageTheme.primary),
                            SizedBox(width: 6),
                            Text(
                              'Foto lokasi merchant ↗',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: GageTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Section: Ulasan dan rating
              Text(
                'Ulasan dan rating',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),

              // Card Rating (Klik seluruh kartu juga membuka ulasan & menampilkan rating aktual pembeli)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openReviews(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.info_outline_rounded, size: 15, color: Colors.grey.shade500),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$displayCount rating',
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(5, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1.5),
                              child: Icon(
                                index < displayRating.floor()
                                    ? Icons.star_rounded
                                    : (index < displayRating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                color: const Color(0xFFF97316),
                                size: 22,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol [Lihat semua]
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GageTheme.primary,
                    side: const BorderSide(color: GageTheme.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => _openReviews(context),
                  child: const Text(
                    'Lihat semua',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context, LatLng coords) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsUrl);
      }
    } catch (e) {
      if (context.mounted) {
        GageToast.show(context, 'Membuka Google Maps...', type: GageToastType.info);
      }
    }
  }
}
