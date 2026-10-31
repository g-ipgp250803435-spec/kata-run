# KATA//RUN — Panduan Konfigurasi Supabase Cloud

**Versi:** Cloud Edition · 31 Oktober 2026  
**Tujuan:** Media untuk 7 slot (maskot, 3 senaman, 3 kad panduan) boleh dikongsi kepada semua pengguna di komputer/telefon lain melalui Internet. Rekod pemerhatian murid **tidak** dimuat naik ke Supabase.

## 1. Kandungan pakej

- `index.html` — aplikasi lengkap KATA//RUN, termasuk Auto-Fit dan permainan.
- `supabase-config.js` — hanya isi **Project URL** dan **publishable key**.
- `supabase-setup.sql` — bina jadual, bucket dan polisi RLS.
- `service-worker.js`, `manifest.webmanifest`, `icons/` — sokongan pemasangan PWA melalui HTTPS.

## 2. Cipta projek Supabase

1. Daftar / log masuk di <https://supabase.com/dashboard> dan cipta projek.
2. Tunggu projek selesai disediakan.
3. Dalam **SQL Editor**, tampal keseluruhan kandungan `supabase-setup.sql`, kemudian pilih **Run**.
4. Pastikan tiada ralat. SQL akan menyediakan:
   - bucket Storage `katarun-media` yang **public-read**;
   - jadual `katarun_media` (7 slot, dibaca oleh semua);
   - jadual `katarun_teachers` (senarai guru yang dibenarkan);
   - fungsi `katarun_is_teacher()`;
   - polisi RLS yang membenarkan **guru yang diluluskan sahaja** memuat naik, mengganti dan memadam media.

> **Keselamatan:** Bucket ini boleh dibaca oleh sesiapa yang mengetahui URL video. Gunakan hanya video demonstrasi yang anda memang mahu dikongsi secara umum. **Jangan muat naik video yang mendedahkan wajah, suara, nama atau maklumat peribadi murid** tanpa sistem akses tertutup dan persetujuan yang sesuai. Polisi ini **tidak** melindungi kerahsiaan media daripada pengguna awam.

## 3. Cipta akaun guru dan beri kebenaran

1. Dalam Dashboard Supabase, buka **Authentication → Users**.
2. Tambah pengguna guru menggunakan e-mel dan kata laluan (contohnya melalui butang **Add user**). Pastikan pengguna disahkan mengikut tetapan projek.
3. Salin **User UID** sebenar bagi akaun tersebut (bukan e-mel).
4. Dalam **SQL Editor**, jalankan perintah berikut dengan menggantikan UID:

```sql
insert into public.katarun_teachers (user_id)
values ('PASTE_TEACHER_USER_UID_HERE')
on conflict (user_id) do nothing;
```

5. Ulang untuk guru lain yang dibenarkan. Untuk membatalkan kebenaran guru, padam baris UID tersebut daripada `public.katarun_teachers` menggunakan SQL Editor.
6. **Disyorkan:** Matikan pendaftaran pengguna awam yang tidak diperlukan dalam **Authentication → Providers / Settings** (nama menu boleh berubah). Akaun biasa yang tidak berada dalam jadual guru tidak boleh memuat naik walaupun berjaya log masuk.

## 4. Isi `supabase-config.js`

1. Dalam Dashboard Supabase, buka **Connect** atau **Settings → API Keys**.
2. Salin **Project URL** dan **Publishable key** (bermula dengan `sb_publishable_`).
3. Edit fail `supabase-config.js`:

```js
window.KATARUN_SUPABASE_CONFIG = {
  url: "https://PROJECT_REF.supabase.co",
  publishableKey: "sb_publishable_XXXXXXXX"
};
```

4. Simpan fail bersama `index.html` dalam folder yang sama.

**JANGAN masukkan `service_role`, `sb_secret_...`, kata laluan guru atau database password ke dalam fail HTML atau `supabase-config.js`.** Publishable key selamat digunakan pada frontend apabila polisi RLS disediakan dengan betul.

## 5. Terbitkan aplikasi untuk semua pengguna

Muat naik **keseluruhan folder** ini ke hosting statik ber-HTTPS, contohnya GitHub Pages, Netlify atau Cloudflare Pages. Pastikan `index.html` dan `supabase-config.js` berada pada direktori akar yang sama, serta `icons/`, `manifest.webmanifest` dan `service-worker.js` turut dimuat naik.

- **Guru** membuka URL yang sama, masuk ke **Studio Guru → Supabase Cloud Sync**, dan log masuk.
- **Murid / pengguna lain** membuka URL yang sama **tanpa log masuk** dan melihat video/gambar yang diterbitkan.
- Media baharu dimuatkan ketika halaman dibuka, disegerakkan secara berkala **setiap 30 saat**, apabila tab kembali aktif, atau melalui butang **Segerak sekarang**. Jika Realtime diaktifkan, perubahan boleh muncul lebih cepat.
- Sambungan Internet diperlukan untuk memuatkan media cloud pada peranti baharu. PWA tidak menjamin semua video cloud tersedia tanpa Internet.

> **Ujian lokal:** Boleh cuba melalui pelayan setempat (`python -m http.server 8000`) selepas fail dikonfigurasi. Untuk penerbitan sebenar gunakan HTTPS. Membuka `index.html` terus melalui `file://` mungkin menghadapi sekatan pelayar; hosting HTTPS lebih disyorkan.

## 6. Muat naik video

1. Buka aplikasi pada URL yang telah diterbitkan.
2. Pilih **Studio Guru**.
3. Dalam kotak **SUPABASE CLOUD SYNC**, log masuk dengan akaun guru yang diluluskan.
4. Pilih **MUAT NAIK** pada slot yang betul dan pilih fail video/gambar.
5. Tunggu mesej **Berjaya diterbitkan ke cloud**. Jangan tutup tab sebelum proses selesai.
6. Buka aplikasi pada telefon/laptop lain. Video akan muncul pada kad yang sama; tekan **Segerak sekarang** jika perlu.
7. Tekan **Asal** pada slot untuk memulihkan ilustrasi asal kepada **semua** pengguna.

**Had:** maksimum 40 MB setiap fail; JPG, PNG, WebP, MP4, WebM, MOV. Codec video perlu disokong pelayar; paling serasi ialah **MP4 (H.264 video + AAC audio)**. Auto-Fit mengekalkan nisbah video tanpa cropping, tetapi tidak menukar codec.

## 7. Pindahkan media lama dari IndexedDB

Media yang pernah dimuat naik dalam versi lama **masih berada pada pelayar/peranti lama**, bukan automatik di cloud. Pada laptop asal:

1. Buka versi Cloud Edition pada **origin/domain yang sama** dengan aplikasi lama (IndexedDB diasingkan mengikut origin). Jika aplikasi lama dibuka menggunakan `file://`, akses IndexedDB mungkin berbeza mengikut pelayar.
2. Log masuk sebagai guru.
3. Tekan **Pindahkan media lama**. Sistem akan mengesan fail dalam IndexedDB lama dan meminta pengesahan.
4. Semak mesej jumlah fail berjaya/gagal, kemudian semak paparan pada laptop lain.

Jika media lama tidak ditemui, muat naik semula fail asal secara manual. Migrasi tidak memadam salinan lama daripada peranti.

## 8. Realtime (pilihan)

Penyegerakan setiap 30 saat berfungsi tanpa Realtime. Jika mahu perubahan lebih segera, dalam Supabase Dashboard buka **Database → Publications**, aktifkan jadual `public.katarun_media` untuk `supabase_realtime` (jika tersedia). Anda juga boleh jalankan arahan SQL opsyenal yang dikomen dalam `supabase-setup.sql` sekali sahaja.

## 9. Troubleshooting

| Masalah | Semakan |
|---|---|
| `Cloud belum dikonfigurasi` | URL atau publishable key masih placeholder; pastikan fail `supabase-config.js` dimuat naik pada lokasi yang betul. |
| `Pustaka Supabase tidak dimuatkan` | Internet/CDN `jsdelivr.net` disekat; pastikan CDN boleh diakses. |
| `relation katarun_media does not exist` | Jalankan `supabase-setup.sql` dalam projek yang sama. |
| `permission denied` / `row-level security` | Periksa SQL policies, UID guru dalam `katarun_teachers`, dan log masuk semula. |
| `Bucket not found` | Jalankan SQL bucket atau semak nama `katarun-media`. |
| `Invalid JWT` | Pastikan menggunakan **publishable key**, bukan secret key, dan sesi guru sah. |
| Video tidak bergerak | Eksport semula sebagai MP4 H.264/AAC. Klik `MAIN VIDEO` jika autoplay disekat. |
| Video belum muncul pada peranti lain | Semak URL aplikasi sama, status cloud, Internet, tekan **Segerak sekarang**; tunggu maksimum ~30 saat untuk poll. |
| Video lama muncul selepas deploy | Lakukan hard refresh, dan jika PWA dipasang, tutup/buka semula aplikasi selepas service worker dikemas kini. |
| Gagal memindahkan media lama | IndexedDB asal hanya boleh dibaca pada origin yang sama; muat naik semula daripada fail sumber. |

## 10. Batasan yang penting

- **Kredensial sebenar belum disertakan**; sambungan langsung hanya berfungsi selepas anda melakukan langkah 2–4.
- **Rekod murid, bintang dan skor kekal setempat**. Hanya media demonstrasi bagi tujuh slot disegerakkan.
- Bucket public boleh dibaca oleh sesiapa yang memiliki URL media; ini sesuai untuk bahan pendidikan awam, **bukan** rakaman peribadi murid.
- Supabase mempunyai had penggunaan dan storan mengikut pelan anda. Ketersediaan media bergantung pada projek Supabase, sambungan Internet dan hosting.
- Ujian kod statik boleh dilakukan tanpa projek, tetapi ujian integrasi cloud sebenar memerlukan projek Supabase anda yang telah dikonfigurasi.

## Rujukan rasmi

- <https://supabase.com/docs/reference/javascript/installing>
- <https://supabase.com/docs/guides/storage/buckets/fundamentals>
- <https://supabase.com/docs/guides/storage/security/access-control>
- <https://supabase.com/docs/guides/getting-started/api-keys>
