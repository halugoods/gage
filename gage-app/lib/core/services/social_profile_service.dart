import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/services/gage_video_feed_service.dart';
import 'package:gage_app/data/models/user_model.dart';

/// Model Statistik Sosial Profil Pengguna / Kreator GAGE
class SocialProfileStats {
  final int followingCount;
  final int followersCount;
  final int likesCount;
  final int cuanCoinBalance;

  const SocialProfileStats({
    this.followingCount = 142,
    this.followersCount = 28400,
    this.likesCount = 156000,
    this.cuanCoinBalance = 85000,
  });

  SocialProfileStats copyWith({
    int? followingCount,
    int? followersCount,
    int? likesCount,
    int? cuanCoinBalance,
  }) {
    return SocialProfileStats(
      followingCount: followingCount ?? this.followingCount,
      followersCount: followersCount ?? this.followersCount,
      likesCount: likesCount ?? this.likesCount,
      cuanCoinBalance: cuanCoinBalance ?? this.cuanCoinBalance,
    );
  }
}

/// SocialProfileService
/// Mengelola grafik sosial (Follow/Unfollow), profil kreator, grid video UGC,
/// daftar video yang disukai, etalase keranjang kuning, dan auto-deteksi akun merchant.
class SocialProfileService extends ChangeNotifier {
  static final SocialProfileService instance = SocialProfileService._internal();

  factory SocialProfileService() => instance;

  SocialProfileService._internal() {
    _loadState();
  }

  static const String _followedTargetsKey = 'gage_social_followed_targets_v1';
  static const String _likedVideoIdsKey = 'gage_social_liked_videos_v1';
  static const String _bookmarkedVideoIdsKey = 'gage_social_bookmarked_videos_v1';
  static const String _repostedVideoIdsKey = 'gage_social_reposted_videos_v1';
  static const String _userBioKey = 'gage_social_user_bio_v1';
  static const String _userHandleKey = 'gage_social_user_handle_v1';

  final Set<String> _followedTargetIds = {};
  final Set<String> _likedVideoIds = {};
  final Set<String> _bookmarkedVideoIds = {};
  final Set<String> _repostedVideoIds = {};

  String _userBio =
      'Food explorer & UMKM Pracimantoro 🍜📍 Cek video review dan rekomendasi kuliner Wonogiri!';
  String _userHandle = 'syams.djuhair';

  SocialProfileStats _currentStats = const SocialProfileStats();

  SocialProfileStats get stats => _currentStats;
  Set<String> get followedTargetIds => Set.unmodifiable(_followedTargetIds);
  Set<String> get likedVideoIds => Set.unmodifiable(_likedVideoIds);
  String get userBio => _userBio;
  String get userHandle => _userHandle;

  Future<void> updateBioAndHandle({
    required String bio,
    required String handle,
  }) async {
    _userBio = bio.trim();
    var cleanHandle = handle.trim();
    if (cleanHandle.startsWith('@')) cleanHandle = cleanHandle.substring(1);
    _userHandle = cleanHandle;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userBioKey, _userBio);
      await prefs.setString(_userHandleKey, _userHandle);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followedList = prefs.getStringList(_followedTargetsKey) ?? [];
      final likedList = prefs.getStringList(_likedVideoIdsKey) ?? [];
      final bookmarkedList = prefs.getStringList(_bookmarkedVideoIdsKey) ?? [];
      final repostedList = prefs.getStringList(_repostedVideoIdsKey) ?? [];
      final savedBio = prefs.getString(_userBioKey);
      final savedHandle = prefs.getString(_userHandleKey);

      if (savedBio != null && savedBio.isNotEmpty) _userBio = savedBio;
      if (savedHandle != null && savedHandle.isNotEmpty) _userHandle = savedHandle;

      _followedTargetIds.addAll(followedList);
      _likedVideoIds.addAll(likedList);
      _bookmarkedVideoIds.addAll(bookmarkedList);
      _repostedVideoIds.addAll(repostedList);

      // Sinkronkan likes dengan video di GageVideoFeedService
      int totalLikes = 156000 + _likedVideoIds.length * 12;
      _currentStats = _currentStats.copyWith(
        likesCount: totalLikes,
        followingCount: 142 + _followedTargetIds.length,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading social profile state: $e');
    }
  }

  /// Mengecek apakah pengguna sedang mengikuti target tertentu (kreator/toko)
  bool isFollowing(String targetId) {
    return _followedTargetIds.contains(targetId);
  }

  /// Toggle follow / unfollow target kreator atau toko mitra
  Future<bool> toggleFollow(String targetId) async {
    final nowFollowing = !_followedTargetIds.contains(targetId);
    if (nowFollowing) {
      _followedTargetIds.add(targetId);
      _currentStats = _currentStats.copyWith(
        followingCount: _currentStats.followingCount + 1,
      );
    } else {
      _followedTargetIds.remove(targetId);
      _currentStats = _currentStats.copyWith(
        followingCount: (_currentStats.followingCount - 1).clamp(0, 9999999),
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_followedTargetsKey, _followedTargetIds.toList());
    } catch (_) {}

    notifyListeners();
    return nowFollowing;
  }

  /// Toggle suka (like) video
  Future<bool> toggleLikeVideo(String videoId) async {
    final nowLiked = !_likedVideoIds.contains(videoId);
    if (nowLiked) {
      _likedVideoIds.add(videoId);
      _currentStats = _currentStats.copyWith(
        likesCount: _currentStats.likesCount + 1,
      );
    } else {
      _likedVideoIds.remove(videoId);
      _currentStats = _currentStats.copyWith(
        likesCount: (_currentStats.likesCount - 1).clamp(0, 9999999),
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_likedVideoIdsKey, _likedVideoIds.toList());
    } catch (_) {}

    notifyListeners();
    return nowLiked;
  }

  /// Mengecek apakah video telah disimpan / dibookmark
  bool isBookmarked(String videoId) {
    return _bookmarkedVideoIds.contains(videoId);
  }

  /// Toggle simpan / bookmark video
  Future<bool> toggleBookmarkVideo(String videoId) async {
    final nowBookmarked = !_bookmarkedVideoIds.contains(videoId);
    if (nowBookmarked) {
      _bookmarkedVideoIds.add(videoId);
    } else {
      _bookmarkedVideoIds.remove(videoId);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_bookmarkedVideoIdsKey, _bookmarkedVideoIds.toList());
    } catch (_) {}

    notifyListeners();
    return nowBookmarked;
  }

  /// Mengecek apakah video telah diposting ulang (reposted)
  bool isReposted(String videoId) {
    return _repostedVideoIds.contains(videoId);
  }

  /// Toggle posting ulang (repost) video
  Future<bool> toggleRepostVideo(String videoId) async {
    final nowReposted = !_repostedVideoIds.contains(videoId);
    if (nowReposted) {
      _repostedVideoIds.add(videoId);
    } else {
      _repostedVideoIds.remove(videoId);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_repostedVideoIdsKey, _repostedVideoIds.toList());
    } catch (_) {}

    notifyListeners();
    return nowReposted;
  }

  /// Mengambil daftar video yang dibuat oleh user / kreator tertentu
  List<GageVideoItem> getVideosByCreator(String creatorHandle) {
    final cleanHandle = creatorHandle.trim().toLowerCase();
    final allVideos = GageVideoFeedService.instance.videos;
    final filtered = allVideos.where((v) {
      return v.creatorHandle.toLowerCase() == cleanHandle ||
          v.creatorName.toLowerCase() == cleanHandle;
    }).toList();

    // Jika belum ada video kustom, sertakan template video dari feed
    if (filtered.isEmpty) {
      return allVideos.take(3).toList();
    }
    return filtered;
  }

  /// Mengambil daftar video yang di-like pengguna
  List<GageVideoItem> getLikedVideos() {
    final allVideos = GageVideoFeedService.instance.videos;
    if (_likedVideoIds.isEmpty) {
      // Default fallback sampel video yang disukai
      return allVideos.take(2).toList();
    }
    return allVideos.where((v) => _likedVideoIds.contains(v.id)).toList();
  }

  /// Mengambil daftar video yang disimpan / dibookmark pengguna
  List<GageVideoItem> getSavedVideos() {
    final allVideos = GageVideoFeedService.instance.videos;
    final bookmarked = allVideos
        .where((v) => _bookmarkedVideoIds.contains(v.id) || v.isBookmarked)
        .toList();
    if (bookmarked.isEmpty && allVideos.isNotEmpty) {
      return [allVideos.first];
    }
    return bookmarked;
  }

  /// Mengambil daftar video yang direpost pengguna
  List<GageVideoItem> getRepostedVideos() {
    final allVideos = GageVideoFeedService.instance.videos;
    final reposted = allVideos
        .where((v) => _repostedVideoIds.contains(v.id) || v.isReposted)
        .toList();
    if (reposted.isEmpty && allVideos.length > 1) {
      return [allVideos[1]];
    }
    return reposted;
  }

  final List<Map<String, dynamic>> _userCustomShowcase = [];
  final Set<String> _removedShowcaseProductIds = {};

  /// Menambah produk ke etalase sendiri
  Future<void> addProductToShowcase(Map<String, dynamic> product) async {
    final pId = (product['productId'] ?? product['id'])?.toString();
    if (pId == null || pId.isEmpty) return;
    _removedShowcaseProductIds.remove(pId);
    if (!_userCustomShowcase.any((p) => (p['productId'] ?? p['id'])?.toString() == pId)) {
      _userCustomShowcase.add(product);
    }
    notifyListeners();
  }

  /// Menghapus produk dari etalase sendiri
  Future<void> removeProductFromShowcase(String productId) async {
    _userCustomShowcase.removeWhere((p) => (p['productId'] ?? p['id'])?.toString() == productId);
    _removedShowcaseProductIds.add(productId);
    notifyListeners();
  }

  /// Mengecek apakah produk sudah ada di etalase
  bool isProductInShowcase(String productId) {
    if (_removedShowcaseProductIds.contains(productId)) return false;
    if (_userCustomShowcase.any((p) => (p['productId'] ?? p['id'])?.toString() == productId)) {
      return true;
    }
    final tagged = getShowcaseProducts(_userHandle);
    return tagged.any((p) => (p['productId'] ?? p['id'])?.toString() == productId);
  }

  /// Mengecek apakah produk telah dihapus dari etalase
  bool isShowcaseProductRemoved(String productId) {
    return _removedShowcaseProductIds.contains(productId);
  }

  /// Mengambil daftar produk rekomendasi / etalase keranjang kuning yang ditag kreator
  List<Map<String, dynamic>> getShowcaseProducts([String creatorHandle = '']) {
    final cleanHandle = creatorHandle.trim().toLowerCase();
    final isOwn = cleanHandle == _userHandle.toLowerCase() || cleanHandle.isEmpty;
    final videos = getVideosByCreator(creatorHandle);
    final List<Map<String, dynamic>> showcase = [];
    final Set<String> seenProductIds = {};

    if (isOwn) {
      for (final p in _userCustomShowcase) {
        final pId = (p['productId'] ?? p['id'])?.toString() ?? '';
        if (pId.isNotEmpty && !seenProductIds.contains(pId) && !_removedShowcaseProductIds.contains(pId)) {
          seenProductIds.add(pId);
          showcase.add(p);
        }
      }
    }

    for (final v in videos) {
      if (v.productId.isNotEmpty &&
          !seenProductIds.contains(v.productId) &&
          (!_removedShowcaseProductIds.contains(v.productId) || !isOwn)) {
        seenProductIds.add(v.productId);
        showcase.add({
          'productId': v.productId,
          'productTitle': v.productTitle,
          'productPrice': v.productPrice,
          'productDescription': v.productDescription,
          'merchantId': v.merchantId,
          'merchantName': v.merchantName,
          'merchantRating': v.merchantRating,
          'thumbnailUrl': v.thumbnailUrl,
          'videoRefId': v.id,
        });
      }
    }
    return showcase;
  }

  /// Cek apakah akun pengguna saat ini memiliki kios/toko resmi terdaftar
  bool isMerchantAccount(UserModel? user) {
    if (user == null) return false;
    if (user.role.toLowerCase() == 'merchant') return true;
    return false;
  }
}
