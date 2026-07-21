# Monitor Harga

> Alat lokal macOS untuk memantau harga dan stok toko pilihan, serta saldo dan penggunaan API WOYAO terbaru di bar menu.

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Bahasa Indonesia**

## Fitur

- Mengelompokkan produk yang sebanding dan mengurutkannya dari harga terendah.
- Memeriksa toko setiap menit dan mengumumkan stok baru atau restok dengan suara macOS.
- Menampilkan saldo WOYAO saat ini langsung di bar menu.
- Memperbarui penggunaan setiap jam dan mengumumkan saldo, kuota terpakai, serta biaya hari ini.
- Menampilkan sepuluh panggilan terbaru dengan model, biaya, token, dan waktu.

## Mulai cepat

1. Unduh `PriceMonitor-v1.4-macOS-arm64.zip` dari [Releases](../../releases/latest), ekstrak, lalu pindahkan aplikasi ke Applications.
2. Buka aplikasi sekali. Untuk menjalankan saat login, pasang templat pengguna `LaunchAgent.plist`.
3. Buka **Penggunaan WOYAO**, tempel API Key, lalu pilih **Simpan ke Documents dan baca**.

## Privasi

Data toko dibaca dari API publik. Kunci WOYAO hanya disimpan di `Documents/价格监控/woyao-api-key.txt`; kunci tidak ditulis ke Git, log biasa, atau data browser. Jangan sinkronkan berkas teks biasa ini ke penyimpanan cloud publik.

## Build dan lisensi

macOS, Xcode Command Line Tools, dan Swift 6 diperlukan. Jalankan `./build_app.sh` untuk membuat `价格监控.app`.

Proyek ini menggunakan [MIT License](../LICENSE). Penulis dan kontak: Jacksun（孙秦吉）· [qinji@jack-sun.com](mailto:qinji@jack-sun.com).
