p = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\shared\widgets\location_picker_sheet.dart'
with open(p, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("""    } catch (e) {
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
    }""", """    } catch (e) {
      final fallbackGps = LocationService.cachedOrFallback;
      final addr = await OsmGeocodingService.reverseGeocode(fallbackGps);
      final fullAddr = OsmGeocodingService.formatFullOfficialAddress(fallbackGps);
      if (!mounted) return;
      setState(() => _isAcquiringGps = false);
      Navigator.pop(context);
      widget.onSelected(addr, fullAddr, fallbackGps);
      GageToast.show(
        context,
        'Menggunakan lokasi GPS tersimpan',
        type: GageToastType.info,
      );
    }""")

text = text.replace("""          if (context.mounted) {
            Navigator.pop(context);
          }
          widget.onSelected(title, fullAddr, latLng);""", """          widget.onSelected(title, fullAddr, latLng);""")

text = text.replace("""            await UserAddressService.addRecent(UserSavedAddress(
              id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
              name: p.title,
              address: p.displayName,
              category: 'personal',
              latitude: p.location.latitude,
              longitude: p.location.longitude,
            ));
            Navigator.pop(context);
            widget.onSelected(p.title, p.displayName, p.location);""", """            await UserAddressService.addRecent(UserSavedAddress(
              id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
              name: p.title,
              address: p.displayName,
              category: 'personal',
              latitude: p.location.latitude,
              longitude: p.location.longitude,
            ));
            if (mounted) {
              Navigator.pop(context);
            }
            widget.onSelected(p.title, p.displayName, p.location);""")

with open(p, 'w', encoding='utf-8') as f:
    f.write(text)

print("Cleaned lints in location_picker_sheet.dart!")
