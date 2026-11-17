import 'package:flutter/foundation.dart';

/// Model untuk Musik / Suara di GAGE Video (TikTok / IG Reels style)
class GageSound {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final String audioAsset;
  final String duration;
  final int videoCount;
  final bool isOriginalSound;
  bool isSaved;

  GageSound({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.audioAsset,
    required this.duration,
    required this.videoCount,
    this.isOriginalSound = false,
    this.isSaved = false,
  });

  GageSound copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArtUrl,
    String? audioAsset,
    String? duration,
    int? videoCount,
    bool? isOriginalSound,
    bool? isSaved,
  }) {
    return GageSound(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      audioAsset: audioAsset ?? this.audioAsset,
      duration: duration ?? this.duration,
      videoCount: videoCount ?? this.videoCount,
      isOriginalSound: isOriginalSound ?? this.isOriginalSound,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

/// Singleton Service Pengelola Musik / Suara GAGE Video
class GageSoundService extends ChangeNotifier {
  GageSoundService._();
  static final GageSoundService instance = GageSoundService._();

  final List<GageSound> _sounds = [
    GageSound(
      id: 'sound-wonogiri-foodie-01',
      title: 'Suara Asli - Wonogiri Foodie',
      artist: '@wonogirifoodie',
      albumArtUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947',
      audioAsset: 'assets/videos/watermarked/vt_mie_ayam_wm.mp4',
      duration: '0:30',
      videoCount: 1420,
      isOriginalSound: true,
      isSaved: true,
    ),
    GageSound(
      id: 'sound-dangdut-koplo-praci',
      title: 'Koplo Asik Pracimantoro (Remix)',
      artist: 'GAGE Audio Labs',
      albumArtUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4',
      audioAsset: 'assets/videos/watermarked/vt_rocket_chicken_wm.mp4',
      duration: '0:45',
      videoCount: 3890,
      isOriginalSound: false,
      isSaved: false,
    ),
    GageSound(
      id: 'sound-acoustic-sore-gage',
      title: 'Sore Santai Wonogiri (Acoustic)',
      artist: 'Pracimantoro Beats',
      albumArtUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819',
      audioAsset: 'assets/videos/watermarked/vt_seblak_pedas_wm.mp4',
      duration: '0:35',
      videoCount: 920,
      isOriginalSound: false,
      isSaved: false,
    ),
    GageSound(
      id: 'sound-cuan-beats-01',
      title: 'Gage Cuan Semangat UMKM',
      artist: 'Halu Goods Indonesia',
      albumArtUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745',
      audioAsset: 'assets/videos/watermarked/vt_rocket_chicken_wm.mp4',
      duration: '0:28',
      videoCount: 650,
      isOriginalSound: false,
      isSaved: false,
    ),
  ];

  final Set<String> _savedSoundIds = {'sound-wonogiri-foodie-01'};

  List<GageSound> get sounds => List.unmodifiable(_sounds);

  List<GageSound> get savedSounds =>
      _sounds.where((s) => _savedSoundIds.contains(s.id)).toList();

  GageSound? getSoundById(String id) {
    try {
      return _sounds.firstWhere((s) => s.id == id);
    } catch (_) {
      return _sounds.first;
    }
  }

  bool isSoundSaved(String id) => _savedSoundIds.contains(id);

  bool toggleSaveSound(String id) {
    final sound = getSoundById(id);
    if (sound == null) return false;

    if (_savedSoundIds.contains(id)) {
      _savedSoundIds.remove(id);
      sound.isSaved = false;
      notifyListeners();
      return false;
    } else {
      _savedSoundIds.add(id);
      sound.isSaved = true;
      notifyListeners();
      return true;
    }
  }
}
