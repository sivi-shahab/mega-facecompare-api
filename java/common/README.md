# java/common — modul Maven bersama (vendored)

| | |
|---|---|
| Artefak | `com.exadel:frs-common-app:0.0.1-SNAPSHOT` (parent `com.exadel:frs-java`) |
| Asal | Monorepo Mega-CompreFace `java/common/` @ `048b77929` (= upstream Exadel CompreFace 1.2.0, tanpa perubahan logika) |
| Versi | 1.2.0 (rilis `v1.2.0-mega.1`) |
| Checksum isi | `6f0b58ecaa6c0f238be014316b1593e8a0adf8d825710963c828f58754758d68` (file [.checksum](.checksum), dihitung oleh `scripts/common-checksum.sh`) |
| Dipakai oleh | `mega-facecompare-admin` (`java/admin`) **dan** `mega-facecompare-api` (`java/api`) |

Bank tidak memiliki Maven registry internal, sehingga modul ini **disalin identik** ke kedua repo dan di-build
sebagai submodule Maven lokal (`java/pom.xml` → `<module>common</module>`; `mvn -pl api -am package`).

## Aturan perubahan

1. Perubahan pada `java/common/` **wajib diterapkan identik** di `mega-facecompare-admin` dan
   `mega-facecompare-api` (patch yang sama, sebaiknya `git format-patch` → `git am` dengan pesan commit sama).
2. Setelah mengubah, jalankan `scripts/common-checksum.sh --update` di **kedua** repo — nilai
   `java/common/.checksum` harus sama. CI (`common-checksum`) gagal bila isi tidak cocok dengan `.checksum`.
3. Naikkan `VERSION` dan catat di `CHANGELOG.md` kedua repo; build ulang **admin dan api**, lalu rilis
   bersama lewat `versions.env` di repo deploy.
4. Merge request yang mengubah `java/common` harus mencantumkan tautan MR pasangannya di repo lain.
5. Jangan mengubah logika upstream kecuali untuk perbaikan yang disetujui (catat alasannya di CHANGELOG).
