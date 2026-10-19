-- GAGE Cloud Migration 0003: Standalone Per-Screen Banners Table
CREATE TABLE IF NOT EXISTS banners (
    id TEXT PRIMARY KEY,
    screen_target TEXT NOT NULL, -- 'customer_home_hero', 'customer_food_explore', 'customer_tani', 'customer_shop', 'driver_home_info', 'merchant_home_info', 'admin_promo'
    title TEXT NOT NULL,
    subtitle TEXT,
    image_url TEXT NOT NULL,
    action_type TEXT DEFAULT 'NONE', -- 'DEEPLINK', 'EXTERNAL_URL', 'NONE'
    action_url TEXT,
    aspect_ratio TEXT NOT NULL DEFAULT '16:9',
    width_px INTEGER NOT NULL DEFAULT 1280,
    height_px INTEGER NOT NULL DEFAULT 720,
    is_active INTEGER NOT NULL DEFAULT 1,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_banners_screen ON banners(screen_target, is_active);

-- Initial seed standalone banners per screen (Zero duplicate banners across screens)
INSERT OR REPLACE INTO banners (id, screen_target, title, subtitle, image_url, action_type, action_url, aspect_ratio, width_px, height_px, is_active, display_order, created_at, updated_at) VALUES
('b-cust-home-1', 'customer_home_hero', 'GAGE Pracimantoro SuperApp', 'Layanan antar makanan, ojek, paket & sembako desa', 'assets/images/home_hero_banner.png', 'NONE', '', '16:9', 1280, 720, 1, 1, 1729245600, 1729245600),
('b-cust-food-1', 'customer_food_explore', 'Kuliner Juara Pracimantoro', 'Diskon s.d 50% kuliner hangat khas pasar', 'assets/images/food_hero_banner.png', 'NONE', '', '16:9', 1280, 720, 1, 1, 1729245600, 1729245600),
('b-cust-tani-1', 'customer_tani', 'Panen Raya & Hasil Tani', 'Langsung dari petani lokal Pracimantoro', 'assets/images/tani_hero_banner.png', 'NONE', '', '16:9', 1280, 720, 1, 1, 1729245600, 1729245600),
('b-cust-shop-1', 'customer_shop', 'Sembako & Kebutuhan Rumah', 'Belanja hemat tanpa repot keluar rumah', 'assets/images/send_hero_banner.png', 'NONE', '', '16:9', 1280, 720, 1, 1, 1729245600, 1729245600),
('b-driver-home-1', 'driver_home_info', 'Program Tupo Gaspol Mitra', 'Selesaikan 8 trip hari ini & raih bonus tunai Rp 25.000', 'assets/images/home_hero_banner.png', 'NONE', '', '3:1', 900, 300, 1, 1, 1729245600, 1729245600),
('b-merchant-home-1', 'merchant_home_info', 'Edukasi Mitra Resto & Kios', 'Perbarui stok menu tepat waktu untuk rating bintang 5', 'assets/images/food_hero_banner.png', 'NONE', '', '3:1', 900, 300, 1, 1, 1729245600, 1729245600),
('b-admin-promo-1', 'admin_promo', 'Radar Operasional Wilayah', 'Monitoring armada & pesanan se-Kecamatan Pracimantoro', 'assets/images/home_hero_banner.png', 'NONE', '', '16:9', 1280, 720, 1, 1, 1729245600, 1729245600);
