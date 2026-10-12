import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';

/// Database Fundamental Titik Lokasi & POI Kecamatan Pracimantoro, Wonogiri
/// Digunakan sebagai Algoritma Pencarian Lokal Utama (Tier 1 Priority) di Gage Pracimantoro.
class PracimantoroPlacesDatabase {
  // Koordinat Titik Pusat Kota / Kecamatan Pracimantoro
  static const LatLng centerPracimantoro = LatLng(-8.05517, 110.80889);

  /// Master Dataset Titik Lokasi Resmi di Kecamatan Pracimantoro & Tetangga Terdekat
  static final List<LocalPlaceRecord> allPlaces = [
    // ══════════════════════════════════════════════════════════════════════
    // 1. PENDIDIKAN (SD, SMP, SMA, SMK, MI, MTS, TK)
    // ══════════════════════════════════════════════════════════════════════
    LocalPlaceRecord(
      name: 'SD Muhammadiyah Program Khusus Pracimantoro',
      shortName: 'SD Muhammadiyah PK Pracimantoro',
      category: 'Pendidikan',
      address: 'Jl. Taruna HS Km. 0,3, Pracimantoro, Wonogiri (57664)',
      location: const LatLng(-8.05460, 110.80660),
      isPrimaryScope: true,
      aliases: [
        'sd muhammadiyah',
        'sd muhammadiyah pk',
        'sd muhammadiyah program khusus',
        'sd pk pracimantoro',
        'sd muhammadiyah pracimantoro',
        'sdmpk',
        'sdm pk',
        'sekolah dasar muhammadiyah',
      ],
    ),
    LocalPlaceRecord(
      name: 'SDIT Nurul Huda Pracimantoro',
      shortName: 'SDIT Nurul Huda',
      category: 'Pendidikan',
      address: 'Jl. Raya Pracimantoro, Wonogiri',
      location: const LatLng(-8.05350, 110.80780),
      isPrimaryScope: true,
      aliases: ['sdit', 'sdit nurul huda', 'nurul huda pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Pracimantoro',
      shortName: 'SDN 1 Pracimantoro',
      category: 'Pendidikan',
      address: 'Jl. Raya Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05520, 110.80910),
      isPrimaryScope: true,
      aliases: ['sdn 1 pracimantoro', 'sd 1 pracimantoro', 'sd negeri 1'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 2 Pracimantoro',
      shortName: 'SDN 2 Pracimantoro',
      category: 'Pendidikan',
      address: 'Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05380, 110.81050),
      isPrimaryScope: true,
      aliases: ['sdn 2 pracimantoro', 'sd 2 pracimantoro', 'sd negeri 2'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 3 Pracimantoro',
      shortName: 'SDN 3 Pracimantoro',
      category: 'Pendidikan',
      address: 'Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05650, 110.81180),
      isPrimaryScope: true,
      aliases: ['sdn 3 pracimantoro', 'sd 3 pracimantoro', 'sd negeri 3'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Sambiroto',
      shortName: 'SDN 1 Sambiroto',
      category: 'Pendidikan',
      address: 'Desa Sambiroto, Kec. Pracimantoro',
      location: const LatLng(-8.07650, 110.84450),
      isPrimaryScope: true,
      aliases: ['sdn 1 sambiroto', 'sd sambiroto'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Tubokarto',
      shortName: 'SDN 1 Tubokarto',
      category: 'Pendidikan',
      address: 'Desa Tubokarto, Kec. Pracimantoro',
      location: const LatLng(-8.02450, 110.82280),
      isPrimaryScope: true,
      aliases: ['sdn 1 tubokarto', 'sd tubokarto'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Joho',
      shortName: 'SDN 1 Joho',
      category: 'Pendidikan',
      address: 'Desa Joho, Kec. Pracimantoro',
      location: const LatLng(-8.09450, 110.79580),
      isPrimaryScope: true,
      aliases: ['sdn 1 joho', 'sd joho'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 2 Joho',
      shortName: 'SDN 2 Joho',
      category: 'Pendidikan',
      address: 'Desa Joho, Kec. Pracimantoro',
      location: const LatLng(-8.09539, 110.79631),
      isPrimaryScope: true,
      aliases: ['sdn 2 joho', 'sd 2 joho'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Gedong',
      shortName: 'SDN 1 Gedong',
      category: 'Pendidikan',
      address: 'Desa Gedong, Kec. Pracimantoro',
      location: const LatLng(-8.06380, 110.78580),
      isPrimaryScope: true,
      aliases: ['sdn 1 gedong', 'sd gedong'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Suci',
      shortName: 'SDN 1 Suci',
      category: 'Pendidikan',
      address: 'Desa Suci, Kec. Pracimantoro',
      location: const LatLng(-8.08480, 110.85120),
      isPrimaryScope: true,
      aliases: ['sdn 1 suci', 'sd suci'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Gambirmanis',
      shortName: 'SDN 1 Gambirmanis',
      category: 'Pendidikan',
      address: 'Desa Gambirmanis, Kec. Pracimantoro',
      location: const LatLng(-8.11120, 110.84600),
      isPrimaryScope: true,
      aliases: ['sdn 1 gambirmanis', 'sd gambirmanis'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Gebangharjo',
      shortName: 'SDN 1 Gebangharjo',
      category: 'Pendidikan',
      address: 'Desa Gebangharjo, Kec. Pracimantoro',
      location: const LatLng(-8.04200, 110.76820),
      isPrimaryScope: true,
      aliases: ['sdn gebangharjo', 'sd gebangharjo'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Wonodadi',
      shortName: 'SDN 1 Wonodadi',
      category: 'Pendidikan',
      address: 'Desa Wonodadi, Kec. Pracimantoro',
      location: const LatLng(-8.02050, 110.79420),
      isPrimaryScope: true,
      aliases: ['sdn wonodadi', 'sd wonodadi'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Glinggang',
      shortName: 'SDN 1 Glinggang',
      category: 'Pendidikan',
      address: 'Desa Glinggang, Kec. Pracimantoro',
      location: const LatLng(-8.02620, 110.77880),
      isPrimaryScope: true,
      aliases: ['sdn glinggang', 'sd glinggang'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Banaran',
      shortName: 'SDN 1 Banaran',
      category: 'Pendidikan',
      address: 'Desa Banaran, Kec. Pracimantoro',
      location: const LatLng(-8.04150, 110.85550),
      isPrimaryScope: true,
      aliases: ['sdn banaran', 'sd banaran'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Trukan',
      shortName: 'SDN 1 Trukan',
      category: 'Pendidikan',
      address: 'Desa Trukan, Kec. Pracimantoro',
      location: const LatLng(-8.03050, 110.84200),
      isPrimaryScope: true,
      aliases: ['sdn trukan', 'sd trukan'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Sedayu',
      shortName: 'SDN 1 Sedayu',
      category: 'Pendidikan',
      address: 'Desa Sedayu, Kec. Pracimantoro',
      location: const LatLng(-8.04400, 110.81380),
      isPrimaryScope: true,
      aliases: ['sdn sedayu', 'sd sedayu'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Petirsari',
      shortName: 'SDN 1 Petirsari',
      category: 'Pendidikan',
      address: 'Desa Petirsari, Kec. Pracimantoro',
      location: const LatLng(-8.12400, 110.82320),
      isPrimaryScope: true,
      aliases: ['sdn petirsari', 'sd petirsari'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Jimbar',
      shortName: 'SDN 1 Jimbar',
      category: 'Pendidikan',
      address: 'Desa Jimbar, Kec. Pracimantoro',
      location: const LatLng(-8.06000, 110.84500),
      isPrimaryScope: true,
      aliases: ['sdn jimbar', 'sd jimbar'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Lebak',
      shortName: 'SDN 1 Lebak',
      category: 'Pendidikan',
      address: 'Desa Lebak, Kec. Pracimantoro',
      location: const LatLng(-8.03850, 110.79820),
      isPrimaryScope: true,
      aliases: ['sdn lebak', 'sd lebak'],
    ),
    LocalPlaceRecord(
      name: 'SD Negeri 1 Digal',
      shortName: 'SDN 1 Digal',
      category: 'Pendidikan',
      address: 'Dusun Digal, Kec. Pracimantoro',
      location: const LatLng(-8.05100, 110.82100),
      isPrimaryScope: true,
      aliases: ['sd digal', 'sdn digal'],
    ),
    LocalPlaceRecord(
      name: 'SMP Negeri 1 Pracimantoro',
      shortName: 'SMPN 1 Pracimantoro',
      category: 'Pendidikan',
      address: 'Jl. Taruna HS, Pracimantoro, Wonogiri',
      location: const LatLng(-8.05600, 110.80900),
      isPrimaryScope: true,
      aliases: ['smpn 1 pracimantoro', 'smp 1 pracimantoro', 'smp 1 praci'],
    ),
    LocalPlaceRecord(
      name: 'SMP Negeri 2 Pracimantoro',
      shortName: 'SMPN 2 Pracimantoro',
      category: 'Pendidikan',
      address: 'Kec. Pracimantoro, Wonogiri',
      location: const LatLng(-8.07200, 110.82500),
      isPrimaryScope: true,
      aliases: ['smpn 2 pracimantoro', 'smp 2 pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'SMP Negeri 3 Pracimantoro',
      shortName: 'SMPN 3 Pracimantoro',
      category: 'Pendidikan',
      address: 'Kec. Pracimantoro, Wonogiri',
      location: const LatLng(-8.03500, 110.81000),
      isPrimaryScope: true,
      aliases: ['smpn 3 pracimantoro', 'smp 3 pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'SMP Negeri 4 Pracimantoro',
      shortName: 'SMPN 4 Pracimantoro',
      category: 'Pendidikan',
      address: 'Kec. Pracimantoro, Wonogiri',
      location: const LatLng(-8.09800, 110.83500),
      isPrimaryScope: true,
      aliases: ['smpn 4 pracimantoro', 'smp 4 pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'SMP Muhammadiyah PK Pracimantoro',
      shortName: 'SMP Muhammadiyah Pracimantoro',
      category: 'Pendidikan',
      address: 'Jl. Taruna HS, Pracimantoro, Wonogiri',
      location: const LatLng(-8.05480, 110.80680),
      isPrimaryScope: true,
      aliases: ['smp muhammadiyah', 'smp muhammadiyah pk', 'smp pk'],
    ),
    LocalPlaceRecord(
      name: 'SMP PGRI 15 Pracimantoro',
      shortName: 'SMP PGRI 15',
      category: 'Pendidikan',
      address: 'Kec. Pracimantoro, Wonogiri',
      location: const LatLng(-8.05750, 110.80850),
      isPrimaryScope: true,
      aliases: ['smp pgri pracimantoro', 'smp pgri 15'],
    ),
    LocalPlaceRecord(
      name: 'MTs Sudirman Pracimantoro',
      shortName: 'MTs Sudirman',
      category: 'Pendidikan',
      address: 'Pracimantoro, Wonogiri',
      location: const LatLng(-8.04293, 110.81424),
      isPrimaryScope: true,
      aliases: ['mts sudirman', 'mts pracimantoro', 'madrasah tsanawiyah'],
    ),
    LocalPlaceRecord(
      name: 'SMA Negeri 1 Pracimantoro',
      shortName: 'SMAN 1 Pracimantoro',
      category: 'Pendidikan',
      address: 'Jl. Raya Pracimantoro - Wonogiri',
      location: const LatLng(-8.05850, 110.81250),
      isPrimaryScope: true,
      aliases: ['sman 1 pracimantoro', 'sma 1 pracimantoro', 'sma pracimantoro', 'sman 1 praci'],
    ),
    LocalPlaceRecord(
      name: 'SMK Negeri 1 Pracimantoro',
      shortName: 'SMKN 1 Pracimantoro',
      category: 'Pendidikan',
      address: 'Jl. Lingkar Luar Pracimantoro',
      location: const LatLng(-8.07329, 110.79091),
      isPrimaryScope: true,
      aliases: ['smkn 1 pracimantoro', 'smk 1 pracimantoro', 'smk pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'SMK Pancasila 7 Pracimantoro',
      shortName: 'SMK Pancasila 7',
      category: 'Pendidikan',
      address: 'Pracimantoro, Wonogiri',
      location: const LatLng(-8.05700, 110.81100),
      isPrimaryScope: true,
      aliases: ['smk pancasila pracimantoro', 'smk pancasila 7'],
    ),
    LocalPlaceRecord(
      name: 'MA Syahiidah Pracimantoro',
      shortName: 'MA Syahiidah',
      category: 'Pendidikan',
      address: 'Pracimantoro, Wonogiri',
      location: const LatLng(-8.05400, 110.80500),
      isPrimaryScope: true,
      aliases: ['ma syahiidah', 'madrasah aliyah syahiidah'],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // 2. KESEHATAN (RS, PUSKESMAS, KLINIK, APOTEK)
    // ══════════════════════════════════════════════════════════════════════
    LocalPlaceRecord(
      name: 'RSU Maguan Husada Pracimantoro',
      shortName: 'RS Maguan Husada',
      category: 'Kesehatan',
      address: 'Jl. Raya Pracimantoro - Wonogiri, Pracimantoro',
      location: const LatLng(-8.07971, 110.85375),
      isPrimaryScope: true,
      aliases: [
        'rsu maguan husada',
        'rs maguan',
        'rs maguan husada',
        'rumah sakit maguan',
        'rs pracimantoro',
        'rumah sakit pracimantoro',
        'rsu maguan',
      ],
    ),
    LocalPlaceRecord(
      name: 'Puskesmas Pracimantoro 1',
      shortName: 'Puskesmas 1 Pracimantoro',
      category: 'Kesehatan',
      address: 'Jl. Raya Pracimantoro (Puskesmas Rawat Inap)',
      location: const LatLng(-8.05211, 110.81025),
      isPrimaryScope: true,
      aliases: [
        'puskesmas pracimantoro',
        'puskesmas 1 pracimantoro',
        'puskesmas rawat inap pracimantoro',
        'puskesmas praci',
      ],
    ),
    LocalPlaceRecord(
      name: 'Puskesmas Pracimantoro 2 (Gedong)',
      shortName: 'Puskesmas 2 Gedong',
      category: 'Kesehatan',
      address: 'Desa Gedong, Kec. Pracimantoro',
      location: const LatLng(-8.06450, 110.78700),
      isPrimaryScope: true,
      aliases: ['puskesmas gedong', 'puskesmas 2 pracimantoro', 'puskesmas 2'],
    ),
    LocalPlaceRecord(
      name: 'Klinik Pratama PKU Muhammadiyah Pracimantoro',
      shortName: 'Klinik PKU Muhammadiyah',
      category: 'Kesehatan',
      address: 'Jl. Taruna HS, Pracimantoro',
      location: const LatLng(-8.05500, 110.80700),
      isPrimaryScope: true,
      aliases: ['pku muhammadiyah pracimantoro', 'klinik muhammadiyah', 'klinik pku'],
    ),
    LocalPlaceRecord(
      name: 'Apotek Pracimantoro Farma',
      shortName: 'Apotek Pracimantoro Farma',
      category: 'Kesehatan',
      address: 'Kawasan Pasar Pracimantoro',
      location: const LatLng(-8.05580, 110.80850),
      isPrimaryScope: true,
      aliases: ['apotek pracimantoro', 'apotek praci'],
    ),
    LocalPlaceRecord(
      name: 'Apotek Sehat Pracimantoro',
      shortName: 'Apotek Sehat',
      category: 'Kesehatan',
      address: 'Jl. Raya Pracimantoro',
      location: const LatLng(-8.05620, 110.80920),
      isPrimaryScope: true,
      aliases: ['apotek sehat', 'apotek sehat praci'],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // 3. PEMERINTAHAN & FASILITAS PUBLIK
    // ══════════════════════════════════════════════════════════════════════
    LocalPlaceRecord(
      name: 'Kantor Kecamatan Pracimantoro',
      shortName: 'Kantor Camat Pracimantoro',
      category: 'Pemerintahan',
      address: 'Jl. Raya Pracimantoro, Kec. Pracimantoro, Wonogiri',
      location: const LatLng(-8.05600, 110.80800),
      isPrimaryScope: true,
      aliases: [
        'kantor kecamatan pracimantoro',
        'kecamatan pracimantoro',
        'kantor camat pracimantoro',
        'camat pracimantoro',
        'kecamatan praci',
      ],
    ),
    LocalPlaceRecord(
      name: 'Polsek Pracimantoro',
      shortName: 'Kantor Polsek Pracimantoro',
      category: 'Keamanan',
      address: 'Jl. Raya Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05580, 110.80750),
      isPrimaryScope: true,
      aliases: ['polsek pracimantoro', 'kantor polisi pracimantoro', 'polsek praci'],
    ),
    LocalPlaceRecord(
      name: 'Koramil 13 Pracimantoro',
      shortName: 'Koramil Pracimantoro',
      category: 'Keamanan',
      address: 'Pracimantoro, Wonogiri',
      location: const LatLng(-8.05520, 110.80720),
      isPrimaryScope: true,
      aliases: ['koramil pracimantoro', 'koramil 13'],
    ),
    LocalPlaceRecord(
      name: 'Kantor Pos Pracimantoro',
      shortName: 'Kantor Pos Pracimantoro',
      category: 'Layanan Publik',
      address: 'Jl. Raya Pasar Pracimantoro (57664)',
      location: const LatLng(-8.05560, 110.80860),
      isPrimaryScope: true,
      aliases: ['kantor pos pracimantoro', 'pos indonesia pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'KUA Kecamatan Pracimantoro',
      shortName: 'KUA Pracimantoro',
      category: 'Layanan Publik',
      address: 'Pracimantoro, Wonogiri',
      location: const LatLng(-8.05650, 110.80780),
      isPrimaryScope: true,
      aliases: ['kua pracimantoro', 'kantor urusan agama pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Balai Desa Wonodadi',
      shortName: 'Balai Desa Wonodadi',
      category: 'Pemerintahan',
      address: 'Desa Wonodadi, Kec. Pracimantoro',
      location: const LatLng(-8.02093, 110.79494),
      isPrimaryScope: true,
      aliases: ['kantor desa wonodadi', 'kelurahan wonodadi'],
    ),
    LocalPlaceRecord(
      name: 'Balai Desa Gedong',
      shortName: 'Balai Desa Gedong',
      category: 'Pemerintahan',
      address: 'Desa Gedong, Kec. Pracimantoro',
      location: const LatLng(-8.06401, 110.78632),
      isPrimaryScope: true,
      aliases: ['kantor desa gedong', 'desa gedong pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Balai Desa Tubokarto',
      shortName: 'Balai Desa Tubokarto',
      category: 'Pemerintahan',
      address: 'Desa Tubokarto, Kec. Pracimantoro',
      location: const LatLng(-8.02485, 110.82320),
      isPrimaryScope: true,
      aliases: ['kantor desa tubokarto', 'desa tubokarto pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Balai Desa Suci',
      shortName: 'Balai Desa Suci',
      category: 'Pemerintahan',
      address: 'Desa Suci, Kec. Pracimantoro',
      location: const LatLng(-8.08507, 110.85177),
      isPrimaryScope: true,
      aliases: ['kantor desa suci', 'desa suci pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Balai Desa Joho',
      shortName: 'Balai Desa Joho',
      category: 'Pemerintahan',
      address: 'Desa Joho, Kec. Pracimantoro',
      location: const LatLng(-8.09500, 110.79600),
      isPrimaryScope: true,
      aliases: ['kantor desa joho', 'desa joho pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Balai Desa Gebangharjo',
      shortName: 'Balai Desa Gebangharjo',
      category: 'Pemerintahan',
      address: 'Desa Gebangharjo, Kec. Pracimantoro',
      location: const LatLng(-8.04238, 110.76870),
      isPrimaryScope: true,
      aliases: ['kantor desa gebangharjo', 'desa gebangharjo'],
    ),
    LocalPlaceRecord(
      name: 'Balai Desa Banaran',
      shortName: 'Balai Desa Banaran',
      category: 'Pemerintahan',
      address: 'Desa Banaran, Kec. Pracimantoro',
      location: const LatLng(-8.04181, 110.85610),
      isPrimaryScope: true,
      aliases: ['kantor desa banaran', 'desa banaran'],
    ),
    LocalPlaceRecord(
      name: 'Balai Desa Gambirmanis',
      shortName: 'Balai Desa Gambirmanis',
      category: 'Pemerintahan',
      address: 'Desa Gambirmanis, Kec. Pracimantoro',
      location: const LatLng(-8.11170, 110.84658),
      isPrimaryScope: true,
      aliases: ['kantor desa gambirmanis', 'desa gambirmanis'],
    ),
    LocalPlaceRecord(
      name: 'Balai Desa Petirsari',
      shortName: 'Balai Desa Petirsari',
      category: 'Pemerintahan',
      address: 'Desa Petirsari, Kec. Pracimantoro',
      location: const LatLng(-8.12433, 110.82366),
      isPrimaryScope: true,
      aliases: ['kantor desa petirsari', 'desa petirsari'],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // 4. PERBELANJAAN, PASAR, TRANSPORTASI & SPBU
    // ══════════════════════════════════════════════════════════════════════
    LocalPlaceRecord(
      name: 'Pasar Pracimantoro (Pasar Pusat / Pasar Wage)',
      shortName: 'Pasar Pracimantoro',
      category: 'Pasar & Belanja',
      address: 'Pusat Kota Pracimantoro, Wonogiri',
      location: const LatLng(-8.05533, 110.80881),
      isPrimaryScope: true,
      aliases: [
        'pasar pracimantoro',
        'pasar wage pracimantoro',
        'pasar praci',
        'pasar besar pracimantoro',
        'pasar umum pracimantoro',
      ],
    ),
    LocalPlaceRecord(
      name: 'Pasar Hewan Pracimantoro',
      shortName: 'Pasar Hewan Pracimantoro',
      category: 'Pasar & Belanja',
      address: 'Pracimantoro, Wonogiri',
      location: const LatLng(-8.05271, 110.80363),
      isPrimaryScope: true,
      aliases: ['pasar hewan', 'pasar kambing pracimantoro', 'pasar sapi pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Simpang Empat Pasar Pracimantoro (Lampu Merah)',
      shortName: 'Perempatan Pasar Pracimantoro',
      category: 'Landmark',
      address: 'Jl. Raya Wonogiri - Pracimantoro',
      location: const LatLng(-8.05559, 110.80838),
      isPrimaryScope: true,
      aliases: [
        'lampu merah pracimantoro',
        'perempatan pasar pracimantoro',
        'simpang pasar pracimantoro',
        'bangjo pracimantoro',
      ],
    ),
    LocalPlaceRecord(
      name: 'Simpang Empat Giribelah',
      shortName: 'Perempatan Giribelah',
      category: 'Landmark',
      address: 'Giribelah, Pracimantoro / Giritontro',
      location: const LatLng(-8.08464, 110.87196),
      isPrimaryScope: true,
      aliases: ['giribelah', 'perempatan giribelah', 'simpang giribelah', 'pasar giribelah'],
    ),
    LocalPlaceRecord(
      name: 'Terminal Bus Pracimantoro',
      shortName: 'Terminal Pracimantoro',
      category: 'Transportasi',
      address: 'Jl. Raya Pracimantoro',
      location: const LatLng(-8.05700, 110.80950),
      isPrimaryScope: true,
      aliases: ['terminal pracimantoro', 'sub terminal pracimantoro', 'terminal bis pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'SPBU Pertamina 44.576.09 Sambiroto Lor Pracimantoro',
      shortName: 'SPBU Sambiroto Lor Pracimantoro',
      category: 'SPBU & Bahan Bakar',
      address: 'Jl. Raya Pracimantoro, Sambiroto Lor',
      location: const LatLng(-8.05871, 110.81191),
      isPrimaryScope: true,
      aliases: ['spbu pracimantoro', 'pom bensin pracimantoro', 'spbu sambiroto lor', 'pom bensin'],
    ),
    LocalPlaceRecord(
      name: 'SPBU Pertamina 44.576.14 Sambiroto Pracimantoro',
      shortName: 'SPBU Sambiroto Selatan',
      category: 'SPBU & Bahan Bakar',
      address: 'Desa Sambiroto, Pracimantoro',
      location: const LatLng(-8.07727, 110.84537),
      isPrimaryScope: true,
      aliases: ['spbu sambiroto', 'pom bensin sambiroto'],
    ),
    LocalPlaceRecord(
      name: 'Alfamart Pasar Pracimantoro',
      shortName: 'Alfamart Pasar Pracimantoro',
      category: 'Minimarket',
      address: 'Jl. Raya Pasar Pracimantoro',
      location: const LatLng(-8.05520, 110.80820),
      isPrimaryScope: true,
      aliases: ['alfamart pracimantoro', 'alfa pracimantoro', 'alfamart'],
    ),
    LocalPlaceRecord(
      name: 'Indomaret Pasar Pracimantoro',
      shortName: 'Indomaret Pasar Pracimantoro',
      category: 'Minimarket',
      address: 'Jl. Raya Pracimantoro depan Pasar',
      location: const LatLng(-8.05570, 110.80870),
      isPrimaryScope: true,
      aliases: ['indomaret pracimantoro', 'indomart pracimantoro', 'indomaret'],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // 5. WISATA, RELIGI & DESTINASI POPULER
    // ══════════════════════════════════════════════════════════════════════
    LocalPlaceRecord(
      name: 'Museum Karst Indonesia',
      shortName: 'Museum Karst Gebangharjo',
      category: 'Wisata & Budaya',
      address: 'Desa Gebangharjo, Kec. Pracimantoro, Wonogiri',
      location: const LatLng(-8.04141, 110.78316),
      isPrimaryScope: true,
      aliases: ['museum karst', 'museum kars', 'museum karst indonesia', 'karst gebangharjo'],
    ),
    LocalPlaceRecord(
      name: 'Kawasan Wisata Gua Tembus & Gua Gilap',
      shortName: 'Gua Tembus Karst',
      category: 'Wisata Alam',
      address: 'Gebangharjo, Pracimantoro',
      location: const LatLng(-8.04250, 110.77200),
      isPrimaryScope: true,
      aliases: ['gua tembus', 'gua gilap', 'wisata gua pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Lapangan Merdeka Pracimantoro',
      shortName: 'Lapangan Merdeka Pracimantoro',
      category: 'Fasilitas Olahraga & Ruang Terbuka',
      address: 'Pusat Kota Pracimantoro, Wonogiri',
      location: const LatLng(-8.05450, 110.80900),
      isPrimaryScope: true,
      aliases: [
        'lapangan merdeka pracimantoro',
        'lapangan pracimantoro',
        'alun-alun pracimantoro',
        'lapangan bola pracimantoro',
      ],
    ),
    LocalPlaceRecord(
      name: 'Masjid Besar Al-Huda Pracimantoro',
      shortName: 'Masjid Al-Huda Pracimantoro',
      category: 'Tempat Ibadah',
      address: 'Pusat Kota Pracimantoro',
      location: const LatLng(-8.05580, 110.80900),
      isPrimaryScope: true,
      aliases: ['masjid al-huda', 'masjid besar pracimantoro', 'masjid raya pracimantoro'],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // 6. DUSUN & DUKUH (KECAMATAN PRACIMANTORO)
    // ══════════════════════════════════════════════════════════════════════
    LocalPlaceRecord(
      name: 'Dusun Belik, Desa Pracimantoro',
      shortName: 'Dusun Belik',
      category: 'Dusun / Pemukiman',
      address: 'Desa Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05350, 110.80620),
      isPrimaryScope: true,
      aliases: ['dusun belik', 'dukuh belik', 'belik pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Gudang, Desa Pracimantoro',
      shortName: 'Dusun Gudang',
      category: 'Dusun / Pemukiman',
      address: 'Desa Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05420, 110.80780),
      isPrimaryScope: true,
      aliases: ['dusun gudang', 'dukuh gudang', 'gudang pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Jenar, Desa Pracimantoro',
      shortName: 'Dusun Jenar',
      category: 'Dusun / Pemukiman',
      address: 'Desa Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05700, 110.80650),
      isPrimaryScope: true,
      aliases: ['dusun jenar', 'dukuh jenar', 'jenar pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Ngululor, Desa Pracimantoro',
      shortName: 'Dusun Ngululor',
      category: 'Dusun / Pemukiman',
      address: 'Desa Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05150, 110.80950),
      isPrimaryScope: true,
      aliases: ['dusun ngululor', 'ngululor', 'ngulu lor'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Ngulurejo, Desa Pracimantoro',
      shortName: 'Dusun Ngulurejo',
      category: 'Dusun / Pemukiman',
      address: 'Desa Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05280, 110.81150),
      isPrimaryScope: true,
      aliases: ['dusun ngulurejo', 'ngulurejo'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Ngulutengah, Desa Pracimantoro',
      shortName: 'Dusun Ngulutengah',
      category: 'Dusun / Pemukiman',
      address: 'Desa Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05380, 110.81250),
      isPrimaryScope: true,
      aliases: ['dusun ngulutengah', 'ngulutengah', 'ngulu tengah'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Nguluwetan, Desa Pracimantoro',
      shortName: 'Dusun Nguluwetan',
      category: 'Dusun / Pemukiman',
      address: 'Desa Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05450, 110.81400),
      isPrimaryScope: true,
      aliases: ['dusun nguluwetan', 'nguluwetan', 'ngulu wetan'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Tulangan, Desa Pracimantoro',
      shortName: 'Dusun Tulangan',
      category: 'Dusun / Pemukiman',
      address: 'Desa Pracimantoro, Kec. Pracimantoro',
      location: const LatLng(-8.05850, 110.80500),
      isPrimaryScope: true,
      aliases: ['dusun tulangan', 'tulangan pracimantoro'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Digal, Desa Sambiroto',
      shortName: 'Dusun Digal',
      category: 'Dusun / Pemukiman',
      address: 'Desa Sambiroto, Kec. Pracimantoro',
      location: const LatLng(-8.05100, 110.82100),
      isPrimaryScope: true,
      aliases: ['dusun digal', 'dukuh digal', 'digal sambiroto', 'digal'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Sambiroto Lor, Desa Sambiroto',
      shortName: 'Dusun Sambiroto Lor',
      category: 'Dusun / Pemukiman',
      address: 'Desa Sambiroto, Kec. Pracimantoro',
      location: const LatLng(-8.06500, 110.82800),
      isPrimaryScope: true,
      aliases: ['sambiroto lor', 'dusun sambiroto lor'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Sambiroto Kidul, Desa Sambiroto',
      shortName: 'Dusun Sambiroto Kidul',
      category: 'Dusun / Pemukiman',
      address: 'Desa Sambiroto, Kec. Pracimantoro',
      location: const LatLng(-8.07700, 110.84500),
      isPrimaryScope: true,
      aliases: ['sambiroto kidul', 'dusun sambiroto kidul'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Sawahan, Desa Gedong',
      shortName: 'Dusun Sawahan Gedong',
      category: 'Dusun / Pemukiman',
      address: 'Desa Gedong, Kec. Pracimantoro',
      location: const LatLng(-8.06200, 110.78300),
      isPrimaryScope: true,
      aliases: ['sawahan gedong', 'dusun sawahan'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Melikan, Desa Gedong',
      shortName: 'Dusun Melikan',
      category: 'Dusun / Pemukiman',
      address: 'Desa Gedong, Kec. Pracimantoro',
      location: const LatLng(-8.06800, 110.78100),
      isPrimaryScope: true,
      aliases: ['melikan gedong', 'dusun melikan'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Slempung, Desa Tubokarto',
      shortName: 'Dusun Slempung',
      category: 'Dusun / Pemukiman',
      address: 'Desa Tubokarto, Kec. Pracimantoro',
      location: const LatLng(-8.02800, 110.82600),
      isPrimaryScope: true,
      aliases: ['dusun slempung', 'slempung tubokarto'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Mudal, Desa Gebangharjo',
      shortName: 'Dusun Mudal',
      category: 'Dusun / Pemukiman',
      address: 'Desa Gebangharjo, Kec. Pracimantoro',
      location: const LatLng(-8.04500, 110.77100),
      isPrimaryScope: true,
      aliases: ['dusun mudal', 'mudal gebangharjo', 'mudal'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Nongko, Desa Suci',
      shortName: 'Dusun Nongko',
      category: 'Dusun / Pemukiman',
      address: 'Desa Suci, Kec. Pracimantoro',
      location: const LatLng(-8.08200, 110.84800),
      isPrimaryScope: true,
      aliases: ['dusun nongko', 'nongko suci'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Galih, Desa Joho',
      shortName: 'Dusun Galih',
      category: 'Dusun / Pemukiman',
      address: 'Desa Joho, Kec. Pracimantoro',
      location: const LatLng(-8.09200, 110.79200),
      isPrimaryScope: true,
      aliases: ['dusun galih', 'galih joho'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Pagutan, Desa Sumberagung',
      shortName: 'Dusun Pagutan',
      category: 'Dusun / Pemukiman',
      address: 'Desa Sumberagung, Kec. Pracimantoro',
      location: const LatLng(-8.06800, 110.83500),
      isPrimaryScope: true,
      aliases: ['dusun pagutan', 'pagutan sumberagung'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Pule, Desa Gambirmanis',
      shortName: 'Dusun Pule',
      category: 'Dusun / Pemukiman',
      address: 'Desa Gambirmanis, Kec. Pracimantoro',
      location: const LatLng(-8.11500, 110.84200),
      isPrimaryScope: true,
      aliases: ['dusun pule', 'pule gambirmanis'],
    ),
    LocalPlaceRecord(
      name: 'Dusun Beji, Desa Wonodadi',
      shortName: 'Dusun Beji',
      category: 'Dusun / Pemukiman',
      address: 'Desa Wonodadi, Kec. Pracimantoro',
      location: const LatLng(-8.01800, 110.79200),
      isPrimaryScope: true,
      aliases: ['dusun beji', 'beji wonodadi'],
    ),

    // ══════════════════════════════════════════════════════════════════════
    // 7. WILAYAH TETANGGA (KECAMATAN SEKITARNYA - SECONDARY SCOPE)
    // ══════════════════════════════════════════════════════════════════════
    LocalPlaceRecord(
      name: 'Pasar Giritontro',
      shortName: 'Pasar Giritontro',
      category: 'Kecamatan Tetangga',
      address: 'Kec. Giritontro, Wonogiri',
      location: const LatLng(-8.08200, 110.86600),
      isPrimaryScope: false,
      aliases: ['giritontro', 'pasar giritontro', 'kecamatan giritontro'],
    ),
    LocalPlaceRecord(
      name: 'Pasar Eromoko',
      shortName: 'Pasar Eromoko',
      category: 'Kecamatan Tetangga',
      address: 'Kec. Eromoko, Wonogiri',
      location: const LatLng(-7.98500, 110.85500),
      isPrimaryScope: false,
      aliases: ['eromoko', 'pasar eromoko', 'kecamatan eromoko'],
    ),
    LocalPlaceRecord(
      name: 'Pasar Giriwoyo',
      shortName: 'Pasar Giriwoyo',
      category: 'Kecamatan Tetangga',
      address: 'Kec. Giriwoyo, Wonogiri',
      location: const LatLng(-8.03500, 110.91500),
      isPrimaryScope: false,
      aliases: ['giriwoyo', 'pasar giriwoyo', 'kecamatan giriwoyo'],
    ),
    LocalPlaceRecord(
      name: 'Pasar Baturetno',
      shortName: 'Pasar Baturetno',
      category: 'Kecamatan Tetangga',
      address: 'Kec. Baturetno, Wonogiri',
      location: const LatLng(-7.98000, 110.92500),
      isPrimaryScope: false,
      aliases: ['baturetno', 'pasar baturetno', 'kecamatan baturetno'],
    ),
  ];

  /// Algoritma Pencarian Cerdas Fundamental GAGE Pracimantoro:
  /// - Memberikan Prioritas Tertinggi (#1) untuk titik di Kecamatan Pracimantoro
  /// - Mendukung singkatan umum: 'sd', 'smp', 'sma', 'rs', 'camat', 'polsek', 'pasar'
  static List<OsmPlace> searchLocalPlaces(String query, {LatLng? userLocation}) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final LatLng refLocation = userLocation ?? centerPracimantoro;
    const Distance distCalc = Distance();

    final List<ScoredPlace> matches = [];

    for (final p in allPlaces) {
      int score = 0;
      final nameLower = p.name.toLowerCase();
      final shortNameLower = p.shortName.toLowerCase();

      // 1. Exact Name Matching
      if (nameLower == cleanQuery || shortNameLower == cleanQuery) {
        score += 150;
      }
      // 2. Alias / Akronim Matching
      else if (p.aliases.any((a) => a == cleanQuery)) {
        score += 130;
      }
      // 3. Name Starts With Query
      else if (nameLower.startsWith(cleanQuery) || shortNameLower.startsWith(cleanQuery)) {
        score += 100;
      }
      // 4. Words Matching
      else {
        final queryWords = cleanQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        int matchedWords = 0;
        for (final w in queryWords) {
          if (nameLower.contains(w) ||
              shortNameLower.contains(w) ||
              p.aliases.any((a) => a.contains(w))) {
            matchedWords++;
          }
        }
        if (matchedWords == queryWords.length && queryWords.isNotEmpty) {
          score += 85;
        } else if (matchedWords > 0) {
          score += (matchedWords * 30);
        }
      }

      // Khusus Query Umum Jenjang Sekolah: misal user ketik "sd"
      if (cleanQuery == 'sd' || cleanQuery == 'sdn') {
        if (p.name.toLowerCase().startsWith('sd')) {
          score += 90;
        }
      } else if (cleanQuery == 'smp' || cleanQuery == 'smpn') {
        if (p.name.toLowerCase().startsWith('smp')) {
          score += 90;
        }
      } else if (cleanQuery == 'sma' || cleanQuery == 'smk') {
        if (p.name.toLowerCase().startsWith('sma') || p.name.toLowerCase().startsWith('smk')) {
          score += 90;
        }
      } else if (cleanQuery == 'rs' || cleanQuery == 'rsu' || cleanQuery == 'rumah sakit') {
        if (p.category == 'Kesehatan') {
          score += 95;
        }
      }

      // 5. Scope Prioritization (Pracimantoro adalah Wilayah Inti)
      if (p.isPrimaryScope && score > 0) {
        score += 40; // Bonus besar untuk lokasi di dalam Kecamatan Pracimantoro
      }

      if (score > 0) {
        final dist = distCalc.as(LengthUnit.Meter, refLocation, p.location);
        matches.add(ScoredPlace(place: p, score: score, distanceMeters: dist));
      }
    }

    // Urutkan: Skor Relevansi Tertinggi -> Lalu Jarak Terdekat
    matches.sort((a, b) {
      if (a.score != b.score) {
        return b.score.compareTo(a.score);
      }
      return a.distanceMeters.compareTo(b.distanceMeters);
    });

    return matches.map((m) {
      return OsmPlace(
        title: m.place.shortName,
        displayName: '${m.place.name}, ${m.place.address}',
        location: m.place.location,
        distanceMeters: m.distanceMeters,
      );
    }).toList();
  }
}

class LocalPlaceRecord {
  final String name;
  final String shortName;
  final String category;
  final String address;
  final LatLng location;
  final bool isPrimaryScope;
  final List<String> aliases;

  const LocalPlaceRecord({
    required this.name,
    required this.shortName,
    required this.category,
    required this.address,
    required this.location,
    required this.isPrimaryScope,
    required this.aliases,
  });
}

class ScoredPlace {
  final LocalPlaceRecord place;
  final int score;
  final double distanceMeters;

  ScoredPlace({
    required this.place,
    required this.score,
    required this.distanceMeters,
  });
}
