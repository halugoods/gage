import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class FullScreenMapResult {
  final String title;
  final String fullAddress;
  final LatLng location;

  const FullScreenMapResult({
    required this.title,
    required this.fullAddress,
    required this.location,
  });
}

/// Layar peta full-screen standar GAGE dengan search bar lokasi di atas,
/// pin geser tengah, tombol GPS, dan kartu konfirmasi lokasi di bawah.
class FullScreenMapPicker extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;
  final String? initialTitle;
  final String? initialFullAddress;
  final String confirmLabel;

  const FullScreenMapPicker({
    super.key,
    this.title = 'Pilih Titik Lokasi',
    this.initialLocation,
    this.initialTitle,
    this.initialFullAddress,
    this.confirmLabel = 'Pakai Lokasi Ini',
  });

  static Future<FullScreenMapResult?> open(
    BuildContext context, {
    String title = 'Pilih Titik Lokasi',
    LatLng? initialLocation,
    String? initialTitle,
    String? initialFullAddress,
    String confirmLabel = 'Pakai Lokasi Ini',
  }) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push<FullScreenMapResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullScreenMapPicker(
          title: title,
          initialLocation: initialLocation,
          initialTitle: initialTitle,
          initialFullAddress: initialFullAddress,
          confirmLabel: confirmLabel,
        ),
      ),
    );
  }

  @override
  State<FullScreenMapPicker> createState() => _FullScreenMapPickerState();
}

class _FullScreenMapPickerState extends State<FullScreenMapPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late LatLng _center;
  String _detectedTitle = 'Mendeteksi lokasi...';
  String _detectedAddress = 'Mengambil alamat lengkap di sekitar pin...';
  bool _isGeocoding = false;
  bool _isSearching = false;
  bool _isAcquiringGps = false;
  List<OsmPlace> _searchResults = [];
  Timer? _geocodeDebounce;
  Timer? _searchDebounce;
  int _geocodeSeq = 0;

  @override
  void initState() {
    super.initState();
    _center = widget.initialLocation ?? LocationService.cachedOrFallback;
    if (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty) {
      _detectedTitle = widget.initialTitle!.trim();
    }
    if (widget.initialFullAddress != null && widget.initialFullAddress!.trim().isNotEmpty) {
      _detectedAddress = widget.initialFullAddress!.trim();
    } else {
      _detectedAddress = OsmGeocodingService.formatFullOfficialAddress(_center);
    }
    if (widget.initialTitle == null || widget.initialTitle!.trim().isEmpty) {
      _reverseGeocodeCenter(_center);
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _safeMove(LatLng target, [double zoom = 17.0]) {
    try {
      _mapController.move(target, zoom);
    } catch (_) {}
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _center = camera.center;
    _geocodeDebounce?.cancel();
    if (mounted) {
      setState(() => _isGeocoding = true);
    }
    _geocodeDebounce = Timer(const Duration(milliseconds: 380), () {
      _reverseGeocodeCenter(_center);
    });
  }

  Future<void> _reverseGeocodeCenter(LatLng point) async {
    final seq = ++_geocodeSeq;
    if (mounted) setState(() => _isGeocoding = true);
    try {
      final raw = await OsmGeocodingService.reverseGeocode(point);
      if (!mounted || seq != _geocodeSeq) return;
      final cleanRaw = raw.trim();
      final full = cleanRaw.isNotEmpty
          ? (cleanRaw.contains('Wonogiri') ? cleanRaw : '$cleanRaw, Wonogiri')
          : OsmGeocodingService.formatFullOfficialAddress(point);
      final title = raw.trim().isNotEmpty ? raw.split(',').first.trim() : full.split(',').first.trim();
      setState(() {
        _detectedTitle = title.isNotEmpty ? title : 'Titik Lokasi Terpilih';
        _detectedAddress = full;
        _isGeocoding = false;
      });
    } catch (_) {
      if (!mounted || seq != _geocodeSeq) return;
      setState(() {
        _detectedTitle = 'Titik Lokasi (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
        _detectedAddress = OsmGeocodingService.formatFullOfficialAddress(point);
        _isGeocoding = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 320), () async {
      final results = await OsmGeocodingService.searchPlaces(
        trimmed,
        proximityLocation: _center,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  void _selectSearchPlace(OsmPlace place) {
    HapticFeedback.selectionClick();
    _searchFocusNode.unfocus();
    setState(() {
      _center = place.location;
      _detectedTitle = place.title;
      _detectedAddress = place.displayName.isNotEmpty
          ? place.displayName
          : OsmGeocodingService.formatFullOfficialAddress(place.location);
      _searchResults = [];
      _searchCtrl.clear();
      _isGeocoding = false;
    });
    _safeMove(place.location, 17.5);
  }

  Future<void> _recenterGps() async {
    HapticFeedback.selectionClick();
    setState(() => _isAcquiringGps = true);
    try {
      final gps = await LocationService.getCurrentLocation(forceFresh: true);
      if (!mounted) return;
      setState(() {
        _center = gps;
        _isAcquiringGps = false;
      });
      _safeMove(gps, 17.5);
      await _reverseGeocodeCenter(gps);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAcquiringGps = false);
      GageToast.show(context, 'Tidak dapat menjangkau GPS, geser pin secara manual', type: GageToastType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : Colors.white,
      body: Stack(
        children: [
          // 1. Full-Screen Retina Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 17.0,
              minZoom: 10.0,
              maxZoom: 21.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                tileDimension: 256,
                userAgentPackageName: 'com.gage.customer',
                maxZoom: 21.0,
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
            ],
          ),

          // 2. Fixed Center Location Pin
          Center(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 42),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Text(
                        'Geser peta untuk menentukan titik',
                        style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 46,
                      color: GageTheme.primary,
                    ),
                    Container(
                      width: 10,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Top Search Bar & Results Dropdown
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: textPrimary, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Cari jalan, tempat, atau patokan di ${widget.title.toLowerCase()}...',
                            hintStyle: TextStyle(fontSize: 12.5, color: isDark ? Colors.white38 : Colors.grey.shade500),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                          ),
                        )
                      else if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: Icon(Icons.search_rounded, color: GageTheme.primary, size: 20),
                        ),
                    ],
                  ),
                ),

                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                      itemBuilder: (ctx, i) {
                        final place = _searchResults[i];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: GageTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 17),
                          ),
                          title: Text(
                            place.title,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            place.displayName,
                            style: TextStyle(fontSize: 11, color: textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: place.distanceText.isNotEmpty
                              ? Text(place.distanceText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary))
                              : null,
                          onTap: () => _selectSearchPlace(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 4. Floating GPS Recenter Button
          Positioned(
            right: 16,
            bottom: 204,
            child: FloatingActionButton.small(
              heroTag: 'fullscreen_map_gps_fab',
              backgroundColor: cardBg,
              foregroundColor: GageTheme.primary,
              elevation: 4,
              onPressed: _isAcquiringGps ? null : _recenterGps,
              child: _isAcquiringGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                    )
                  : const Icon(Icons.my_location_rounded, size: 22),
            ),
          ),

          // 5. Bottom Address Confirmation Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pin_drop_rounded, color: GageTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _detectedTitle,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_isGeocoding)
                                    const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _detectedAddress,
                                style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(
                            context,
                            FullScreenMapResult(
                              title: _detectedTitle,
                              fullAddress: _detectedAddress,
                              location: _center,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          widget.confirmLabel,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
