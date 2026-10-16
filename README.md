# FaaStore

FaaStore adalah aplikasi katalog informasi produk top-up dan voucher digital yang dibuat dengan Flutter dan Dart. Aplikasi mengambil data produk secara dinamis dari API dan menampilkannya dalam antarmuka bertema hitam dan emas.

> Proyek ini dibuat untuk keperluan akademik (UTS Pemrograman Mobile). Aplikasi **tidak** memproses transaksi, pembayaran, atau top-up sungguhan. Tombol "Pilih Produk" hanya simulasi.

## Fitur

- Menampilkan katalog produk dari API dalam bentuk grid (gambar, nama, harga, dan mata uang sesuai data API).
- Pencarian produk berdasarkan nama. Pencarian menyaring produk yang sudah dimuat, bukan seluruh katalog.
- Tombol "Muat lebih banyak" untuk mengambil halaman berikutnya (pagination dari API).
- Tarik untuk menyegarkan data.
- Indikator loading, tampilan error dengan tombol "Coba lagi", dan tampilan ketika data kosong.
- Halaman detail produk: informasi produk, rentang harga, dan data yang dibutuhkan.
- Produk berstatus khusus reseller (`h2h_only`) ditampilkan secara informatif dan tidak dapat dipilih.
- Gambar yang gagal dimuat diganti ikon placeholder.

## Sumber Data (API)

- Endpoint: `GET https://distribution.liogames.com/api/v1/products`
- Halaman berikutnya: `GET https://distribution.liogames.com/api/v1/products?page=2`
- Struktur respons yang dibaca: `ok`, `code`, `message`, `data.products`, dan `data.pagination`.
- Harga ditampilkan memakai mata uang dari field `currency` pada API, tanpa konversi.

## Package

| Package | Fungsi |
|---|---|
| `http` | Permintaan HTTP GET ke API |
| `cupertino_icons` | Bawaan template Flutter |

## Struktur Proyek

```
lib/
├── main.dart                      # Titik masuk aplikasi
├── models/product.dart            # Model data dan parsing JSON
├── services/product_service.dart  # Permintaan HTTP dan penanganan error
├── theme/app_theme.dart           # Tema hitam dan emas
├── widgets/product_card.dart      # Kartu produk dan gambar dengan fallback
└── pages/
    ├── home_page.dart             # Katalog, pencarian, loading, error
    └── product_detail_page.dart   # Detail produk
test/
├── product_test.dart              # Tes parsing model
└── product_service_test.dart      # Tes service (sukses, error, data kosong)
```

## Cara Menjalankan

Prasyarat: Flutter SDK (dikembangkan dengan Flutter 3.47.2 / Dart 3.13.2) dan emulator atau perangkat Android.

```bash
git clone <URL-REPOSITORY-INI>
cd <NAMA-FOLDER>
flutter pub get
flutter run
```

Menjalankan pengujian:

```bash
flutter analyze
flutter test
```

Catatan: versi web (Chrome/Edge) tidak digunakan karena respons API tidak menyertakan header CORS pada pengujian awal. Aplikasi diuji pada emulator Android (Pixel 8, API 37.2).