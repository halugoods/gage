-- GAGE Cloud Database Real Seed Data v1.0
-- UMKM Hyperlocal Kecamatan: Dimsum Sewu by Halu Goods

-- 1. Pengguna Utama (Owner, Affiliator, Driver, Customer)
INSERT OR IGNORE INTO users (id, phone, name, role, tiktok_username, tiktok_verified, affiliate_code, membership_tier, created_at, updated_at)
VALUES 
    ('usr-owner-01', '081234567890', 'Owner Dimsum Sewu', 'merchant', '@dimsumsewu', 1, 'DIMSUMSEWU', 'free', 1728345600, 1728345600),
    ('usr-aff-01', '081234567891', 'Ratih Pratiwi', 'user', '@ratih_kuliner', 1, 'GAGERATIH', 'free', 1728345600, 1728345600),
    ('usr-drv-01', '081234567892', 'Pak Sugeng', 'driver', NULL, 0, NULL, 'free', 1728345600, 1728345600),
    ('usr-cust-01', '081234567893', 'Pelanggan Gage', 'user', NULL, 0, NULL, 'free', 1728345600, 1728345600);

-- 2. Dompet Saldo Awal (Real Nol atau Saldo Aktif)
INSERT OR IGNORE INTO wallets (id, user_id, balance, points, created_at, updated_at)
VALUES 
    ('wal-owner-01', 'usr-owner-01', 0, 0, 1728345600, 1728345600),
    ('wal-aff-01', 'usr-aff-01', 0, 0, 1728345600, 1728345600),
    ('wal-drv-01', 'usr-drv-01', 0, 0, 1728345600, 1728345600),
    ('wal-cust-01', 'usr-cust-01', 50000, 100, 1728345600, 1728345600);

-- 3. Merchant Nyata: Dimsum Sewu by Halu Goods
INSERT OR IGNORE INTO merchants (id, owner_user_id, name, slug, category, address, latitude, longitude, phone_wa, is_open, is_affiliate_enabled, affiliate_commission_rate, created_at, updated_at)
VALUES 
    ('m-dimsum-sewu', 'usr-owner-01', 'Dimsum Sewu by Halu Goods', 'dimsum-sewu', 'Kuliner Dimsum', 'Jl. Wates Km 3, Kadipiro, Kasihan', -7.8012, 110.3456, '081234567890', 1, 1, 0.10, 1728345600, 1728345600);

-- 4. Menu Nyata Dimsum Sewu
INSERT OR IGNORE INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
VALUES 
    ('menu-ds-01', 'm-dimsum-sewu', 'Combo Mentai 6 Pcs', 'Dimsum ayam bakar keju saus mentai gurih pedas', 'Makanan', 13500, 15000, 1, 1728345600, 1728345600),
    ('menu-ds-02', 'm-dimsum-sewu', 'Dimsum Mozzarella 4 Pcs', 'Dimsum ayam kukus leleh keju mozzarella asli', 'Makanan', 11000, 12000, 1, 1728345600, 1728345600),
    ('menu-ds-03', 'm-dimsum-sewu', 'Dimsum Goreng Crispy 4 Pcs', 'Dimsum goreng renyah dengan saus asam manis', 'Makanan', 9000, 10000, 1, 1728345600, 1728345600),
    ('menu-ds-04', 'm-dimsum-sewu', 'Siomay Ayam Original 4 Pcs', 'Siomay ayam lembut disajikan hangat', 'Makanan', 10000, 11000, 1, 1728345600, 1728345600),
    ('menu-ds-05', 'm-dimsum-sewu', 'Es Teh Manis Jumbo', 'Es teh seduh daun melati segar gelas 22oz', 'Minuman', 2500, 3000, 1, 1728345600, 1728345600);

-- 5. Profil Driver Nyata
INSERT OR IGNORE INTO drivers (id, user_id, vehicle_plate, vehicle_type, latitude, longitude, is_online, today_order_count, created_at)
VALUES 
    ('drv-01', 'usr-drv-01', 'AB 4521 XY', 'motor', -7.8015, 110.3460, 1, 0, 1728345600);

-- 6. Promo Kode Voucher Nyata
INSERT OR IGNORE INTO promos (id, code, title, discount_type, discount_value, min_order, affiliator_user_id, is_active, created_at)
VALUES 
    ('prm-ratih', 'GAGERATIH', 'Diskon Ongkir Kreator Ratih', 'FIXED', 2000, 10000, 'usr-aff-01', 1, 1728345600);
