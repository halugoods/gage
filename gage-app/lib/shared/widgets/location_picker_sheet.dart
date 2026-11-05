import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/core/services/user_address_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

/// Sheet terpadu pemilihan titik lokasi untuk seluruh layanan Gage (Ride, Car, Food, Shop, Send).
class LocationPickerSheet extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;
  final Function(String title, String fullAddress, LatLng latLng) onSelected;
  final bool showMiniMap;
  final bool autoFocusSearch;

  const LocationPickerSheet({
    super.key,
    required this.title,
    this.initialLocation,
    required this.onSelected,
    this.showMiniMap = true,
    this.autoFocusSearch = false,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Pilih Lokasi',
    LatLng? initialLocation,
    required Function(String title, String fullAddress, LatLng latLng) onSelected,
    bool showMiniMap = true,
    bool autoFocusSearch = false,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: LocationPickerSheet(
              title: title,
              initialLocation: initialLocation,
              onSelected: onSelected,
              showMiniMap: showMiniMap,
              autoFocusSearch: autoFocusSearch,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchFilter = '';
  List<OsmPlace> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  String _favoriteCategory = 'personal'; // 'personal' or 'business'
  List<UserSavedAddress> _favorites = [];
  List<UserSavedAddress> _recents = [];
  bool _isLoadingAddresses = true;
  bool _isAcquiringGps = false;
  bool _hasPinMoved = false;

  // State Accordion Tambah Alamat Baru & Mini Preview Map
  bool _isAddingNewAddress = false;
  final TextEditingController _newAddrNameCtrl = TextEditingController();
  final TextEditingController _newAddrNotesCtrl = TextEditingController();
  final TextEditingController _newAddrSearchCtrl = TextEditingController();
  late LatLng _activePreviewLocation;
  String _activePreviewTitle = 'Titik Lokasi Pengantaran';
  late LatLng _selectedPin;
  String _detectedAddr = 'Pracimantoro, Wonogiri';
  String _detectedFullAddr = 'Kec. Pracimantoro, Kabupaten Wonogiri, Jawa Tengah';
  final MapController _miniMapController = MapController();
  final MapController _accordionMapController = MapController();

  @override
  void initState() {
    super.initState();
    _activePreviewLocation = widget.initialLocation ?? const LatLng(-8.05517, 110.80889);
    _selectedPin = _activePreviewLocation;
    _loadAddressData();
    _initPreviewAddress();
    if (widget.initialLocation == null) {
      _acquireDefaultGps();
    }
  }

  Future<void> _acquireDefaultGps() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _activePreviewLocation = pos;
        _selectedPin = pos;
      });
      _miniMapController.move(pos, 16.5);
      _initPreviewAddress();
    } catch (_) {}
  }

  void _initPreviewAddress() async {
    try {
      final name = await OsmGeocodingService.reverseGeocode(_activePreviewLocation);
      final full = OsmGeocodingService.formatFullOfficialAddress(_activePreviewLocation);
      if (mounted) {
        setState(() {
          _activePreviewTitle = name;
          _detectedAddr = name;
          _detectedFullAddr = full;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAddressData() async {
    final favs = await UserAddressService.getFavorites();
    final recs = await UserAddressService.getRecents();
    if (mounted) {
      setState(() {
        _favorites = favs;
        _recents = recs;
        _isLoadingAddresses = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    final clean = val.trim();
    setState(() => _searchFilter = clean);

    if (clean.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 320), () async {
      final results = await OsmGeocodingService.searchPlaces(
        clean,
        proximityLocation: widget.initialLocation,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _newAddrNameCtrl.dispose();
    _newAddrNotesCtrl.dispose();
    _newAddrSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectCurrentGps() async {
    setState(() => _isAcquiringGps = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _isAcquiringGps = false);
        GageToast.show(
          context,
          'Layanan GPS mati. Harap nyalakan GPS pada pengaturan HP Anda.',
          type: GageToastType.warning,
        );
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() => _isAcquiringGps = false);
          GageToast.show(
            context,
            'Izin akses lokasi ditolak. Aktifkan izin lokasi untuk GAGE.',
            type: GageToastType.error,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _isAcquiringGps = false);
        GageToast.show(
          context,
          'Izin lokasi diblokir permanen. Harap izinkan di pengaturan aplikasi.',
          type: GageToastType.error,
        );
        await Geolocator.openAppSettings();
        return;
      }

      // Membaca posisi GPS riil langsung dari hardware perangkat
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final gps = LatLng(position.latitude, position.longitude);
      final addr = await OsmGeocodingService.reverseGeocode(gps);
      final fullAddr = OsmGeocodingService.formatFullOfficialAddress(gps);

      await UserAddressService.addRecent(UserSavedAddress(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
        name: addr,
        address: fullAddr,
        category: 'personal',
        latitude: gps.latitude,
        longitude: gps.longitude,
      ));

      if (!mounted) return;
      setState(() {
        _activePreviewLocation = gps;
        _selectedPin = gps;
        _activePreviewTitle = addr;
        _detectedAddr = addr;
        _detectedFullAddr = fullAddr;
        _hasPinMoved = true;
        _isAcquiringGps = false;
      });
      _miniMapController.move(gps, 16.5);
      GageToast.show(
        context,
        'Peta diarahkan ke lokasi GPS saat ini',
        type: GageToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAcquiringGps = false);
      GageToast.show(
        context,
        'Sensor GPS sibuk atau sinyal lemah. Silakan coba lagi atau pilih lewat peta.',
        type: GageToastType.error,
      );
    }
  }

  void _openMapPicker() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RetinaMapPickerModal(
        initialLocation: widget.initialLocation,
        onConfirmed: (title, fullAddr, latLng) async {
          await UserAddressService.addRecent(UserSavedAddress(
            id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
            name: title,
            address: fullAddr,
            category: 'personal',
            latitude: latLng.latitude,
            longitude: latLng.longitude,
          ));
          widget.onSelected(title, fullAddr, latLng);
        },
      ),
    );
  }

  Future<void> _acquireGpsForNewAddress() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      _updateSelectedPin(latLng);
      _accordionMapController.move(latLng, 17.0);
      if (mounted) {
        GageToast.show(context, 'Titik GPS berhasil diarahkan', type: GageToastType.success);
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Gagal mendeteksi sinyal GPS', type: GageToastType.warning);
      }
    }
  }

  void _openMapPickerForNewAddress() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RetinaMapPickerModal(
        initialLocation: _selectedPin,
        onConfirmed: (title, fullAddr, latLng) {
          _updateSelectedPin(latLng, title: title, fullAddr: fullAddr);
          _accordionMapController.move(latLng, 17.0);
        },
      ),
    );
  }

  void _updateSelectedPin(LatLng pin, {String? title, String? fullAddr}) async {
    setState(() {
      _selectedPin = pin;
      if (title != null) _detectedAddr = title;
      if (fullAddr != null) _detectedFullAddr = fullAddr;
    });

    if (title == null || fullAddr == null) {
      final name = await OsmGeocodingService.reverseGeocode(pin);
      final full = OsmGeocodingService.formatFullOfficialAddress(pin);
      if (mounted) {
        setState(() {
          _detectedAddr = name;
          _detectedFullAddr = full;
        });
      }
    }
  }

  Future<void> _saveNewAddress() async {
    final label = _newAddrNameCtrl.text.trim();
    if (label.isEmpty) {
      GageToast.show(context, 'Silakan masukkan nama alamat (misal: Rumah / Toko)', type: GageToastType.warning);
      return;
    }

    final newAddr = UserSavedAddress(
      id: 'fav_${DateTime.now().millisecondsSinceEpoch}',
      name: label,
      address: _detectedAddr,
      category: _favoriteCategory,
      latitude: _selectedPin.latitude,
      longitude: _selectedPin.longitude,
      notes: _newAddrNotesCtrl.text.trim().isEmpty ? null : _newAddrNotesCtrl.text.trim(),
    );

    await UserAddressService.saveFavorite(newAddr);
    if (!mounted) return;

    setState(() {
      _isAddingNewAddress = false;
      _newAddrNameCtrl.clear();
      _newAddrNotesCtrl.clear();
      _newAddrSearchCtrl.clear();
      _activePreviewLocation = _selectedPin;
      _activePreviewTitle = label;
    });

    _miniMapController.move(_selectedPin, 16.5);
    _loadAddressData();
    GageToast.show(context, 'Alamat $label berhasil disimpan ke cloud', type: GageToastType.success);
  }

  Widget _buildMiniMapWidget({
    required LatLng center,
    required VoidCallback onExpand,
    required VoidCallback onRecenter,
    required String addressLabel,
    required String fullAddressLabel,
    required MapController mapController,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture) {
                    _updateSelectedPin(pos.center);
                    if (!_hasPinMoved) {
                      setState(() => _hasPinMoved = true);
                    }
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
                  subdomains: const ['0', '1', '2', '3'],
                  tileDimension: 256,
                  maxZoom: 21.0,
                  userAgentPackageName: 'com.gage.customer',
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
              ],
            ),
            // Center Pin Marker
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: GageTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                    ),
                    Container(width: 3.5, height: 10, color: GageTheme.primary),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
            ),
            // Action Buttons on Top Right: Pusatkan GPS & Fullscreen Expand
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Pusatkan di Titik Lokasi Saat Ini
                  InkWell(
                    onTap: onRecenter,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.my_location_rounded, size: 18, color: GageTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Expand Fullscreen
                  InkWell(
                    onTap: onExpand,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Icon(Icons.fullscreen_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          // Address Chip at Bottom (2-line with coordinates & optional 'Pakai Lokasi Ini')
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pin_drop_rounded, size: 14, color: GageTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          addressLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          fullAddressLabel.isNotEmpty
                              ? fullAddressLabel
                              : '${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_hasPinMoved) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setState(() => _hasPinMoved = false);
                        widget.onSelected(addressLabel, fullAddressLabel, center);
                        GageToast.show(context, 'Titik lokasi berhasil dikunci', type: GageToastType.success);
                      },
                      child: const Text('Pakai Lokasi Ini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAddAddressAccordion(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: GageTheme.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_add_rounded, color: GageTheme.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Tambah Alamat ${_favoriteCategory == "personal" ? "Personal" : "Bisnis"} Baru',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Lokasi / Alamat Cepat
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: GageTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _newAddrSearchCtrl,
                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'Cari alamat atau ketik jalan...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (query) async {
                      if (query.trim().length >= 2) {
                        final results = await OsmGeocodingService.searchPlaces(query.trim(), proximityLocation: _selectedPin);
                        if (results.isNotEmpty) {
                          final top = results.first;
                          _updateSelectedPin(top.location, title: top.title, fullAddr: top.displayName);
                          _accordionMapController.move(top.location, 17.0);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2 Quick Chips: Lokasi Saat Ini & Pilih Lewat Peta
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _acquireGpsForNewAddress,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.my_location_rounded, size: 14, color: GageTheme.primary),
                        SizedBox(width: 4),
                        Text('Lokasi Saat Ini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _openMapPickerForNewAddress,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 14, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text('Pilih Lewat Peta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Text Field: Nama Alamat (Rumah, Kos, Kantor)
          TextField(
            controller: _newAddrNameCtrl,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Nama Alamat',
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              hintText: _favoriteCategory == 'personal' ? 'Contoh: Rumah, Kos, Rumah Ortu' : 'Contoh: Toko Berkah, Kantor GAGE',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Text Field: Patokan Pengantaran
          TextField(
            controller: _newAddrNotesCtrl,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Patokan / Catatan Pengantaran (Opsional)',
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              hintText: 'Contoh: Pagar hitam depan masjid',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Mini Preview Map Realtime Pin dengan Tombol Expand Fullscreen & Pusatkan GPS
          _buildMiniMapWidget(
            center: _selectedPin,
            onExpand: _openMapPickerForNewAddress,
            onRecenter: _acquireGpsForNewAddress,
            addressLabel: _detectedAddr,
            fullAddressLabel: _detectedFullAddr,
            mapController: _accordionMapController,
          ),
          const SizedBox(height: 12),

          // Tombol Aksi: Buang & Simpan
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isAddingNewAddress = false;
                      _newAddrNameCtrl.clear();
                      _newAddrNotesCtrl.clear();
                      _newAddrSearchCtrl.clear();
                    });
                  },
                  child: const Text('Buang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _saveNewAddress,
                  child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFavs = _favorites.where((f) => f.category == _favoriteCategory).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasAddresses = filteredFavs.isNotEmpty || _recents.isNotEmpty;
    final isSearching = _searchFilter.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom > 0 ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar: Title + Circular Close Button
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Realtime Pin Mini Preview Map Terkini (Disembunyikan saat tambah alamat baru agar lapang)
          if (!_isAddingNewAddress && widget.showMiniMap) ...[
            _buildMiniMapWidget(
              center: _activePreviewLocation,
              onExpand: _openMapPicker,
              onRecenter: _selectCurrentGps,
              addressLabel: _activePreviewTitle,
              fullAddressLabel: _detectedFullAddr,
              mapController: _miniMapController,
            ),
            const SizedBox(height: 12),
          ],

          if (!_isAddingNewAddress) ...[
            // 1. Search Box (Full Rounded 24px)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: GageTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: widget.autoFocusSearch,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Ketik nama jalan, gedung, atau area...',
                        hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchFilter.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchFilter = '';
                          _searchResults = [];
                        });
                      },
                      child: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : Colors.black54, size: 18),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. Quick Actions: 2 Tombol Full Rounded Bersebelahan
            Row(
              children: [
                // Tombol KIRI: Lokasi Saat Ini
                Expanded(
                  child: InkWell(
                    onTap: _isAcquiringGps ? null : _selectCurrentGps,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isAcquiringGps
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                                )
                              : const Icon(Icons.my_location_rounded, size: 16, color: GageTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            _isAcquiringGps ? 'Mendeteksi...' : 'Lokasi Saat Ini',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: GageTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol KANAN: Pilih Titik Lewat Peta
                Expanded(
                  child: InkWell(
                    onTap: _openMapPicker,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_rounded, size: 16, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text(
                            'Pilih Lewat Peta',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // 3. Body: Search Results OR Favorites + Recents (Expanded, Fluid Space)
          if (isSearching)
            Expanded(
              child: _buildSearchResults(),
            )
          else if (hasAddresses || _isAddingNewAddress)
            Expanded(
              child: _buildFavoritesAndRecents(filteredFavs),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Belum ada alamat tersimpan',
                    style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isAddingNewAddress = true);
                    },
                    icon: const Icon(Icons.add_rounded, size: 15, color: GageTheme.primary),
                    label: const Text(
                      'Simpan Alamat',
                      style: TextStyle(fontSize: 11.5, color: GageTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (ctx, idx) => const GageSkeletonLocationTile(),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 40, color: Colors.black26),
              SizedBox(height: 10),
              Text('Lokasi tidak ditemukan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              SizedBox(height: 4),
              Text('Coba ketik nama lokasi atau fasilitas publik', style: TextStyle(fontSize: 12, color: Colors.black38)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (ctx, i) {
        final p = _searchResults[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFFFEBEE),
            radius: 18,
            child: const Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 20),
          ),
          title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          subtitle: Text(p.displayName, style: const TextStyle(fontSize: 11.5, color: Colors.black54), maxLines: 2),
          trailing: p.distanceText.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                  child: Text(p.distanceText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                )
              : null,
          onTap: () async {
            Navigator.pop(context);
            await UserAddressService.addRecent(UserSavedAddress(
              id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
              name: p.title,
              address: p.displayName,
              category: 'personal',
              latitude: p.location.latitude,
              longitude: p.location.longitude,
            ));
            widget.onSelected(p.title, p.displayName, p.location);
          },
        );
      },
    );
  }

  Widget _buildFavoritesAndRecents(List<UserSavedAddress> filteredFavs) {
    if (_isLoadingAddresses) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (ctx, idx) => const GageSkeletonLocationTile(),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Favorit & Tombol Tambah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alamat Favorit', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isAddingNewAddress = !_isAddingNewAddress);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(_isAddingNewAddress ? Icons.close_rounded : Icons.add_rounded, size: 16, color: GageTheme.primary),
                      const SizedBox(width: 4),
                      Text(_isAddingNewAddress ? 'Batal' : 'Tambah', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Switcher 2 Tab: Personal vs Bisnis
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _favoriteCategory = 'personal'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _favoriteCategory == 'personal'
                            ? (isDark ? const Color(0xFF3F3F46) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _favoriteCategory == 'personal'
                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_rounded, size: 16, color: _favoriteCategory == 'personal' ? GageTheme.primary : (isDark ? Colors.white60 : Colors.grey)),
                          const SizedBox(width: 6),
                          Text('Personal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _favoriteCategory == 'personal' ? GageTheme.primary : (isDark ? Colors.white70 : Colors.grey))),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _favoriteCategory = 'business'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _favoriteCategory == 'business'
                            ? (isDark ? const Color(0xFF3F3F46) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _favoriteCategory == 'business'
                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_center_rounded, size: 16, color: _favoriteCategory == 'business' ? GageTheme.primary : (isDark ? Colors.white60 : Colors.grey)),
                          const SizedBox(width: 6),
                          Text('Bisnis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _favoriteCategory == 'business' ? GageTheme.primary : (isDark ? Colors.white70 : Colors.grey))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Accordion Form Field Tambah Alamat Baru (Inline, Bukan Floating Sheet)
          if (_isAddingNewAddress) ...[
            _buildAddAddressAccordion(isDark),
            const SizedBox(height: 14),
          ],

          // List Alamat Favorit
          if (filteredFavs.isEmpty && !_isAddingNewAddress)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    _favoriteCategory == 'personal' ? Icons.home_outlined : Icons.storefront_outlined,
                    size: 32,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _favoriteCategory == 'personal' ? 'Belum ada alamat personal' : 'Belum ada alamat bisnis/toko',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text('Ketuk "Tambah" di atas untuk menyimpan', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
                ],
              ),
            )
          else
            ...filteredFavs.map((fav) => _buildAddressCard(
              address: fav,
              onTap: () {
                Navigator.pop(context);
                widget.onSelected(fav.name, fav.address, fav.location);
              },
              onDelete: () async {
                await UserAddressService.deleteFavorite(fav.id);
                _loadAddressData();
              },
            )),

          const SizedBox(height: 20),

          // Alamat Terakhir
          if (_recents.isNotEmpty) ...[
            const Text('Alamat Terakhir', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._recents.map((rec) => _buildAddressCard(
              address: rec,
              isRecent: true,
              onTap: () {
                Navigator.pop(context);
                widget.onSelected(rec.name, rec.address, rec.location);
              },
            )),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required UserSavedAddress address,
    bool isRecent = false,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tampilan Alamat Terakhir yang Ramping & Hemat Tempat
    if (isRecent) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_rounded, size: 15, color: Colors.black54),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        address.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        address.address,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black26),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFFFEBEE),
          child: Icon(
            address.icon,
            size: 20,
            color: GageTheme.primary,
          ),
        ),
        title: Text(address.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address.address, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (address.notes != null && address.notes!.isNotEmpty)
              Text('Patokan: ${address.notes!}', style: TextStyle(fontSize: 10.5, color: Colors.orange.shade800)),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.black38),
                onPressed: onDelete,
              )
            : const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black26),
      ),
    );
  }
}

/// Modal Peta Retina HD Interaktif dengan Draggable Pin & Live Reverse Geocoding
class _RetinaMapPickerModal extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(String title, String fullAddress, LatLng latLng) onConfirmed;

  const _RetinaMapPickerModal({
    this.initialLocation,
    required this.onConfirmed,
  });

  @override
  State<_RetinaMapPickerModal> createState() => _RetinaMapPickerModalState();
}

class _RetinaMapPickerModalState extends State<_RetinaMapPickerModal> {
  final MapController _mapController = MapController();
  late LatLng _currentCenter;
  String _detectedTitle = 'Mendeteksi titik koordinat...';
  String _detectedDetail = '';
  bool _isGeocoding = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation ?? const LatLng(-8.05517, 110.80889);
    _reverseGeocodeCenter(_currentCenter);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _currentCenter = camera.center;
    _debounce?.cancel();
    setState(() => _isGeocoding = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _reverseGeocodeCenter(_currentCenter);
    });
  }

  Future<void> _reverseGeocodeCenter(LatLng point) async {
    final title = await OsmGeocodingService.reverseGeocode(point);
    final detail = OsmGeocodingService.formatFullOfficialAddress(point);
    if (!mounted) return;
    setState(() {
      _detectedTitle = title;
      _detectedDetail = detail;
      _isGeocoding = false;
    });
  }

  Future<void> _recenterGps() async {
    final gps = await LocationService.getCurrentLocation();
    _mapController.move(gps, 17.5);
    _reverseGeocodeCenter(gps);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Google Maps Retina HD (scale=2, hl=id, maxZoom=21.0)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 17.0,
              minZoom: 11.0,
              maxZoom: 21.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                tileDimension: 256,
                maxZoom: 21.0,
                userAgentPackageName: 'com.gage.customer',
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
            ],
          ),

          // Pin Tengah Tetap (Center Indicator)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: GageTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                  ),
                  Container(
                    width: 4,
                    height: 12,
                    color: GageTheme.primary,
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  const Text('Geser Peta ke Titik Lokasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // Floating Recenter Button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton.small(
              heroTag: 'recenter_gps_picker',
              backgroundColor: Colors.white,
              foregroundColor: GageTheme.primary,
              elevation: 4,
              onPressed: _recenterGps,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // Bottom Confirmation Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -3))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded, color: GageTheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _detectedTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isGeocoding)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _detectedDetail,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onConfirmed(_detectedTitle, _detectedDetail, _currentCenter);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Konfirmasi Titik Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
