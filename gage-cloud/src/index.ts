import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { generateDynamicQRIS } from './qris';
import { TrackingRoomDO } from './room_do';

export { TrackingRoomDO };

type Bindings = {
  DB: D1Database;
  TRACKING_ROOM: DurableObjectNamespace;
  GAGE_ENV: string;
  DEFAULT_STATIC_QRIS: string;
  ADMIN_API_KEY: string;
};

const app = new Hono<{ Bindings: Bindings }>();

app.use('*', cors({
  origin: '*',
  allowHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));

app.get('/', (c) => {
  return c.json({
    status: 'online',
    service: 'GAGE Hyperlocal Delivery Cloud',
    version: '1.1.0',
    phase: 'Phase 1 - Customer App Engine',
    env: c.env.GAGE_ENV || 'production',
    timestamp: Math.floor(Date.now() / 1000),
  });
});

// Formula subsidi ongkir bertingkat
function calculateTieredDiscount(subtotal: number): number {
  if (subtotal >= 80000) return 5000;
  if (subtotal >= 50000) return 3000;
  if (subtotal >= 25000) return 1000;
  return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. AUTHENTICATION & USER SESSIONS (STANDALONE GOOGLE - NO FIREBASE)
// ─────────────────────────────────────────────────────────────────────────────

// Standalone Google Sign-In Token Verification
app.post('/api/auth/google', async (c) => {
  try {
    const body = await c.req.json();
    const idToken = (body.id_token || '').trim();

    if (!idToken) {
      return c.json({ success: false, message: 'Google ID Token wajib disertakan' }, 400);
    }

    // Verifikasi id_token ke Google OAuth endpoint resmi
    const googleRes = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`);
    if (!googleRes.ok) {
      const errText = await googleRes.text();
      return c.json({ success: false, message: 'Token Google tidak valid', detail: errText }, 401);
    }

    const payload: any = await googleRes.json();
    const sub = payload.sub; // Google User ID unik
    const email = payload.email || '';
    const name = payload.name || payload.given_name || 'Pengguna Gage';
    const avatar = payload.picture || null;
    const phone = (body.phone || '').trim();

    const userId = `usr-g-${sub.substring(0, 12)}`;
    const now = Math.floor(Date.now() / 1000);

    // Upsert ke database D1
    const existing: any = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first();

    if (existing) {
      await c.env.DB.prepare(
        `UPDATE users SET name = ?, avatar_url = COALESCE(?, avatar_url), phone = CASE WHEN phone = '' THEN ? ELSE phone END, updated_at = ? WHERE id = ?`
      ).bind(name, avatar, phone, now, userId).run();
    } else {
      await c.env.DB.prepare(
        `INSERT INTO users (id, phone, name, avatar_url, role, membership_tier, created_at, updated_at)
         VALUES (?, ?, ?, ?, 'user', 'free', ?, ?)`
      ).bind(userId, phone || '0812' + Math.floor(10000000 + Math.random() * 90000000), name, avatar, now, now).run();
    }

    // Pastikan wallet ada
    let wallet: any = await c.env.DB.prepare('SELECT * FROM wallets WHERE user_id = ?').bind(userId).first();
    if (!wallet) {
      const walletId = `wal-${userId}`;
      const welcomeBonus = 50000; // Saldo awal promosi dev/testing
      await c.env.DB.prepare(
        `INSERT INTO wallets (id, user_id, balance, points, created_at, updated_at) VALUES (?, ?, ?, 1000, ?, ?)`
      ).bind(walletId, userId, welcomeBonus, now, now).run();

      await c.env.DB.prepare(
        `INSERT INTO wallet_transactions (id, wallet_id, type, amount, balance_after, reference_id, description, created_at)
         VALUES (?, ?, 'TOPUP', ?, ?, 'BONUS_WELCOME', 'Bonus Selamat Datang GagePay', ?)`
      ).bind(`tx-init-${userId}`, walletId, welcomeBonus, welcomeBonus, now).run();

      wallet = { id: walletId, user_id: userId, balance: welcomeBonus, points: 1000 };
    }

    const userRecord: any = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first();
    const token = `gage_jwt_${userId}_${now}`;

    return c.json({
      success: true,
      message: 'Login Google berhasil',
      token,
      data: {
        user: userRecord,
        wallet,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Dev Quick Login Bypass (Lightning-Fast Testing di ADB Wireless)
app.post('/api/auth/dev-login', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const email = body.email || 'test-customer@gage.id';
    const name = body.name || 'Pelanggan Setia Gage';
    const phone = body.phone || '081234567893';
    const userId = body.user_id || 'usr-cust-01';
    const now = Math.floor(Date.now() / 1000);

    const existing: any = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first();
    if (!existing) {
      await c.env.DB.prepare(
        `INSERT INTO users (id, phone, name, avatar_url, role, membership_tier, created_at, updated_at)
         VALUES (?, ?, ?, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150', 'user', 'free', ?, ?)`
      ).bind(userId, phone, name, now, now).run();
    }

    let wallet: any = await c.env.DB.prepare('SELECT * FROM wallets WHERE user_id = ?').bind(userId).first();
    if (!wallet) {
      const walletId = `wal-${userId}`;
      await c.env.DB.prepare(
        `INSERT INTO wallets (id, user_id, balance, points, created_at, updated_at) VALUES (?, ?, 50000, 1500, ?, ?)`
      ).bind(walletId, userId, now, now).run();
      wallet = { id: walletId, user_id: userId, balance: 50000, points: 1500 };
    }

    const userRecord: any = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first();
    const token = `gage_dev_token_${userId}`;

    return c.json({
      success: true,
      message: 'Dev Login Berhasil',
      token,
      data: {
        user: userRecord,
        wallet,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Profile Detail & Update
app.get('/api/user/profile', async (c) => {
  const userId = c.req.query('user_id') || 'usr-cust-01';
  try {
    const user: any = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first();
    if (!user) {
      return c.json({ success: false, message: 'User tidak ditemukan' }, 404);
    }
    const wallet: any = await c.env.DB.prepare('SELECT * FROM wallets WHERE user_id = ?').bind(userId).first();
    const orderCount: any = await c.env.DB.prepare('SELECT COUNT(*) as count FROM orders WHERE user_id = ?').bind(userId).first();

    return c.json({
      success: true,
      data: {
        ...user,
        wallet: wallet || { balance: 0, points: 0 },
        total_orders: orderCount?.count || 0,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.post('/api/user/profile', async (c) => {
  try {
    const body = await c.req.json();
    const userId = body.user_id;
    if (!userId) return c.json({ success: false, message: 'user_id wajib' }, 400);

    const now = Math.floor(Date.now() / 1000);
    await c.env.DB.prepare(
      `UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone), updated_at = ? WHERE id = ?`
    ).bind(body.name || null, body.phone || null, now, userId).run();

    return c.json({ success: true, message: 'Profil berhasil diperbarui' });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. WALLET (GAGEPAY CLOSED-LOOP) & MUTASI TRANSAKSI
// ─────────────────────────────────────────────────────────────────────────────

app.get('/api/wallet/:userId', async (c) => {
  const userId = c.req.param('userId');
  try {
    let wallet: any = await c.env.DB.prepare('SELECT * FROM wallets WHERE user_id = ?').bind(userId).first();
    if (!wallet) {
      const walletId = `wal-${userId}`;
      const now = Math.floor(Date.now() / 1000);
      await c.env.DB.prepare('INSERT INTO wallets (id, user_id, balance, points, created_at, updated_at) VALUES (?, ?, 0, 0, ?, ?)')
        .bind(walletId, userId, now, now).run();
      wallet = { id: walletId, user_id: userId, balance: 0, points: 0 };
    }

    const txs = await c.env.DB.prepare(
      `SELECT * FROM wallet_transactions WHERE wallet_id = ? ORDER BY created_at DESC LIMIT 20`
    ).bind(wallet.id).all();

    return c.json({
      success: true,
      data: {
        wallet,
        transactions: txs.results,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.post('/api/wallet/topup', async (c) => {
  try {
    const body = await c.req.json();
    const userId = body.user_id || 'usr-cust-01';
    const amount = Number(body.amount);

    if (!amount || amount < 10000) {
      return c.json({ success: false, message: 'Nominal top-up minimal Rp 10.000' }, 400);
    }

    const staticQris = c.env.DEFAULT_STATIC_QRIS;
    const dynamicString = generateDynamicQRIS(staticQris, amount);
    const reference = `TOP-${Date.now().toString(36).toUpperCase()}`;
    const now = Math.floor(Date.now() / 1000);

    await c.env.DB.prepare(
      `INSERT INTO qris_transactions (id, reference_type, reference_id, amount, qris_string, status, created_at)
       VALUES (?, 'TOPUP', ?, ?, ?, 'PENDING', ?)`
    ).bind(reference, userId, amount, dynamicString, now).run();

    return c.json({
      success: true,
      data: {
        reference,
        amount,
        qris_string: dynamicString,
        created_at: now,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Simulasi top-up berhasil langsung (Instant testing)
app.post('/api/wallet/topup-simulate-success', async (c) => {
  try {
    const body = await c.req.json();
    const userId = body.user_id || 'usr-cust-01';
    const amount = Number(body.amount || 20000);
    const now = Math.floor(Date.now() / 1000);

    let wallet: any = await c.env.DB.prepare('SELECT * FROM wallets WHERE user_id = ?').bind(userId).first();
    const walletId = wallet?.id || `wal-${userId}`;

    if (!wallet) {
      await c.env.DB.prepare('INSERT INTO wallets (id, user_id, balance, points, created_at, updated_at) VALUES (?, ?, 0, 0, ?, ?)')
        .bind(walletId, userId, now, now).run();
      wallet = { balance: 0 };
    }

    const newBalance = wallet.balance + amount;
    await c.env.DB.prepare('UPDATE wallets SET balance = ?, updated_at = ? WHERE id = ?').bind(newBalance, now, walletId).run();

    const txId = `tx-top-${Date.now().toString(36)}`;
    await c.env.DB.prepare(
      `INSERT INTO wallet_transactions (id, wallet_id, type, amount, balance_after, reference_id, description, created_at)
       VALUES (?, ?, 'TOPUP', ?, ?, 'QRIS_INSTANT', 'Top-Up Saldo via QRIS Dinamis', ?)`
    ).bind(txId, walletId, amount, newBalance, now).run();

    return c.json({
      success: true,
      message: `Top-Up Rp ${amount.toLocaleString('id-ID')} berhasil!`,
      data: {
        wallet_id: walletId,
        new_balance: newBalance,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. MERCHANTS & CATALOG
// ─────────────────────────────────────────────────────────────────────────────

app.get('/api/merchants', async (c) => {
  try {
    const res = await c.env.DB.prepare('SELECT * FROM merchants WHERE is_open = 1 ORDER BY name ASC').all();
    return c.json({ success: true, data: res.results });
  } catch (err: any) {
    return c.json({ success: false, message: err.message, data: [] }, 500);
  }
});

app.get('/api/merchants/:id', async (c) => {
  const merchantId = c.req.param('id');
  try {
    const merchant: any = await c.env.DB.prepare('SELECT * FROM merchants WHERE id = ?').bind(merchantId).first();
    if (!merchant) return c.json({ success: false, message: 'Merchant tidak ditemukan' }, 404);

    const menus = await c.env.DB.prepare('SELECT * FROM merchant_menus WHERE merchant_id = ? ORDER BY category, name ASC').bind(merchantId).all();

    return c.json({
      success: true,
      data: {
        ...merchant,
        menus: menus.results,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.get('/api/merchants/:id/menu', async (c) => {
  const merchantId = c.req.param('id');
  try {
    const res = await c.env.DB.prepare('SELECT * FROM merchant_menus WHERE merchant_id = ? ORDER BY category, name ASC').bind(merchantId).all();
    return c.json({ success: true, data: res.results });
  } catch (err: any) {
    return c.json({ success: false, message: err.message, data: [] }, 500);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. ORDER CREATION, CALCULATION & LIFECYCLE
// ─────────────────────────────────────────────────────────────────────────────

app.post('/api/orders/calculate', async (c) => {
  const body = await c.req.json();
  const subtotal = Number(body.items_subtotal || 0);
  const distanceKm = Math.max(1, Number(body.distance_km || 1));
  const isCod = body.payment_method === 'CASH_COD';

  const adminFee = isCod ? 3000 : 1000;
  const baseRatePerKm = 3500;
  const rawShippingFee = Math.max(7000, Math.round(distanceKm * baseRatePerKm));
  const shippingDiscount = calculateTieredDiscount(subtotal);
  const finalShippingFee = Math.max(0, rawShippingFee - shippingDiscount);

  const driverCutPerKm = 3000;
  const driverCut = Math.max(6000, Math.round(distanceKm * driverCutPerKm));
  const merchantCut = Math.round(subtotal * 0.9);
  const totalAmount = subtotal + finalShippingFee + adminFee;

  return c.json({
    success: true,
    data: {
      items_subtotal: subtotal,
      distance_km: distanceKm,
      raw_shipping_fee: rawShippingFee,
      shipping_discount: shippingDiscount,
      final_shipping_fee: finalShippingFee,
      admin_fee: adminFee,
      total_amount: totalAmount,
      breakdown: {
        merchant_cut: merchantCut,
        driver_cut: driverCut,
        platform_cut: totalAmount - merchantCut - driverCut,
      },
    },
  });
});

app.post('/api/orders', async (c) => {
  try {
    const body = await c.req.json();
    const userId = body.user_id || 'usr-cust-01';
    const merchantId = body.merchant_id || 'm-dimsum-sewu';
    const items = body.items || [];
    const distanceKm = Math.max(1, Number(body.distance_km || 1.5));
    const paymentMethod = body.payment_method || 'GAGEPAY'; // 'GAGEPAY', 'QRIS', 'CASH_COD'
    const deliveryAddress = body.delivery_address || 'Jl. Wates Km 3, Kadipiro';
    const deliveryLat = Number(body.delivery_lat || -7.8012);
    const deliveryLng = Number(body.delivery_lng || 110.3456);
    const affiliatorId = body.affiliator_id || null;
    const promoCode = (body.promo_code || '').trim().toUpperCase();

    if (!items || items.length === 0) {
      return c.json({ success: false, message: 'Keranjang belanja kosong' }, 400);
    }

    let subtotal = 0;
    for (const item of items) {
      subtotal += Number(item.price) * Number(item.quantity);
    }

    const isCod = paymentMethod === 'CASH_COD';
    const adminFee = isCod ? 3000 : 1000;
    const rawShipping = Math.max(7000, Math.round(distanceKm * 3500));
    let shippingDiscount = calculateTieredDiscount(subtotal);

    // Voucher Kreator GAGERATIH / kode diskon
    if (promoCode === 'GAGERATIH') {
      shippingDiscount += 2000;
    }

    const finalShipping = Math.max(0, rawShipping - shippingDiscount);
    const totalAmount = subtotal + finalShipping + adminFee;

    // Proteksi COD Anti-Fraud
    if (isCod && totalAmount > 75000) {
      return c.json({
        success: false,
        message: 'Batas maksimal pesanan tunai (COD) untuk akun baru adalah Rp 75.000. Silakan pilih pembayaran QRIS atau GagePay.',
      }, 400);
    }

    const now = Math.floor(Date.now() / 1000);
    const orderId = `ord-${Date.now().toString(36)}`;
    const orderNumber = `GAGE-${Math.floor(1000 + Math.random() * 9000)}`;
    const trackingToken = `tok-${Date.now().toString(36)}`;

    let paymentStatus = 'UNPAID';
    let orderStatus = 'PAYMENT_PENDING';
    let dynamicQrisString: string | null = null;

    // Alur Pembayaran
    if (paymentMethod === 'GAGEPAY') {
      const wallet: any = await c.env.DB.prepare('SELECT * FROM wallets WHERE user_id = ?').bind(userId).first();
      if (!wallet || wallet.balance < totalAmount) {
        return c.json({
          success: false,
          message: `Saldo GagePay tidak mencukupi (Tersedia: Rp ${(wallet?.balance || 0).toLocaleString('id-ID')}, Dibutuhkan: Rp ${totalAmount.toLocaleString('id-ID')}). Silakan top-up terlebih dahulu.`,
        }, 400);
      }

      // Potong saldo GagePay
      const newBalance = wallet.balance - totalAmount;
      await c.env.DB.prepare('UPDATE wallets SET balance = ?, updated_at = ? WHERE id = ?').bind(newBalance, now, wallet.id).run();

      // Catat di ledger mutasi
      await c.env.DB.prepare(
        `INSERT INTO wallet_transactions (id, wallet_id, type, amount, balance_after, reference_id, description, created_at)
         VALUES (?, ?, 'PAYMENT', ?, ?, ?, ?, ?)`
      ).bind(`tx-${orderId}`, wallet.id, totalAmount, newBalance, orderId, `Pembayaran Pesanan #${orderNumber}`, now).run();

      paymentStatus = 'PAID';
      orderStatus = 'PAID';
    } else if (paymentMethod === 'QRIS') {
      const staticQris = c.env.DEFAULT_STATIC_QRIS;
      dynamicQrisString = generateDynamicQRIS(staticQris, totalAmount);
      await c.env.DB.prepare(
        `INSERT INTO qris_transactions (id, reference_type, reference_id, amount, qris_string, status, created_at)
         VALUES (?, 'ORDER', ?, ?, ?, 'PENDING', ?)`
      ).bind(`qris-${orderId}`, orderId, totalAmount, dynamicQrisString, now).run();
      paymentStatus = 'UNPAID';
      orderStatus = 'PAYMENT_PENDING';
    } else if (paymentMethod === 'CASH_COD') {
      paymentStatus = 'UNPAID';
      orderStatus = 'PAID'; // Langsung diteruskan ke resto
    }

    const driverCut = Math.max(6000, Math.round(distanceKm * 3000));
    const merchantCut = Math.round(subtotal * 0.9);
    const platformCut = totalAmount - merchantCut - driverCut;
    const affiliateCommission = (affiliatorId || promoCode === 'GAGERATIH') ? Math.round(subtotal * 0.10) : 0;

    // Simpan Pesanan ke D1
    await c.env.DB.prepare(
      `INSERT INTO orders (id, order_number, user_id, merchant_id, affiliator_id, status, payment_method, payment_status,
       items_subtotal, shipping_fee, shipping_discount, admin_fee, total_amount, merchant_cut, driver_cut, platform_cut,
       affiliate_commission, delivery_address, delivery_lat, delivery_lng, distance_km, tracking_token, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      orderId, orderNumber, userId, merchantId, affiliatorId, orderStatus, paymentMethod, paymentStatus,
      subtotal, rawShipping, shippingDiscount, adminFee, totalAmount, merchantCut, driverCut, platformCut,
      affiliateCommission, deliveryAddress, deliveryLat, deliveryLng, distanceKm, trackingToken, now, now
    ).run();

    // Simpan Detail Menu
    for (const item of items) {
      const itemId = `item-${Math.random().toString(36).substring(2, 9)}`;
      await c.env.DB.prepare(
        `INSERT INTO order_items (id, order_id, menu_id, name, price, quantity, subtotal, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      ).bind(
        itemId, orderId, item.menu_id || 'menu-01', item.name, item.price, item.quantity, item.price * item.quantity, item.notes || null
      ).run();
    }

    return c.json({
      success: true,
      message: 'Pesanan berhasil dibuat!',
      data: {
        order_id: orderId,
        order_number: orderNumber,
        total_amount: totalAmount,
        payment_method: paymentMethod,
        payment_status: paymentStatus,
        status: orderStatus,
        tracking_token: trackingToken,
        qris_string: dynamicQrisString,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Riwayat Pesanan Pengguna
app.get('/api/orders/user/:userId', async (c) => {
  const userId = c.req.param('userId');
  try {
    const res = await c.env.DB.prepare(
      `SELECT o.*, m.name as merchant_name, m.address as merchant_address, m.image_url as merchant_image,
              d.vehicle_plate as driver_plate, du.name as driver_name, du.phone as driver_phone
       FROM orders o
       JOIN merchants m ON o.merchant_id = m.id
       LEFT JOIN drivers d ON o.driver_id = d.id
       LEFT JOIN users du ON d.user_id = du.id
       WHERE o.user_id = ?
       ORDER BY o.created_at DESC`
    ).bind(userId).all();

    const orders = await Promise.all(res.results.map(async (order: any) => {
      const items = await c.env.DB.prepare('SELECT * FROM order_items WHERE order_id = ?').bind(order.id).all();
      return { ...order, items: items.results };
    }));

    return c.json({ success: true, count: orders.length, data: orders });
  } catch (err: any) {
    return c.json({ success: false, message: err.message, data: [] }, 500);
  }
});

// Detail Pesanan Tunggal & Live Status Tracker
app.get('/api/orders/:id', async (c) => {
  const orderId = c.req.param('id');
  try {
    const order: any = await c.env.DB.prepare(
      `SELECT o.*, m.name as merchant_name, m.address as merchant_address, m.phone_wa as merchant_phone, m.image_url as merchant_image,
              d.vehicle_plate as driver_plate, du.name as driver_name, du.phone as driver_phone
       FROM orders o
       JOIN merchants m ON o.merchant_id = m.id
       LEFT JOIN drivers d ON o.driver_id = d.id
       LEFT JOIN users du ON d.user_id = du.id
       WHERE o.id = ? OR o.order_number = ?`
    ).bind(orderId, orderId).first();

    if (!order) {
      return c.json({ success: false, message: 'Pesanan tidak ditemukan' }, 404);
    }

    const items = await c.env.DB.prepare('SELECT * FROM order_items WHERE order_id = ?').bind(order.id).all();

    return c.json({
      success: true,
      data: {
        ...order,
        items: items.results,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Endpoint Simulasi Transisi Status untuk Uji Coba Tracker Pelanggan
app.post('/api/orders/:id/simulate-stage', async (c) => {
  const orderId = c.req.param('id');
  const body = await c.req.json();
  const nextStage = body.stage; // 'PAID', 'COOKING', 'READY_FOR_PICKUP', 'ON_DELIVERY', 'COMPLETED'
  const now = Math.floor(Date.now() / 1000);
  try {
    await c.env.DB.prepare(
      `UPDATE orders SET status = ?, driver_id = COALESCE(driver_id, 'drv-01'), updated_at = ? WHERE id = ?`
    ).bind(nextStage, now, orderId).run();

    return c.json({ success: true, order_id: orderId, new_status: nextStage });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 5. MERCHANT KITCHEN, DRIVER, & AFFILIATE ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

app.get('/api/merchant/orders', async (c) => {
  const merchantId = c.req.query('merchant_id') || 'm-dimsum-sewu';
  try {
    const res = await c.env.DB.prepare(
      `SELECT o.*, u.name as customer_name, u.phone as customer_phone, d.vehicle_plate as driver_plate, du.name as driver_name
       FROM orders o
       JOIN users u ON o.user_id = u.id
       LEFT JOIN drivers d ON o.driver_id = d.id
       LEFT JOIN users du ON d.user_id = du.id
       WHERE o.merchant_id = ? AND o.status IN ('PAID', 'COOKING', 'READY_FOR_PICKUP')
       ORDER BY o.created_at DESC`
    ).bind(merchantId).all();

    const orders = await Promise.all(res.results.map(async (order: any) => {
      const items = await c.env.DB.prepare('SELECT * FROM order_items WHERE order_id = ?').bind(order.id).all();
      return { ...order, items: items.results };
    }));

    return c.json({ success: true, data: orders });
  } catch (err: any) {
    return c.json({ success: false, message: err.message, data: [] }, 500);
  }
});

app.post('/api/merchant/orders/:id/update-stage', async (c) => {
  const orderId = c.req.param('id');
  const body = await c.req.json();
  const nextStage = body.stage;
  const now = Math.floor(Date.now() / 1000);
  try {
    await c.env.DB.prepare('UPDATE orders SET status = ?, updated_at = ? WHERE id = ?').bind(nextStage, now, orderId).run();
    return c.json({
      success: true,
      data: { order_id: orderId, stage: nextStage, updated_at: now },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.get('/api/driver/orders/available', async (c) => {
  try {
    const res = await c.env.DB.prepare(
      `SELECT o.*, m.name as merchant_name, m.address as merchant_address, u.name as customer_name
       FROM orders o
       JOIN merchants m ON o.merchant_id = m.id
       JOIN users u ON o.user_id = u.id
       WHERE o.driver_id IS NULL AND o.status IN ('PAID', 'COOKING', 'READY_FOR_PICKUP')
       ORDER BY o.created_at ASC`
    ).all();

    const orders = await Promise.all(res.results.map(async (order: any) => {
      const items = await c.env.DB.prepare('SELECT * FROM order_items WHERE order_id = ?').bind(order.id).all();
      return { ...order, items: items.results };
    }));

    return c.json({ success: true, count: orders.length, data: orders });
  } catch (err: any) {
    return c.json({ success: false, message: err.message, count: 0, data: [] }, 500);
  }
});

app.post('/api/driver/orders/:id/accept', async (c) => {
  const orderId = c.req.param('id');
  const body = await c.req.json();
  const driverId = body.driver_id || 'drv-01';
  const now = Math.floor(Date.now() / 1000);
  try {
    await c.env.DB.prepare('UPDATE orders SET driver_id = ?, status = ?, updated_at = ? WHERE id = ?').bind(driverId, 'ON_DELIVERY', now, orderId).run();
    return c.json({
      success: true,
      data: { order_id: orderId, driver_id: driverId, status: 'ON_DELIVERY', assigned_at: now },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.post('/api/driver/orders/:id/status', async (c) => {
  const orderId = c.req.param('id');
  const body = await c.req.json();
  const newStatus = body.status;
  const now = Math.floor(Date.now() / 1000);
  try {
    await c.env.DB.prepare('UPDATE orders SET status = ?, updated_at = ? WHERE id = ?').bind(newStatus, now, orderId).run();
    if (newStatus === 'COMPLETED') {
      const order: any = await c.env.DB.prepare('SELECT * FROM orders WHERE id = ?').bind(orderId).first();
      if (order && order.driver_id) {
        const driver: any = await c.env.DB.prepare('SELECT user_id FROM drivers WHERE id = ?').bind(order.driver_id).first();
        if (driver) {
          await c.env.DB.prepare('UPDATE wallets SET balance = balance + ?, updated_at = ? WHERE user_id = ?').bind(order.driver_cut, now, driver.user_id).run();
        }
      }
    }
    return c.json({
      success: true,
      data: { order_id: orderId, status: newStatus, updated_at: now },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Affiliate Stats
app.get('/api/affiliate/stats/:code', async (c) => {
  const code = c.req.param('code');
  try {
    const user: any = await c.env.DB.prepare('SELECT id FROM users WHERE affiliate_code = ?').bind(code).first();
    if (!user) {
      return c.json({
        success: true,
        data: {
          affiliate_code: code,
          total_clicks: 0,
          total_orders: 0,
          conversion_rate: 0,
          total_commission_earned: 0,
        },
      });
    }

    const stats: any = await c.env.DB.prepare(
      `SELECT COUNT(*) as total_orders, COALESCE(SUM(affiliate_commission), 0) as total_commission
       FROM orders WHERE affiliator_id = ? AND status = 'COMPLETED'`
    ).bind(user.id).first();

    const clicks = 48; // Sample click count
    const orders = Number(stats?.total_orders || 0);
    const commission = Number(stats?.total_commission || 0);
    const convRate = clicks > 0 ? Number(((orders / clicks) * 100).toFixed(1)) : 0;

    return c.json({
      success: true,
      data: {
        affiliate_code: code,
        total_clicks: clicks,
        total_orders: orders,
        conversion_rate: convRate,
        total_commission_earned: commission,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Tracking Durable Object Proxy
app.all('/api/tracking/*', async (c) => {
  const trackingRoom = c.env.TRACKING_ROOM;
  if (!trackingRoom) {
    return c.json({ success: false, message: 'Durable Object binding tidak tersedia' }, 500);
  }

  const id = trackingRoom.idFromName('GLOBAL_GAGE_TRACKER');
  const stub = trackingRoom.get(id);

  const url = new URL(c.req.url);
  url.pathname = url.pathname.replace('/api/tracking', '');
  return stub.fetch(new Request(url.toString(), c.req.raw));
});

// Web Tracking View
app.get('/track/:token', (c) => {
  const token = c.req.param('token');
  const html = `<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pantau Pesanan GAGE: Live Tracking</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; background: #f8fafc; color: #1e293b; }
    .header { background: #E52320; color: white; padding: 16px; text-align: center; font-weight: bold; font-size: 18px; }
    .card { background: white; margin: 16px; padding: 16px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
    .status-badge { display: inline-block; background: #fee2e2; color: #b91c1c; padding: 6px 12px; border-radius: 20px; font-weight: 600; font-size: 14px; margin-bottom: 8px; }
    .map-box { height: 240px; background: #e2e8f0; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-weight: 500; color: #64748b; }
    .btn { display: block; width: 100%; box-sizing: border-box; background: #22c55e; color: white; text-align: center; text-decoration: none; padding: 14px; border-radius: 12px; font-weight: bold; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="header">GAGE: Pengantaran Cepat</div>
  <div class="card">
    <div class="status-badge">Driver Sedang Mengantar</div>
    <h3 style="margin: 4px 0 8px 0;">Pesanan #${token.substring(0, 8).toUpperCase()}</h3>
    <p style="margin: 0; color: #64748b; font-size: 14px;">Driver menuju lokasi pengantaran.</p>
    <div class="map-box" id="mapInfo" style="margin-top: 16px;">
      Menghubungkan ke GPS Live Driver...
    </div>
    <a href="https://wa.me/?text=Halo%20Driver%20Gage" class="btn">Hubungi Driver via WhatsApp</a>
  </div>
</body>
</html>`;
  return c.html(html);
});

export default app;
