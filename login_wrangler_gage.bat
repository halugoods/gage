@echo off
title Login Cloudflare Wrangler (GAGE Ecosystem)
cd /d "C:\Users\ertyui\ZCodeProject\gage\gage-cloud"

echo ===============================================================
echo   LOGIN CLOUDFLARE WRANGLER - AKUN KHUSUS GAGE
echo ===============================================================
echo.
echo Browser akan otomatis terbuka ke halaman otorisasi Cloudflare.
echo Silakan login dengan akun Cloudflare khusus GAGE kamu dan klik "Allow".
echo.

call npx.cmd wrangler login

echo.
echo ===============================================================
echo   Login berhasil diverifikasi!
echo   Menyimpan profil akun GAGE ke gage_default.toml...
echo ===============================================================

copy /y "%APPDATA%\xdg.config\.wrangler\config\default.toml" "%APPDATA%\xdg.config\.wrangler\config\gage_default.toml"

echo.
echo Siap! Profil tersimpan sebagai gage_default.toml.
echo Jalankan "cmd /c npx wrangler whoami" untuk memverifikasi.
pause
