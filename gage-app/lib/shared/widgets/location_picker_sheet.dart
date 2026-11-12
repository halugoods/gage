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
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';

/// Sheet terpadu pemilihan titik lokasi untuk seluruh layanan Gage (Ride, Car, Food, Shop, Send).
class LocationPickerSheet extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;
  final String? initialLocationTitle;
  final String? selectedFavoriteId;
  final Function(String title, String fullAddress, LatLng latLng) onSelected;
  final ValueChanged<UserSavedAddress?>? onFavoriteSelected;
  final bool showMiniMap;
  final bool autoFocusSearch;

  const LocationPickerSheet({
    super.key,
    required this.title,
    this.initialLocation,
    this.initialLocationTitle,
    this.selectedFavoriteId,
    required this.onSelected,
    this.onFavoriteSelected,
    this.showMiniMap = true,
    this.autoFocusSearch = false,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Pilih Lokasi',
    LatLng? initialLocation,
    String? initialLocationTitle,
    String? selectedFavoriteId,
    required Function(String title, String fullAddress, LatLng latLng) onSelected,
    ValueChanged<UserSavedAddress?>? onFavoriteSelected,
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
              initialLocationTitle: initialLocationTitle,
              selectedFavoriteId: selectedFavoriteId,
              onSelected: onSelected,
              onFavoriteSelected: onFavoriteSelected,
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

  // State Main Preview MiniMap (terpisah dari draft Tambah Alamat Favorit)
  late LatLng _activePreviewLocation;
  String _activePreviewTitle = 'Titik Lokasi Pengantaran';
  String _activePreviewFullAddr = 'Kec. Pracimantoro, Kabupaten Wonogiri, Jawa Tengah';
  bool _hasMainPinMoved = false;
  UserSavedAddress? _matchedFavorite;
  int _mainGeocodeSeq = 0;

  // State Accordion Tambah Alamat Baru & Draft MiniMap
  bool _isAddingNewAddress = false;
  final TextEditingController _newAddrNameCtrl = TextEditingController();
  final TextEditingController _newAddrNotesCtrl = TextEditingController();
  final TextEditingController _newAddrSearchCtrl = TextEditingController();
  List<OsmPlace> _newAddrSearchResults = [];
  bool _isNewAddrSearching = false;
  Timer? _newAddrDebounce;
  late LatLng _draftPin;
  String _draftAddr = 'Pracimantoro, Wonogiri';
  String _draftFullAddr = 'Kec. Pracimantoro, Kabupaten Wonogiri, Jawa Tengah';
  bool _hasDraftPinMoved = false;
  bool _isDraftPinLocked = false;
  int _draftGeocodeSeq = 0;

  final MapController _miniMapController = MapController();
  final MapController _accordionMapController = MapController();

  void _safeMoveMap(MapController controller, LatLng target, double zoom) {
    try {
      controller.move(target, zoom);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _activePreviewLocation = widget.initialLocation ?? LocationService.cachedOrFallback;
    if (widget.initialLocationTitle != null && widget.initialLocationTitle!.trim().isNotEmpty) {
      _activePreviewTitle = widget.initialLocationTitle!.trim();
    }
    _activePreviewFullAddr = OsmGeocodingService.formatFullOfficialAddress(_activePreviewLocation);
    _draftPin = _activePreviewLocation;
    _draftAddr = _activePreviewTitle;
    _draftFullAddr = _activePreviewFullAddr;
    _loadAddressData();
    _initPreviewAddress();
    if (widget.initialLocation == null) {
      _acquireDefaultGps();
    }
  }

  Future<void> _acquireDefaultGps() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      if (!mounted || _hasMainPinMoved) return;
      setState(() {
        _activePreviewLocation = pos;
        if (!_isAddingNewAddress) {
          _draftPin = pos;
        }
      });
      _safeMoveMap(_miniMapController, pos, 16.5);
      _initPreviewAddress();
    } catch (_) {}
  }

  Future<void> _initPreviewAddress() async {
    final target = _activePreviewLocation;
    final seq = ++_mainGeocodeSeq;
    try {
      final name = await OsmGeocodingService.reverseGeocode(target);
      final full = OsmGeocodingService.formatFullOfficialAddress(target);
      if (!mounted || seq != _mainGeocodeSeq) return;
      setState(() {
        if (_matchedFavorite != null) {
          _activePreviewTitle = _matchedFavorite!.name;
        } else if (!_hasMainPinMoved &&
            widget.initialLocationTitle != null &&
            widget.initialLocationTitle!.trim().isNotEmpty) {
          _activePreviewTitle = widget.initialLocationTitle!.trim();
        } else {
          _activePreviewTitle = name;
        }
        _activePreviewFullAddr = full;
        if (!_isAddingNewAddress && !_hasDraftPinMoved && !_isDraftPinLocked) {
          _draftAddr = name;
          _draftFullAddr = full;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadAddressData() async {
    final favs = await UserAddressService.getFavorites();
    final recs = await UserAddressService.getRecents();
    final matched = UserAddressService.matchFavoriteInList(
      favs,
      location: _activePreviewLocation,
      preferredId: _hasMainPinMoved ? null : widget.selectedFavoriteId,
      preferredName: _hasMainPinMoved ? null : widget.initialLocationTitle,
    );
    if (!mounted) return;
    setState(() {
      _favorites = favs;
      _recents = recs;
      _isLoadingAddresses = false;
      _matchedFavorite = matched;
      if (matched != null) {
        _favoriteCategory = matched.category;
        _activePreviewTitle = matched.name;
        if (_activePreviewFullAddr.trim().isEmpty) {
          _activePreviewFullAddr = matched.address;
        }
      }
    });
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

  void _onNewAddrSearchChanged(String val) {
    _newAddrDebounce?.cancel();
    final clean = val.trim();
    if (clean.length < 2) {
      setState(() {
        _newAddrSearchResults = [];
        _isNewAddrSearching = false;
      });
      return;
    }

    setState(() => _isNewAddrSearching = true);
    _newAddrDebounce = Timer(const Duration(milliseconds: 320), () async {
      final results = await OsmGeocodingService.searchPlaces(
        clean,
        proximityLocation: _draftPin,
      );
      if (!mounted) return;
      setState(() {
        _newAddrSearchResults = results;
        _isNewAddrSearching = false;
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _newAddrDebounce?.cancel();
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

      // Ambil posisi GPS riil dengan fallback cerdas ke LastKnownPosition / Cache
      final gps = await LocationService.getCurrentLocation(forceFresh: true);
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
      setState(() => _isAcquiringGps = false);
      GageToast.show(
        context,
        'Lokasi saat ini berhasil dipilih',
        type: GageToastType.success,
      );
      Navigator.pop(context);
      widget.onFavoriteSelected?.call(null);
      widget.onSelected(addr, fullAddr, gps);
    } catch (e) {
      final fallbackGps = LocationService.cachedOrFallback;
      final addr = await OsmGeocodingService.reverseGeocode(fallbackGps);
      final fullAddr = OsmGeocodingService.formatFullOfficialAddress(fallbackGps);
      if (!mounted) return;
      setState(() => _isAcquiringGps = false);
      GageToast.show(
        context,
        'Menggunakan lokasi GPS tersimpan',
        type: GageToastType.info,
      );
      Navigator.pop(context);
      widget.onFavoriteSelected?.call(null);
      widget.onSelected(addr, fullAddr, fallbackGps);
    }
  }

  Future<void> _openMapPicker({
    LatLng? overrideInitialLocation,
    String? overrideInitialTitle,
    String? overrideInitialFullAddr,
  }) async {
    final initialPin = overrideInitialLocation ?? _activePreviewLocation;
    final initialTitle = overrideInitialTitle ?? _activePreviewTitle;
    final initialFullAddr = overrideInitialFullAddr ?? _activePreviewFullAddr;
    final nav = Navigator.of(context);
    nav.pop();
    final picked = await nav.push<FullScreenMapResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullScreenMapPicker(
          title: widget.title,
          initialLocation: initialPin,
          initialTitle: initialTitle,
          initialFullAddress: initialFullAddr,
        ),
      ),
    );
    if (picked == null) return;
    await UserAddressService.addRecent(UserSavedAddress(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      name: picked.title,
      address: picked.fullAddress,
      category: 'personal',
      latitude: picked.location.latitude,
      longitude: picked.location.longitude,
    ));
    widget.onFavoriteSelected?.call(null);
    widget.onSelected(picked.title, picked.fullAddress, picked.location);
  }

  void _openAddAddressForm() {
    HapticFeedback.lightImpact();
    setState(() {
      _isAddingNewAddress = !_isAddingNewAddress;
      if (_isAddingNewAddress) {
        _draftPin = _activePreviewLocation;
        _draftAddr = _activePreviewTitle;
        _draftFullAddr = _activePreviewFullAddr;
        _hasDraftPinMoved = false;
        _isDraftPinLocked = false;
      }
    });
  }

  Future<void> _acquireGpsForNewAddress() async {
    try {
      final latLng = await LocationService.getCurrentLocation(forceFresh: true);
      _updateDraftPin(latLng, markMoved: false, locked: true);
      _safeMoveMap(_accordionMapController, latLng, 17.0);
      if (mounted) {
        GageToast.show(context, 'Titik GPS berhasil diarahkan', type: GageToastType.success);
      }
    } catch (e) {
      if (mounted) {
        final fallback = LocationService.cachedOrFallback;
        _updateDraftPin(fallback, markMoved: false, locked: true);
        _safeMoveMap(_accordionMapController, fallback, 17.0);
        GageToast.show(context, 'Menggunakan titik lokasi tersimpan', type: GageToastType.info);
      }
    }
  }

  Future<void> _openMapPickerForNewAddress() async {
    final picked = await FullScreenMapPicker.open(
      context,
      title: 'Tambah Titik Alamat',
      initialLocation: _draftPin,
      initialTitle: _draftAddr,
      initialFullAddress: _draftFullAddr,
    );
    if (picked == null || !mounted) return;
    _updateDraftPin(
      picked.location,
      title: picked.title,
      fullAddr: picked.fullAddress,
      markMoved: false,
      locked: true,
    );
    _safeMoveMap(_accordionMapController, picked.location, 17.5);
  }

  Future<void> _updateMainPreviewPin(LatLng pin) async {
    final seq = ++_mainGeocodeSeq;
    final matched = UserAddressService.matchFavoriteInList(
      _favorites,
      location: pin,
    );
    setState(() {
      _activePreviewLocation = pin;
      _hasMainPinMoved = true;
      _matchedFavorite = matched;
      if (matched != null) {
        _activePreviewTitle = matched.name;
      }
    });

    final name = await OsmGeocodingService.reverseGeocode(pin);
    final full = OsmGeocodingService.formatFullOfficialAddress(pin);
    if (!mounted || seq != _mainGeocodeSeq) return;
    setState(() {
      if (_matchedFavorite != null) {
        _activePreviewTitle = _matchedFavorite!.name;
      } else {
        _activePreviewTitle = name;
      }
      _activePreviewFullAddr = full;
    });
  }

  Future<void> _confirmMainMiniMapPin() async {
    final target = _activePreviewLocation;
    final title = _activePreviewTitle.trim().isNotEmpty
        ? _activePreviewTitle.trim()
        : OsmGeocodingService.formatFullOfficialAddress(target);
    final fullAddr = _activePreviewFullAddr.trim().isNotEmpty
        ? _activePreviewFullAddr.trim()
        : OsmGeocodingService.formatFullOfficialAddress(target);
    final matched = UserAddressService.matchFavoriteInList(
      _favorites,
      location: target,
      preferredId: _matchedFavorite?.id,
      preferredName: _matchedFavorite?.name,
    );

    await UserAddressService.addRecent(UserSavedAddress(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      address: fullAddr,
      category: 'personal',
      latitude: target.latitude,
      longitude: target.longitude,
    ));
    if (!mounted) return;
    setState(() => _hasMainPinMoved = false);
    GageToast.show(context, 'Titik lokasi berhasil dikunci', type: GageToastType.success);
    Navigator.pop(context);
    widget.onFavoriteSelected?.call(matched);
    widget.onSelected(title, fullAddr, target);
  }

  Future<void> _updateDraftPin(
    LatLng pin, {
    String? title,
    String? fullAddr,
    bool markMoved = true,
    bool locked = false,
  }) async {
    final seq = ++_draftGeocodeSeq;
    setState(() {
      _draftPin = pin;
      if (title != null) _draftAddr = title;
      if (fullAddr != null) _draftFullAddr = fullAddr;
      _hasDraftPinMoved = markMoved;
      _isDraftPinLocked = locked;
    });

    if (title == null || fullAddr == null) {
      final name = await OsmGeocodingService.reverseGeocode(pin);
      final full = OsmGeocodingService.formatFullOfficialAddress(pin);
      if (!mounted || seq != _draftGeocodeSeq) return;
      setState(() {
        _draftAddr = name;
        _draftFullAddr = full;
      });
    }
  }

  void _lockDraftMiniMapPin() {
    HapticFeedback.selectionClick();
    setState(() {
      _hasDraftPinMoved = false;
      _isDraftPinLocked = true;
    });
    GageToast.show(
      context,
      'Titik peta dikunci. Isi nama alamat lalu tekan Simpan.',
      type: GageToastType.success,
    );
  }

  Future<void> _saveNewAddress() async {
    final label = _newAddrNameCtrl.text.trim();
    if (label.isEmpty) {
      GageToast.show(context, 'Silakan masukkan nama alamat (misal: Rumah / Toko)', type: GageToastType.warning);
      return;
    }

    final savedCoord = _draftPin;
    final savedAddrText = _draftAddr.trim().isNotEmpty
        ? _draftAddr.trim()
        : OsmGeocodingService.formatFullOfficialAddress(savedCoord);

    final newAddr = UserSavedAddress(
      id: 'fav_${DateTime.now().millisecondsSinceEpoch}',
      name: label,
      address: savedAddrText,
      category: _favoriteCategory,
      latitude: savedCoord.latitude,
      longitude: savedCoord.longitude,
      notes: _newAddrNotesCtrl.text.trim().isEmpty ? null : _newAddrNotesCtrl.text.trim(),
    );

    await UserAddressService.saveFavorite(newAddr);
    if (!mounted) return;

    setState(() {
      _isAddingNewAddress = false;
      _hasDraftPinMoved = false;
      _isDraftPinLocked = false;
      _newAddrNameCtrl.clear();
      _newAddrNotesCtrl.clear();
      _newAddrSearchCtrl.clear();
      _activePreviewLocation = savedCoord;
      _activePreviewTitle = label;
      _activePreviewFullAddr = _draftFullAddr;
      _matchedFavorite = newAddr;
    });

    _safeMoveMap(_miniMapController, savedCoord, 16.5);
    await _loadAddressData();
    if (mounted) {
      GageToast.show(context, 'Alamat $label berhasil disimpan ke favorit', type: GageToastType.success);
    }
  }

  Widget _buildMiniMapWidget({
    required LatLng center,
    required VoidCallback onExpand,
    required VoidCallback onRecenter,
    required String addressLabel,
    required String fullAddressLabel,
    required MapController mapController,
    required ValueChanged<LatLng> onPositionDragged,
    required bool showConfirmButton,
    VoidCallback? onConfirmPin,
    bool isPinLocked = false,
    Key? mapKey,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1.7,
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
              key: mapKey,
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture) {
                    onPositionDragged(pos.center);
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
            // Center Pin Marker (IgnorePointer agar tidak menghalangi gesture geser peta di tengah pin)
            IgnorePointer(
              child: Center(
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
                  if (showConfirmButton && onConfirmPin != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onConfirmPin,
                      child: const Text('Pakai Lokasi Ini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ] else if (isPinLocked) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 12, color: Color(0xFF047857)),
                          SizedBox(width: 4),
                          Text(
                            'Terkunci',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
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
                    onChanged: _onNewAddrSearchChanged,
                    onSubmitted: (query) async {
                      if (query.trim().length >= 2) {
                        final results = await OsmGeocodingService.searchPlaces(query.trim(), proximityLocation: _draftPin);
                        if (results.isNotEmpty) {
                          final top = results.first;
                          _updateDraftPin(
                            top.location,
                            title: top.title,
                            fullAddr: top.displayName,
                            markMoved: false,
                            locked: true,
                          );
                          _safeMoveMap(_accordionMapController, top.location, 17.0);
                          setState(() => _newAddrSearchResults = []);
                        }
                      }
                    },
                  ),
                ),
                if (_newAddrSearchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _newAddrSearchCtrl.clear();
                      _onNewAddrSearchChanged('');
                    },
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                  ),
              ],
            ),
          ),

          // Live Dropdown Hasil Pencarian Accordion
          if (_isNewAddrSearching) ...[
            const SizedBox(height: 6),
            const LinearProgressIndicator(
              minHeight: 2,
              color: GageTheme.primary,
              backgroundColor: Colors.transparent,
            ),
          ],
          if (_newAddrSearchResults.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GageTheme.primary.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _newAddrSearchResults.length,
                separatorBuilder: (ctx, i) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                itemBuilder: (ctx, idx) {
                  final place = _newAddrSearchResults[idx];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    leading: const Icon(Icons.location_on_rounded, size: 18, color: GageTheme.primary),
                    title: Text(
                      place.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      place.displayName,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _newAddrSearchCtrl.text = place.title;
                        _newAddrSearchResults = [];
                      });
                      _updateDraftPin(
                        place.location,
                        title: place.title,
                        fullAddr: place.displayName,
                        markMoved: false,
                        locked: true,
                      );
                      _safeMoveMap(_accordionMapController, place.location, 17.0);
                    },
                  );
                },
              ),
            ),
          ],
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
                        Flexible(
                          child: Text(
                            'Lokasi Saat Ini',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary),
                          ),
                        ),
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
                        Flexible(
                          child: Text(
                            'Pilih Lewat Peta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ),
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

          // Mini Preview Map Realtime Pin untuk Alamat Favorit (mengunci lokasi tanpa keluar sheet)
          _buildMiniMapWidget(
            mapKey: const ValueKey('add_favorite_draft_minimap'),
            center: _draftPin,
            onExpand: _openMapPickerForNewAddress,
            onRecenter: _acquireGpsForNewAddress,
            addressLabel: _draftAddr,
            fullAddressLabel: _draftFullAddr,
            mapController: _accordionMapController,
            onPositionDragged: (center) => _updateDraftPin(center, markMoved: true, locked: false),
            showConfirmButton: _hasDraftPinMoved,
            onConfirmPin: _lockDraftMiniMapPin,
            isPinLocked: _isDraftPinLocked,
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
              mapKey: const ValueKey('main_preview_minimap'),
              center: _activePreviewLocation,
              onExpand: _openMapPicker,
              onRecenter: _selectCurrentGps,
              addressLabel: _activePreviewTitle,
              fullAddressLabel: _activePreviewFullAddr,
              mapController: _miniMapController,
              onPositionDragged: _updateMainPreviewPin,
              showConfirmButton: _hasMainPinMoved,
              onConfirmPin: _confirmMainMiniMapPin,
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
                          Flexible(
                            child: Text(
                              _isAcquiringGps ? 'Mendeteksi...' : 'Lokasi Saat Ini',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: GageTheme.primary),
                            ),
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
                          Flexible(
                            child: Text(
                              'Pilih Lewat Peta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF2563EB)),
                            ),
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
                children: [
                  const Expanded(
                    child: Text(
                      'Belum ada alamat tersimpan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openAddAddressForm,
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
            widget.onFavoriteSelected?.call(null);
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
                onTap: _openAddAddressForm,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(999),
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

          // Switcher 2 Tab Full-Rounded Capsule: Personal vs Bisnis
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _favoriteCategory = 'personal');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _favoriteCategory == 'personal' ? GageTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: _favoriteCategory == 'personal'
                                ? Colors.white
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Personal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _favoriteCategory == 'personal'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _favoriteCategory = 'business');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _favoriteCategory == 'business' ? GageTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_center_rounded,
                            size: 16,
                            color: _favoriteCategory == 'business'
                                ? Colors.white
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Bisnis',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _favoriteCategory == 'business'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
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
              isSelected: _matchedFavorite?.id == fav.id,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                widget.onFavoriteSelected?.call(fav);
                widget.onSelected(fav.name, fav.address, fav.location);
              },
              onChange: _matchedFavorite?.id == fav.id
                  ? () {
                      HapticFeedback.selectionClick();
                      _openMapPicker(
                        overrideInitialLocation: fav.location,
                        overrideInitialTitle: fav.name,
                        overrideInitialFullAddr: fav.address,
                      );
                    }
                  : null,
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
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                widget.onFavoriteSelected?.call(null);
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
    bool isSelected = false,
    required VoidCallback onTap,
    VoidCallback? onChange,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? (isDark
                ? GageTheme.primary.withValues(alpha: 0.14)
                : const Color(0xFFFFF5F5))
            : (isDark ? const Color(0xFF27272A) : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected
                ? GageTheme.primary
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isSelected ? GageTheme.primary : const Color(0xFFFFEBEE),
          child: Icon(
            address.icon,
            size: 20,
            color: isSelected ? Colors.white : GageTheme.primary,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                address.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: GageTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Terpilih',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address.address, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (address.notes != null && address.notes!.isNotEmpty)
              Text('Patokan: ${address.notes!}', style: TextStyle(fontSize: 10.5, color: Colors.orange.shade800)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && onChange != null) ...[
              InkWell(
                onTap: onChange,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3F3F46) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: GageTheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 14, color: GageTheme.primary),
                      SizedBox(width: 4),
                      Text(
                        'Ganti',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: GageTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 2),
            ],
            if (onDelete != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
                onPressed: onDelete,
              )
            else if (!isSelected)
              const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black26),
          ],
        ),
        ),
      ),
    );
  }
}
