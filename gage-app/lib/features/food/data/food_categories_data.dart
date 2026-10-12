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
      name: 'Aneka Nasi',
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
      id: 'cat-roti',
      name: 'Roti & Bakery',
      image: 'assets/images/dish_roti_cokelat.png',
      description: 'Roti gembong, bolu kukus, donat, dan roti manis',
    ),
    FoodCategory(
      id: 'cat-seafood',
      name: 'Seafood & Ikan',
      image: 'assets/images/dish_bakso_urat.png',
      description: 'Ikan bakar nila/gurame, cumi saus padang, dan udang',
    ),
    FoodCategory(
      id: 'cat-soto',
      name: 'Soto & Sop',
      image: 'assets/images/dish_mie_ayam.png',
      description: 'Soto ayam lamongan, soto sapi bening, dan sop iga',
    ),
    FoodCategory(
      id: 'cat-dessert',
      name: 'Dessert & Es Krim',
      image: 'assets/images/dish_es_teh.png',
      description: 'Es campur, es teler, es krim sundae, dan puding',
    ),
    FoodCategory(
      id: 'cat-sarapan',
      name: 'Sarapan Pagi',
      image: 'assets/images/cat_nasi.png',
      description: 'Bubur ayam, nasi kuning, lontong sayur, dan nasi liwet',
    ),
    FoodCategory(
      id: 'cat-camilan',
      name: 'Camilan & Oleh-Oleh',
      image: 'assets/images/cat_dimsum.png',
      description: 'Keripik tempe, emping, rengginang, dan camilan gurih',
    ),
  ];
}
