# Fundamental Algoritma Pencarian Lokasi & Master Dataset POI - GAGE Pracimantoro

Dokumen ini mendokumentasikan arsitektur fundamental pencarian lokasi untuk aplikasi **Gage Pracimantoro** (Kecamatan Pracimantoro, Kabupaten Wonogiri, Jawa Tengah), sekaligus standar pola ekspansi ke kecamatan lain (`Gage {nama kecamatan}`).

---

## 1. Latar Belakang & Filosofi "Hyper-Local First"

Layanan on-demand di wilayah kecamatan pedesaan/sub-urban (seperti Pracimantoro) memiliki karakteristik khusus:
1. **Peta Global Sering Tidak Lengkap**: Banyak sekolah (seperti *SD Muhammadiyah Program Khusus Pracimantoro*), klinik lokal, balai dusun, dan warung/toko penting belum terdaftar atau tidak memiliki indexing token yang memadai pada database OpenStreetMap (OSM) global.
2. **Kueri Singkat Rentan Salah Arah**: Pencarian kata kunci singkat seperti `"sd"`, `"rs"`, `"pasar"` pada API publik global tanpa kurasi lokal akan menghasilkan POI dari kecamatan lain (misal: Eromoko, Rongkop, Wonogiri Kota, bahkan hingga luar negeri).
3. **Standar Ekspansi Antar-Kecamatan**: Aplikasi dirancang spesifik per wilayah (`Gage Pracimantoro`). Ketika ekspansi ke kecamatan tetangga (misal: `Gage Giritontro`, `Gage Eromoko`), sistem cukup menduplikasi pola dataset lokal kecamatan target tanpa merusak kestabilan core engine.

---

## 2. Arsitektur Dua Tingkat (Two-Tier Hybrid Search Engine)

```
                            [ User Input Query ]
                                     │
                                     ▼
                     [ 1. Query Normalization & Tokenizer ]
                                     │
                 ┌───────────────────┴───────────────────┐
                 ▼                                       ▼
     [ TIER 1: Local Knowledge Base ]        [ TIER 2: Bounded Photon OSM ]
     - PracimantoroPlacesDatabase            - Lat: -8.05517, Lon: 110.80889
     - 50+ Verified Official POIs            - Bounding Box Delta: 0.22 (~20 km)
     - Multi-Keyword & Alias Match           - Filter: Country == 'Indonesia'
     - Instant Response (< 5 ms)             - Radius Sekunder (Jalan / Dusun)
                 │                                       │
                 └───────────────────┬───────────────────┘
                                     ▼
                    [ 3. Scoring, Merge & Deduplication ]
                     - Tier 1 Exact / High Match: #1 Rank
                     - Pracimantoro Core Scope: +40 Boost
                     - Remote Nearby Sorted by Distance
                                     │
                                     ▼
                       [ Top Accurate Places List ]
```

### A. Tier 1: Local Knowledge Base (Prioritas Tertinggi / Instant)
Tersimpan langsung dalam aplikasi di [`lib/core/services/pracimantoro_places_database.dart`](file:///C:/Users/ertyui/ZCodeProject/gage/gage-app/lib/core/services/pracimantoro_places_database.dart).
- **Waktu Respons**: < 5 milidetik (tanpa latensi internet).
- **Akurasi Token**: Mendukung singkatan dan akronim lokal:
  - `"sd"` / `"sdn"` $\rightarrow$ Seluruh 22+ SD di Kecamatan Pracimantoro.
  - `"sd muhammadiyah"` / `"sd pk"` $\rightarrow$ `SD Muhammadiyah Program Khusus Pracimantoro`.
  - `"rs"` / `"rsu"` $\rightarrow$ `RSU Maguan Husada Pracimantoro`.
  - `"pasar"` $\rightarrow$ `Pasar Pracimantoro (Pasar Wage)`.
  - `"camat"` / `"kecamatan"` $\rightarrow$ `Kantor Kecamatan Pracimantoro`.
  - `"polsek"` $\rightarrow$ `Polsek Pracimantoro`.

### B. Tier 2: Photon OSM Geocoding (Radius Fokus ~20 km)
Tersimpan di [`lib/core/services/osm_geocoding_service.dart`](file:///C:/Users/ertyui/ZCodeProject/gage/gage-app/lib/core/services/osm_geocoding_service.dart).
- Dibatasi secara ketat pada Bounding Box pusat kota Pracimantoro:
  - Bounding Box: `minLon: 110.5889, minLat: -8.2752, maxLon: 111.0289, maxLat: -7.8352`.
- Hanya memuat hasil di wilayah NKRI (`country == 'indonesia'`).
- Mengakomodasi pencarian alamat jalan spesifik atau wilayah tetangga (Giritontro, Eromoko, Giriwoyo).

---

## 3. Master Dataset Titik Lokasi Kecamatan Pracimantoro

### A. Fasilitas Pendidikan
| Nama Lokasi | Kategori | Alamat | Koordinat (Lat, Lon) |
|---|---|---|---|
| **SD Muhammadiyah Program Khusus (PK) Pracimantoro** | Pendidikan | Jl. Taruna HS Km. 0,3, Pracimantoro | `-8.05460, 110.80660` |
| **SDIT Nurul Huda Pracimantoro** | Pendidikan | Jl. Raya Pracimantoro | `-8.05350, 110.80780` |
| **SD Negeri 1 Pracimantoro** | Pendidikan | Jl. Raya Pracimantoro | `-8.05520, 110.80910` |
| **SD Negeri 2 Pracimantoro** | Pendidikan | Pracimantoro | `-8.05380, 110.81050` |
| **SD Negeri 3 Pracimantoro** | Pendidikan | Pracimantoro | `-8.05650, 110.81180` |
| **SD Negeri 1 Sambiroto** | Pendidikan | Desa Sambiroto | `-8.07650, 110.84450` |
| **SD Negeri 1 Tubokarto** | Pendidikan | Desa Tubokarto | `-8.02450, 110.82280` |
| **SD Negeri 1 Joho** | Pendidikan | Desa Joho | `-8.09450, 110.79580` |
| **SD Negeri 2 Joho** | Pendidikan | Desa Joho | `-8.09539, 110.79631` |
| **SD Negeri 1 Gedong** | Pendidikan | Desa Gedong | `-8.06380, 110.78580` |
| **SD Negeri 1 Suci** | Pendidikan | Desa Suci | `-8.08480, 110.85120` |
| **SD Negeri 1 Gambirmanis** | Pendidikan | Desa Gambirmanis | `-8.11120, 110.84600` |
| **SD Negeri 1 Wonodadi** | Pendidikan | Desa Wonodadi | `-8.02050, 110.79420` |
| **SD Negeri 1 Gebangharjo** | Pendidikan | Desa Gebangharjo | `-8.04200, 110.76820` |
| **SMP Negeri 1 Pracimantoro** | Pendidikan | Jl. Taruna HS, Pracimantoro | `-8.05600, 110.80900` |
| **SMP Negeri 2 Pracimantoro** | Pendidikan | Pracimantoro | `-8.07200, 110.82500` |
| **SMP Negeri 3 Pracimantoro** | Pendidikan | Pracimantoro | `-8.03500, 110.81000` |
| **SMP Negeri 4 Pracimantoro** | Pendidikan | Pracimantoro | `-8.09800, 110.83500` |
| **SMPS Muhammadiyah PK Pracimantoro** | Pendidikan | Jl. Taruna HS, Pracimantoro | `-8.05480, 110.80680` |
| **SMA Negeri 1 Pracimantoro** | Pendidikan | Jl. Raya Pracimantoro - Wonogiri | `-8.05850, 110.81250` |
| **SMK Negeri 1 Pracimantoro** | Pendidikan | Jl. Lingkar Luar Pracimantoro | `-8.07329, 110.79091` |
| **SMK Pancasila 7 Pracimantoro** | Pendidikan | Pracimantoro | `-8.05700, 110.81100` |

### B. Fasilitas Kesehatan
| Nama Lokasi | Kategori | Alamat | Koordinat (Lat, Lon) |
|---|---|---|---|
| **RSU Maguan Husada Pracimantoro** | Kesehatan | Jl. Raya Pracimantoro - Wonogiri | `-8.07971, 110.85375` |
| **Puskesmas Pracimantoro 1** | Kesehatan | Jl. Raya Pracimantoro (Rawat Inap) | `-8.05211, 110.81025` |
| **Puskesmas Pracimantoro 2 (Gedong)** | Kesehatan | Desa Gedong, Pracimantoro | `-8.06450, 110.78700` |
| **Klinik Pratama PKU Muhammadiyah** | Kesehatan | Jl. Taruna HS, Pracimantoro | `-8.05500, 110.80700` |
| **Apotek Pracimantoro Farma** | Kesehatan | Pasar Pracimantoro | `-8.05580, 110.80850` |
| **Apotek Sehat Pracimantoro** | Kesehatan | Jl. Raya Pracimantoro | `-8.05620, 110.80920` |

### C. Pemerintahan, Keamanan & Layanan Publik
| Nama Lokasi | Kategori | Alamat | Koordinat (Lat, Lon) |
|---|---|---|---|
| **Kantor Kecamatan Pracimantoro** | Pemerintahan | Jl. Raya Pracimantoro | `-8.05600, 110.80800` |
| **Polsek Pracimantoro** | Keamanan | Jl. Raya Pracimantoro | `-8.05580, 110.80750` |
| **Koramil 13 Pracimantoro** | Keamanan | Pracimantoro | `-8.05520, 110.80720` |
| **Kantor Pos Pracimantoro (57664)** | Layanan Publik | Kawasan Pasar Pracimantoro | `-8.05560, 110.80860` |
| **KUA Kecamatan Pracimantoro** | Layanan Publik | Pracimantoro | `-8.05650, 110.80780` |
| **Balai Desa Wonodadi** | Pemerintahan | Desa Wonodadi | `-8.02093, 110.79494` |
| **Balai Desa Gedong** | Pemerintahan | Desa Gedong | `-8.06401, 110.78632` |
| **Balai Desa Tubokarto** | Pemerintahan | Desa Tubokarto | `-8.02485, 110.82320` |
| **Balai Desa Suci** | Pemerintahan | Desa Suci | `-8.08507, 110.85177` |
| **Balai Desa Joho** | Pemerintahan | Desa Joho | `-8.09500, 110.79600` |
| **Balai Desa Gebangharjo** | Pemerintahan | Desa Gebangharjo | `-8.04238, 110.76870` |
| **Balai Desa Banaran** | Pemerintahan | Desa Banaran | `-8.04181, 110.85610` |
| **Balai Desa Gambirmanis** | Pemerintahan | Desa Gambirmanis | `-8.11170, 110.84658` |
| **Balai Desa Petirsari** | Pemerintahan | Desa Petirsari | `-8.12433, 110.82366` |

### D. Pasar, SPBU & Transportasi
| Nama Lokasi | Kategori | Alamat | Koordinat (Lat, Lon) |
|---|---|---|---|
| **Pasar Pracimantoro (Pasar Wage)** | Pasar & Belanja | Pusat Kota Pracimantoro | `-8.05533, 110.80881` |
| **Pasar Hewan Pracimantoro** | Pasar & Belanja | Pracimantoro | `-8.05271, 110.80363` |
| **Perempatan Pasar (Bangjo Pracimantoro)** | Landmark | Simpang Jl. Raya Pracimantoro | `-8.05559, 110.80838` |
| **Simpang Empat Giribelah** | Landmark | Giribelah | `-8.08464, 110.87196` |
| **Terminal Bus Pracimantoro** | Transportasi | Jl. Raya Pracimantoro | `-8.05700, 110.80950` |
| **SPBU 44.576.09 Sambiroto Lor** | SPBU | Jl. Raya Pracimantoro | `-8.05871, 110.81191` |
| **SPBU 44.576.14 Sambiroto Selatan** | SPBU | Desa Sambiroto | `-8.07727, 110.84537` |
| **Alfamart Pasar Pracimantoro** | Minimarket | Depan Pasar Pracimantoro | `-8.05520, 110.80820` |
| **Indomaret Pasar Pracimantoro** | Minimarket | Depan Pasar Pracimantoro | `-8.05570, 110.80870` |

### E. Wisata & Tempat Ibadah
| Nama Lokasi | Kategori | Alamat | Koordinat (Lat, Lon) |
|---|---|---|---|
| **Museum Karst Indonesia** | Wisata Budaya | Gebangharjo, Pracimantoro | `-8.04141, 110.78316` |
| **Kawasan Gua Tembus & Gua Gilap** | Wisata Alam | Gebangharjo, Pracimantoro | `-8.04250, 110.77200` |
| **Lapangan Merdeka Pracimantoro** | Olahraga / Publik | Pusat Kota Pracimantoro | `-8.05450, 110.80900` |
| **Masjid Besar Al-Huda Pracimantoro** | Ibadah | Pusat Kota Pracimantoro | `-8.05580, 110.80900` |

### F. Dusun & Dukuh (Pemukiman Warga)
| Nama Dusun | Desa | Kategori | Koordinat (Lat, Lon) |
|---|---|---|---|
| **Dusun Belik** | Pracimantoro | Dusun / Pemukiman | `-8.05350, 110.80620` |
| **Dusun Gudang** | Pracimantoro | Dusun / Pemukiman | `-8.05420, 110.80780` |
| **Dusun Jenar** | Pracimantoro | Dusun / Pemukiman | `-8.05700, 110.80650` |
| **Dusun Ngululor** | Pracimantoro | Dusun / Pemukiman | `-8.05150, 110.80950` |
| **Dusun Ngulurejo** | Pracimantoro | Dusun / Pemukiman | `-8.05280, 110.81150` |
| **Dusun Ngulutengah** | Pracimantoro | Dusun / Pemukiman | `-8.05380, 110.81250` |
| **Dusun Nguluwetan** | Pracimantoro | Dusun / Pemukiman | `-8.05450, 110.81400` |
| **Dusun Tulangan** | Pracimantoro | Dusun / Pemukiman | `-8.05850, 110.80500` |
| **Dusun Digal** | Sambiroto | Dusun / Pemukiman | `-8.05100, 110.82100` |
| **Dusun Sambiroto Lor** | Sambiroto | Dusun / Pemukiman | `-8.06500, 110.82800` |
| **Dusun Sambiroto Kidul** | Sambiroto | Dusun / Pemukiman | `-8.07700, 110.84500` |
| **Dusun Sawahan** | Gedong | Dusun / Pemukiman | `-8.06200, 110.78300` |
| **Dusun Melikan** | Gedong | Dusun / Pemukiman | `-8.06800, 110.78100` |
| **Dusun Slempung** | Tubokarto | Dusun / Pemukiman | `-8.02800, 110.82600` |
| **Dusun Mudal** | Gebangharjo | Dusun / Pemukiman | `-8.04500, 110.77100` |
| **Dusun Nongko** | Suci | Dusun / Pemukiman | `-8.08200, 110.84800` |
| **Dusun Galih** | Joho | Dusun / Pemukiman | `-8.09200, 110.79200` |
| **Dusun Pagutan** | Sumberagung | Dusun / Pemukiman | `-8.06800, 110.83500` |
| **Dusun Pule** | Gambirmanis | Dusun / Pemukiman | `-8.11500, 110.84200` |
| **Dusun Beji** | Wonodadi | Dusun / Pemukiman | `-8.01800, 110.79200` |

---

## 4. Pola Ekspansi ke Kecamatan Lain (`Gage {Kecamatan}`)

Jika kelak membuka cabang di kecamatan lain:
1. Ganti flavor/appName di `build.gradle.kts` menjadi `Gage {Kecamatan}` (misal: `Gage Giritontro`, `Gage Eromoko`).
2. Duplikasi template dataset ini menjadi `{Kecamatan}PlacesDatabase` dengan titik pusat koordinat kecamatan tersebut.
3. Seluruh alur kalkulasi tarif ongkir Rp 500, pembagian komisi driver, dan multi-merchant order langsung berjalan secara plug-and-play.
