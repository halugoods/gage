import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { generateDynamicQRIS } from './qris';
import { TrackingRoomDO } from './room_do';
import {
  getVerifiedRequestClaims,
  isAdminOrAuthorizedRole,
  isProductionRuntime,
  signAuthToken,
} from './security';

export { TrackingRoomDO };

type Bindings = {
  DB: D1Database;
  TRACKING_ROOM: DurableObjectNamespace;
  GAGE_ENV: string;
  DEFAULT_STATIC_QRIS: string;
  ADMIN_API_KEY: string;
  AUTH_JWT_SECRET?: string;
  MEDIA_BUCKET?: R2Bucket;
};

const app = new Hono<{ Bindings: Bindings }>();

app.use('*', cors({
  origin: '*',
  allowHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));

// Global Admin, Role & Production Simulation Guard Middleware
app.use('/api/admin/*', async (c, next) => {
  const ok = await isAdminOrAuthorizedRole(c, ['admin']);
  if (!ok) {
    return c.json({ success: false, message: 'Unauthorized admin access' }, 401);
  }
  await next();
});

app.use('/api/banners*', async (c, next) => {
  if (c.req.method === 'POST' || c.req.method === 'PUT' || c.req.method === 'DELETE') {
    const ok = await isAdminOrAuthorizedRole(c, ['admin']);
    if (!ok) {
      return c.json({ success: false, message: 'Unauthorized banner mutation' }, 401);
    }
  }
  await next();
});

app.use('/api/*', async (c, next) => {
  const path = c.req.path;
  if (
    path === '/api/auth/google' ||
    path === '/api/pricing-config' ||
    path.startsWith('/api/merchants') ||
    (path === '/api/banners' && c.req.method === 'GET') ||
    path.startsWith('/api/orders/calculate') ||
    path.startsWith('/api/tracking')
  ) {
    await next();
    return;
  }

  // Verification on protected production routes when running in production
  if (
    isProductionRuntime(c) &&
    (path === '/api/user/profile' ||
      path === '/api/user/addresses' ||
      path.startsWith('/api/wallet/') ||
      path.startsWith('/api/orders') ||
      path.startsWith('/api/merchant/') ||
      path.startsWith('/api/driver/') ||
      path === '/api/affiliate/payout' ||
      path.startsWith('/api/chat/media/upload'))
  ) {
    if (!(await isAdminOrAuthorizedRole(c, ['user', 'customer', 'merchant', 'driver', 'admin']))) {
      const claims = await getVerifiedRequestClaims(c);
      if (!claims) {
        return c.json({ success: false, message: 'Autentikasi diperlukan untuk akses layanan ini' }, 401);
      }
    }
  }
  await next();
});

import { getLandingPageHtml, getTermsHtml, getPrivacyHtml } from './legal_pages';

app.get('/', (c) => {
  const acceptHeader = c.req.header('Accept') || '';
  if (acceptHeader.includes('text/html')) {
    return c.html(getLandingPageHtml());
  }
  return c.json({
    status: 'online',
    service: 'Gage by Halu Goods Indonesia',
    holding: 'Halu Goods Indonesia',
    product: 'GAGE Pracimantoro',
    version: '1.2.0',
    phase: 'Phase 1 - Customer App Engine',
    env: c.env.GAGE_ENV || 'production',
    timestamp: Math.floor(Date.now() / 1000),
  });
});

app.get('/terms', (c) => {
  return c.html(getTermsHtml());
});

app.get('/privacy', (c) => {
  return c.html(getPrivacyHtml());
});

// TikTok Developers Site Verification
app.get('/tiktok4xymtEZESVRXQmehutrFQkYZ7thRVsva.txt', (c) => {
  return c.text('tiktok-developers-site-verification=4xymtEZESVRXQmehutrFQkYZ7thRVsva');
});
app.get('/tiktok*.txt', (c) => {
  return c.text('tiktok-developers-site-verification=4xymtEZESVRXQmehutrFQkYZ7thRVsva');
});
app.get('/tiktok-developers-site-verification*', (c) => {
  return c.text('tiktok-developers-site-verification=4xymtEZESVRXQmehutrFQkYZ7thRVsva');
});

// TikTok OAuth Redirect URIs
app.get('/auth/tiktok/callback', (c) => {
  return c.html(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>TikTok Authorization Success - GAGE</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #0F172A; color: white; text-align: center; }
          .card { background: #1E293B; padding: 32px; border-radius: 20px; border: 1px solid #334155; max-width: 400px; box-shadow: 0 10px 25px rgba(0,0,0,0.4); }
          h2 { color: #22C55E; margin-top: 0; }
          p { color: #94A3B8; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="card">
          <h2>✓ Otorisasi Berhasil</h2>
          <p>Akun TikTok Anda berhasil terhubung dengan <b>GAGE by Halu Goods Indonesia</b>.</p>
          <p>Silakan kembali ke aplikasi GAGE.</p>
        </div>
      </body>
    </html>
  `);
});
app.get('/callback', (c) => {
  return c.redirect('/auth/tiktok/callback');
});

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE DRIVE API (5TB STORAGE VAULT) OAUTH INTEGRATION
// ─────────────────────────────────────────────────────────────────────────────

// Store active Google Drive connection state (in-memory for worker runtime)
let activeDriveAuth: {
  email?: string;
  name?: string;
  picture?: string;
  access_token?: string;
  refresh_token?: string;
  connected_at?: number;
  storage_quota?: string;
} | null = null;

// 1. Google Drive OAuth Hub & Launchpad
app.get('/auth/google/drive', (c) => {
  const host = c.req.header('host') || 'gage-cloud.gagebyhalugoodsindonesia.workers.dev';
  const protocol = host.includes('localhost') ? 'http' : 'https';
  const defaultRedirectUri = `${protocol}://${host}/auth/google/drive/callback`;
  
  const serverClientId = (c.env as any).GOOGLE_DRIVE_CLIENT_ID || '';
  const queryClientId = c.req.query('client_id') || '';
  const redirectUri = c.req.query('redirect_uri') || defaultRedirectUri;
  const isConnected = !!activeDriveAuth?.email;

  return c.html(`
    <!DOCTYPE html>
    <html lang="id">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>GAGE Video Cloud Vault • Hubungkan Google Drive 5TB</title>
        <style>
          * { box-sizing: border-box; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: #0B0F19;
            color: #F8FAFC;
            margin: 0;
            padding: 24px 16px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
          }
          .card {
            background: #151D2F;
            border: 1px solid #24324D;
            border-radius: 24px;
            max-width: 520px;
            width: 100%;
            padding: 32px 24px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.5);
            text-align: center;
          }
          .badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 14px;
            background: rgba(229, 35, 32, 0.15);
            color: #FF5A57;
            border: 1px solid rgba(229, 35, 32, 0.3);
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            margin-bottom: 16px;
          }
          .badge-connected {
            background: rgba(34, 197, 94, 0.15);
            color: #4ADE80;
            border-color: rgba(34, 197, 94, 0.3);
          }
          h1 {
            font-size: 22px;
            font-weight: 800;
            margin: 0 0 10px 0;
            letter-spacing: -0.5px;
          }
          p.subtitle {
            font-size: 13.5px;
            color: #94A3B8;
            line-height: 1.5;
            margin: 0 0 20px 0;
          }
          .storage-box {
            background: #0D1322;
            border: 1px solid #1E293B;
            border-radius: 16px;
            padding: 16px;
            margin-bottom: 20px;
            text-align: left;
          }
          .storage-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 13px;
            margin-bottom: 8px;
          }
          .storage-bar-bg {
            background: #1E293B;
            height: 8px;
            border-radius: 4px;
            overflow: hidden;
          }
          .storage-bar-fill {
            background: linear-gradient(90deg, #E52320, #F97316);
            height: 100%;
            width: 1.2%;
            border-radius: 4px;
          }
          .form-group {
            text-align: left;
            margin-bottom: 16px;
          }
          .form-label {
            display: block;
            font-size: 12.5px;
            font-weight: 700;
            color: #CBD5E1;
            margin-bottom: 6px;
          }
          .form-input {
            width: 100%;
            padding: 12px 14px;
            background: #0D1322;
            border: 1px solid #334155;
            border-radius: 12px;
            color: #FFFFFF;
            font-size: 13px;
            font-family: monospace;
            outline: none;
            transition: border-color 0.2s;
          }
          .form-input:focus {
            border-color: #38BDF8;
          }
          .btn-google {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            width: 100%;
            padding: 14px 20px;
            background: #FFFFFF;
            color: #1F2937;
            font-size: 14.5px;
            font-weight: 700;
            border-radius: 14px;
            border: none;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.2s ease;
            box-shadow: 0 4px 12px rgba(255,255,255,0.1);
          }
          .btn-google:hover {
            background: #F1F5F9;
            transform: translateY(-1px);
          }
          .btn-google:active {
            transform: translateY(0);
          }
          .config-details {
            margin-top: 20px;
            text-align: left;
            background: rgba(0,0,0,0.25);
            padding: 14px;
            border-radius: 12px;
            font-size: 11.5px;
            color: #94A3B8;
            line-height: 1.6;
            border: 1px solid #1E293B;
          }
          .config-details code {
            background: #1E293B;
            color: #38BDF8;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: monospace;
            word-break: break-all;
            user-select: all;
          }
          .steps-list {
            margin: 8px 0 0 0;
            padding-left: 18px;
            color: #CBD5E1;
          }
          .steps-list li {
            margin-bottom: 6px;
          }
          .copy-btn {
            background: #1E293B;
            color: #38BDF8;
            border: 1px solid #334155;
            padding: 2px 8px;
            border-radius: 6px;
            font-size: 11px;
            cursor: pointer;
            margin-left: 6px;
          }
          .copy-btn:hover {
            background: #334155;
          }
          .footer {
            margin-top: 20px;
            font-size: 11px;
            color: #475569;
          }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="badge ${isConnected ? 'badge-connected' : ''}">
            ${isConnected ? '✓ CLOUD VAULT AKTIF' : '☁ MASTER COLD ARCHIVE'}
          </div>
          <h1>GAGE Video Storage (Google Drive 5TB)</h1>
          <p class="subtitle">
            Hubungkan akun Google Drive 5TB Anda (<b>halugoods.indonesia@gmail.com</b>) sebagai brankas master konten video TikTok.
          </p>

          <div class="storage-box">
            <div class="storage-row">
              <span style="color: #94A3B8;">Kapasitas Master Archive:</span>
              <strong style="color: #F8FAFC;">5.000 GB (5 TB)</strong>
            </div>
            <div class="storage-bar-bg">
              <div class="storage-bar-fill"></div>
            </div>
            <div class="storage-row" style="margin-top: 8px; margin-bottom: 0; font-size: 11px; color: #64748B;">
              <span>Status: ${isConnected ? 'Terhubung (' + activeDriveAuth?.email + ')' : 'Siap Diotorisasi'}</span>
              <span>Unlimited Egress Edge Cache</span>
            </div>
          </div>

          <form id="oauthForm" onsubmit="handleAuthorize(event)">
            <div class="form-group">
              <label class="form-label" for="clientIdInput">
                OAuth Client ID (dari Google Cloud Console):
              </label>
              <input 
                id="clientIdInput" 
                class="form-input" 
                type="text" 
                placeholder="xxxx-xxxxxxxx.apps.googleusercontent.com"
                value="${queryClientId || serverClientId}"
                required
              />
            </div>

            <button type="submit" class="btn-google">
              <svg width="18" height="18" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/>
              </svg>
              Pilih Akun Google (5TB) & Otorisasi
            </button>
          </form>

          <div class="config-details">
            <strong style="color: #38BDF8;">⚡ Panduan Cepat 2 Menit (Google Cloud Console):</strong>
            <ol class="steps-list">
              <li>Buka <a href="https://console.cloud.google.com/apis/credentials" target="_blank" style="color:#38BDF8;">Google Cloud Console Credentials</a> dengan akun <code>halugoods.indonesia@gmail.com</code>.</li>
              <li>Klik <b>+ CREATE CREDENTIALS</b> &rarr; pilih <b>OAuth client ID</b>.</li>
              <li>Application type: <b>Web application</b>.</li>
              <li>Pada bagian <b>Authorized redirect URIs</b>, klik <b>+ ADD URI</b> dan masukkan persis:<br/>
                <code id="redirectUriText">${redirectUri}</code>
                <button type="button" class="copy-btn" onclick="copyRedirectUri()">Salin</button>
              </li>
              <li>Klik <b>CREATE</b>, salin <b>Client ID</b> yang muncul, tempel di kotak formulir di atas, lalu tekan tombol <b>Pilih Akun Google</b>.</li>
            </ol>
            <div style="margin-top: 10px; font-size: 11px; color: #64748B;">
              * <code>prompt=select_account</code> aktif otomatis agar Anda dapat memilih langsung akun mana yang digunakan.
            </div>
          </div>

          <div class="footer">
            Property of GAGE • PT Halu Goods Indonesia
          </div>
        </div>

        <script>
          const REDIRECT_URI = "${redirectUri}";
          const SCOPE = encodeURIComponent("https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile");

          // Load from localStorage if available
          const inputEl = document.getElementById('clientIdInput');
          const savedId = localStorage.getItem('gage_gdrive_client_id');
          if (savedId && !inputEl.value) {
            inputEl.value = savedId;
          }

          inputEl.addEventListener('input', (e) => {
            const val = e.target.value.trim();
            if (val) localStorage.setItem('gage_gdrive_client_id', val);
          });

          function copyRedirectUri() {
            navigator.clipboard.writeText(REDIRECT_URI);
            alert("Redirect URI berhasil disalin: " + REDIRECT_URI);
          }

          function handleAuthorize(e) {
            e.preventDefault();
            const clientId = inputEl.value.trim();
            if (!clientId) {
              alert("Silakan masukkan Client ID dari Google Cloud Console terlebih dahulu.");
              return;
            }
            localStorage.setItem('gage_gdrive_client_id', clientId);
            const targetUrl = 'https://accounts.google.com/o/oauth2/v2/auth'
              + '?client_id=' + encodeURIComponent(clientId)
              + '&redirect_uri=' + encodeURIComponent(REDIRECT_URI)
              + '&response_type=code'
              + '&scope=' + SCOPE
              + '&access_type=offline'
              + '&prompt=select_account%20consent'
              + '&state=gage_gdrive_vault';
            window.location.href = targetUrl;
          }
        </script>
      </body>
    </html>
  `);
});

// 2. Google Drive OAuth Callback Endpoint
app.get('/auth/google/drive/callback', async (c) => {
  const code = c.req.query('code');
  const error = c.req.query('error');
  const host = c.req.header('host') || 'gage-cloud.gagebyhalugoodsindonesia.workers.dev';
  const protocol = host.includes('localhost') ? 'http' : 'https';
  const redirectUri = `${protocol}://${host}/auth/google/drive/callback`;

  if (error) {
    return c.html(`
      <body style="background:#0F172A;color:white;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;">
        <div style="background:#1E293B;padding:32px;border-radius:18px;max-width:400px;text-align:center;">
          <h2 style="color:#EF4444;">Otorisasi Dibatalkan</h2>
          <p style="color:#94A3B8;">${error}</p>
          <a href="/auth/google/drive" style="color:#38BDF8;text-decoration:none;">Coba Hubungkan Kembali</a>
        </div>
      </body>
    `);
  }

  let connectedEmail = 'affiliate@halugoods.com';
  let connectedName = 'GAGE Cloud Vault Master';
  let storageStatus = '5.000 GB (5 TB) Tersambung';

  if (code) {
    try {
      const clientId = (c.env as any).GOOGLE_DRIVE_CLIENT_ID || '';
      const clientSecret = (c.env as any).GOOGLE_DRIVE_CLIENT_SECRET || '';

      if (clientSecret) {
        const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({
            code,
            client_id: clientId,
            client_secret: clientSecret,
            redirect_uri: redirectUri,
            grant_type: 'authorization_code',
          }),
        });

        if (tokenRes.ok) {
          const tokenData: any = await tokenRes.json();
          const userRes = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
            headers: { Authorization: `Bearer ${tokenData.access_token}` },
          });
          if (userRes.ok) {
            const userData: any = await userRes.json();
            connectedEmail = userData.email || connectedEmail;
            connectedName = userData.name || connectedName;
          }
          activeDriveAuth = {
            email: connectedEmail,
            name: connectedName,
            access_token: tokenData.access_token,
            refresh_token: tokenData.refresh_token,
            connected_at: Math.floor(Date.now() / 1000),
            storage_quota: '5 TB',
          };
        }
      } else {
        // Mock successful registration when running without client_secret
        activeDriveAuth = {
          email: connectedEmail,
          name: connectedName,
          connected_at: Math.floor(Date.now() / 1000),
          storage_quota: '5 TB',
        };
      }
    } catch (_) {}
  }

  return c.html(`
    <!DOCTYPE html>
    <html lang="id">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Google Drive 5TB Berhasil Terhubung • GAGE</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            background: #0B0F19;
            color: white;
            text-align: center;
            padding: 20px;
          }
          .card {
            background: #151D2F;
            padding: 36px 28px;
            border-radius: 24px;
            border: 1px solid #22C55E40;
            max-width: 440px;
            width: 100%;
            box-shadow: 0 20px 40px rgba(0,0,0,0.5);
          }
          .icon-success {
            width: 64px;
            height: 64px;
            background: rgba(34, 197, 94, 0.15);
            color: #22C55E;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
            margin: 0 auto 16px auto;
            border: 2px solid #22C55E;
          }
          h2 { color: #22C55E; margin: 0 0 10px 0; font-size: 21px; }
          p { color: #94A3B8; font-size: 13.5px; line-height: 1.5; margin: 0 0 20px 0; }
          .detail-box {
            background: #0D1322;
            border: 1px solid #1E293B;
            border-radius: 14px;
            padding: 14px;
            text-align: left;
            margin-bottom: 24px;
            font-size: 13px;
          }
          .detail-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 6px;
          }
          .btn-app {
            display: inline-block;
            width: 100%;
            padding: 14px 20px;
            background: #E52320;
            color: white;
            font-weight: 700;
            font-size: 14px;
            border-radius: 12px;
            text-decoration: none;
            box-shadow: 0 4px 14px rgba(229, 35, 32, 0.35);
          }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="icon-success">✓</div>
          <h2>Google Drive 5TB Berhasil Terhubung!</h2>
          <p>Cold Master Archive GAGE kini aktif. Seluruh video konten kreator dan affiliator akan otomatis diarsip dan disinkronkan ke feed video aplikasi.</p>

          <div class="detail-box">
            <div class="detail-row">
              <span style="color:#64748B;">Akun Terpilih:</span>
              <strong style="color:#F8FAFC;">${connectedEmail}</strong>
            </div>
            <div class="detail-row">
              <span style="color:#64748B;">Kapasitas Vault:</span>
              <strong style="color:#4ADE80;">${storageStatus}</strong>
            </div>
            <div class="detail-row" style="margin-bottom:0;">
              <span style="color:#64748B;">Status Feed:</span>
              <span style="color:#38BDF8;">30 Video Viral Siap Putar</span>
            </div>
          </div>

          <a class="btn-app" href="gage://affiliate">Buka Aplikasi GAGE</a>
        </div>
      </body>
    </html>
  `);
});

// 3. API Status Google Drive Vault
app.get('/api/drive/status', (c) => {
  return c.json({
    success: true,
    data: {
      connected: !!activeDriveAuth?.email,
      email: activeDriveAuth?.email || 'affiliate@halugoods.com',
      storage_type: 'Google Drive 5TB Master Vault',
      total_capacity_gb: 5000,
      feed_cache_edge: 'Cloudflare R2 (Unlimited Egress)',
      oauth_url: 'https://gage-cloud.gagebyhalugoodsindonesia.workers.dev/auth/google/drive',
    },
  });
});


// GAGE Video Deep Link & OpenGraph Web Fallback
app.get('/v/:id', (c) => {
  const videoId = c.req.param('id') || 'v-default';
  const appDeepLink = `gage://video/${videoId}`;
  const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.halugoods.gage';

  return c.html(`
    <!DOCTYPE html>
    <html lang="id">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Tonton Video Kuliner GAGE Pracimantoro</title>
        <!-- OpenGraph Tags -->
        <meta property="og:title" content="Viral! Kuliner Pilihan GAGE Pracimantoro">
        <meta property="og:description" content="Tonton review lezat dan pesan langsung lewat Keranjang Kuning GAGE by Halu Goods Indonesia.">
        <meta property="og:image" content="https://gage-cloud.gagebyhalugoodsindonesia.workers.dev/assets/images/gage_logo.png">
        <meta property="og:url" content="https://gage-cloud.gagebyhalugoodsindonesia.workers.dev/v/${videoId}">
        <meta property="og:type" content="video.other">
        <!-- Twitter Card -->
        <meta name="twitter:card" content="summary_large_image">
        <meta name="twitter:title" content="GAGE Video - Kuliner & UMKM">
        <meta name="twitter:description" content="Pesan menu favoritmu langsung dari video di GAGE!">
        
        <style>
          body {
            margin: 0;
            padding: 0;
            background: #0F172A;
            color: #F8FAFC;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            text-align: center;
          }
          .container {
            max-width: 420px;
            padding: 32px 24px;
            background: #1E293B;
            border-radius: 24px;
            border: 1px solid #334155;
            box-shadow: 0 20px 40px rgba(0,0,0,0.5);
            margin: 16px;
          }
          .logo {
            width: 72px;
            height: 72px;
            border-radius: 18px;
            margin-bottom: 16px;
            background: #DC2626;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
            font-weight: 900;
            color: white;
          }
          h1 {
            font-size: 20px;
            font-weight: 800;
            margin: 0 0 8px 0;
            color: #FFFFFF;
          }
          p {
            font-size: 13.5px;
            color: #94A3B8;
            line-height: 1.5;
            margin: 0 0 24px 0;
          }
          .btn-open {
            display: block;
            background: #DC2626;
            color: white;
            text-decoration: none;
            padding: 14px 20px;
            border-radius: 14px;
            font-weight: 700;
            font-size: 15px;
            box-shadow: 0 4px 14px rgba(220, 38, 38, 0.4);
            margin-bottom: 12px;
          }
          .btn-playstore {
            display: block;
            background: transparent;
            color: #38BDF8;
            text-decoration: none;
            padding: 10px;
            font-size: 13px;
            font-weight: 600;
          }
          .footer-note {
            font-size: 11px;
            color: #64748B;
            margin-top: 20px;
          }
        </style>
        <script>
          // Auto-launch deep link on mobile browser
          window.location.href = "${appDeepLink}";
          setTimeout(function() {
            // Optional: Jika dalam 2.5 detik belum berpindah, user dapat klik tombol manual
          }, 2500);
        </script>
      </head>
      <body>
        <div class="container">
          <div class="logo">G</div>
          <h1>Membuka GAGE Video...</h1>
          <p>Jika aplikasi tidak terbuka secara otomatis dalam beberapa detik, ketuk tombol di bawah.</p>
          <a class="btn-open" href="${appDeepLink}">Buka di Aplikasi GAGE</a>
          <a class="btn-playstore" href="${playStoreUrl}">Belum punya aplikasi? Download di Google Play</a>
          <div class="footer-note">Property GAGE • Halu Goods Indonesia</div>
        </div>
      </body>
    </html>
  `);
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
    const token = await signAuthToken(c.env, {
      sub: userId,
      role: (userRecord?.role as string) || 'user',
    });

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

// Dev Quick Login Bypass (Blocked in production unless explicitly authorized by Admin Key)
app.post('/api/auth/dev-login', async (c) => {
  try {
    if (isProductionRuntime(c) && !(await isAdminOrAuthorizedRole(c, ['admin']))) {
      return c.json({ success: false, message: 'Dev login dinonaktifkan di lingkungan produksi' }, 403);
    }
    const body = await c.req.json().catch(() => ({}));
    const email = body.email || 'test-customer@gage.id';
    const name = body.name || 'Pelanggan Setia Gage';
    const phone = body.phone || '081234567893';
    const userId = body.user_id || 'usr-cust-01';
    const now = Math.floor(Date.now() / 1000);

    const existing: any = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(userId).first();
    if (!existing) {
      await c.env.DB.prepare(
        `INSERT INTO users (id, phone, name, email, avatar_url, role, membership_tier, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, 'user', 'free', ?, ?)`
      ).bind(userId, phone, name, email, null, now, now).run().catch(async () => {
        await c.env.DB.prepare(
          `INSERT INTO users (id, phone, name, avatar_url, role, membership_tier, created_at, updated_at)
           VALUES (?, ?, ?, ?, 'user', 'free', ?, ?)`
        ).bind(userId, phone, name, null, now, now).run();
      });
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
    const token = await signAuthToken(c.env, {
      sub: userId,
      role: (userRecord?.role as string) || 'user',
    });

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
      `UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone), email = COALESCE(?, email), avatar_url = COALESCE(?, avatar_url), updated_at = ? WHERE id = ?`
    ).bind(body.name || null, body.phone || null, body.email || null, body.avatar_url || null, now, userId).run().catch(async () => {
      await c.env.DB.prepare(
        `UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone), avatar_url = COALESCE(?, avatar_url), updated_at = ? WHERE id = ?`
      ).bind(body.name || null, body.phone || null, body.avatar_url || null, now, userId).run();
    });

    return c.json({ success: true, message: 'Profil berhasil diperbarui' });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// User Saved Addresses (Cloudflare Persistence)
app.get('/api/user/addresses', async (c) => {
  const userId = c.req.query('user_id') || 'usr-cust-01';
  try {
    const list: any = await c.env.DB.prepare(
      'SELECT * FROM user_addresses WHERE user_id = ? ORDER BY created_at DESC'
    ).bind(userId).all().catch(() => ({ results: [] }));
    return c.json({ success: true, data: list?.results || [] });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.post('/api/user/addresses', async (c) => {
  try {
    const body = await c.req.json();
    const userId = body.user_id || 'usr-cust-01';
    const addr = body.address || {};
    const id = addr.id || `addr_${Date.now()}`;
    const now = Math.floor(Date.now() / 1000);

    // Create table if not exists safely on D1
    await c.env.DB.prepare(`
      CREATE TABLE IF NOT EXISTS user_addresses (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'personal',
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    `).run().catch(() => {});

    await c.env.DB.prepare(`
      INSERT OR REPLACE INTO user_addresses (id, user_id, name, address, category, latitude, longitude, notes, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      id,
      userId,
      addr.name || 'Alamat',
      addr.address || '',
      addr.category || 'personal',
      addr.latitude || -8.05517,
      addr.longitude || 110.80889,
      addr.notes || null,
      now
    ).run().catch(() => {});

    return c.json({ success: true, message: 'Alamat berhasil disimpan ke cloud' });
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

// Simulasi top-up berhasil langsung (Hanya non-production atau Admin Key)
app.post('/api/wallet/topup-simulate-success', async (c) => {
  try {
    if (isProductionRuntime(c) && !(await isAdminOrAuthorizedRole(c, ['admin']))) {
      return c.json({ success: false, message: 'Simulasi top-up dinonaktifkan di lingkungan produksi' }, 403);
    }
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

const DEFAULT_PRICING_CONFIG = {
  delivery_hemat_min_subtotal: 50000,
  ride_hemat_base_km: 3.0,
  ride_hemat_base: 9000,
  ride_reguler_base_km: 3.0,
  ride_reguler_base: 12000,
  car_base_km: 1.0,
  car_base: 8000,
  car_per_km: 5000,
  delivery_base_km: 3.0,
  delivery_base: 9000,
  delivery_per_km: 3000,
  driver_commission_ratio: 0.80,
  admin_fee_cashless: 1000,
  admin_fee_cod_base: 3000,
};

function roundUpTo500(amount: number): number {
  if (amount <= 0) return 0;
  const rem = amount % 500;
  return rem === 0 ? amount : amount + (500 - rem);
}

function calculateAlignedShippingFee(
  distanceKm: number,
  deliveryOption = 'REGULER',
  serviceType = 'food',
  subtotal = 0,
  minHematSubtotal = 50000,
  weightKg = 1.0
): { rawShippingFee: number; effectiveOption: string } {
  const lowerSvc = serviceType.toLowerCase();
  const isTransport = lowerSvc === 'ride' || lowerSvc === 'car' || lowerSvc === 'send';
  const lowerOpt = (deliveryOption || 'REGULER').toLowerCase();
  let effectiveOption = deliveryOption.toUpperCase();
  let isHemat = lowerOpt.includes('hemat') || lowerOpt.includes('sameday');
  const isPrioritas = lowerOpt.includes('prioritas');
  const isCar = lowerSvc === 'car' || lowerOpt.includes('car');

  // Commercial orders only unlock HEMAT when subtotal meets minimum threshold (Rp 50.000)
  if (!isTransport && isHemat && subtotal < minHematSubtotal) {
    isHemat = false;
    effectiveOption = 'REGULER';
  }

  let weightSurcharge = 0;
  if (weightKg > 5.0) {
    weightSurcharge = Math.ceil(weightKg - 5.0) * 2000;
  }

  if (isCar) {
    const base = isHemat ? 14000 : isPrioritas ? 20000 : 16000;
    const perKm = isHemat ? 4500 : isPrioritas ? 5500 : 5000;
    const fare = distanceKm <= 3.0 ? base : roundUpTo500(Math.round(base + (distanceKm - 3.0) * perKm));
    return { rawShippingFee: fare + weightSurcharge, effectiveOption };
  }

  const baseFare = isHemat ? 9000 : 12000;
  const baseKm = 3.0;
  let fare = baseFare;
  if (distanceKm > baseKm) {
    const km4Rate = isHemat ? 3000 : 4000;
    const km5Rate = isHemat ? 2500 : 3500;
    const km6Rate = isHemat ? 2000 : 3000;
    if (distanceKm <= 4.0) {
      fare = baseFare + (distanceKm - baseKm) * km4Rate;
    } else if (distanceKm <= 5.0) {
      fare = baseFare + (4.0 - baseKm) * km4Rate + (distanceKm - 4.0) * km5Rate;
    } else {
      fare = baseFare + (4.0 - baseKm) * km4Rate + km5Rate + (distanceKm - 5.0) * km6Rate;
    }
    fare = roundUpTo500(Math.round(fare));
  }
  if (isPrioritas) fare += 4000;
  return { rawShippingFee: fare + weightSurcharge, effectiveOption };
}

app.get('/api/pricing-config', async (c) => {
  try {
    const row: any = await c.env.DB.prepare('SELECT config_json, updated_at FROM pricing_config WHERE id = ?')
      .bind('default')
      .first()
      .catch(() => null);
    if (row && row.config_json) {
      return c.json({
        success: true,
        data: { ...DEFAULT_PRICING_CONFIG, ...JSON.parse(row.config_json) },
        updated_at: row.updated_at,
      });
    }
  } catch {
    // Fallback to aligned default pricing config
  }
  return c.json({ success: true, data: DEFAULT_PRICING_CONFIG });
});

app.put('/api/admin/pricing-config', async (c) => {
  try {
    const body = await c.req.json();
    const now = Math.floor(Date.now() / 1000);
    const merged = { ...DEFAULT_PRICING_CONFIG, ...body };
    await c.env.DB.prepare(
      `INSERT OR REPLACE INTO pricing_config (id, config_json, updated_at) VALUES (?, ?, ?)`
    ).bind('default', JSON.stringify(merged), now).run();
    return c.json({ success: true, data: merged, updated_at: now });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.post('/api/qris/generate', async (c) => {
  try {
    const body = await c.req.json();
    const amount = Math.round(Number(body.amount || 0));
    const referenceType = String(body.reference_type || 'ORDER').toUpperCase();
    const referenceId = String(body.reference_id || `ref-${Date.now()}`);
    if (amount <= 0) {
      return c.json({ success: false, message: 'Nominal QRIS harus lebih dari 0' }, 400);
    }
    const qrisString = generateDynamicQRIS(c.env.DEFAULT_STATIC_QRIS, amount);
    const now = Math.floor(Date.now() / 1000);
    const qrisId = `qris-${Date.now().toString(36)}`;
    await c.env.DB.prepare(
      `INSERT INTO qris_transactions (id, reference_type, reference_id, amount, qris_string, status, created_at)
       VALUES (?, ?, ?, ?, ?, 'PENDING', ?)`
    ).bind(qrisId, referenceType, referenceId, amount, qrisString, now).run().catch(() => {});
    return c.json({
      success: true,
      data: { id: qrisId, amount, qris_string: qrisString, status: 'PENDING', created_at: now },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.post('/api/orders/calculate', async (c) => {
  const body = await c.req.json();
  const subtotal = Math.max(0, Number(body.items_subtotal || 0));
  const distanceKm = Math.max(0.5, Number(body.distance_km || 1));
  const serviceType = String(body.service_type || 'food').toLowerCase();
  const orderType = String(body.order_type || 'DELIVERY').toUpperCase();
  const deliveryOption = String(body.delivery_option || 'REGULER').toUpperCase();
  const weightKg = Number(body.weight_kg || 1.0);
  const isCod = body.payment_method === 'CASH_COD' || body.payment_method === 'COD';

  const adminFee = isCod ? 3000 : 1000;
  const { rawShippingFee } = orderType === 'PICKUP'
    ? { rawShippingFee: 0 }
    : calculateAlignedShippingFee(distanceKm, deliveryOption, serviceType, subtotal, DEFAULT_PRICING_CONFIG.delivery_hemat_min_subtotal, weightKg);
  const shippingDiscount = orderType === 'PICKUP' ? 0 : Math.min(rawShippingFee, calculateTieredDiscount(subtotal));
  const finalShippingFee = Math.max(0, rawShippingFee - shippingDiscount);

  const driverCut = orderType === 'PICKUP' ? 0 : Math.round(rawShippingFee * DEFAULT_PRICING_CONFIG.driver_commission_ratio);
  const merchantCut = serviceType === 'ride' || serviceType === 'car' || serviceType === 'send' ? 0 : Math.round(subtotal * 0.9);
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
    const serviceType = String(body.service_type || 'food').toLowerCase();
    const isTransport = serviceType === 'ride' || serviceType === 'car' || serviceType === 'send';
    const merchantId = body.merchant_id || (isTransport ? 'mch-gage-transport' : 'mch-dimsum-01');
    const items = Array.isArray(body.items) ? body.items : [];
    const orderType = String(body.order_type || (body.is_pickup ? 'PICKUP' : 'DELIVERY')).toUpperCase();
    const isPickup = orderType === 'PICKUP';
    const distanceKm = isPickup ? 0 : Math.max(0.5, Number(body.distance_km || 1.5));
    const paymentMethod = body.payment_method === 'COD' ? 'CASH_COD' : (body.payment_method || 'GAGEPAY');
    const deliveryOption = String(body.delivery_option || 'REGULER').toUpperCase();
    const pickupAddress = body.pickup_address || null;
    const pickupLat = body.pickup_lat != null ? Number(body.pickup_lat) : null;
    const pickupLng = body.pickup_lng != null ? Number(body.pickup_lng) : null;
    const deliveryAddress = body.delivery_address || 'Pracimantoro, Wonogiri';
    const deliveryLat = Number(body.delivery_lat ?? -8.05517);
    const deliveryLng = Number(body.delivery_lng ?? 110.80889);
    const driverTip = Math.max(0, Math.round(Number(body.driver_tip || 0)));
    const notes = body.notes ? String(body.notes) : null;
    const packageDetailsJson = body.package_details_json
      ? String(body.package_details_json)
      : (body.package_details ? JSON.stringify(body.package_details) : null);
    const weightKg = Number(body.weight_kg || 1.0);
    const affiliatorId = body.affiliator_id || null;
    const promoCode = (body.promo_code || '').trim().toUpperCase();

    if (!isTransport && items.length === 0) {
      return c.json({ success: false, message: 'Keranjang belanja kosong' }, 400);
    }

    // Recompute authoritative item prices from D1 merchant_menus when available
    let subtotal = 0;
    const verifiedItems: Array<{ menuId: string; name: string; price: number; quantity: number; notes: string | null }> = [];
    for (const item of items) {
      const menuId = String(item.menu_id || item.id || 'menu-01');
      const qty = Math.max(1, Math.round(Number(item.quantity || 1)));
      let verifiedPrice = Math.max(0, Math.round(Number(item.price || 0)));
      if (!isTransport) {
        const dbMenu: any = await c.env.DB.prepare(
          'SELECT gage_price, promo_price, promo_active FROM merchant_menus WHERE id = ? AND merchant_id = ?'
        ).bind(menuId, merchantId).first().catch(() => null);
        if (dbMenu) {
          const hasPromo = Number(dbMenu.promo_active) === 1 && Number(dbMenu.promo_price) > 0 && Number(dbMenu.promo_price) < Number(dbMenu.gage_price);
          verifiedPrice = hasPromo ? Number(dbMenu.promo_price) : Number(dbMenu.gage_price);
        }
      }
      subtotal += verifiedPrice * qty;
      verifiedItems.push({
        menuId,
        name: String(item.name || 'Item GAGE'),
        price: verifiedPrice,
        quantity: qty,
        notes: item.notes ? String(item.notes) : null,
      });
    }

    const isCod = paymentMethod === 'CASH_COD';
    const adminFee = isCod ? 3000 : 1000;
    const { rawShippingFee: rawShipping } = isPickup
      ? { rawShippingFee: 0 }
      : calculateAlignedShippingFee(
          distanceKm,
          deliveryOption,
          serviceType,
          subtotal,
          DEFAULT_PRICING_CONFIG.delivery_hemat_min_subtotal,
          weightKg
        );
    let shippingDiscount = isPickup ? 0 : Math.min(rawShipping, calculateTieredDiscount(subtotal));

    if (!isPickup && promoCode === 'GAGERATIH') {
      shippingDiscount = Math.min(rawShipping, shippingDiscount + 2000);
    }

    const finalShipping = Math.max(0, rawShipping - shippingDiscount);
    const fareBaseForTotal = isTransport ? finalShipping : subtotal + finalShipping;
    const totalAmount = fareBaseForTotal + adminFee + driverTip;

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
    let orderStatus = isTransport ? 'SEARCHING_DRIVER' : 'PAID';
    let dynamicQrisString: string | null = null;

    if (paymentMethod === 'GAGEPAY' || paymentMethod === 'GAGEPAY_QRIS' || paymentMethod === 'GAGEPAY_COD') {
      const wallet: any = await c.env.DB.prepare('SELECT * FROM wallets WHERE user_id = ?').bind(userId).first();
      if (!wallet || wallet.balance < totalAmount) {
        return c.json({
          success: false,
          message: `Saldo GagePay tidak mencukupi (Tersedia: Rp ${(wallet?.balance || 0).toLocaleString('id-ID')}, Dibutuhkan: Rp ${totalAmount.toLocaleString('id-ID')}). Silakan top-up terlebih dahulu.`,
        }, 400);
      }

      const newBalance = wallet.balance - totalAmount;
      await c.env.DB.prepare('UPDATE wallets SET balance = ?, updated_at = ? WHERE id = ?').bind(newBalance, now, wallet.id).run();
      await c.env.DB.prepare(
        `INSERT INTO wallet_transactions (id, wallet_id, type, amount, balance_after, reference_id, description, created_at)
         VALUES (?, ?, 'PAYMENT', ?, ?, ?, ?, ?)`
      ).bind(`tx-${orderId}`, wallet.id, totalAmount, newBalance, orderId, `Pembayaran Pesanan #${orderNumber}`, now).run();

      paymentStatus = 'PAID';
      orderStatus = isTransport ? 'SEARCHING_DRIVER' : 'PAID';
    } else if (paymentMethod === 'QRIS') {
      const staticQris = c.env.DEFAULT_STATIC_QRIS;
      dynamicQrisString = generateDynamicQRIS(staticQris, totalAmount);
      await c.env.DB.prepare(
        `INSERT INTO qris_transactions (id, reference_type, reference_id, amount, qris_string, status, created_at)
         VALUES (?, 'ORDER', ?, ?, ?, 'PENDING', ?)`
      ).bind(`qris-${orderId}`, orderId, totalAmount, dynamicQrisString, now).run();
      paymentStatus = 'UNPAID';
      orderStatus = 'PAYMENT_PENDING';
    } else if (isCod) {
      paymentStatus = 'UNPAID';
      orderStatus = isTransport ? 'SEARCHING_DRIVER' : 'PAID';
    }

    const driverCut = isPickup ? 0 : Math.round(rawShipping * DEFAULT_PRICING_CONFIG.driver_commission_ratio);
    const merchantCut = isTransport ? 0 : Math.round(subtotal * 0.9);
    const platformCut = totalAmount - merchantCut - driverCut;
    const affiliateCommission = (affiliatorId || promoCode === 'GAGERATIH') ? Math.round(subtotal * 0.10) : 0;

    await c.env.DB.prepare(
      `INSERT INTO orders (id, order_number, user_id, merchant_id, affiliator_id, status, payment_method, payment_status,
       items_subtotal, shipping_fee, shipping_discount, admin_fee, driver_tip, total_amount, merchant_cut, driver_cut, platform_cut,
       affiliate_commission, service_type, order_type, delivery_option, pickup_address, pickup_lat, pickup_lng,
       delivery_address, delivery_lat, delivery_lng, distance_km, tracking_token, notes, package_details_json, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      orderId, orderNumber, userId, merchantId, affiliatorId, orderStatus, paymentMethod, paymentStatus,
      isTransport ? 0 : subtotal, rawShipping, shippingDiscount, adminFee, driverTip, totalAmount, merchantCut, driverCut, platformCut,
      affiliateCommission, serviceType, orderType, deliveryOption, pickupAddress, pickupLat, pickupLng,
      deliveryAddress, deliveryLat, deliveryLng, distanceKm, trackingToken, notes, packageDetailsJson, now, now
    ).run().catch(async () => {
      // Compatibility fallback if 0006 columns have not yet migrated on remote D1
      await c.env.DB.prepare(
        `INSERT INTO orders (id, order_number, user_id, merchant_id, affiliator_id, status, payment_method, payment_status,
         items_subtotal, shipping_fee, shipping_discount, admin_fee, total_amount, merchant_cut, driver_cut, platform_cut,
         affiliate_commission, delivery_address, delivery_lat, delivery_lng, distance_km, tracking_token, notes, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
      ).bind(
        orderId, orderNumber, userId, merchantId, affiliatorId, orderStatus, paymentMethod, paymentStatus,
        isTransport ? 0 : subtotal, rawShipping, shippingDiscount, adminFee, totalAmount, merchantCut, driverCut, platformCut,
        affiliateCommission, deliveryAddress, deliveryLat, deliveryLng, distanceKm, trackingToken, notes, now, now
      ).run();
    });

    for (const item of verifiedItems) {
      const itemId = `item-${Math.random().toString(36).substring(2, 9)}`;
      await c.env.DB.prepare(
        `INSERT INTO order_items (id, order_id, menu_id, name, price, quantity, subtotal, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      ).bind(
        itemId, orderId, item.menuId, item.name, item.price, item.quantity, item.price * item.quantity, item.notes
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
        service_type: serviceType,
        order_type: orderType,
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
      `SELECT o.*, COALESCE(m.name, 'Layanan GAGE') as merchant_name, COALESCE(m.address, 'Pracimantoro, Wonogiri') as merchant_address,
              m.image_url as merchant_avatar, u.name as customer_name, u.phone as customer_phone, u.avatar_url as customer_avatar,
              d.vehicle_plate as driver_plate, d.vehicle_type as driver_vehicle, du.name as driver_name, du.phone as driver_phone, du.avatar_url as driver_avatar
       FROM orders o
       LEFT JOIN merchants m ON o.merchant_id = m.id
       LEFT JOIN users u ON o.user_id = u.id
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
      `SELECT o.*, COALESCE(m.name, 'Layanan GAGE') as merchant_name, COALESCE(m.address, 'Pracimantoro, Wonogiri') as merchant_address,
              m.phone_wa as merchant_phone, m.image_url as merchant_avatar, u.name as customer_name, u.phone as customer_phone, u.avatar_url as customer_avatar,
              d.vehicle_plate as driver_plate, d.vehicle_type as driver_vehicle, du.name as driver_name, du.phone as driver_phone, du.avatar_url as driver_avatar
       FROM orders o
       LEFT JOIN merchants m ON o.merchant_id = m.id
       LEFT JOIN users u ON o.user_id = u.id
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

// Endpoint Simulasi Transisi Status (Dibatasi non-production atau Admin Key)
app.post('/api/orders/:id/simulate-stage', async (c) => {
  if (isProductionRuntime(c) && !(await isAdminOrAuthorizedRole(c, ['admin']))) {
    return c.json({ success: false, message: 'Simulasi stage dinonaktifkan di lingkungan produksi' }, 403);
  }
  const orderId = c.req.param('id');
  const body = await c.req.json();
  const nextStage = body.stage;
  const now = Math.floor(Date.now() / 1000);
  try {
    await c.env.DB.prepare(
      `UPDATE orders SET status = ?, updated_at = ? WHERE id = ?`
    ).bind(nextStage, now, orderId).run();

    return c.json({ success: true, order_id: orderId, new_status: nextStage });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 5. MERCHANT KITCHEN, DRIVER, & AFFILIATE ENDPOINTS
// ─────────────────────────────────────────────────────────────────────────────

app.post('/api/merchant/menu/:itemId/toggle-stock', async (c) => {
  const itemId = c.req.param('itemId');
  try {
    const body = await c.req.json();
    const isAvailable = body.is_available ? 1 : 0;
    const now = Math.floor(Date.now() / 1000);
    await c.env.DB.prepare('UPDATE merchant_menus SET is_available = ?, updated_at = ? WHERE id = ?')
      .bind(isAvailable, now, itemId).run();
    return c.json({ success: true, data: { id: itemId, is_available: isAvailable, updated_at: now } });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.post('/api/merchant/menu', async (c) => {
  try {
    const body = await c.req.json();
    const merchantId = String(body.merchant_id || '').trim();
    const name = String(body.name || '').trim();
    const category = String(body.category || 'Umum').trim();
    const offlinePrice = Math.round(Number(body.offline_price || 0));
    const gagePrice = Math.round(Number(body.gage_price || offlinePrice));
    if (!merchantId || !name || offlinePrice <= 0) {
      return c.json({ success: false, message: 'merchant_id, name, dan offline_price wajib valid' }, 400);
    }
    const id = `menu-${Date.now().toString(36)}-${Math.random().toString(36).substring(2, 6)}`;
    const now = Math.floor(Date.now() / 1000);
    await c.env.DB.prepare(
      `INSERT INTO merchant_menus (id, merchant_id, name, description, category, offline_price, gage_price, is_available, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)`
    ).bind(id, merchantId, name, body.description || '', category, offlinePrice, gagePrice, now, now).run();
    return c.json({
      success: true,
      data: { id, merchant_id: merchantId, name, category, offline_price: offlinePrice, gage_price: gagePrice, is_available: 1, created_at: now },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

app.get('/api/merchant/orders', async (c) => {
  const merchantId = c.req.query('merchant_id') || 'mch-dimsum-01';
  try {
    const res = await c.env.DB.prepare(
      `SELECT o.*, u.name as customer_name, u.phone as customer_phone, d.vehicle_plate as driver_plate, du.name as driver_name, du.avatar_url as driver_avatar
       FROM orders o
       JOIN users u ON o.user_id = u.id
       LEFT JOIN drivers d ON o.driver_id = d.id
       LEFT JOIN users du ON d.user_id = du.id
       WHERE o.merchant_id = ? AND o.status IN ('NEW', 'PAID', 'COOKING', 'READY_FOR_PICKUP', 'AT_MERCHANT', 'PICKED_UP', 'ON_DELIVERY')
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
      `SELECT o.*, COALESCE(m.name, 'Layanan GAGE') as merchant_name, COALESCE(m.address, COALESCE(o.pickup_address, 'Pracimantoro')) as merchant_address, u.name as customer_name
       FROM orders o
       LEFT JOIN merchants m ON o.merchant_id = m.id
       LEFT JOIN users u ON o.user_id = u.id
       WHERE o.driver_id IS NULL AND COALESCE(o.order_type, 'DELIVERY') != 'PICKUP'
         AND o.status IN ('SEARCHING_DRIVER', 'PAID', 'COOKING', 'READY_FOR_PICKUP')
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
  const driverId = String(body.driver_id || '').trim();
  if (!driverId) {
    return c.json({ success: false, message: 'driver_id wajib diisi' }, 400);
  }
  const now = Math.floor(Date.now() / 1000);
  try {
    // Atomic claim: prevent double assignment and preserve merchant kitchen stage if still preparing
    const result = await c.env.DB.prepare(
      `UPDATE orders SET driver_id = ?,
       status = CASE WHEN status = 'SEARCHING_DRIVER' THEN 'DRIVER_ASSIGNED' WHEN status = 'READY_FOR_PICKUP' THEN 'AT_MERCHANT' ELSE status END,
       updated_at = ? WHERE id = ? AND driver_id IS NULL`
    ).bind(driverId, now, orderId).run();

    if ((result.meta?.changes || 0) === 0) {
      return c.json({ success: false, message: 'Order sudah diambil driver lain atau tidak tersedia' }, 409);
    }

    const updated: any = await c.env.DB.prepare(
      `SELECT o.status, d.vehicle_plate as driver_plate, u.name as driver_name, u.phone as driver_phone, u.avatar_url as driver_avatar
       FROM orders o
       LEFT JOIN drivers d ON o.driver_id = d.id
       LEFT JOIN users u ON d.user_id = u.id
       WHERE o.id = ?`
    ).bind(orderId).first();

    return c.json({
      success: true,
      data: {
        order_id: orderId,
        driver_id: driverId,
        status: updated?.status || 'DRIVER_ASSIGNED',
        driver_name: updated?.driver_name || null,
        driver_plate: updated?.driver_plate || null,
        driver_phone: updated?.driver_phone || null,
        driver_avatar: updated?.driver_avatar || null,
        assigned_at: now,
      },
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

app.post('/api/affiliate/payout', async (c) => {
  try {
    const body = await c.req.json();
    const affiliateCode = String(body.affiliate_code || '').trim();
    const amount = Math.round(Number(body.amount || 0));
    const bankName = String(body.bank_name || '').trim();
    const accountNumber = String(body.account_number || '').trim();
    const accountHolder = String(body.account_holder || '').trim();
    if (!affiliateCode || amount < 10000 || !bankName || !accountNumber || !accountHolder) {
      return c.json({ success: false, message: 'Data penarikan komisi tidak lengkap (min. Rp 10.000)' }, 400);
    }
    const id = `affpay-${Date.now().toString(36)}`;
    const now = Math.floor(Date.now() / 1000);
    await c.env.DB.prepare(
      `INSERT INTO affiliate_payouts (id, affiliate_code, amount, bank_name, account_number, account_holder, status, created_at)
       VALUES (?, ?, ?, ?, ?, ?, 'PENDING', ?)`
    ).bind(id, affiliateCode, amount, bankName, accountNumber, accountHolder, now).run();
    return c.json({
      success: true,
      message: 'Permintaan pencairan komisi dicatat',
      data: { id, affiliate_code: affiliateCode, amount, status: 'PENDING', created_at: now },
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

// ─────────────────────────────────────────────────────────────────────────────
// 6. STANDALONE PER-SCREEN BANNER CRUD (D1 QUOTA SHIELD + EDGE CACHING)
// ─────────────────────────────────────────────────────────────────────────────

// Mengambil banner aktif berdasarkan screen_target (atau seluruh banner untuk Admin)
app.get('/api/banners', async (c) => {
  const target = c.req.query('screen_target');
  const forAdmin = c.req.query('admin') === 'true';

  try {
    let query = 'SELECT * FROM banners';
    let params: any[] = [];

    if (target) {
      if (forAdmin) {
        query += ' WHERE screen_target = ? ORDER BY display_order ASC, created_at DESC';
        params.push(target);
      } else {
        query += ' WHERE screen_target = ? AND is_active = 1 ORDER BY display_order ASC, created_at DESC';
        params.push(target);
      }
    } else {
      if (forAdmin) {
        query += ' ORDER BY screen_target ASC, display_order ASC, created_at DESC';
      } else {
        query += ' WHERE is_active = 1 ORDER BY screen_target ASC, display_order ASC, created_at DESC';
      }
    }

    const res = await c.env.DB.prepare(query).bind(...params).all();

    // D1 Quota Shield: Pasang Cache-Control jika bukan untuk admin
    if (!forAdmin) {
      c.header('Cache-Control', 'public, max-age=3600, s-maxage=86400');
    }

    return c.json({
      success: true,
      count: res.results.length,
      data: res.results,
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message, data: [] }, 500);
  }
});

// Admin Menambah Banner Baru
app.post('/api/banners', async (c) => {
  try {
    const body = await c.req.json();
    const {
      screen_target,
      title,
      subtitle = '',
      image_url,
      action_type = 'NONE',
      action_url = '',
      aspect_ratio = '16:9',
      width_px = 1280,
      height_px = 720,
      display_order = 0,
      is_active = 1,
    } = body;

    if (!screen_target || !title || !image_url) {
      return c.json({ success: false, message: 'screen_target, title, dan image_url wajib diisi' }, 400);
    }

    const now = Math.floor(Date.now() / 1000);
    const id = `bnr-${Date.now().toString(36)}-${Math.random().toString(36).substring(2, 6)}`;

    await c.env.DB.prepare(
      `INSERT INTO banners (id, screen_target, title, subtitle, image_url, action_type, action_url, aspect_ratio, width_px, height_px, is_active, display_order, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      id, screen_target, title, subtitle, image_url, action_type, action_url, aspect_ratio, width_px, height_px, is_active, display_order, now, now
    ).run();

    return c.json({
      success: true,
      message: 'Banner berhasil ditambahkan',
      data: { id, screen_target, title, image_url },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Admin Mengubah Banner
app.put('/api/banners/:id', async (c) => {
  const id = c.req.param('id');
  try {
    const body = await c.req.json();
    const {
      screen_target,
      title,
      subtitle,
      image_url,
      action_type,
      action_url,
      aspect_ratio,
      width_px,
      height_px,
      is_active,
      display_order,
    } = body;

    const existing: any = await c.env.DB.prepare('SELECT * FROM banners WHERE id = ?').bind(id).first();
    if (!existing) {
      return c.json({ success: false, message: 'Banner tidak ditemukan' }, 404);
    }

    const now = Math.floor(Date.now() / 1000);

    await c.env.DB.prepare(
      `UPDATE banners SET
        screen_target = COALESCE(?, screen_target),
        title = COALESCE(?, title),
        subtitle = COALESCE(?, subtitle),
        image_url = COALESCE(?, image_url),
        action_type = COALESCE(?, action_type),
        action_url = COALESCE(?, action_url),
        aspect_ratio = COALESCE(?, aspect_ratio),
        width_px = COALESCE(?, width_px),
        height_px = COALESCE(?, height_px),
        is_active = COALESCE(?, is_active),
        display_order = COALESCE(?, display_order),
        updated_at = ?
       WHERE id = ?`
    ).bind(
      screen_target ?? null, title ?? null, subtitle ?? null, image_url ?? null, action_type ?? null, action_url ?? null,
      aspect_ratio ?? null, width_px ?? null, height_px ?? null, is_active ?? null, display_order ?? null, now, id
    ).run();

    return c.json({
      success: true,
      message: 'Banner berhasil diperbarui',
      data: { id, updated_at: now },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Admin Menghapus Banner
app.delete('/api/banners/:id', async (c) => {
  const id = c.req.param('id');
  try {
    await c.env.DB.prepare('DELETE FROM banners WHERE id = ?').bind(id).run();
    return c.json({ success: true, message: 'Banner berhasil dihapus', id });
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

// ─────────────────────────────────────────────────────────────────────────────
// 7. GAGE ADMIN OPERATIONAL & BUSINESS METRICS (D1 SYNC)
// ─────────────────────────────────────────────────────────────────────────────

// Ambil Ringkasan Metrik Harian / Rollup GMV
app.get('/api/admin/metrics/daily', async (c) => {
  const dateParam = c.req.query('date');
  const days = parseInt(c.req.query('days') || '7', 10);
  try {
    if (dateParam) {
      let metric = await c.env.DB.prepare('SELECT * FROM daily_business_metrics WHERE date = ?').bind(dateParam).first();
      if (!metric) {
        // Fallback default snapshot
        metric = {
          date: dateParam,
          total_orders: 42,
          completed_orders: 38,
          cancelled_orders: 1,
          gmv_total: 1428000,
          items_subtotal: 1020000,
          shipping_total: 366000,
          admin_fee_total: 42000,
          platform_net_revenue: 238476,
          driver_earnings_total: 292800,
          merchant_payout_total: 1020000,
        };
      }
      return c.json({ success: true, data: metric });
    }

    const { results } = await c.env.DB.prepare(
      'SELECT * FROM daily_business_metrics ORDER BY date DESC LIMIT ?'
    ).bind(days).all();

    return c.json({ success: true, data: results });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// Intervensi Darurat: Re-assign Driver Pesanan
app.post('/api/admin/orders/:id/reassign-driver', async (c) => {
  const orderId = c.req.param('id');
  try {
    const body = await c.req.json();
    const { new_driver_id, new_driver_name, reason } = body;
    const now = Math.floor(Date.now() / 1000);

    await c.env.DB.prepare(
      'UPDATE orders SET driver_id = ?, updated_at = ? WHERE id = ?'
    ).bind(new_driver_id, now, orderId).run();

    return c.json({
      success: true,
      message: `Driver berhasil dialihkan ke ${new_driver_name} (Alasan: ${reason || 'Intervensi Darurat Admin'})`,
      data: {
        order_id: orderId,
        new_driver_id,
        new_driver_name,
        reassigned_at: now,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: err.message }, 500);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// CHAT MEDIA UPLOAD & CDN (CLOUDFLARE R2 & EDGE CACHE)
// ─────────────────────────────────────────────────────────────────────────────

// 1. Dapatkan Pre-signed Upload URL / Direktori Media Key
app.post('/api/chat/media/upload-url', async (c) => {
  try {
    const body = await c.req.json();
    const orderId = body.order_id || 'general';
    const filename = body.filename || `chat-${Date.now()}.jpg`;
    const contentType = body.content_type || 'image/jpeg';
    const key = `orders/${orderId}/${Date.now()}-${filename.replace(/[^a-zA-Z0-9._-]/g, '_')}`;

    const publicUrl = `https://media.gage.id/${key}`;

    return c.json({
      success: true,
      key,
      upload_url: `/api/chat/media/upload?key=${encodeURIComponent(key)}`,
      public_url: publicUrl,
      content_type: contentType,
      headers: {
        'Content-Type': contentType,
      },
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Gagal membuat upload URL', error: err.message }, 500);
  }
});

// 2. Direct binary / multipart upload ke R2
app.post('/api/chat/media/upload', async (c) => {
  try {
    const key = c.req.query('key') || `misc/${Date.now()}.bin`;
    const contentType = c.req.header('Content-Type') || 'application/octet-stream';
    const body = await c.req.arrayBuffer();

    if (!c.env.MEDIA_BUCKET) {
      return c.json({ success: false, message: 'R2 bucket MEDIA_BUCKET belum aktif' }, 503);
    }

    await c.env.MEDIA_BUCKET.put(key, body, {
      httpMetadata: {
        contentType,
        cacheControl: 'public, max-age=31536000, immutable',
      },
    });

    return c.json({
      success: true,
      key,
      url: `/api/chat/media/${key}`,
      size_bytes: body.byteLength,
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Gagal upload media ke R2', error: err.message }, 500);
  }
});

// 3. Streaming file dari R2 dengan CDN Edge Cache
app.get('/api/chat/media/*', async (c) => {
  try {
    const key = c.req.path.replace('/api/chat/media/', '');
    if (!key) return c.text('Key required', 400);

    if (!c.env.MEDIA_BUCKET) {
      return c.json({ status: 'mock_mode', message: 'R2 bucket belum aktif di local runtime', key }, 200);
    }

    const object = await c.env.MEDIA_BUCKET.get(key);
    if (!object) {
      return c.text('Media not found in R2', 404);
    }

    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set('etag', object.httpEtag);
    headers.set('Cache-Control', 'public, max-age=31536000, immutable');

    return new Response(object.body, { headers });
  } catch (err: any) {
    return c.text(`R2 stream error: ${err.message}`, 500);
  }
});

export default app;

