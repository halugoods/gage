import 'package:flutter/foundation.dart';

/// Model Data Komentar Video GAGE (Mendukung Threaded / Nested Replies)
class GageVideoComment {
  final String id;
  final String username;
  final String text;
  final String timeAgo;
  int likes;
  final String? replyToUsername;
  final List<GageVideoComment> replies;

  GageVideoComment({
    String? id,
    required this.username,
    required this.text,
    required this.timeAgo,
    this.likes = 0,
    this.replyToUsername,
    List<GageVideoComment>? replies,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        replies = replies ?? [];
}

/// Model Data Katalog Video Kuliner & UMKM Lokal GAGE (Pracimantoro, Wonogiri)
class GageVideoItem {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String creatorHandle;
  final String creatorName;
  final String creatorAvatarUrl;
  final bool isCreatorVerified;
  final String caption;
  final String merchantId;
  final String merchantName;
  final double merchantRating;
  final String merchantLocation;
  final String merchantAddress;
  final String deliveryEstimate;
  final String productId;
  final String productTitle;
  final int productPrice;
  final int? originalPrice;
  final String productDescription;
  int likesCount;
  int commentsCount;
  int bookmarksCount;
  int sharesCount;
  int repostsCount;
  bool isLiked;
  bool isBookmarked;
  bool isFollowing;
  bool isReposted;
  final List<GageVideoComment> sampleComments;

  GageVideoItem({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.creatorHandle,
    required this.creatorName,
    required this.creatorAvatarUrl,
    this.isCreatorVerified = true,
    required this.caption,
    required this.merchantId,
    required this.merchantName,
    required this.merchantRating,
    required this.merchantLocation,
    required this.merchantAddress,
    required this.deliveryEstimate,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    this.originalPrice,
    required this.productDescription,
    required this.likesCount,
    required this.commentsCount,
    required this.bookmarksCount,
    required this.sharesCount,
    this.repostsCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isFollowing = false,
    this.isReposted = false,
    List<GageVideoComment>? sampleComments,
  }) : sampleComments = sampleComments ?? [];
}

/// GageVideoFeedService
/// Mengelola katalog feed video komunitas UMKM Pracimantoro dan integrasi Keranjang Kuning
class GageVideoFeedService extends ChangeNotifier {
  static final GageVideoFeedService instance = GageVideoFeedService._internal();

  factory GageVideoFeedService() => instance;

  GageVideoFeedService._internal() {
    _initDefaultVideos();
  }

  final List<GageVideoItem> _videos = [];

  List<GageVideoItem> get videos => List.unmodifiable(_videos);

  void _initDefaultVideos() {
    _videos.addAll([
      GageVideoItem(
        id: 'vid-praci-01',
        videoUrl: 'assets/videos/vt_bakso_urat.mp4',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&q=80',
        creatorHandle: '@wonogirifoodie',
        creatorName: 'Wonogiri Foodie',
        creatorAvatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
        caption:
            'Bakso Urat Jumbo Pracimantoro, kuah ngaldu pol! 🍲🔥 Tetelan melimpah, sambal rawitnya nampol banget buat makan siang #wonogiri #gagekuliner #pracimantoro',
        merchantId: 'mch-bakso-masno',
        merchantName: 'RM Bakso Mas No',
        merchantRating: 4.8,
        merchantLocation: 'Pracimantoro',
        merchantAddress: 'Jl. Raya Pracimantoro - Wonogiri (Utara SPBU Praci)',
        deliveryEstimate: '10-15 mnt',
        productId: 'prd-bakso-urat-01',
        productTitle: 'Bakso Urat Jumbo',
        productPrice: 15000,
        originalPrice: 18000,
        productDescription:
            '1 bakso urat jumbo daging sapi asli + 4 bakso halus, mie kuning, bihun, sawi, tetelan, dan kuah kaldu sapi gurih.',
        likesCount: 12400,
        commentsCount: 248,
        bookmarksCount: 892,
        sharesCount: 1200,
        sampleComments: [
          GageVideoComment(
            id: 'c-praci-01',
            username: '@nisa_praci',
            text: 'Langgananku tiap pulang kerja, tetelannya gak pelit!',
            timeAgo: '12m lalu',
            likes: 34,
            replies: [
              GageVideoComment(
                id: 'r-praci-01-1',
                username: '@wonogirifoodie',
                text: '@nisa_praci Kuahnya juga gurih rempah banget kak!',
                timeAgo: '8m lalu',
                likes: 6,
                replyToUsername: '@nisa_praci',
              ),
              GageVideoComment(
                id: 'r-praci-01-2',
                username: '@dimas.wng',
                text: '@nisa_praci Tambah tetelan cuma Rp 5rb puas pol.',
                timeAgo: '5m lalu',
                likes: 3,
                replyToUsername: '@nisa_praci',
              ),
            ],
          ),
          GageVideoComment(
            id: 'c-praci-02',
            username: '@dimas.wng',
            text:
                'Baru aja order lewat GAGE 10 menit langsung sampe masih panas 🔥',
            timeAgo: '1j lalu',
            likes: 19,
          ),
        ],
      ),
      GageVideoItem(
        id: 'vid-praci-02',
        videoUrl: 'assets/videos/vt_seblak_pedas.mp4',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=400&q=80',
        creatorHandle: '@jajanpraci',
        creatorName: 'Jajan Pracimantoro',
        creatorAvatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
        caption:
            'Dimsum ayam udang hangat lumer di mulut! 🥟✨ Chili oil-nya pedas gurih bikin nagih, cocok buat camilan sore bareng keluarga #dimsumsewu #jajananwonogiri #gagefood',
        merchantId: 'm-dimsum-sewu',
        merchantName: 'Dimsum Sewu Praci',
        merchantRating: 4.9,
        merchantLocation: 'Pracimantoro',
        merchantAddress: 'Depan Pasar Pracimantoro, Wonogiri',
        deliveryEstimate: '10-12 mnt',
        productId: 'prd-dimsum-mix-01',
        productTitle: 'Dimsum Ayam Mix Chili Oil',
        productPrice: 12000,
        originalPrice: 15000,
        productDescription:
            'Porsi isi 4 pcs dimsum ayam udang premium topping wortel, jamur, keju, lengkap dengan saus dimsum & chili oil.',
        likesCount: 8750,
        commentsCount: 164,
        bookmarksCount: 640,
        sharesCount: 530,
        sampleComments: [
          GageVideoComment(
            username: '@tyas.putri',
            text: 'Chili oil-nya juara sih ini, wajib nambah porsi!',
            timeAgo: '28m lalu',
            likes: 22,
          ),
        ],
      ),
      GageVideoItem(
        id: 'vid-praci-03',
        videoUrl: 'assets/videos/vt_kopi_susu.mp4',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&q=80',
        creatorHandle: '@kopikita.wng',
        creatorName: 'Kopi Kita Wonogiri',
        creatorAvatarUrl:
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&q=80',
        caption:
            'Es Kopi Susu Gula Aren creamy buat nemenin lembur atau nongkrong santai di Praci ☕🧊 Manisnya pas, kopinya berasa! #kopisusu #pracimantoro #gageapp',
        merchantId: 'mrc-kopi-gula-aren',
        merchantName: 'Kopi Senja Praci',
        merchantRating: 4.7,
        merchantLocation: 'Pracimantoro',
        merchantAddress: 'Jl. Pemuda No. 18, Pracimantoro, Wonogiri',
        deliveryEstimate: '12-18 mnt',
        productId: 'prd-kopi-aren-01',
        productTitle: 'Es Kopi Susu Aren Creamy',
        productPrice: 14000,
        productDescription:
            'Double shot espresso robusta pilihan dengan susu segar UHT dan gula aren organik asli Wonogiri.',
        likesCount: 5420,
        commentsCount: 93,
        bookmarksCount: 410,
        sharesCount: 315,
        sampleComments: [
          GageVideoComment(
            username: '@bayu_satria',
            text: 'Espresso-nya mantap, gak bikin kembung!',
            timeAgo: '42m lalu',
            likes: 15,
          ),
        ],
      ),
      GageVideoItem(
        id: 'vid-praci-04',
        videoUrl: 'assets/videos/vt_rocket_chicken.mp4',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1562967914-608f82629710?w=400&q=80',
        creatorHandle: '@kuliner.praci',
        creatorName: 'Kuliner Praci',
        creatorAvatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
        caption:
            'Paket Geprek 1 Rocket Chicken Pracimantoro renyah gurih pedas nampol! Hemat kenyang puas 🍗🔥 #rocketchicken #gagekuliner',
        merchantId: 'mch-rc-01',
        merchantName: 'Rocket Chicken Pracimantoro',
        merchantRating: 4.9,
        merchantLocation: 'Pracimantoro',
        merchantAddress: 'Jl. Raya Pracimantoro No. 45',
        deliveryEstimate: '10-15 mnt',
        productId: 'prd-rc-geprek-01',
        productTitle: 'Paket Geprek 1 (Ayam + Nasi + Es Teh)',
        productPrice: 16000,
        productDescription:
            'Ayam goreng krispi dibalut sambal geprek pedas gurih, disajikan dengan nasi pulen hangat dan es teh manis.',
        likesCount: 14200,
        commentsCount: 310,
        bookmarksCount: 920,
        sharesCount: 1450,
        sampleComments: [],
      ),
      GageVideoItem(
        id: 'vid-praci-05',
        videoUrl: 'assets/videos/vt_mie_ayam.mp4',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&q=80',
        creatorHandle: '@solodelicious',
        creatorName: 'Solo Delicious',
        creatorAvatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
        caption:
            'Mie Ayam Bakso Ceker Pak Kumis Pracimantoro! Kuah kental manis gurih khas Wonogiri 🍜🥢 #mieayampakkuims #gagefood',
        merchantId: 'mch-mie-01',
        merchantName: 'Mie Ayam & Bakso Pak Kumis',
        merchantRating: 4.8,
        merchantLocation: 'Pracimantoro',
        merchantAddress: 'Pasar Pracimantoro Kios No. 12',
        deliveryEstimate: '12-16 mnt',
        productId: 'prd-mie-ceker-01',
        productTitle: 'Mie Ayam Ceker Jumbo',
        productPrice: 15000,
        productDescription:
            'Mie kenyal racikan sendiri dengan topping ayam kecap melimpah, 2 ceker empuk, dan kuah kaldu rempah.',
        likesCount: 9600,
        commentsCount: 180,
        bookmarksCount: 710,
        sharesCount: 880,
        sampleComments: [],
      ),
    ]);
  }

  /// Menambahkan video baru yang diunggah affiliator dengan Keranjang Kuning tersemat
  void addVideo(GageVideoItem item) {
    _videos.insert(0, item);
    notifyListeners();
  }

  /// Toggle suka (like) video
  void toggleLike(String videoId) {
    final idx = _videos.indexWhere((v) => v.id == videoId);
    if (idx != -1) {
      final item = _videos[idx];
      item.isLiked = !item.isLiked;
      item.likesCount += item.isLiked ? 1 : -1;
      notifyListeners();
    }
  }

  /// Toggle simpan / bookmark video ke profil
  void toggleBookmark(String videoId) {
    final idx = _videos.indexWhere((v) => v.id == videoId);
    if (idx != -1) {
      final item = _videos[idx];
      item.isBookmarked = !item.isBookmarked;
      item.bookmarksCount += item.isBookmarked ? 1 : -1;
      notifyListeners();
    }
  }

  /// Toggle posting ulang (repost) video
  void toggleRepost(String videoId) {
    final idx = _videos.indexWhere((v) => v.id == videoId);
    if (idx != -1) {
      final item = _videos[idx];
      item.isReposted = !item.isReposted;
      item.repostsCount += item.isReposted ? 1 : -1;
      notifyListeners();
    }
  }

  /// Toggle mengikuti kreator video
  void toggleFollow(String videoId) {
    final idx = _videos.indexWhere((v) => v.id == videoId);
    if (idx != -1) {
      final item = _videos[idx];
      item.isFollowing = !item.isFollowing;
      notifyListeners();
    }
  }

  /// Menambahkan komentar utama atau balasan bersarang (nested reply)
  void addComment(String videoId, GageVideoComment comment, {String? parentCommentId}) {
    final idx = _videos.indexWhere((v) => v.id == videoId);
    if (idx != -1) {
      final item = _videos[idx];
      if (parentCommentId != null) {
        final parent = item.sampleComments.firstWhere(
          (c) => c.id == parentCommentId,
          orElse: () => item.sampleComments.first,
        );
        parent.replies.add(comment);
      } else {
        item.sampleComments.insert(0, comment);
      }
      item.commentsCount += 1;
      notifyListeners();
    }
  }

  List<GageVideoItem> get bookmarkedVideos =>
      _videos.where((v) => v.isBookmarked).toList();

  List<GageVideoItem> get repostedVideos =>
      _videos.where((v) => v.isReposted).toList();

  List<GageVideoItem> get likedVideos =>
      _videos.where((v) => v.isLiked).toList();
}
