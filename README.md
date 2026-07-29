# Kasir Gen

Aplikasi kasir Flutter untuk layanan laundry, dengan Firebase Authentication dan Cloud Firestore.

## Platform yang didukung

Android, iOS, Windows, dan web. macOS serta Linux sengaja menampilkan pesan tidak didukung karena Firebase untuk kedua platform belum dikonfigurasi pada proyek ini.

## Setup Firebase sebelum rilis

1. Di Firebase Console, aktifkan **Authentication > Sign-in method > Email/Password**.
2. Data pelanggan dan transaksi dibaca bersama oleh semua akun yang sudah disetujui. Data baru tetap diberi `owner_id` sebagai jejak pembuat.
3. Akun yang belum disetujui hanya dapat membaca profil akunnya sendiri.
4. Login ke Firebase CLI lalu jalankan `firebase deploy --only firestore` untuk menerapkan [rules](firestore.rules) dan indeks.

Jangan aktifkan Anonymous Authentication untuk aplikasi produksi ini.

## Role pengguna

Akun baru dibuat sebagai `cashier` dengan status menunggu. Admin menyetujuinya melalui menu **Verifikasi Akun**. Setelah disetujui, kasir dapat membaca data usaha yang sudah ada serta menambah pelanggan dan transaksi. Hanya `admin` yang dapat mengubah atau menghapus pelanggan, layanan, dan transaksi.

Untuk membuat admin pertama: buat akun dari aplikasi, buka Firestore Console, lalu ubah dokumen `users/{UID}` akun tersebut menjadi `role: "admin"`. Firebase Console melewati Firestore Rules. Jangan pernah menyediakan pilihan role admin di layar pendaftaran.

## Android release

Konfigurasi Gradle menggunakan Groovy saja; file Kotlin DSL duplikat sudah dihapus. Sebelum membuat APK/AAB rilis, salin `android/key.properties.example` menjadi `android/key.properties`, isi lokasi keystore serta kredensialnya, lalu simpan file tersebut di luar Git.

Application ID Android saat ini tetap `com.example.kasir_gen` karena itulah ID yang terdaftar pada `google-services.json`. Jika ingin menggantinya untuk Play Store, daftarkan aplikasi Android baru pada Firebase dan jalankan ulang konfigurasi FlutterFire terlebih dahulu.
