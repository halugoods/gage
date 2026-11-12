-- GAGE Cloud Migration 0006: Security, Order Lifecycle Parity & Transport/Pickup Sync
-- Additive D1 SQLite migration matching Flutter OrderModel, GagePricingService & Affiliate/Voucher sync

ALTER TABLE users ADD COLUMN email TEXT;

ALTER TABLE merchant_menus ADD COLUMN promo_price INTEGER;
ALTER TABLE merchant_menus ADD COLUMN promo_active INTEGER NOT NULL DEFAULT 0;

ALTER TABLE orders ADD COLUMN service_type TEXT NOT NULL DEFAULT 'food';
ALTER TABLE orders ADD COLUMN order_type TEXT NOT NULL DEFAULT 'DELIVERY';
ALTER TABLE orders ADD COLUMN delivery_option TEXT NOT NULL DEFAULT 'REGULER';
ALTER TABLE orders ADD COLUMN pickup_address TEXT;
ALTER TABLE orders ADD COLUMN pickup_lat REAL;
ALTER TABLE orders ADD COLUMN pickup_lng REAL;
ALTER TABLE orders ADD COLUMN driver_tip INTEGER NOT NULL DEFAULT 0;
ALTER TABLE orders ADD COLUMN item_discount INTEGER NOT NULL DEFAULT 0;
ALTER TABLE orders ADD COLUMN order_promo_code TEXT;
ALTER TABLE orders ADD COLUMN delivery_promo_code TEXT;
ALTER TABLE orders ADD COLUMN package_details_json TEXT;

CREATE TABLE IF NOT EXISTS pricing_config (
    id TEXT PRIMARY KEY,
    config_json TEXT NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS affiliate_payouts (
    id TEXT PRIMARY KEY,
    affiliate_code TEXT NOT NULL,
    amount INTEGER NOT NULL,
    bank_name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    account_holder TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING',
    created_at INTEGER NOT NULL
);
