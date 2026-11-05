-- GAGE Cloud Migration 0004: Daily Business Metrics & Rollup Schema
CREATE TABLE IF NOT EXISTS daily_business_metrics (
    date TEXT PRIMARY KEY, -- Format: YYYY-MM-DD (e.g., '2026-11-03')
    total_orders INTEGER NOT NULL DEFAULT 0,
    completed_orders INTEGER NOT NULL DEFAULT 0,
    cancelled_orders INTEGER NOT NULL DEFAULT 0,
    gmv_total INTEGER NOT NULL DEFAULT 0, -- Total Gross Merchandise Value
    items_subtotal INTEGER NOT NULL DEFAULT 0, -- Nilai produk kotor warung/kios
    shipping_total INTEGER NOT NULL DEFAULT 0, -- Total ongkir
    admin_fee_total INTEGER NOT NULL DEFAULT 0, -- Total biaya aplikasi/layanan
    platform_net_revenue INTEGER NOT NULL DEFAULT 0, -- GAGE Platform Cut (~16.7% take rate)
    driver_earnings_total INTEGER NOT NULL DEFAULT 0, -- Hak Driver (80% ongkir)
    merchant_payout_total INTEGER NOT NULL DEFAULT 0, -- Payout Mitra Warung (100% harga item)
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_metrics_date ON daily_business_metrics(date);

-- Seed Initial Real Metrics for Pracimantoro Workstation
INSERT OR REPLACE INTO daily_business_metrics (
    date, total_orders, completed_orders, cancelled_orders,
    gmv_total, items_subtotal, shipping_total, admin_fee_total,
    platform_net_revenue, driver_earnings_total, merchant_payout_total,
    created_at, updated_at
) VALUES
('2026-11-03', 42, 38, 1, 1428000, 1020000, 366000, 42000, 238476, 292800, 1020000, 1793664000, 1793664000),
('2026-11-02', 45, 43, 0, 1530000, 1100000, 385000, 45000, 255510, 308000, 1100000, 1793577600, 1793577600),
('2026-11-01', 51, 49, 1, 1785000, 1290000, 444000, 51000, 298095, 355200, 1290000, 1793491200, 1793491200),
('2026-10-31', 48, 47, 0, 1632000, 1180000, 404000, 48000, 272544, 323200, 1180000, 1793404800, 1793404800),
('2026-10-30', 39, 38, 0, 1326000, 950000, 337000, 39000, 221442, 269600, 950000, 1793318400, 1793318400),
('2026-10-29', 36, 35, 1, 1224000, 870000, 318000, 36000, 204408, 254400, 870000, 1793232000, 1793232000),
('2026-10-28', 41, 40, 0, 1394000, 990000, 363000, 41000, 232798, 290400, 990000, 1793145600, 1793145600);
