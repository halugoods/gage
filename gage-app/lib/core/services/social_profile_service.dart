import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/services/gage_video_feed_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
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

  final Set<String> _followedTargetIds = {};
  final Set<String> _likedVideoIds = {};

  SocialProfileStats _currentStats = const SocialProfileStats();

  SocialProfileStats get stats => _currentStats;
  Set<String> get followedTargetIds => Set.unmodifiable(_followedTargetIds);
  Set<String> get likedVideoIds => Set.unmodifiable(_likedVideoIds);

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followedList = prefs.getStringList(_followedTargetsKey) ?? [];
      final likedList = prefs.getStringList(_likedVideoIdsKey) ?? [];

      _followedTargetIds.addAll(followedList);
      _likedVideoIds.addAll(likedList);

      // Sinkronkan likes dengan video di GageVideoFeedService
      final allVideos = GageVideoFeedService.instance.videos;
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

  /// Mengambil daftar produk rekomendasi / etalase keranjang kuning yang ditag kreator
  List<Map<String, dynamic>> getShowcaseProducts(String creatorHandle) {
    final videos = getVideosByCreator(creatorHandle);
    final List<Map<String, dynamic>> showcase = [];
    final Set<String> seenProductIds = {};

    for (final v in videos) {
      if (v.productId.isNotEmpty && !seenProductIds.contains(v.productId)) {
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
