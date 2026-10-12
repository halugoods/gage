-- GAGE Cloud Database Schema v1.0 (Cloudflare D1 SQLite)
-- Standard Date/Time: Unix Timestamp in SECONDS (integers)

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    phone TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'user', -- 'user', 'driver', 'merchant', 'admin'
    tiktok_username TEXT,
    tiktok_verified INTEGER NOT NULL DEFAULT 0,
    affiliate_code TEXT UNIQUE,
    membership_tier TEXT NOT NULL DEFAULT 'free', -- 'free', 'plus', 'max'
    membership_expires_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS wallets (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE REFERENCES users(id),
    balance INTEGER NOT NULL DEFAULT 0, -- Saldo GagePay dalam Rupiah
    points INTEGER NOT NULL DEFAULT 0,  -- GagePoints reward
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
    id TEXT PRIMARY KEY,
    wallet_id TEXT NOT NULL REFERENCES wallets(id),
    type TEXT NOT NULL, -- 'TOPUP', 'PAYMENT', 'COMMISSION_CREDIT', 'REFUND', 'WITHDRAWAL'
    amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    reference_id TEXT,
    description TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS merchants (
    id TEXT PRIMARY KEY,
    owner_user_id TEXT NOT NULL REFERENCES users(id),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL DEFAULT 'Kuliner',
    address TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    phone_wa TEXT NOT NULL,
    image_url TEXT,
    is_open INTEGER NOT NULL DEFAULT 1,
    is_affiliate_enabled INTEGER NOT NULL DEFAULT 0,
    affiliate_commission_rate REAL NOT NULL DEFAULT 0.10, -- 0.05 s/d 0.15
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS merchant_menus (
    id TEXT PRIMARY KEY,
    merchant_id TEXT NOT NULL REFERENCES merchants(id),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'Makanan',
    offline_price INTEGER NOT NULL, -- Harga warung offline
    gage_price INTEGER NOT NULL,    -- Harga di Gage (auto-markup pembulatan)
    image_url TEXT,
    is_available INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS drivers (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE REFERENCES users(id),
    vehicle_plate TEXT NOT NULL,
    vehicle_type TEXT NOT NULL DEFAULT 'motor',
    latitude REAL,
    longitude REAL,
    is_online INTEGER NOT NULL DEFAULT 0,
    today_order_count INTEGER NOT NULL DEFAULT 0, -- Counter antrean adil harian
    last_active_at INTEGER,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    id TEXT PRIMARY KEY,
    order_number TEXT NOT NULL UNIQUE,
    user_id TEXT NOT NULL REFERENCES users(id),
    merchant_id TEXT NOT NULL REFERENCES merchants(id),
    driver_id TEXT REFERENCES drivers(id),
    affiliator_id TEXT REFERENCES users(id),
    affiliate_video_id TEXT,
    status TEXT NOT NULL DEFAULT 'PAYMENT_PENDING',
    payment_method TEXT NOT NULL, -- 'QRIS', 'GAGEPAY', 'CASH_COD'
    payment_status TEXT NOT NULL DEFAULT 'UNPAID', -- 'UNPAID', 'PAID', 'REFUNDED'
    items_subtotal INTEGER NOT NULL,
    shipping_fee INTEGER NOT NULL,
    shipping_discount INTEGER NOT NULL DEFAULT 0,
    admin_fee INTEGER NOT NULL DEFAULT 1000,
    total_amount INTEGER NOT NULL,
    merchant_cut INTEGER NOT NULL,
    driver_cut INTEGER NOT NULL,
    platform_cut INTEGER NOT NULL,
    affiliate_commission INTEGER NOT NULL DEFAULT 0,
    delivery_address TEXT NOT NULL,
    delivery_lat REAL NOT NULL,
    delivery_lng REAL NOT NULL,
    distance_km REAL NOT NULL,
    proof_image_url TEXT,
    tracking_token TEXT NOT NULL UNIQUE,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS order_items (
    id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES orders(id),
    menu_id TEXT NOT NULL REFERENCES merchant_menus(id),
    name TEXT NOT NULL,
    price INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    subtotal INTEGER NOT NULL,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS affiliate_videos (
    id TEXT PRIMARY KEY,
    affiliator_user_id TEXT NOT NULL REFERENCES users(id),
    tiktok_video_url TEXT NOT NULL,
    tiktok_video_id TEXT NOT NULL,
    merchant_id TEXT NOT NULL REFERENCES merchants(id),
    menu_id TEXT NOT NULL REFERENCES merchant_menus(id),
    unique_tag TEXT NOT NULL UNIQUE, -- e.g. '[GAGE#HGDS-M01]'
    promo_voucher_code TEXT,        -- e.g. 'GAGERATIH'
    view_count INTEGER NOT NULL DEFAULT 0,
    order_count INTEGER NOT NULL DEFAULT 0,
    total_earned INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS promos (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    discount_type TEXT NOT NULL DEFAULT 'FIXED', -- 'FIXED', 'PERCENT'
    discount_value INTEGER NOT NULL,
    min_order INTEGER NOT NULL DEFAULT 0,
    max_discount INTEGER,
    affiliator_user_id TEXT REFERENCES users(id),
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS qris_transactions (
    id TEXT PRIMARY KEY,
    reference_type TEXT NOT NULL, -- 'ORDER', 'TOPUP'
    reference_id TEXT NOT NULL,
    amount INTEGER NOT NULL,
    qris_string TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'PAID', 'EXPIRED'
    created_at INTEGER NOT NULL,
    paid_at INTEGER
);

CREATE TABLE IF NOT EXISTS payout_records (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    user_type TEXT NOT NULL, -- 'MERCHANT', 'DRIVER', 'AFFILIATE'
    amount INTEGER NOT NULL,
    bank_name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    account_holder TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'PROCESSED', 'REJECTED'
    batch_date TEXT NOT NULL,
    processed_at INTEGER,
    created_at INTEGER NOT NULL
);

-- Indexing untuk query cepat & hemat pembacaan D1
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_merchant_id ON orders(merchant_id);
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_tracking_token ON orders(tracking_token);
CREATE INDEX IF NOT EXISTS idx_menus_merchant_id ON merchant_menus(merchant_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_videos_tag ON affiliate_videos(unique_tag);
CREATE INDEX IF NOT EXISTS idx_affiliate_videos_affiliator ON affiliate_videos(affiliator_user_id);
