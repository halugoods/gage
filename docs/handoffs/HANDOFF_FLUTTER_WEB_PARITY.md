# Handoff & Panduan Arsitektur: 100% 1:1 Flutter Web Parity

* **Target Audiens**: Sesi Agent Khusus Brainstorming & Eksekusi Web/PWA GAGE
* **Dokumen Tujuan**: `docs/handoffs/HANDOFF_FLUTTER_WEB_PARITY.md`
* **Prinsip Utama**: **100% 1:1 Pixel Identical**, Nol Perbedaan Kode Logika, Nol Rewrite ke Framework Web Lain.

---

## 1. Analisis & Jawaban Masalah: Bagaimana Menghasilkan Web 1:1 dengan Dart

Pengguna sering kali terjebak berpikir bahwa untuk membuat versi website dari aplikasi Flutter, mereka harus menulis ulang (*rewrite*) antarmuka menggunakan React, Next.js, atau Vue. **Pendekatan tersebut salah besar untuk kasus GAGE karena:**
1. Menulis ulang di React akan menimbulkan ribuan perbedaan mikroskopis (*visual drift*) pada radius sudut tombol, timing animasi, shadow, physics scroll, dan parsing data.
2. Membutuhkan sinkronisasi ganda: setiap kali ada perubahan fitur di Flutter, tim harus mengupdate ulang kode React.

### Solusi Resmi: Kompilasi Langsung Flutter Web
Flutter memiliki engine kompilasi bawaan yang dapat mengkompilasi **kode Dart yang sama persis** ke Web Assembly (Wasm) dan CanvasKit (Skia Web):
* **Satu Kode Sumber**: 100% file widget, tema `GageTheme`, service, dan provider yang berjalan di Android akan berjalan langsung di browser.
* **CanvasKit Renderer**: Menggunakan engine grafis Skia berbasis WebGL di dalam browser, menghasilkan rendering bayangan, kurva `BorderRadius.circular(999)`, tipografi, dan canvas peta yang **100% identik piksel-demi-piksel** dengan ponsel Android.

---

## 2. Strategi Pengalaman Pengguna (Mobile Viewport Framing)

Target utama versi web ini adalah:
1. **Pengguna dengan memori ponsel penuh** (tidak bisa menginstal APK).
2. **Pengguna iPhone / iOS** (belum dirilis ke App Store karena belum ada revenue).
3. **Pengguna Laptop / Desktop** yang ingin memantau atau memesan via browser.

### Layout Adaptive Shell di Desktop
Agar tampilan di layar monitor desktop tidak melebar secara canggung (merusak proporsi mobile yang sudah dirancang sempurna), kita menerapkan **Responsive Smartphone Frame Wrapper** di `lib/main_customer.dart` atau wrapper root:

```dart
class GageWebResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const GageWebResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Jika dibuka di browser laptop/desktop lebar (> 600px)
        if (constraints.maxWidth > 600) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A), // Latar gelap elegan
            body: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460), // Lebar proporsional smartphone
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRect(child: child),
              ),
            ),
          );
        }
        // Jika dibuka di browser smartphone (iOS Safari / Chrome Android), tampil full edge-to-edge
        return child;
      },
    );
  }
}
```

---

## 3. PWA (Progressive Web App) untuk Pengguna iOS

Untuk pengguna iOS (iPhone), kita tidak perlu mendaftar Apple Developer Program ($99/tahun):
1. **Instalasi Instan**: Pengguna membuka URL website di Safari, menekan ikon **Share** -> **"Add to Home Screen"** (*Tambah ke Layar Utama*).
2. **Pengalaman Native**: Aplikasi akan muncul di homescreen iPhone dengan ikon GAGE, berjalan dalam mode layar penuh (tanpa bilah URL Safari), dan memiliki cache offline via Service Worker.

### Konfigurasi `web/manifest.json`:
```json
{
  "name": "GAGE Pracimantoro",
  "short_name": "GAGE",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#E52320",
  "description": "Layanan Transportasi & Pengantaran Lokal Terpercaya Pracimantoro",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

---

## 4. Penanganan Keterbatasan Platform Web & Solusinya

| Fitur | Keterbatasan di Web | Solusi Teruji |
| :--- | :--- | :--- |
| **GPS Lokasi** | Browser meminta izin popup *"Allow Location"* | `geolocator_web` sudah otomatis fallback ke browser Geolocation API HTML5. |
| **Kamera Scanner QR** | Perlu izin kamera browser | Paket `mobile_scanner` sudah mendukung Web menggunakan HTML5 video stream (`mobile_scanner_web`). |
| **Penyimpanan Lokal** | `SharedPreferences` tidak memakai SQLite Android | Otomatis menggunakan `localStorage` / `IndexedDB` browser (100% transparan tanpa ubah kode Dart). |
| **URL Navigation** | URL Flutter default memakai `#` (`/#/food`) | Aktifkan `usePathUrlStrategy()` di `main()` agar URL bersih (`/food`, `/orders`). |

---

## 5. Panduan Build & Deploy Gratis ke Cloudflare Pages

### A. Perintah Kompilasi
```powershell
Set-Location c:\Users\ertyui\ZCodeProject\gage\gage-app
flutter build web --release --web-renderer canvaskit
```
Hasil build akan berada di `gage-app/build/web`.

### B. Deployment ke Cloudflare Pages
GAGE sudah terintegrasi dengan ekosistem Cloudflare (`gage-cloud`). Anda dapat menghubungkan repo atau mendeploy langsung dengan Wrangler:
```powershell
npx wrangler pages deploy gage-app/build/web --project-name=gage-web
```
Website langsung aktif dengan SSL HTTPS gratis, CDN global ultra-cepat, dan siap diakses pengguna iOS maupun Android tanpa instalasi APK!
