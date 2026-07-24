# Kasir Gen

Aplikasi kasir Flutter untuk layanan laundry, dengan Firebase Authentication dan Cloud Firestore.

## Platform yang didukung

Android, iOS, Windows, dan web. macOS serta Linux sengaja menampilkan pesan tidak didukung karena Firebase untuk kedua platform belum dikonfigurasi pada proyek ini.

## Setup Firebase sebelum rilis

1. Di Firebase Console, aktifkan **Authentication > Sign-in method > Email/Password**.
2. Data baru diberi field `owner_id` dari UID pengguna yang masuk. Karena itu, setiap akun hanya bisa membaca dan menulis datanya sendiri.
3. Dokumen lama tanpa `owner_id` tidak dapat diakses setelah rules baru dipublikasikan. Migrasikan dokumen lama melalui Admin SDK/Cloud Functions dengan menetapkan UID pemilik yang benar.
4. Login ke Firebase CLI lalu jalankan `firebase deploy --only firestore` untuk menerapkan [rules](firestore.rules) dan indeks.

Jangan aktifkan Anonymous Authentication untuk aplikasi produksi ini.

## Android release

Konfigurasi Gradle menggunakan Groovy saja; file Kotlin DSL duplikat sudah dihapus. Sebelum membuat APK/AAB rilis, salin `android/key.properties.example` menjadi `android/key.properties`, isi lokasi keystore serta kredensialnya, lalu simpan file tersebut di luar Git.

Application ID Android saat ini tetap `com.example.kasir_gen` karena itulah ID yang terdaftar pada `google-services.json`. Jika ingin menggantinya untuk Play Store, daftarkan aplikasi Android baru pada Firebase dan jalankan ulang konfigurasi FlutterFire terlebih dahulu.
