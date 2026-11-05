class FoodCategory {
  final String id;
  final String name;
  final String image;
  final String description;

  const FoodCategory({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
  });
}

class FoodCategoriesData {
  static const List<FoodCategory> allCategories = [
    FoodCategory(
      id: 'cat-nasi',
      name: 'Nasi',
      image: 'assets/images/cat_nasi.png',
      description: 'Nasi goreng, nasi uduk, ramesan, dan penyetan',
    ),
    FoodCategory(
      id: 'cat-mie',
      name: 'Mie & Bakso',
      image: 'assets/images/cat_mie.png',
      description: 'Mie ayam, bakso urat, pangsit, dan kwetiau',
    ),
    FoodCategory(
      id: 'cat-ayam',
      name: 'Ayam & Bebek',
      image: 'assets/images/cat_ayam.png',
      description: 'Ayam goreng, ayam bakar, bebek ungkep, dan kremes',
    ),
    FoodCategory(
      id: 'cat-cepat-saji',
      name: 'Cepat Saji',
      image: 'assets/images/cat_cepat_saji.png',
      description: 'Fried chicken, burger, french fries, dan nuggets',
    ),
    FoodCategory(
      id: 'cat-dimsum',
      name: 'Jajanan & Dimsum',
      image: 'assets/images/cat_dimsum.png',
      description: 'Dimsum sewu, siomay, mentai, dan gorengan hangat',
    ),
    FoodCategory(
      id: 'cat-sate',
      name: 'Sate & Bakaran',
      image: 'assets/images/cat_sate.png',
      description: 'Sate ayam madura, sate kambing, dan tongseng',
    ),
    FoodCategory(
      id: 'cat-seblak',
      name: 'Seblak & Pedas',
      image: 'assets/images/cat_seblak.png',
      description: 'Seblak prasmanan, ceker mercon, dan makaroni pedas',
    ),
    FoodCategory(
      id: 'cat-minuman',
      name: 'Minuman Segar',
      image: 'assets/images/cat_minuman.png',
      description: 'Es teh jumbo, jus buah segar, boba, dan squash',
    ),
    FoodCategory(
      id: 'cat-kopi',
      name: 'Kopi & Teh',
      image: 'assets/images/cat_kopi.png',
      description: 'Kopi susu gula aren, espresso, matcha, dan teh tarik',
    ),
    FoodCategory(
      id: 'cat-martabak',
      name: 'Martabak',
      image: 'assets/images/cat_martabak.png',
      description: 'Martabak manis bangka, telur bebek, dan tipker',
    ),
    FoodCategory(
      id: 'cat-roti',
      name: 'Roti & Bakery',
      image: 'assets/images/cat_roti.png',
      description: 'Roti bakar gembong, bolu kukus, donat, dan pastry',
    ),
    FoodCategory(
      id: 'cat-seafood',
      name: 'Seafood & Ikan',
      image: 'assets/images/cat_seafood.png',
      description: 'Ikan bakar nila/gurame, cumi saus padang, dan udang',
    ),
    FoodCategory(
      id: 'cat-soto',
      name: 'Soto & Sop',
      image: 'assets/images/cat_soto.png',
      description: 'Soto ayam lamongan, soto sapi bening, dan sop iga',
    ),
    FoodCategory(
      id: 'cat-padang',
      name: 'Masakan Padang',
      image: 'assets/images/cat_padang.png',
      description: 'Rendang daging sapi, ayam pop, gulai tunjang, dan dendeng',
    ),
    FoodCategory(
      id: 'cat-bubur',
      name: 'Bubur & Sarapan',
      image: 'assets/images/cat_bubur.png',
      description: 'Bubur ayam cirebon, nasi kuning, lontong sayur, dan liwet',
    ),
    FoodCategory(
      id: 'cat-jajanan',
      name: 'Kue Tradisional',
      image: 'assets/images/cat_jajanan.png',
      description: 'Klepon, lemper, onde-onde, pukis, dan jajan pasar legendaris',
    ),
  ];
}
