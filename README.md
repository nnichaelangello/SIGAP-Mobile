# SIGAP — Sistem Informasi Gesit dan Aktif untuk Perlindungan

> **Platform Mobile & Web Pencegahan dan Penanganan Kekerasan Seksual di Lingkungan Kampus**

![Flutter](https://img.shields.io/badge/Mobile-Flutter-blue?logo=flutter)
![Go](https://img.shields.io/badge/Backend-Go%201.22-00ADD8?logo=go)
![SQLite](https://img.shields.io/badge/Database-SQLite-003B57?logo=sqlite)
![License](https://img.shields.io/badge/License-Academic-green)

---

## Daftar Isi

- [Tentang Proyek](#tentang-proyek)
- [Fitur Utama](#fitur-utama)
- [Arsitektur Sistem](#arsitektur-sistem)
- [Teknologi yang Digunakan](#teknologi-yang-digunakan)
- [Struktur Repository](#struktur-repository)
- [Cara Menjalankan](#cara-menjalankan)
- [REST API Endpoint](#rest-api-endpoint)
- [Skema Basis Data](#skema-basis-data)
- [Tim Pengembang](#tim-pengembang)
- [Keterbatasan & Pengembangan Lanjutan](#keterbatasan--pengembangan-lanjutan)

---

## Tentang Proyek

SIGAP adalah sistem informasi multi-layer yang dirancang untuk memfasilitasi pelaporan dan penanganan kasus kekerasan seksual di lingkungan perguruan tinggi, sesuai dengan amanat **Permendikbudristek Nomor 30 Tahun 2021** tentang Pencegahan dan Penanganan Kekerasan Seksual (PPKS).

Sistem ini mengintegrasikan tiga kanal dalam satu ekosistem terpadu:
1. **Aplikasi Mobile Flutter** — untuk pengguna/penyintas
2. **Dashboard Admin Web** — untuk pengelolaan laporan dan pemantauan darurat
3. **Portal Psikolog Web** — untuk manajemen sesi konsultasi
4. **Panel DB Admin Web** — untuk administrasi basis data
5. **Backend RESTful Go** — sebagai lapisan logika bisnis dan data tunggal

---

## Fitur Utama

### 📱 Aplikasi Mobile (Flutter)
- Onboarding & autentikasi (Register / Login)
- **Pelaporan anonim** dengan kode pelacak unik (*tracking code*)
- Pemantauan status laporan secara berkala
- Pemilihan jadwal konsultasi psikolog
- Melihat catatan dan hasil sesi konsultasi dari psikolog

### 🆘 Fitur Darurat SOS
- Tombol SOS satu sentuh untuk mengaktifkan mode darurat
- **Perekaman audio otomatis** berbasis *chunk* 3 detik secara real-time
- Pembaruan **lokasi GPS** korban secara periodik
- Notifikasi instan ke semua admin aktif
- Tampilan peta responder dengan jarak ke korban
- Pemantauan audio real-time dari Dashboard Admin

### 📡 Mode Pantau (Preventif)
- Aktivasi sesi pantau dengan interval check-in yang dapat disesuaikan
- Pengiriman titik GPS berkala (*heartbeat*) ke server
- Eskalasi otomatis ke mode darurat jika check-in terlewat

### 🖥️ Dashboard Admin Web
- Statistik ringkasan laporan dan insiden aktif
- Manajemen seluruh siklus laporan via **state machine** yang terstruktur
- Penjadwalan psikolog untuk setiap laporan
- Pemantauan audio SOS real-time langsung dari browser
- Panel manajemen pengguna

### 🧑‍⚕️ Portal Psikolog Web
- Manajemen slot jadwal konsultasi mingguan
- Konfirmasi / penolakan janji temu dari user
- Pengisian **catatan sesi format SOAP** (Subjective, Objective, Assessment, Plan)
- Penilaian risiko klien (low / medium / high / critical)
- Penandaan kebutuhan sesi lanjutan (*follow-up*)
- Pengakhiran sesi secara resmi

---

## Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────────┐  ┌─────────────┐  ┌────────────────────┐  │
│  │ Mobile App   │  │ Web Admin   │  │  Portal Psikolog   │  │
│  │ (Flutter)    │  │ Dashboard   │  │  + DB Admin Panel  │  │
│  └──────┬───────┘  └──────┬──────┘  └─────────┬──────────┘  │
└─────────┼────────────────┼───────────────────┼─────────────┘
          │   REST API / JSON (HTTP + JWT)      │
┌─────────▼────────────────▼───────────────────▼─────────────┐
│                    BUSINESS LOGIC LAYER                      │
│              Go HTTP Server (net/http)                       │
│   Auth │ Report │ Emergency │ Schedule │ Session │ Pantau   │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      DATA LAYER                              │
│                  SQLite (sigap.db)                           │
│  13 tabel: users, reports, appointments, session_notes,      │
│  emergency_incidents, emergency_audios, pantau_sessions, ... │
└─────────────────────────────────────────────────────────────┘
```

---

## Teknologi yang Digunakan

| Lapisan | Komponen | Teknologi |
|---|---|---|
| Presentasi (Mobile) | Aplikasi Pengguna | Flutter (Dart), Provider |
| Presentasi (Web Admin) | Dashboard Admin | HTML5, Vanilla JS, CSS3 |
| Presentasi (Web Psikolog) | Portal Psikolog | HTML5, Vanilla JS, CSS3 |
| Presentasi (Web DB) | Panel Database Admin | HTML5, Vanilla JS, CSS3 |
| Logika Bisnis | Backend REST API | Go 1.22, net/http |
| Autentikasi | Token Manajemen | JWT (golang-jwt/jwt) |
| Data | Basis Data Relasional | SQLite (modernc.org/sqlite) |
| Peta & Lokasi | GPS & Navigasi | Google Maps SDK |
| Audio | Perekaman & Pemutaran | record, audioplayers (Dart) |
| Notifikasi | Email Transaksional | SMTP (net/smtp Go) |

---

## Struktur Repository

```
SIGAP-Mobile/
├── frontend/              # Aplikasi mobile Flutter
│   ├── lib/
│   │   ├── core/          # Service, config, API client
│   │   └── features/      # Modul fitur (auth, lapor, sos, pantau, dll)
│   └── pubspec.yaml
├── backend/               # Backend REST API (Go)
│   ├── handlers/          # Handler per fitur (9 handler)
│   ├── database/          # Skema & migrasi SQLite
│   ├── middleware/        # JWT Auth, Admin-only, Staff-only
│   ├── utils/             # Helper (JWT, response, email)
│   └── main.go
├── web-dashboard/         # Dashboard Admin (HTML/JS)
│   ├── index.html
│   ├── css/
│   └── js/
├── psikolog-portal/       # Portal Psikolog (HTML/JS)
│   ├── index.html
│   ├── css/
│   └── js/
├── db-admin/              # Panel Database Admin (HTML/JS)
│   ├── index.html
│   └── js/
└── README.md
```

---

## Cara Menjalankan

### Prasyarat
- [Go 1.22+](https://golang.org/dl/)
- [Flutter SDK 3.x+](https://flutter.dev/docs/get-started/install)
- Android Studio / VS Code
- Android Emulator atau perangkat fisik Android

### 1. Jalankan Backend

```bash
cd backend
go mod tidy
go run .
```

> Server akan berjalan di `http://localhost:8080`

### 2. Konfigurasi IP pada Aplikasi Mobile

Buka file `frontend/lib/core/services/api_service.dart` dan sesuaikan IP:

```dart
// Untuk Android Emulator:
static String _baseUrl = 'http://10.0.2.2:8080';

// Untuk perangkat fisik (ganti dengan IP laptop Anda):
static String _baseUrl = 'http://192.168.x.x:8080';
```

### 3. Jalankan Aplikasi Mobile

```bash
cd frontend
flutter pub get
flutter run
```

### 4. Akses Antarmuka Web

Buka file berikut langsung di browser:
- **Dashboard Admin:** `web-dashboard/index.html`
- **Portal Psikolog:** `psikolog-portal/index.html`
- **Panel DB Admin:** `db-admin/index.html`

### Akun Default (Setelah Server Pertama Kali Dijalankan)

| Peran | Email | Password |
|---|---|---|
| Admin | `admin@sigap.id` | `admin123` |
| Psikolog | `psikolog@sigap.id` | `psikolog123` |

---

## REST API Endpoint

### Autentikasi
| Metode | Endpoint | Fungsi | Peran |
|---|---|---|---|
| POST | `/api/auth/register` | Registrasi pengguna baru | Publik |
| POST | `/api/auth/login` | Login & mendapatkan JWT | Publik |
| GET | `/api/auth/me` | Profil pengguna aktif | Semua |

### Laporan
| Metode | Endpoint | Fungsi | Peran |
|---|---|---|---|
| POST | `/api/reports` | Kirim laporan baru | User |
| GET | `/api/reports` | Daftar semua laporan | Admin/Psikolog |
| POST | `/api/reports/status` | Update status laporan | Admin |

### Konsultasi
| Metode | Endpoint | Fungsi | Peran |
|---|---|---|---|
| POST | `/api/appointments/initiate` | Tunjuk psikolog | Admin |
| POST | `/api/appointments/select` | Pilih slot jadwal | User |
| POST | `/api/appointments/respond` | Konfirmasi/tolak jadwal | Psikolog |
| POST | `/api/appointments/complete` | Akhiri sesi | Psikolog |
| POST | `/api/session-notes` | Simpan catatan SOAP | Psikolog |

### Darurat SOS
| Metode | Endpoint | Fungsi | Peran |
|---|---|---|---|
| POST | `/api/emergency/sos` | Aktifkan darurat SOS | User |
| POST | `/api/upload/audio` | Upload chunk audio | User |
| GET | `/api/emergency/audio` | Ambil daftar audio chunk | Admin/User |

### Mode Pantau
| Metode | Endpoint | Fungsi | Peran |
|---|---|---|---|
| POST | `/api/pantau/start` | Mulai sesi pantau GPS | User |
| POST | `/api/pantau/heartbeat` | Kirim titik GPS | User |

---

## Skema Basis Data

Sistem menggunakan 13 tabel relasional:

| Tabel | Fungsi |
|---|---|
| `users` | Data seluruh pengguna (user, admin, psikolog) |
| `reports` | Laporan kekerasan seksual dari penyintas |
| `appointments` | Jadwal sesi konsultasi user–psikolog |
| `session_notes` | Catatan SOAP psikolog per sesi |
| `session_feedback` | Rating & ulasan user setelah sesi |
| `emergency_incidents` | Insiden darurat SOS aktif |
| `emergency_audios` | Rekaman audio chunk dari insiden SOS |
| `emergency_responses` | Data responder yang merespons SOS |
| `pantau_sessions` | Sesi mode pantau berbasis GPS |
| `pantau_heartbeats` | Rekam jejak GPS per sesi pantau |
| `psikolog_schedules` | Slot jadwal mingguan psikolog |
| `notifications` | Notifikasi dalam aplikasi per pengguna |
| `audit_trail` | Log setiap perubahan status laporan |

### Alur Status Laporan (State Machine)

```
pending ──► diterima ──► menunggu_penjadwalan ──► dijadwalkan ──► diproses ──► selesai (final)
   │            │
   └──► ditolak (final)
```

> ⚠️ Laporan hanya dapat ditandai `selesai` oleh Admin **jika dan hanya jika** psikolog telah mengakhiri sesi konsultasi terakhir.

---

## Tim Pengembang

| NIM | Nama | Kontribusi Utama |
|---|---|---|
| 1202230023 | Sulthonika Mahfudz Al Mujahidin | Aplikasi mobile Flutter: fitur kritis utama (pelaporan, pantau, SOS & darurat) |
| 1202230014 | Michael Angello Qadosy Riyadi | Backend Go, Dashboard Admin/Psikolog Web, SOS & darurat, integrasi layer mobile & web |
| 1202230008 | Nur Alifia Rustan | Aplikasi mobile Flutter: fitur kritis utama (pelaporan, pantau, SOS & darurat) |
| 1202230050 | A'isyah Belqis Febi Aulia | Aplikasi mobile Flutter: halaman psikolog, akun, wawasan, Portal Psikolog Web |

---

## Keterbatasan & Pengembangan Lanjutan

### Fitur Belum Selesai
- [ ] **Chatbot AI** — Handler backend tersedia, namun integrasi model bahasa belum selesai
- [ ] **Antarmuka mobile untuk Admin** — Saat ini hanya tersedia via web
- [ ] **Antarmuka mobile untuk Psikolog** — Saat ini hanya tersedia via web

### Saran Pengembangan Lanjutan
- Migrasi basis data dari SQLite ke **PostgreSQL** untuk skalabilitas produksi
- Implementasi **enkripsi end-to-end** pada konten laporan dan audio
- Integrasi **Push Notification** via Firebase Cloud Messaging (FCM)
- Penambahan fitur **chatbot AI** untuk dukungan awal korban

---

## Referensi

1. H. Tjahjaningsih, "Kekerasan Seksual di Perguruan Tinggi: Faktor Penyebab dan Dampak Psikologis," *Jurnal Ilmu Sosial dan Ilmu Politik*, vol. 24, no. 2, pp. 112–125, 2021.
2. Kemendikbudristek, "Permendikbudristek No. 30 Tahun 2021 tentang PPKS di Lingkungan Perguruan Tinggi," Jakarta, 2021.
3. R. Pratama and A. Nugraha, "Rancang Bangun Sistem Informasi Pelaporan Pelecehan Seksual Berbasis Web," *JTIIK*, vol. 9, no. 4, pp. 741–750, 2022.
4. M. Sari et al., "Pengembangan Aplikasi Mobile untuk Pelaporan Kekerasan Seksual dengan Fitur Anonimitas," *SEMNASTIK*, pp. 231–239, 2022.
5. I. Sommerville, *Software Engineering*, 10th ed. London: Pearson, 2016.
6. M. B. Jones et al., "JSON Web Token (JWT)," RFC 7519, IETF, May 2015.

---

<div align="center">

**SIGAP** — Dibuat sebagai Tugas Besar Mata Kuliah Aplikasi Perangkat Bergerak  
Program Studi Teknologi Informasi, Telkom University Surabaya · 2026

</div>
