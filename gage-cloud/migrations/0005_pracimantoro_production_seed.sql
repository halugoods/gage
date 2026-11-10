-- GAGE SuperApp Pracimantoro Production Seed v2.0
-- Hyperlocal Kecamatan Pracimantoro, Kabupaten Wonogiri, Jawa Tengah

-- 1. Koreksi Koordinat & Alamat Dimsum Sewu ke Pracimantoro
UPDATE merchants 
SET address = 'Depan Alfamidi Pracimantoro, Jl. Raya Pracimantoro-Wonogiri',
    latitude = -8.0892,
    longitude = 110.8374,
    phone_wa = '081226001001'
WHERE id = 'm-dimsum-sewu';

-- 2. Insert Merchant Lengkap: Kuliner (Food)
INSERT OR REPLACE INTO merchants (id, owner_user_id, name, slug, category, address, latitude, longitude, phone_wa, is_open, is_affiliate_enabled, affiliate_commission_rate, created_at, updated_at)
VALUES 
    ('mch-rc-01', 'usr-owner-01', 'Rocket Chicken Sambiroto, Pracimantoro', 'rocket-chicken-praci', 'Ayam Goreng Krispi & Aneka Burger', 'Sambiroto, Kec. Pracimantoro', -8.0872, 110.8354, '081226001002', 1, 1, 0.10, 1728345600, 1728345600),
    ('mch-mie-01', 'usr-owner-01', 'Mie Ayam & Bakso Pak Kumis', 'mie-ayam-pak-kumis', 'Mie & Bakso Urat Komplit', 'Pasar Pracimantoro Kios No. 4', -8.0901, 110.8382, '081226001003', 1, 1, 0.12, 1728345600, 1728345600),
    ('mch-seblak-01', 'usr-owner-01', 'Seblak Prasmanan Nyentrik Pracimantoro', 'seblak-nyentrik-praci', 'Seblak & Pedas Prasmanan', 'Jl. Raya Pracimantoro - Giritontro', -8.0890, 110.8365, '081226001004', 1, 1, 0.11, 1728345600, 1728345600),
    ('mch-roti-01', 'usr-owner-01', 'Roti Gembong Gedhe, Pracimantoro', 'roti-gembong-gedhe-praci', 'Roti & Bakery, Jajanan Manis', 'Kompleks Ruko Barat Pasar Pracimantoro', -8.0885, 110.8370, '081226001005', 1, 1, 0.08, 1728345600, 1728345600);

-- 3. Insert Merchant Lengkap: Sembako & Kelontong (Shop)
INSERT OR REPLACE INTO merchants (id, owner_user_id, name, slug, category, address, latitude, longitude, phone_wa, is_open, is_affiliate_enabled, affiliate_commission_rate, created_at, updated_at)
VALUES 
    ('shop-berkah-fajar', 'usr-owner-01', 'Toko Sembako Berkah Fajar', 'sembako-berkah-fajar', 'Sembako, Beras & Minyak Goreng', 'Sambiroto, Pracimantoro', -8.0895, 110.8390, '081226001006', 1, 1, 0.05, 1728345600, 1728345600),
    ('shop-telur-jaya', 'usr-owner-01', 'Agen Telur & Sembako Jaya', 'agen-telur-jaya', 'Telur Ayam Ras, Gula Pasir & Tepung', 'Pasar Pracimantoro Blok B-12', -8.0910, 110.8405, '081226001007', 1, 1, 0.06, 1728345600, 1728345600),
    ('shop-lapak-siti', 'usr-owner-01', 'Lapak Segar Sayur Mbak Siti', 'sayur-mbak-siti', 'Sayur Mayur & Bumbu Dapur Segar', 'Pasar Tradisional Pracimantoro', -8.0898, 110.8378, '081226001008', 1, 1, 0.07, 1728345600, 1728345600);

-- 4. Insert Merchant Lengkap: Pertanian & Peternakan (Farm)
INSERT OR REPLACE INTO merchants (id, owner_user_id, name, slug, category, address, latitude, longitude, phone_wa, is_open, is_affiliate_enabled, affiliate_commission_rate, created_at, updated_at)
VALUES 
    ('farm-kios-subur', 'usr-owner-01', 'Kios Tani Subur Makmur', 'kios-tani-subur-makmur', 'Pupuk NPK & Urea, Benih Padi & Sayur', 'Gedong, Pracimantoro', -8.0860, 110.8340, '081226001009', 1, 1, 0.08, 1728345600, 1728345600),
    ('farm-sentra-mandiri', 'usr-owner-01', 'Sentra Konsentrat Ternak Mandiri', 'sentra-ternak-mandiri', 'Pakan Sapi, Kambing & Vitamin Hewan', 'Jl. Lingkar Barat Pracimantoro', -8.0850, 110.8330, '081226001010', 1, 1, 0.08, 1728345600, 1728345600),
    ('farm-tani-lestari', 'usr-owner-01', 'Kios Pertanian Tani Lestari', 'kios-tani-lestari', 'Obat Hama & Alat Semprot Pertanian', 'Tubokarto, Kec. Pracimantoro', -8.0920, 110.8420, '081226001011', 1, 1, 0.08, 1728345600, 1728345600);

-- 5. Insert Merchant Lengkap: Bahan Bangunan (Build)
INSERT OR REPLACE INTO merchants (id, owner_user_id, name, slug, category, address, latitude, longitude, phone_wa, is_open, is_affiliate_enabled, affiliate_commission_rate, created_at, updated_at)
VALUES 
    ('build-sumber-abadi', 'usr-owner-01', 'Toko Besi & Bangunan Sumber Abadi', 'tb-sumber-abadi', 'Semen, Besi Beton, Cat & Pipa PVC', 'Jl. Raya Wonogiri - Pracimantoro Km 1', -8.0875, 110.8350, '081226001012', 1, 1, 0.05, 1728345600, 1728345600),
    ('build-sinar-mulia', 'usr-owner-01', 'TB Sinar Mulia Pracimantoro', 'tb-sinar-mulia', 'Baja Ringan, Genteng Metal & Pasir', 'Sambiroto RT 02/RW 01, Pracimantoro', -8.0880, 110.8360, '081226001013', 1, 1, 0.05, 1728345600, 1728345600),
    ('build-berkah-jaya', 'usr-owner-01', 'Depo Bahan Bangunan Berkah Jaya', 'depo-berkah-jaya', 'Keramik, Cat Tembok & Sanitari', 'Jl. Suci, Pracimantoro', -8.0930, 110.8430, '081226001014', 1, 1, 0.05, 1728345600, 1728345600);

-- 6. Insert Menu & Item Produk Unggulan
-- Rocket Chicken
INSERT OR REPLACE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-rc-01', 'mch-rc-01', 'Paket Rocket 1 (Ayam Goreng Paha/Dada + Nasi)', 'Ayam goreng krispi bumbu resep rahasia + nasi pulen hangat + saus sambal.', 'Makanan', 14500, 16000, 1, 1728345600, 1728345600),
    ('menu-rc-02', 'mch-rc-01', 'Ayam Geprek Sambal Bawang Pedas Nampol', 'Ayam krispi digeprek dengan cabai rawit merah segar dan bawang gurih.', 'Makanan', 16000, 17500, 1, 1728345600, 1728345600),
    ('menu-rc-03', 'mch-rc-01', 'Burger Beef Cheese Special', 'Roti wijen empuk dengan patty daging sapi dan keju cheddar leleh.', 'Makanan', 12500, 14000, 1, 1728345600, 1728345600);

-- Mie Ayam & Bakso Pak Kumis
INSERT OR REPLACE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-mie-01', 'mch-mie-01', 'Mie Ayam Bakso Urat Spesial', 'Mie kenyal gurih topping ayam semur manis + 2 bakso urat sapi asli.', 'Makanan', 14000, 16000, 1, 1728345600, 1728345600),
    ('menu-mie-02', 'mch-mie-01', 'Bakso Urat Jumbo Kuah Kaldu Sapi', 'Bakso urat sapi super kenyal gurih kuah kaldu rempah bening mantap.', 'Makanan', 16000, 18000, 1, 1728345600, 1728345600);

-- Seblak Prasmanan
INSERT OR REPLACE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-seblak-01', 'mch-seblak-01', 'Seblak Prasmanan Komplit Ceker Sosis Dumpling', 'Kuah kencur pedas level 1-5 dengan aneka topping lengkap.', 'Makanan', 13500, 15000, 1, 1728345600, 1728345600);

-- Roti Gembong Gedhe
INSERT OR REPLACE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-roti-01', 'mch-roti-01', 'Roti Gembong Cokelat Lumer Original', 'Roti sobek khas lembut tabur meses cokelat tebal lumer panggang.', 'Makanan', 15000, 17000, 1, 1728345600, 1728345600);

-- Toko Sembako Berkah Fajar
INSERT OR REPLACE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-shop-01', 'shop-berkah-fajar', 'Beras C4 Super Delanggu 5kg', 'Beras putih pulen alami kualitas super langsung dari sentra Delanggu.', 'Sembako', 69000, 72000, 1, 1728345600, 1728345600),
    ('menu-shop-02', 'shop-berkah-fajar', 'Minyak Goreng Sania Pouch 2 Liter', 'Minyak kelapa sawit higienis jernih, tahan panas untuk masakan renyah.', 'Sembako', 33000, 34500, 1, 1728345600, 1728345600);

-- Agen Telur Jaya
INSERT OR REPLACE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-shop-03', 'shop-telur-jaya', 'Telur Ayam Ras Segar Kiloan (1kg)', 'Telur ayam ras segar grade A cangkang tebal langsung dari peternak lokal.', 'Sembako', 25000, 26500, 1, 1728345600, 1728345600);

-- Kios Tani Subur Makmur
INSERT OR REPLACE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-farm-01', 'farm-kios-subur', 'Pupuk NPK Phonska Plus 15-15-15 (5kg)', 'Pupuk majemuk untuk menyuburkan tanah dan mempercepat pembuahan tanaman.', 'Pertanian', 45000, 48000, 1, 1728345600, 1728345600),
    ('menu-farm-02', 'farm-kios-subur', 'Benih Padi Inpari 32 Hibrida 5kg', 'Benih unggul bersertifikasi resmi, tahan wereng batang coklat dan hawar daun.', 'Pertanian', 72000, 76000, 1, 1728345600, 1728345600);

-- Sentra Ternak Mandiri
INSERT OR REPLACE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-farm-03', 'farm-sentra-mandiri', 'Konsentrat Pakan Sapi Penggemukan Super 10kg', 'Formula khusus peningkat bobot harian sapi potong dengan protein tinggi.', 'Peternakan', 62000, 66000, 1, 1728345600, 1728345600);

-- TB Sumber Abadi
INSERT OR REPLACE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-build-01', 'build-sumber-abadi', 'Semen Gresik PPC 40kg Sak', 'Semen portland serbaguna daya rekat tinggi untuk pasangan bata dan plesteran.', 'Bahan Bangunan', 52000, 55000, 1, 1728345600, 1728345600),
    ('menu-build-02', 'build-sumber-abadi', 'Cat Tembok Nippon Paint Weatherbond 5kg', 'Cat eksterior premium tahan cuaca ekstrem dan anti lumut.', 'Bahan Bangunan', 120000, 126000, 1, 1728345600, 1728345600),
    ('menu-build-03', 'build-sumber-abadi', 'Besi Beton Polos SNI 8mm x 12m', 'Besi beton konstruksi standar SNI mutu terjamin untuk struktur cor.', 'Bahan Bangunan', 48000, 51000, 1, 1728345600, 1728345600);

-- 7. Insert Video Creator Feed dengan Keranjang Kuning Terhubung Riil
INSERT OR REPLACE INTO affiliate_videos (id, affiliator_user_id, tiktok_video_url, tiktok_video_id, merchant_id, menu_id, unique_tag, promo_voucher_code, view_count, order_count, total_earned, created_at)
VALUES 
    ('v-culinary-01', 'usr-aff-01', 'https://tiktok.com/@halugoods/video/1', '72834560001', 'mch-rc-01', 'menu-rc-01', '#GAGE_RC01', 'GAGE-AFF-RC01', 0, 0, 0, 1728345600),
    ('v-culinary-02', 'usr-aff-01', 'https://tiktok.com/@halugoods/video/2', '72834560002', 'mch-seblak-01', 'menu-seblak-01', '#GAGE_SEBLAK', 'GAGE-AFF-SB01', 0, 0, 0, 1728345600),
    ('v-culinary-04', 'usr-aff-01', 'https://tiktok.com/@halugoods/video/4', '72834560004', 'mch-mie-01', 'menu-mie-01', '#GAGE_MIE01', 'GAGE-AFF-MIE01', 0, 0, 0, 1728345600),
    ('v-shop-01', 'usr-aff-01', 'https://tiktok.com/@halugoods/video/5', '72834560005', 'shop-berkah-fajar', 'menu-shop-01', '#GAGE_SHOP01', 'GAGE-AFF-SHOP01', 0, 0, 0, 1728345600),
    ('v-farm-01', 'usr-aff-01', 'https://tiktok.com/@halugoods/video/6', '72834560006', 'farm-kios-subur', 'menu-farm-01', '#GAGE_FARM01', 'GAGE-AFF-FARM01', 0, 0, 0, 1728345600),
    ('v-build-01', 'usr-aff-01', 'https://tiktok.com/@halugoods/video/7', '72834560007', 'build-sumber-abadi', 'menu-build-01', '#GAGE_BUILD01', 'GAGE-AFF-BUILD01', 0, 0, 0, 1728345600);
