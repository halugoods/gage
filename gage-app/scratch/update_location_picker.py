path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\shared\widgets\location_picker_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _selectCurrentGps
old_select_gps = '''      // Membaca posisi GPS riil langsung dari hardware perangkat
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final gps = LatLng(position.latitude, position.longitude);'''

new_select_gps = '''      // Ambil posisi GPS riil dengan fallback cerdas ke LastKnownPosition / Cache
      final gps = await LocationService.getCurrentLocation(forceFresh: true);'''

old_catch_select = '''    } catch (e) {
      if (!mounted) return;
      setState(() => _isAcquiringGps = false);
      GageToast.show(
        context,
        'Sensor GPS sibuk atau sinyal lemah. Silakan coba lagi atau pilih lewat peta.',
        type: GageToastType.error,
      );
    }'''

new_catch_select = '''    } catch (e) {
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
    }'''

old_acquire_new = '''  Future<void> _acquireGpsForNewAddress() async {
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
  }'''

new_acquire_new = '''  Future<void> _acquireGpsForNewAddress() async {
    try {
      final latLng = await LocationService.getCurrentLocation(forceFresh: true);
      _updateSelectedPin(latLng);
      _accordionMapController.move(latLng, 17.0);
      if (mounted) {
        GageToast.show(context, 'Titik GPS berhasil diarahkan', type: GageToastType.success);
      }
    } catch (e) {
      if (mounted) {
        final fallback = LocationService.cachedOrFallback;
        _updateSelectedPin(fallback);
        _accordionMapController.move(fallback, 17.0);
        GageToast.show(context, 'Menggunakan titik lokasi tersimpan', type: GageToastType.info);
      }
    }
  }'''

if old_select_gps in content:
    content = content.replace(old_select_gps, new_select_gps)
    print("Replaced old_select_gps")
else:
    print("WARNING: old_select_gps not found!")

if old_catch_select in content:
    content = content.replace(old_catch_select, new_catch_select)
    print("Replaced old_catch_select")
else:
    print("WARNING: old_catch_select not found!")

if old_acquire_new in content:
    content = content.replace(old_acquire_new, new_acquire_new)
    print("Replaced old_acquire_new")
else:
    print("WARNING: old_acquire_new not found!")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated location_picker_sheet.dart successfully!")
