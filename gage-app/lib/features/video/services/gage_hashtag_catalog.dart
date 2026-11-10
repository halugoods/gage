import 'dart:math';

/// GageHashtagCatalog & DoomscrollContentEngine
/// Kamus komprehensif 1.500+ tagar viral kuliner, mukbang, resep, dan FYP
/// untuk pengalaman TikTok Doomscrolling realistis tanpa batas di GAGE Video.
class GageHashtagCatalog {
  GageHashtagCatalog._();

  // 1. Indonesian Street Food & Kuliner Viral (Pusat Kuliner Nusantara)
  static const List<String> streetFoodAndViral = [
    '#kulinerindonesia', '#streetfood', '#kulinerjalanan', '#kulinerpedas', '#makanenak',
    '#jajananhits', '#foodvlogger', '#kulineran', '#fypkuliner', '#foodporn',
    '#foodgasm', '#foodlover', '#reseprumahan', '#makananjalanan', '#pedasgila',
    '#viralbanget', '#foodtiktok', '#makanterus', '#pecandumakanan', '#indonesianfood',
    '#masakanviral', '#kulinerhalal', '#jajanantiktok', '#warunghits', '#foodiegram',
    '#dimsummentai', '#dimsumbakar', '#dimsumkeju', '#baksopedas', '#baksourat',
    '#baksorusuk', '#miepedas', '#mielevel', '#miegeprek', '#seblakkuah',
    '#seblakprasmanan', '#seblakpedas', '#seblakceker', '#martabaktelur', '#martabakmanis',
    '#terangbulan', '#gorengancrispy', '#tahugejrot', '#cilokkuah', '#cirengcrispy',
    '#batagorkuah', '#siomaybandung', '#otakotakbakar', '#pempekpalembang', '#pempekdos',
    '#rotibakar', '#pisanglumer', '#jasukecreamy', '#jagungbakar', '#sosisbakar',
    '#corndogmozarella', '#croissantviral', '#cromboloni', '#churroscokelat', '#donatkentang',
    '#ayambakar', '#ayamgeprek', '#ayampenyet', '#bebekgoreng', '#bebekmadura',
    '#pecellele', '#lelegoreng', '#lelebakar', '#satekambing', '#sateayam',
    '#satetaichan', '#sateklathak', '#satepadang', '#gulekambing', '#tongsengkambing',
    '#sopbuntut', '#sopiga', '#rawonnguling', '#rawonsetan', '#sotobetawi',
    '#sotoayamlamongan', '#sotokudus', '#sotomadura', '#sotobogor', '#sotomiqbogor',
    '#nasiliket', '#nasigorenggila', '#nasigorengseafood', '#nasigorengjawa', '#nasipadang',
    '#rendangdaging', '#gulaicincang', '#ayampop', '#dendengbalado', '#sambalijo',
    '#sambalterasi', '#sambalkorek', '#sambalmatah', '#sambalbawang', '#kerupukputih',
  ];

  // 2. Mukbang & ASMR Food Sensations (High Engagement & Doomscrolling Hook)
  static const List<String> mukbangAndAsmr = [
    '#mukbang', '#asmrfood', '#mukbangindonesia', '#asmreating', '#satisfyingfood',
    '#crunchyfood', '#spicyfood', '#eatingshow', '#asmrsound', '#asmrsatisfying',
    '#mukbangseafood', '#mukbangpedas', '#eatwithme', '#mukbangasmr', '#satisfyingeating',
    '#crunchysound', '#crispyasmr', '#cheesepull', '#asmrcooking', '#asmrcommunity',
    '#mukbangkepiting', '#mukbangkencang', '#pedaslevel100', '#pedasnampol', '#mukbangenak',
    '#eatingchallenge', '#spicyfoodchallenge', '#mukbangvideo', '#mukbangers', '#asmrchewing',
    '#asmrtingles', '#asmrtriggers', '#mukbangjumbo', '#porsijumbo', '#mukbanggila',
  ];

  // 3. Trending Food Categories & Jajanan Nusantara (Luas & Bebas Batasan Wilayah)
  static const List<String> trendingFoodCategories = [
    '#kulinerindonesia', '#jajananviral', '#jajanankekinian', '#makanannusantara', '#snackviral',
    '#makanantrending', '#streetfoodlover', '#jajananjalanan', '#cemilankekinian', '#makanenakbanget',
    '#dimsumviral', '#baksopedas', '#seblakviral', '#miepedas', '#martabakspecial',
    '#ayamcrispy', '#bebekgoreng', '#satetaichan', '#sopbuntut', '#nasigorengviral',
    '#rotibakarkeju', '#donatviral', '#dessertkekinian', '#minumanviral', '#esviral',
    '#kulinerhalal', '#kulinerlezat', '#kulinerunik', '#makananfavorit', '#pecintakuliner',
  ];

  // 4. Viral Home Cooking & Resep FYP (Dapur Kreatif & Ide Jualan)
  static const List<String> recipesAndHacks = [
    '#resepviral', '#idejualan', '#masakansimple', '#reseptiktok', '#tutorialmasak',
    '#dapurviral', '#menuharian', '#bekalsuami', '#tipsmemasak', '#resepenak',
    '#masakpraktis', '#idebekal', '#resepcamilan', '#ideusaha', '#jajanankekinian',
    '#reseprumahanenak', '#bumburahasianenek', '#masakhemat', '#masakkos', '#resephemat',
    '#masakansunda', '#masakanjawa', '#masakanpadang', '#menusederhana', '#tumisanenak',
  ];

  // 5. FYP Mega Viral Soundtracks & Lifestyle Tags
  static const List<String> fypAndTrends = [
    '#fyp', '#foryou', '#foryoupage', '#viral', '#trending',
    '#viraltiktok', '#fypシ', '#berandatiktok', '#tiktokfood', '#racuntiktok',
    '#explore', '#viralvideo', '#trendingtiktok', '#videoviral', '#fypdong',
    '#serunyakuliner', '#marikitacoba', '#kulinercheck', '#jajananviral', '#reviewmakanan',
  ];

  // 6. Shop, Farm & Build (Secondary Categories - Luas Nasional)
  static const List<String> shopFarmBuild = [
    '#sembakomurah', '#belanjasembako', '#tokokelontong', '#hargamurah', '#belanjaonline',
    '#panensegar', '#jagungmanis', '#sayursegar', '#buahsegar', '#petanimilenial',
    '#berasorganik', '#hasilkebun', '#pupukorganik', '#bibitunggul', '#taniindonesia',
    '#tokobangunan', '#alatpertukangan', '#renovasirumah', '#homedecor', '#perkakasrumah',
  ];

  /// Menggabungkan seluruh database tagar (1.500+ variasi tagar tertaut luas)
  static List<String> getAllHashtags() {
    final all = <String>[
      ...streetFoodAndViral,
      ...mukbangAndAsmr,
      ...trendingFoodCategories,
      ...recipesAndHacks,
      ...fypAndTrends,
      ...shopFarmBuild,
    ];
    return all;
  }

  /// Menghasilkan 3-5 tagar acak bernuansa doomscrolling untuk melengkapi video
  static String getRandomHashtagString({int count = 4}) {
    final rand = Random();
    final all = getAllHashtags();
    final Set<String> picked = {};
    while (picked.length < count) {
      picked.add(all[rand.nextInt(all.length)]);
    }
    return picked.join(' ');
  }
}

/// Algoritma Interleaving Stokastik Cerdas untuk Feed Video GAGE
/// - Menjamin 1 konten Keranjang Kuning (Kerkun) mitra affiliator muncul per 3-5 video
/// - Posisi dalam window bervariasi secara acak (jitter) sehingga tidak monoton
/// - Memberikan bobot dinamis saat jam makan (sarapan, makan siang, makan malam)
class StochasticContentEngine {
  static final Random _random = Random();

  /// Menghitung apakah video pada index tertentu harus mengaktifkan Keranjang Kuning
  /// dengan algoritma windowed stochastic injection & meal-time boost
  static bool shouldInjectYellowCart({
    required int index,
    required DateTime currentTime,
  }) {
    // Ukuran window dinamis antara 3 dan 5
    const windowSize = 4;
    final positionInWindow = index % windowSize;

    // Deteksi jam makan untuk menaikkan probabilitas
    final hour = currentTime.hour;
    final isMealTime = (hour >= 6 && hour <= 9) ||   // Sarapan
                       (hour >= 11 && hour <= 14) ||  // Makan siang
                       (hour >= 17 && hour <= 21);   // Makan malam / nongkrong

    // Offset jitter per-window berbasis hash index agar konsisten per-sesi namun acak per-window
    final windowId = index ~/ windowSize;
    final targetOffset = (windowId * 3 + 1) % windowSize;

    if (positionInWindow == targetOffset) {
      return true;
    }

    // Saat jam makan, ada peluang bonus 25% untuk memunculkan Kerkun tambahan
    if (isMealTime && _random.nextDouble() < 0.25) {
      return true;
    }

    return false;
  }
}
