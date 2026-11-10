# 1. Update location_service.dart
loc_path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\core\services\location_service.dart'
with open(loc_path, 'r', encoding='utf-8') as f:
    loc_text = f.read()

old_loc = """      // 2. Ambil getLastKnownPosition dari OS Android (0ms response instant jika ada)
      if (!forceFresh) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final result = LatLng(last.latitude, last.longitude);
          _cachedLocation = result;
          return result;
        }
      }

      // 3. Request GPS aktual dengan akurasi balanced/medium dan timeout cepat (max 4 detik)
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        final result = LatLng(position.latitude, position.longitude);
        _cachedLocation = result;
        return result;
      } catch (_) {
        // Fallback cepat ke getLastKnownPosition jika satelit indoor timeout
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final result = LatLng(last.latitude, last.longitude);
          _cachedLocation = result;
          return result;
        }
        return _cachedLocation ?? defaultLocation;
      }"""

new_loc = """      // 2. Ambil getLastKnownPosition dari OS Android (0ms response instant jika ada)
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && !forceFresh) {
        final result = LatLng(last.latitude, last.longitude);
        _cachedLocation = result;
        return result;
      }

      // 3. Request GPS aktual dengan akurasi high dan timeout 5 detik
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        final result = LatLng(position.latitude, position.longitude);
        _cachedLocation = result;
        return result;
      } catch (_) {
        // Fallback cepat ke getLastKnownPosition jika satelit indoor timeout
        if (last != null) {
          final result = LatLng(last.latitude, last.longitude);
          _cachedLocation = result;
          return result;
        }
        return _cachedLocation ?? defaultLocation;
      }"""

assert old_loc in loc_text, "old_loc not found"
loc_text = loc_text.replace(old_loc, new_loc)

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(loc_text)
print("SUCCESS: Updated location_service.dart!")

# 2. Update location_picker_sheet.dart
sheet_path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\shared\widgets\location_picker_sheet.dart'
with open(sheet_path, 'r', encoding='utf-8') as f:
    sheet_text = f.read()

# Fix _selectCurrentGps
old_select_gps = """      if (!mounted) return;
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
      final fallbackGps = LocationService.cachedOrFallback;
      final addr = await OsmGeocodingService.reverseGeocode(fallbackGps);
      setState(() {
        _activePreviewLocation = fallbackGps;
        _selectedPin = fallbackGps;
        _activePreviewTitle = addr;
        _detectedAddr = addr;
        _hasPinMoved = true;
        _isAcquiringGps = false;
      });
      _miniMapController.move(fallbackGps, 16.5);
      GageToast.show(
        context,
        'Peta diarahkan ke lokasi GPS tersimpan',
        type: GageToastType.info,
      );
    }"""

new_select_gps = """      if (!mounted) return;
      setState(() => _isAcquiringGps = false);
      Navigator.pop(context);
      widget.onSelected(addr, fullAddr, gps);
      GageToast.show(
        context,
        'Lokasi saat ini berhasil dipilih',
        type: GageToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      final fallbackGps = LocationService.cachedOrFallback;
      final addr = await OsmGeocodingService.reverseGeocode(fallbackGps);
      final fullAddr = OsmGeocodingService.formatFullOfficialAddress(fallbackGps);
      setState(() => _isAcquiringGps = false);
      Navigator.pop(context);
      widget.onSelected(addr, fullAddr, fallbackGps);
      GageToast.show(
        context,
        'Menggunakan lokasi GPS tersimpan',
        type: GageToastType.info,
      );
    }"""

assert old_select_gps in sheet_text, "old_select_gps not found"
sheet_text = sheet_text.replace(old_select_gps, new_select_gps)

# Fix _openMapPicker callback to pop the sheet
old_map_pick = """          await UserAddressService.addRecent(UserSavedAddress(
            id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
            name: title,
            address: fullAddr,
            category: 'personal',
            latitude: latLng.latitude,
            longitude: latLng.longitude,
          ));
          widget.onSelected(title, fullAddr, latLng);"""

new_map_pick = """          await UserAddressService.addRecent(UserSavedAddress(
            id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
            name: title,
            address: fullAddr,
            category: 'personal',
            latitude: latLng.latitude,
            longitude: latLng.longitude,
          ));
          if (context.mounted) {
            Navigator.pop(context);
          }
          widget.onSelected(title, fullAddr, latLng);"""

assert old_map_pick in sheet_text, "old_map_pick not found"
sheet_text = sheet_text.replace(old_map_pick, new_map_pick)

# Fix 'Pakai Lokasi Ini' button on preview card
old_apply_btn = """                      onPressed: () {
                        setState(() => _hasPinMoved = false);
                        widget.onSelected(addressLabel, fullAddressLabel, center);
                        GageToast.show(context, 'Titik lokasi berhasil dikunci', type: GageToastType.success);
                      },"""

new_apply_btn = """                      onPressed: () {
                        setState(() => _hasPinMoved = false);
                        Navigator.pop(context);
                        widget.onSelected(addressLabel, fullAddressLabel, center);
                        GageToast.show(context, 'Titik lokasi berhasil dikunci', type: GageToastType.success);
                      },"""

assert old_apply_btn in sheet_text, "old_apply_btn not found"
sheet_text = sheet_text.replace(old_apply_btn, new_apply_btn)

# Fix search result selection to pop the sheet
old_search_tap = """            await UserAddressService.addRecent(UserSavedAddress(
              id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
              name: p.title,
              address: p.displayName,
              category: 'personal',
              latitude: p.location.latitude,
              longitude: p.location.longitude,
            ));
            widget.onSelected(p.title, p.displayName, p.location);"""

new_search_tap = """            await UserAddressService.addRecent(UserSavedAddress(
              id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
              name: p.title,
              address: p.displayName,
              category: 'personal',
              latitude: p.location.latitude,
              longitude: p.location.longitude,
            ));
            Navigator.pop(context);
            widget.onSelected(p.title, p.displayName, p.location);"""

assert old_search_tap in sheet_text, "old_search_tap not found"
sheet_text = sheet_text.replace(old_search_tap, new_search_tap)

with open(sheet_path, 'w', encoding='utf-8') as f:
    f.write(sheet_text)
print("SUCCESS: Updated location_picker_sheet.dart!")
