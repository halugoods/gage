import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/open_location_code_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/core/services/pracimantoro_places_database.dart';
import 'package:gage_app/core/services/user_address_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class FullScreenMapResult {
  final String title;
  final String fullAddress;
  final LatLng location;
  final UserSavedAddress? matchedFavorite;

  const FullScreenMapResult({
    required this.title,
    required this.fullAddress,
    required this.location,
    this.matchedFavorite,
  });
}

/// Layar peta full-screen standar GAGE dengan search bar lokasi + Alamat Terakhir saat fokus,
/// pil cepat Alamat Favorit (dapat dihapus dengan long press / icon tempat sampah),
/// mode in-place Tambah Alamat Favorit (tanpa ganti screen), pin geser tengah, tombol GPS aman,
/// dan kartu konfirmasi di bawah.
class FullScreenMapPicker extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;
  final String? initialTitle;
  final String? initialFullAddress;
  final String? selectedFavoriteId;
  final bool autoFocusSearch;
  final String confirmLabel;
  final bool isAddFavoriteInitialMode;

  const FullScreenMapPicker({
    super.key,
    this.title = 'Pilih Titik Lokasi',
    this.initialLocation,
    this.initialTitle,
    this.initialFullAddress,
    this.selectedFavoriteId,
    this.autoFocusSearch = false,
    this.confirmLabel = 'Pakai Lokasi Ini',
    this.isAddFavoriteInitialMode = false,
  });

  static Future<FullScreenMapResult?> open(
    BuildContext context, {
    String title = 'Pilih Titik Lokasi',
    LatLng? initialLocation,
    String? initialTitle,
    String? initialFullAddress,
    String? selectedFavoriteId,
    bool autoFocusSearch = false,
    String confirmLabel = 'Pakai Lokasi Ini',
    bool isAddFavoriteInitialMode = false,
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
          selectedFavoriteId: selectedFavoriteId,
          autoFocusSearch: autoFocusSearch,
          confirmLabel: confirmLabel,
          isAddFavoriteInitialMode: isAddFavoriteInitialMode,
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

  final TextEditingController _favNameCtrl = TextEditingController();
  final TextEditingController _favRecipientNameCtrl = TextEditingController();
  final TextEditingController _favRecipientPhoneCtrl = TextEditingController();
  final TextEditingController _favNotesCtrl = TextEditingController();
  String _favCategory = 'personal';
  bool _isAddingFavorite = false;
  bool _isFavoritesExpanded = false;
  bool _isSelectingLocationForFavorite = false;
  String? _editingFavoriteId;

  late LatLng _center;
  String _detectedTitle = 'Mendeteksi lokasi...';
  String _detectedAddress = 'Mengambil alamat lengkap di sekitar pin...';
  bool _isGeocoding = false;
  bool _isSearching = false;
  bool _isAcquiringGps = false;
  bool _isSearchFocused = false;
  List<OsmPlace> _searchResults = [];
  List<UserSavedAddress> _favorites = [];
  List<UserSavedAddress> _recents = [];
  UserSavedAddress? _activeFavorite;
  String? _selectedFavoriteId;
  Timer? _geocodeDebounce;
  Timer? _searchDebounce;
  int _geocodeSeq = 0;
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    _center = widget.initialLocation ?? LocationService.cachedOrFallback;
    _selectedFavoriteId = widget.selectedFavoriteId;
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
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _loadSavedAddresses();

    if (widget.isAddFavoriteInitialMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openAddFavoriteMode();
      });
    }

    if (widget.autoFocusSearch && !_isAddingFavorite) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _favNameCtrl.dispose();
    _favRecipientNameCtrl.dispose();
    _favRecipientPhoneCtrl.dispose();
    _favNotesCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
  }

  Future<void> _loadSavedAddresses() async {
    final results = await Future.wait([
      UserAddressService.getFavorites(),
      UserAddressService.getRecents(),
    ]);
    if (!mounted) return;
    final favs = results[0];
    final recents = results[1];
    final matched = UserAddressService.matchFavoriteInList(
      favs,
      location: _center,
      preferredId: _selectedFavoriteId,
      preferredName: widget.initialTitle,
    );
    setState(() {
      _favorites = favs;
      _recents = recents;
      _activeFavorite = matched;
      _selectedFavoriteId = matched?.id;
    });
  }

  void _safeMove(LatLng target, [double zoom = 17.0]) {
    try {
      _mapController.move(target, zoom);
    } catch (_) {}
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
    _center = camera.center;
    if (!_isAddingFavorite && !_isSelectingLocationForFavorite) {
      _activeFavorite = null;
      _selectedFavoriteId = null;
      final shortPlus = OpenLocationCodeService.getShortPlusCode(_center);
      final village = OsmGeocodingService.getNearestVillage(_center);
      _detectedTitle = '$shortPlus, $village';
      _detectedAddress = OsmGeocodingService.formatFullOfficialAddress(_center);
    }
    _geocodeDebounce?.cancel();
    if (mounted) {
      setState(() => _isGeocoding = true);
    }
    _geocodeDebounce = Timer(const Duration(milliseconds: 380), () {
      _reverseGeocodeCenter(
        _center,
        forceRawMaps: _isSelectingLocationForFavorite || (_isAddingFavorite && _editingFavoriteId == null),
      );
    });
  }

  Future<void> _reverseGeocodeCenter(LatLng point, {bool forceRawMaps = false}) async {
    final seq = ++_geocodeSeq;
    if (mounted) setState(() => _isGeocoding = true);
    try {
      final raw = await OsmGeocodingService.reverseGeocode(point);
      if (!mounted || seq != _geocodeSeq) return;
      final cleanRaw = raw.trim();
      final full = cleanRaw.isNotEmpty
          ? (cleanRaw.contains('Wonogiri') ? cleanRaw : '$cleanRaw, Wonogiri')
          : OsmGeocodingService.formatFullOfficialAddress(point);
      final rawTitle = raw.trim().isNotEmpty
          ? raw.split(',').first.trim()
          : (cleanRaw.isNotEmpty
              ? cleanRaw.split(',').first.trim()
              : OpenLocationCodeService.getShortPlusCode(point));

      final isEditing = _editingFavoriteId != null;
      final shouldMatchFavorite = !forceRawMaps &&
          !_isSelectingLocationForFavorite &&
          (isEditing || !_isAddingFavorite);

      final matched = shouldMatchFavorite
          ? UserAddressService.matchFavoriteInList(
              _favorites,
              location: point,
              preferredId: _selectedFavoriteId,
              preferredName: rawTitle,
              maxDistanceMeters: 5.0,
            )
          : null;

      setState(() {
        if (!_isAddingFavorite && !_isSelectingLocationForFavorite) {
          _activeFavorite = matched;
          _selectedFavoriteId = matched?.id;
        } else if (_isSelectingLocationForFavorite || (_isAddingFavorite && !isEditing)) {
          _activeFavorite = null;
          _selectedFavoriteId = null;
        }
        _detectedTitle = matched?.name ?? (rawTitle.isNotEmpty ? rawTitle : 'Titik Lokasi Terpilih');
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

    final seq = ++_searchSeq;
    final instant = OsmGeocodingService.searchLocalInstant(
      trimmed,
      proximityLocation: _center,
    );
    setState(() {
      _searchResults = instant;
      _isSearching = instant.isEmpty;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 100), () async {
      final results = await OsmGeocodingService.searchPlaces(
        trimmed,
        proximityLocation: _center,
      );
      if (!mounted || seq != _searchSeq) return;
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
      _searchCtrl.clear();
      _searchResults = [];
      _center = place.location;
      _detectedTitle = place.title;
      _detectedAddress = place.displayName;
      _isGeocoding = false;
    });
    _safeMove(place.location, 17.5);
  }

  void _selectSavedAddress(UserSavedAddress saved, {required bool isFavorite}) {
    HapticFeedback.selectionClick();
    _searchFocusNode.unfocus();
    _geocodeDebounce?.cancel();
    ++_geocodeSeq;
    final matched = isFavorite
        ? saved
        : UserAddressService.matchFavoriteInList(
            _favorites,
            location: saved.location,
            preferredId: saved.id,
            preferredName: saved.name,
          );
    setState(() {
      _center = saved.location;
      _detectedTitle = saved.name;
      _detectedAddress = saved.address.isNotEmpty
          ? saved.address
          : OsmGeocodingService.formatFullOfficialAddress(saved.location);
      _activeFavorite = matched;
      _selectedFavoriteId = matched?.id;
      _searchResults = [];
      _searchCtrl.clear();
      _isGeocoding = false;
    });
    _safeMove(saved.location, 17.5);
  }

  void _selectFavorite(UserSavedAddress fav) {
    _selectSavedAddress(fav, isFavorite: true);
  }

  Future<void> _openAddFavoriteMode() async {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    final initialRaw = OpenLocationCodeService.getShortPlusCode(_center);
    setState(() {
      _isFavoritesExpanded = false;
      _isSelectingLocationForFavorite = true;
      _isAddingFavorite = false;
      _editingFavoriteId = null;
      _activeFavorite = null;
      _selectedFavoriteId = null;
      _favNameCtrl.clear();
      _detectedTitle = initialRaw;
      _favRecipientNameCtrl.clear();
      _favRecipientPhoneCtrl.clear();
      _favNotesCtrl.clear();
      _favCategory = 'personal';
      _searchFocusNode.unfocus();
    });
    _reverseGeocodeCenter(_center, forceRawMaps: true);
  }

  void _openEditFavorite(UserSavedAddress fav) {
    HapticFeedback.selectionClick();
    setState(() {
      _editingFavoriteId = fav.id;
      _favNameCtrl.text = fav.name;
      _favRecipientNameCtrl.text = fav.recipientName ?? '';
      _favRecipientPhoneCtrl.text = fav.recipientPhone ?? '';
      _favNotesCtrl.text = fav.notes ?? '';
      _favCategory = fav.category;
      _center = fav.location;
      _detectedTitle = fav.name;
      _detectedAddress = fav.address;
      _isFavoritesExpanded = false;
      _isSelectingLocationForFavorite = false;
      _isAddingFavorite = true;
      _searchFocusNode.unfocus();
    });
    _safeMove(fav.location, 17.5);
  }

  Future<void> _saveFavoriteAddress() async {
    final trimmedName = _favNameCtrl.text.trim();
    if (trimmedName.isEmpty) {
      GageToast.show(context, 'Masukkan nama alamat terlebih dahulu', type: GageToastType.warning);
      return;
    }
    if (!OsmGeocodingService.isWithinPracimantoro(_center)) {
      GageToast.show(
        context,
        'Alamat favorit harus berada di wilayah Kecamatan Pracimantoro',
        type: GageToastType.warning,
      );
      return;
    }

    final recName = _favRecipientNameCtrl.text.trim();
    final recPhone = _favRecipientPhoneCtrl.text.trim();

    HapticFeedback.mediumImpact();
    final isEditing = _editingFavoriteId != null;
    final favId = _editingFavoriteId ?? 'fav_${DateTime.now().millisecondsSinceEpoch}';
    final newFav = UserSavedAddress(
      id: favId,
      name: trimmedName,
      address: _detectedAddress.trim().isNotEmpty
          ? _detectedAddress.trim()
          : OsmGeocodingService.formatFullOfficialAddress(_center),
      category: _favCategory,
      latitude: _center.latitude,
      longitude: _center.longitude,
      notes: _favNotesCtrl.text.trim().isEmpty ? null : _favNotesCtrl.text.trim(),
      recipientName: recName.isNotEmpty ? recName : null,
      recipientPhone: recPhone.isNotEmpty ? recPhone : null,
    );
    await UserAddressService.saveFavorite(newFav);
    if (recName.isNotEmpty || recPhone.isNotEmpty) {
      await UserAddressService.saveLastRecipient(name: recName, phone: recPhone);
    }
    final updatedFavs = await UserAddressService.getFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = updatedFavs;
      _activeFavorite = newFav;
      _selectedFavoriteId = newFav.id;
      _detectedTitle = newFav.name;
      _detectedAddress = newFav.address;
      _isAddingFavorite = false;
      _isSelectingLocationForFavorite = false;
      _editingFavoriteId = null;
      _isFavoritesExpanded = false;
    });
    GageToast.show(
      context,
      isEditing ? 'Alamat favorit berhasil diperbarui' : 'Disimpan ke Alamat Favorit',
      type: GageToastType.success,
    );
  }

  Future<void> _confirmDeleteFavorite(UserSavedAddress fav) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Hapus Alamat Favorit?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${fav.name}" dari daftar favorit?',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await UserAddressService.deleteFavorite(fav.id);
      if (!mounted) return;
      final updatedFavs = await UserAddressService.getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = updatedFavs;
        if (_selectedFavoriteId == fav.id) {
          _selectedFavoriteId = null;
          _activeFavorite = null;
        }
      });
      GageToast.show(context, 'Alamat "${fav.name}" berhasil dihapus', type: GageToastType.info);
    }
  }

  Future<void> _recenterGps() async {
    HapticFeedback.selectionClick();
    setState(() => _isAcquiringGps = true);
    try {
      final rawGps = await LocationService.getCurrentLocation(forceFresh: true);
      if (!mounted) return;
      final inScope = OsmGeocodingService.isWithinPracimantoro(rawGps);
      final target = inScope ? rawGps : PracimantoroPlacesDatabase.centerPracimantoro;
      if (!inScope) {
        GageToast.show(
          context,
          'Lokasi saat ini di luar Kecamatan Pracimantoro',
          type: GageToastType.warning,
        );
      }
      setState(() {
        _center = target;
        if (!_isAddingFavorite && !_isSelectingLocationForFavorite) {
          _activeFavorite = null;
          _selectedFavoriteId = null;
        }
        _isAcquiringGps = false;
      });
      _safeMove(target, 17.5);
      await _reverseGeocodeCenter(target);
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
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final hasFavoritesInActiveCategory = _favorites.any(
      (f) => (_favCategory == 'business'
          ? (f.category == 'business' || f.category == 'kantor')
          : (f.category != 'business' && f.category != 'kantor')),
    );

    // Posisi vertikal GPS FAB dihitung dinamis agar TIDAK PERNAH tertutup kartu bawah
    final fabBottom = _isAddingFavorite
        ? bottomPadding + 360
        : (_isSelectingLocationForFavorite
            ? bottomPadding + 200
            : (_isFavoritesExpanded
                ? (hasFavoritesInActiveCategory ? bottomPadding + 420 : bottomPadding + 490)
                : bottomPadding + 84));

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Full-Screen Retina Map (terkunci di lingkup Kec. Pracimantoro)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 17.0,
              minZoom: 12.0,
              maxZoom: 21.0,
              cameraConstraint: CameraConstraint.containCenter(bounds: OsmGeocodingService.pracimantoroBounds),
              interactionOptions: InteractionOptions(
                flags: _isAddingFavorite ? InteractiveFlag.none : InteractiveFlag.all,
              ),
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
                    if (!_isAddingFavorite && !_isFavoritesExpanded) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Text(
                          _isSelectingLocationForFavorite
                              ? 'Geser peta untuk tentukan titik favorit'
                              : 'Geser peta untuk menentukan titik',
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
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

          // 3. Top Search Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: textPrimary,
                        ),
                        onPressed: () {
                          if (_isAddingFavorite) {
                            setState(() {
                              _isAddingFavorite = false;
                              if (_editingFavoriteId != null) {
                                _isFavoritesExpanded = true;
                                _editingFavoriteId = null;
                              } else {
                                _isSelectingLocationForFavorite = true;
                              }
                            });
                          } else if (_isSelectingLocationForFavorite) {
                            setState(() {
                              _isSelectingLocationForFavorite = false;
                              _isFavoritesExpanded = true;
                              _editingFavoriteId = null;
                            });
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        splashRadius: 20,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          style: TextStyle(fontSize: 13.5, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Cari jalan, tempat, atau patokan di Pracimantoro...',
                            hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                          ),
                        )
                      else if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                          splashRadius: 18,
                        ),
                    ],
                  ),
                ),

                // Kartu Posisi Lokasi Terpilih di Bawah Search Bar (selalu tampil di bawah search bar)
                if (_searchResults.isEmpty && !_isSearchFocused) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pin_drop_rounded, color: GageTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
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
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_activeFavorite != null &&
                                      !_isSelectingLocationForFavorite &&
                                      (_editingFavoriteId != null || !_isAddingFavorite)) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: GageTheme.primary,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Favorit',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (_isGeocoding)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _detectedAddress,
                                style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (_isAddingFavorite) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isSelectingLocationForFavorite = true;
                                _isAddingFavorite = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: GageTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: GageTheme.primary.withValues(alpha: 0.25)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_location_alt_rounded, size: 13, color: GageTheme.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ubah Titik',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: GageTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Search Results Dropdown Overlay
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.38,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
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
                  )
                else if (_isSearchFocused && _searchCtrl.text.trim().isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        children: [
                          if (_favorites.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                              child: Row(
                                children: [
                                  Text(
                                    'Alamat Favorit',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Tahan untuk hapus',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textSecondary.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final fav in _favorites)
                              ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: GageTheme.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(fav.icon, color: GageTheme.primary, size: 17),
                                ),
                                title: Text(
                                  fav.name,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  fav.address,
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 19),
                                  tooltip: 'Hapus Alamat',
                                  onPressed: () => _confirmDeleteFavorite(fav),
                                ),
                                onTap: () => _selectSavedAddress(fav, isFavorite: true),
                              ),
                            if (_recents.isNotEmpty)
                              Divider(height: 12, color: isDark ? Colors.white10 : Colors.grey.shade100),
                          ],
                          if (_recents.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                              child: Text(
                                'Alamat Terakhir',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            for (final recent in _recents)
                              ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.history_rounded, size: 17, color: Colors.black54),
                                ),
                                title: Text(
                                  recent.name,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  recent.address,
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectSavedAddress(recent, isFavorite: false),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 4. Floating GPS Recenter Button (selalu melayang bebas di atas kartu bawah)
          if (bottomInset == 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              right: 16,
              bottom: fabBottom,
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

          // 5. Bottom Card: Normal / Expanded Favorites VS Mode Tambah Alamat Favorit
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _isAddingFavorite
                ? _buildAddFavoriteFormCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    bottomInset: bottomInset,
                  )
                : _isSelectingLocationForFavorite
                    ? _buildSelectLocationForFavoriteCard(
                        isDark: isDark,
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                      )
                    : _buildBottomConfirmationCard(
                        isDark: isDark,
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomConfirmationCard({
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final isFavActive = _activeFavorite != null;
    final filteredFavs = _favorites.where((f) => f.category == _favCategory).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Alamat Favorit (Sesuai Screenshot Gambar 1)
            if (_isFavoritesExpanded) ...[
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isFavoritesExpanded = false),
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) > 100) {
                      setState(() => _isFavoritesExpanded = false);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alamat Favorit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  if (filteredFavs.isNotEmpty)
                    InkWell(
                      onTap: _openAddFavoriteMode,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: GageTheme.primary),
                            SizedBox(width: 4),
                            Text(
                              'Tambah',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: GageTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Segmented Category Switcher (Personal vs Bisnis - Capsule 999)
              Container(
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _favCategory = 'personal');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: _favCategory == 'personal' ? GageTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 15,
                                color: _favCategory == 'personal' ? Colors.white : textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Personal',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: _favCategory == 'personal' ? Colors.white : textSecondary,
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
                          setState(() => _favCategory = 'business');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: _favCategory == 'business' ? GageTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_center_rounded,
                                size: 15,
                                color: _favCategory == 'business' ? Colors.white : textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Bisnis',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: _favCategory == 'business' ? Colors.white : textSecondary,
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
              const SizedBox(height: 10),

              // Favorites List Cards (Sesuai Screenshot Gambar 1)
              if (filteredFavs.isEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _favCategory == 'personal' ? Icons.home_rounded : Icons.business_center_rounded,
                          size: 24,
                          color: GageTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada alamat ${_favCategory == "personal" ? "Personal" : "Bisnis"} tersimpan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Simpan titik lokasi favorit agar pemesanan berikutnya jadi instan.',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: const StadiumBorder(),
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text(
                          'Tambah Alamat Sekarang',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _openAddFavoriteMode,
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 6),
                    itemCount: filteredFavs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final fav = filteredFavs[idx];
                      final isSelected = _selectedFavoriteId == fav.id;
                      final contactInfo = [
                        if (fav.recipientName != null && fav.recipientName!.isNotEmpty) fav.recipientName!,
                        if (fav.recipientPhone != null && fav.recipientPhone!.isNotEmpty) fav.recipientPhone!,
                      ].join(' • ');

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _selectFavorite(fav);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? GageTheme.primary
                                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? GageTheme.primary
                                      : (isDark
                                          ? GageTheme.primary.withValues(alpha: 0.15)
                                          : const Color(0xFFFFEBEE)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  fav.category == 'personal' ? Icons.home_rounded : Icons.business_center_rounded,
                                  color: isSelected ? Colors.white : GageTheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            fav.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                              color: textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
                                    if (contactInfo.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        contactInfo,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: GageTheme.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      fav.address,
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (fav.notes != null && fav.notes!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Patokan: ${fav.notes}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFFD97706),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 19, color: textSecondary),
                                    tooltip: 'Edit Alamat',
                                    onPressed: () => _openEditFavorite(fav),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, size: 19, color: textSecondary),
                                    tooltip: 'Hapus Alamat',
                                    onPressed: () => _confirmDeleteFavorite(fav),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
            ],

            // Baris Tombol Konfirmasi & Bookmark
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: const ValueKey('map_picker_confirm_button'),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        final finalResult = FullScreenMapResult(
                          title: _detectedTitle,
                          fullAddress: _detectedAddress,
                          location: _center,
                          matchedFavorite: _activeFavorite,
                        );
                        UserAddressService.addRecent(UserSavedAddress(
                          id: 'recent_${DateTime.now().millisecondsSinceEpoch}',
                          name: _detectedTitle,
                          address: _detectedAddress,
                          category: _activeFavorite?.category ?? 'personal',
                          latitude: _center.latitude,
                          longitude: _center.longitude,
                          notes: _activeFavorite?.notes,
                          recipientName: _activeFavorite?.recipientName,
                          recipientPhone: _activeFavorite?.recipientPhone,
                        ));
                        Navigator.pop(context, finalResult);
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
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isFavoritesExpanded = !_isFavoritesExpanded);
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (_isFavoritesExpanded || isFavActive)
                            ? GageTheme.primary
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (_isFavoritesExpanded || isFavActive)
                              ? GageTheme.primary
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          (_isFavoritesExpanded || isFavActive)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_add_rounded,
                          color: (_isFavoritesExpanded || isFavActive)
                              ? Colors.white
                              : GageTheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFavoriteFormCard({
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required double bottomInset,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, bottomInset + 16),
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.58,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _editingFavoriteId != null ? Icons.edit_rounded : Icons.bookmark_add_rounded,
                            color: GageTheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _editingFavoriteId != null ? 'Edit Alamat Favorit' : 'Tambah Alamat Favorit',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isAddingFavorite = false;
                          _isSelectingLocationForFavorite = false;
                          _editingFavoriteId = null;
                          _isFavoritesExpanded = true;
                        });
                      },
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Segmented Switch Capsule: Personal vs Bisnis (tanpa tanda kurung)
                Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      for (final entry in [('personal', 'Personal'), ('business', 'Bisnis')])
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _favCategory = entry.$1);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _favCategory == entry.$1 ? GageTheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                entry.$2,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _favCategory == entry.$1
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Form Field 1: Nama Alamat
                TextField(
                  controller: _favNameCtrl,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nama Alamat',
                    labelStyle: TextStyle(fontSize: 12, color: textSecondary),
                    hintText: _favCategory == 'personal'
                        ? 'Contoh: Rumah, Kos'
                        : 'Contoh: Toko, Kantor',
                    hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.bookmark_outline_rounded, size: 18, color: GageTheme.primary),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Form Field 2: Nama Penerima / Kontak
                TextField(
                  controller: _favRecipientNameCtrl,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nama Penerima / Kontak',
                    labelStyle: TextStyle(fontSize: 12, color: textSecondary),
                    hintText: 'Nama orang yang menerima di lokasi',
                    hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: GageTheme.primary),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Form Field 3: Nomor WhatsApp / HP
                TextField(
                  controller: _favRecipientPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nomor WhatsApp / HP',
                    labelStyle: TextStyle(fontSize: 12, color: textSecondary),
                    hintText: 'Contoh: 0812xxxxxxxx',
                    hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: GageTheme.primary),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Form Field 2: Patokan / Catatan Pengantaran (Opsional)
                TextField(
                  controller: _favNotesCtrl,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Patokan / Catatan Pengantaran (Opsional)',
                    labelStyle: TextStyle(fontSize: 12, color: textSecondary),
                    hintText: 'Contoh: Pagar hitam depan masjid, masuk gang mawar',
                    hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: GageTheme.primary),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Primary Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    onPressed: _saveFavoriteAddress,
                    child: Text(
                      _editingFavoriteId != null ? 'Simpan Perubahan' : 'Simpan Lokasi Ini',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectLocationForFavoriteCard({
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final isEditing = _editingFavoriteId != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isSelectingLocationForFavorite = false;
                    if (isEditing) {
                      _isAddingFavorite = true;
                    } else {
                      _isFavoritesExpanded = true;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                          color: GageTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Ubah Titik Lokasi Favorit' : 'Tentukan Titik Alamat Favorit',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Arahkan pin merah di peta ke titik lokasi yang diinginkan.',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isSelectingLocationForFavorite = false;
                            if (isEditing) {
                              _isAddingFavorite = true;
                            } else {
                              _isFavoritesExpanded = true;
                            }
                          });
                        },
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Pilih Alamat Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isSelectingLocationForFavorite = false;
                    _isAddingFavorite = true;
                  });
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text(
                  'Pilih Alamat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper kompatibilitas mundur untuk rute pemanggil AddFavoriteMapPickerScreen
class AddFavoriteMapPickerScreen extends StatelessWidget {
  final LatLng initialLocation;
  final String initialName;
  final String initialAddress;

  const AddFavoriteMapPickerScreen({
    super.key,
    required this.initialLocation,
    required this.initialName,
    required this.initialAddress,
  });

  static Future<UserSavedAddress?> open(
    BuildContext context, {
    required LatLng initialLocation,
    String initialName = '',
    String initialAddress = '',
  }) async {
    HapticFeedback.lightImpact();
    final result = await FullScreenMapPicker.open(
      context,
      initialLocation: initialLocation,
      initialTitle: initialName,
      initialFullAddress: initialAddress,
      isAddFavoriteInitialMode: true,
    );
    return result?.matchedFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return FullScreenMapPicker(
      initialLocation: initialLocation,
      initialTitle: initialName,
      initialFullAddress: initialAddress,
      isAddFavoriteInitialMode: true,
    );
  }
}
