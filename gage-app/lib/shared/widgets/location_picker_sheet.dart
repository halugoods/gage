import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/core/services/user_address_service.dart';

/// Sheet terpadu pemilihan titik lokasi untuk seluruh layanan Gage (Ride, Car, Food, Shop, Send).
class LocationPickerSheet extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;
  final Function(String title, String fullAddress, LatLng latLng) onSelected;

  const LocationPickerSheet({
    super.key,
    required this.title,
    this.initialLocation,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Pilih Lokasi',
    LatLng? initialLocation,
    required Function(String title, String fullAddress, LatLng latLng) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPickerSheet(
        title: title,
        initialLocation: initialLocation,
        onSelected: onSelected,
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

  @override
  void initState() {
    super.initState();
    _loadAddressData();
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
    super.dispose();
  }

  Future<void> _selectCurrentGps() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membaca posisi GPS riil Anda...'),
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
    final gps = await LocationService.getCurrentLocation();
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

    widget.onSelected(addr, fullAddr, gps);
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

  void _showAddAddressDialog() {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String cat = _favoriteCategory;
    LatLng selectedPin = widget.initialLocation ?? const LatLng(-8.05517, 110.80889);
    String detectedAddr = 'Mendeteksi alamat...';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setDialogState) {
          if (detectedAddr == 'Mendeteksi alamat...') {
            OsmGeocodingService.reverseGeocode(selectedPin).then((addr) {
              setDialogState(() => detectedAddr = addr);
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tambah Alamat Favorit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),

                  // Kategori Tab (Personal vs Bisnis)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Personal (Rumah/Kos)')),
                          selected: cat == 'personal',
                          onSelected: (val) => setDialogState(() => cat = 'personal'),
                          selectedColor: const Color(0xFFE8F5E9),
                          labelStyle: TextStyle(
                            color: cat == 'personal' ? const Color(0xFF00880C) : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Bisnis (Toko/Kantor)')),
                          selected: cat == 'business',
                          onSelected: (val) => setDialogState(() => cat = 'business'),
                          selectedColor: const Color(0xFFE8F5E9),
                          labelStyle: TextStyle(
                            color: cat == 'business' ? const Color(0xFF00880C) : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Alamat',
                      hintText: cat == 'personal' ? 'Contoh: Rumah, Kos, Rumah Ortu' : 'Contoh: Toko Berkah, Kantor GAGE',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Patokan / Catatan Pengantaran (Opsional)',
                      hintText: 'Contoh: Pagar hitam depan masjid, masuk gang mawar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Info Titik Koordinat & Alamat Terdeteksi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pin_drop_rounded, color: Color(0xFF00880C), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(detectedAddr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                OsmGeocodingService.formatFullOfficialAddress(selectedPin),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final label = nameCtrl.text.trim();
                        if (label.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Silakan masukkan nama alamat')),
                          );
                          return;
                        }
                        final newAddr = UserSavedAddress(
                          id: 'fav_${DateTime.now().millisecondsSinceEpoch}',
                          name: label,
                          address: detectedAddr,
                          category: cat,
                          latitude: selectedPin.latitude,
                          longitude: selectedPin.longitude,
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );
                        await UserAddressService.saveFavorite(newAddr);
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        _loadAddressData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00880C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Simpan Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFavs = _favorites.where((f) => f.category == _favoriteCategory).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 12),

          // Header Bar
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. Search Box
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF00880C), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Ketik nama jalan, gedung, atau desa...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
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
                    child: const Icon(Icons.close_rounded, color: Colors.black54, size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Quick Actions: "Lokasiku saat ini" & "Pilih lewat peta"
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectCurrentGps,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.my_location_rounded, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'Lokasiku saat ini',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _openMapPicker,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 16, color: Color(0xFF00880C)),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Pilih lewat peta',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // 3. Body: Search Results OR Favorites + Recents
          Expanded(
            child: _searchFilter.isNotEmpty
                ? _buildSearchResults()
                : _buildFavoritesAndRecents(filteredFavs),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF00880C)),
              SizedBox(height: 12),
              Text('Mencari alamat di Kecamatan Pracimantoro...', style: TextStyle(fontSize: 12.5, color: Colors.black54)),
            ],
          ),
        ),
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
              Text('Coba ketik nama desa atau fasilitas publik', style: TextStyle(fontSize: 12, color: Colors.black38)),
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
            backgroundColor: const Color(0xFFE8F5E9),
            radius: 18,
            child: const Icon(Icons.location_on_rounded, color: Color(0xFF00880C), size: 20),
          ),
          title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          subtitle: Text(p.displayName, style: const TextStyle(fontSize: 11.5, color: Colors.black54), maxLines: 2),
          trailing: p.distanceText.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                  child: Text(p.distanceText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00880C))),
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
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00880C)));
    }

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
                onTap: _showAddAddressDialog,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Color(0xFF00880C)),
                      SizedBox(width: 4),
                      Text('+ Tambah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF00880C))),
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
              color: Colors.grey.shade100,
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
                        color: _favoriteCategory == 'personal' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _favoriteCategory == 'personal'
                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_rounded, size: 16, color: _favoriteCategory == 'personal' ? const Color(0xFF00880C) : Colors.grey),
                          const SizedBox(width: 6),
                          Text('Personal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _favoriteCategory == 'personal' ? const Color(0xFF00880C) : Colors.grey)),
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
                        color: _favoriteCategory == 'business' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _favoriteCategory == 'business'
                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_center_rounded, size: 16, color: _favoriteCategory == 'business' ? const Color(0xFF00880C) : Colors.grey),
                          const SizedBox(width: 6),
                          Text('Bisnis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _favoriteCategory == 'business' ? const Color(0xFF00880C) : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List Alamat Favorit
          if (filteredFavs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    _favoriteCategory == 'personal' ? Icons.home_outlined : Icons.storefront_outlined,
                    size: 32,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _favoriteCategory == 'personal' ? 'Belum ada alamat personal' : 'Belum ada alamat bisnis/toko',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  const Text('Ketuk "+ Tambah" di atas untuk menyimpan', style: TextStyle(fontSize: 11, color: Colors.black38)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isRecent ? Colors.grey.shade100 : const Color(0xFFE8F5E9),
          child: Icon(
            isRecent ? Icons.access_time_rounded : address.icon,
            size: 20,
            color: isRecent ? Colors.black54 : const Color(0xFF00880C),
          ),
        ),
        title: Text(address.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address.address, style: const TextStyle(fontSize: 11.5, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      color: Color(0xFF00880C),
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
                    color: const Color(0xFF00880C),
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
              foregroundColor: const Color(0xFF00880C),
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
                      const Icon(Icons.pin_drop_rounded, color: Color(0xFF00880C), size: 22),
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
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00880C))),
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
                        backgroundColor: const Color(0xFF00880C),
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
