package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

// InitDB menginisialisasi koneksi database dan menjalankan migrasi
func InitDB(dbPath string) error {
	// Pastikan directory ada
	dir := filepath.Dir(dbPath)
	if dir != "." && dir != "" {
		os.MkdirAll(dir, 0755)
	}

	var err error
	DB, err = sql.Open("sqlite", dbPath+"?_pragma=journal_mode(WAL)&_pragma=foreign_keys(1)")
	if err != nil {
		return fmt.Errorf("gagal buka database: %w", err)
	}

	// Test koneksi
	if err := DB.Ping(); err != nil {
		return fmt.Errorf("gagal ping database: %w", err)
	}

	// Konfigurasi connection pool
	DB.SetMaxOpenConns(10)
	DB.SetMaxIdleConns(5)

	log.Println("[Database] Koneksi SQLite berhasil:", dbPath)

	// Jalankan migrasi
	if err := runMigrations(); err != nil {
		return fmt.Errorf("gagal migrasi: %w", err)
	}

	return nil
}

func runMigrations() error {
	migrations := []string{
		// TABEL USERS
		`CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			email TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			nama_lengkap TEXT NOT NULL,
			role TEXT NOT NULL DEFAULT 'user' CHECK(role IN ('user','admin','psikolog')),
			sub_role TEXT DEFAULT '' CHECK(sub_role IN ('','mahasiswa','dosen','karyawan')),
			nim_nidn_nik TEXT DEFAULT '',
			no_hp TEXT DEFAULT '',
			prodi_unit TEXT DEFAULT '',
			avatar_url TEXT DEFAULT '',
			is_active INTEGER DEFAULT 1,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)`,

		// TABEL REPORTS (Laporan Pelecehan)
		`CREATE TABLE IF NOT EXISTS reports (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			tracking_code TEXT UNIQUE NOT NULL,
			user_id INTEGER NOT NULL,
			jenis_penyintas TEXT DEFAULT '',
			kategori_kekhawatiran TEXT DEFAULT '',
			gender_pelaku TEXT DEFAULT '',
			hubungan_pelaku TEXT DEFAULT '',
			detail_kejadian TEXT DEFAULT '',
			email_penyintas TEXT DEFAULT '',
			bukti_path TEXT DEFAULT '',
			status TEXT DEFAULT 'pending' CHECK(status IN ('pending','diterima','menunggu_penjadwalan','dijadwalkan','ditolak','diproses','selesai')),
			assigned_admin_id INTEGER,
			assigned_psikolog_id INTEGER,
			alasan_tolak TEXT DEFAULT '',
			catatan_admin TEXT DEFAULT '',
			catatan_psikolog TEXT DEFAULT '',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(user_id) REFERENCES users(id),
			FOREIGN KEY(assigned_admin_id) REFERENCES users(id),
			FOREIGN KEY(assigned_psikolog_id) REFERENCES users(id)
		)`,

		// TABEL PSIKOLOG SCHEDULES (Slot Jadwal Konsultasi)
		`CREATE TABLE IF NOT EXISTS psikolog_schedules (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			psikolog_id INTEGER NOT NULL,
			hari TEXT NOT NULL CHECK(hari IN ('senin','selasa','rabu','kamis','jumat','sabtu')),
			jam_mulai TEXT NOT NULL,
			jam_selesai TEXT NOT NULL,
			is_active INTEGER DEFAULT 1,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(psikolog_id) REFERENCES users(id)
		)`,

		// TABEL APPOINTMENTS (Pertemuan Terjadwal)
		`CREATE TABLE IF NOT EXISTS appointments (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			report_id INTEGER NOT NULL,
			psikolog_id INTEGER NOT NULL,
			user_id INTEGER NOT NULL,
			tanggal DATE NOT NULL DEFAULT '',
			jam_mulai TEXT NOT NULL DEFAULT '',
			jam_selesai TEXT NOT NULL DEFAULT '',
			status TEXT DEFAULT 'menunggu_user' CHECK(status IN ('menunggu_user','menunggu_psikolog','diterima','ditolak','reschedule','selesai','batal','no_show_user','no_show_psikolog')),
			tipe_lokasi TEXT DEFAULT 'online' CHECK(tipe_lokasi IN ('online','offline')),
			link_lokasi TEXT DEFAULT '',
			catatan_reschedule TEXT DEFAULT '',
			created_by_admin_id INTEGER,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(report_id) REFERENCES reports(id),
			FOREIGN KEY(psikolog_id) REFERENCES users(id),
			FOREIGN KEY(user_id) REFERENCES users(id),
			FOREIGN KEY(created_by_admin_id) REFERENCES users(id)
		)`,

		// TABEL EMERGENCY INCIDENTS (Darurat SOS)
		`CREATE TABLE IF NOT EXISTS emergency_incidents (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			incident_id TEXT UNIQUE NOT NULL,
			korban_id INTEGER NOT NULL,
			lat REAL DEFAULT 0,
			lng REAL DEFAULT 0,
			status TEXT DEFAULT 'active' CHECK(status IN ('active','responding','resolved','cancelled','stopped_by_user')),
			audio_path TEXT DEFAULT '',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			resolved_at DATETIME,
			FOREIGN KEY(korban_id) REFERENCES users(id)
		)`,

		// TABEL EMERGENCY RESPONSES (Responder)
		`CREATE TABLE IF NOT EXISTS emergency_responses (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			incident_id INTEGER NOT NULL,
			responder_id INTEGER NOT NULL,
			responder_lat REAL DEFAULT 0,
			responder_lng REAL DEFAULT 0,
			is_primary INTEGER DEFAULT 0,
			status TEXT DEFAULT 'navigating' CHECK(status IN ('navigating','arrived','resolved')),
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(incident_id) REFERENCES emergency_incidents(id),
			FOREIGN KEY(responder_id) REFERENCES users(id)
		)`,

		// TABEL EMERGENCY AUDIOS (Rekaman suara real-time SOS)
		`CREATE TABLE IF NOT EXISTS emergency_audios (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			incident_id TEXT NOT NULL,
			file_path TEXT NOT NULL,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)`,

		// TABEL PANTAU SESSIONS
		`CREATE TABLE IF NOT EXISTS pantau_sessions (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			interval_menit INTEGER DEFAULT 45,
			lokasi_deskripsi TEXT DEFAULT '',
			status TEXT DEFAULT 'active' CHECK(status IN ('active','checkin','emergency','resolved')),
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			last_checkin_at DATETIME,
			ended_at DATETIME,
			FOREIGN KEY(user_id) REFERENCES users(id)
		)`,

		// TABEL PANTAU HEARTBEATS (GPS)
		`CREATE TABLE IF NOT EXISTS pantau_heartbeats (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			session_id INTEGER NOT NULL,
			lat REAL DEFAULT 0,
			lng REAL DEFAULT 0,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(session_id) REFERENCES pantau_sessions(id)
		)`,

		// TABEL EMERGENCY CONTACTS
		`CREATE TABLE IF NOT EXISTS emergency_contacts (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			nama TEXT NOT NULL,
			no_hp TEXT NOT NULL,
			hubungan TEXT DEFAULT '',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(user_id) REFERENCES users(id)
		)`,

		// TABEL CHAT LOGS
		`CREATE TABLE IF NOT EXISTS chat_logs (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			role TEXT NOT NULL CHECK(role IN ('user','assistant')),
			content TEXT NOT NULL,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(user_id) REFERENCES users(id)
		)`,

		// TABEL NOTIFICATIONS
		`CREATE TABLE IF NOT EXISTS notifications (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			title TEXT NOT NULL,
			body TEXT DEFAULT '',
			type TEXT DEFAULT 'info',
			payload_json TEXT DEFAULT '{}',
			is_read INTEGER DEFAULT 0,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(user_id) REFERENCES users(id)
		)`,

		// TABEL AUDIT TRAIL
		`CREATE TABLE IF NOT EXISTS audit_trail (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			report_id INTEGER,
			incident_id INTEGER,
			actor_id INTEGER NOT NULL,
			action TEXT NOT NULL,
			detail TEXT DEFAULT '',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(report_id) REFERENCES reports(id),
			FOREIGN KEY(actor_id) REFERENCES users(id)
		)`,

		// INDEXES
		`CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)`,
		`CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)`,
		`CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status)`,
		`CREATE INDEX IF NOT EXISTS idx_reports_user ON reports(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_emergency_status ON emergency_incidents(status)`,
		`CREATE INDEX IF NOT EXISTS idx_emergency_incident_id ON emergency_incidents(incident_id)`,
		`CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read)`,
		`CREATE INDEX IF NOT EXISTS idx_pantau_user ON pantau_sessions(user_id, status)`,
		`CREATE INDEX IF NOT EXISTS idx_psikolog_schedules_psikolog ON psikolog_schedules(psikolog_id, is_active)`,
		`CREATE INDEX IF NOT EXISTS idx_appointments_report ON appointments(report_id)`,
		`CREATE INDEX IF NOT EXISTS idx_appointments_psikolog ON appointments(psikolog_id, status)`,
		`CREATE INDEX IF NOT EXISTS idx_appointments_user ON appointments(user_id, status)`,
		`CREATE TABLE IF NOT EXISTS emergency_audios (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			incident_id TEXT NOT NULL,
			file_path TEXT NOT NULL,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)`,
		`CREATE INDEX IF NOT EXISTS idx_emergency_audios_incident ON emergency_audios(incident_id)`,

		// TABEL SESSION NOTES (Catatan Sesi Psikolog — Format SOAP)
		`CREATE TABLE IF NOT EXISTS session_notes (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			appointment_id INTEGER NOT NULL,
			psikolog_id INTEGER NOT NULL,
			user_id INTEGER NOT NULL,
			subjective TEXT DEFAULT '',
			objective TEXT DEFAULT '',
			assessment TEXT DEFAULT '',
			plan TEXT DEFAULT '',
			mood_score INTEGER DEFAULT 0,
			risk_level TEXT DEFAULT 'low' CHECK(risk_level IN ('low','medium','high','critical')),
			follow_up_needed INTEGER DEFAULT 0,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(appointment_id) REFERENCES appointments(id),
			FOREIGN KEY(psikolog_id) REFERENCES users(id),
			FOREIGN KEY(user_id) REFERENCES users(id)
		)`,

		// TABEL SESSION FEEDBACK (Rating dari User setelah Sesi)
		`CREATE TABLE IF NOT EXISTS session_feedback (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			appointment_id INTEGER UNIQUE NOT NULL,
			user_id INTEGER NOT NULL,
			rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
			comment TEXT DEFAULT '',
			is_anonymous INTEGER DEFAULT 1,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(appointment_id) REFERENCES appointments(id)
		)`,

		// TABEL PSIKOLOG UNAVAILABILITY (Tanggal Tidak Tersedia)
		`CREATE TABLE IF NOT EXISTS psikolog_unavailability (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			psikolog_id INTEGER NOT NULL,
			tanggal DATE NOT NULL,
			alasan TEXT DEFAULT '',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(psikolog_id) REFERENCES users(id),
			UNIQUE(psikolog_id, tanggal)
		)`,

		// INDEXES baru
		`CREATE INDEX IF NOT EXISTS idx_session_notes_appointment ON session_notes(appointment_id)`,
		`CREATE INDEX IF NOT EXISTS idx_session_notes_psikolog ON session_notes(psikolog_id)`,
		`CREATE INDEX IF NOT EXISTS idx_psikolog_unavailability ON psikolog_unavailability(psikolog_id, tanggal)`,
	}

	for i, m := range migrations {
		if _, err := DB.Exec(m); err != nil {
			return fmt.Errorf("migrasi ke-%d gagal: %w", i, err)
		}
	}

	// ── ALTER TABLE migrations (safe untuk database yang sudah ada) ──
	// SQLite akan error jika kolom sudah ada, jadi kita ignore error-nya.
	alterMigrations := []string{
		// Reports columns (legacy)
		`ALTER TABLE reports ADD COLUMN tracking_code TEXT DEFAULT ''`,
		`ALTER TABLE reports ADD COLUMN email_penyintas TEXT DEFAULT ''`,
		// Pantau: kolom untuk server-side timeout detection
		// Menyimpan waktu check-in terakhir agar server bisa cek timeout
		// tanpa perlu mengandalkan client app yang mungkin sudah offline.
		`ALTER TABLE pantau_sessions ADD COLUMN last_checkin_at DATETIME DEFAULT CURRENT_TIMESTAMP`,
		// Emergency: tambah kolom cancelled_at untuk audit trail pembatalan SOS
		`ALTER TABLE emergency_incidents ADD COLUMN cancelled_at DATETIME`,
		// Emergency: tambah kolom cancelled_by untuk audit trail
		`ALTER TABLE emergency_incidents ADD COLUMN cancelled_by INTEGER`,
		// Appointments: tambah preferensi lokasi (online/offline) dan link lokasi aktual
		`ALTER TABLE appointments ADD COLUMN tipe_lokasi TEXT DEFAULT 'online'`,
		`ALTER TABLE appointments ADD COLUMN link_lokasi TEXT DEFAULT ''`,
	}
	for _, alter := range alterMigrations {
		DB.Exec(alter) // Ignore error — kolom mungkin sudah ada
	}

	// ── REBUILD reports TABLE: tambah status 'menunggu_penjadwalan' ──
	DB.Exec(`PRAGMA foreign_keys=off;`)
	DB.Exec(`BEGIN TRANSACTION;`)
	DB.Exec(`
		CREATE TABLE IF NOT EXISTS reports_new (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			tracking_code TEXT UNIQUE NOT NULL DEFAULT '',
			user_id INTEGER NOT NULL,
			jenis_penyintas TEXT DEFAULT '',
			kategori_kekhawatiran TEXT DEFAULT '',
			gender_pelaku TEXT DEFAULT '',
			hubungan_pelaku TEXT DEFAULT '',
			detail_kejadian TEXT DEFAULT '',
			email_penyintas TEXT DEFAULT '',
			bukti_path TEXT DEFAULT '',
			status TEXT DEFAULT 'pending' CHECK(status IN ('pending','diterima','menunggu_penjadwalan','dijadwalkan','ditolak','diproses','selesai')),
			assigned_admin_id INTEGER,
			assigned_psikolog_id INTEGER,
			alasan_tolak TEXT DEFAULT '',
			catatan_admin TEXT DEFAULT '',
			catatan_psikolog TEXT DEFAULT '',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(user_id) REFERENCES users(id),
			FOREIGN KEY(assigned_admin_id) REFERENCES users(id),
			FOREIGN KEY(assigned_psikolog_id) REFERENCES users(id)
		);
	`)
	DB.Exec(`
		INSERT OR IGNORE INTO reports_new
		SELECT id, tracking_code, user_id, jenis_penyintas, kategori_kekhawatiran, gender_pelaku, hubungan_pelaku,
		       detail_kejadian, email_penyintas, bukti_path, status, assigned_admin_id, assigned_psikolog_id,
		       alasan_tolak, catatan_admin, catatan_psikolog, created_at, updated_at
		FROM reports;
	`)
	DB.Exec(`DROP TABLE IF EXISTS reports;`)
	DB.Exec(`ALTER TABLE reports_new RENAME TO reports;`)
	DB.Exec(`COMMIT;`)

	// ── REBUILD appointments TABLE: tambah status 'batal','no_show_user','no_show_psikolog' ──
	DB.Exec(`BEGIN TRANSACTION;`)
	DB.Exec(`
		CREATE TABLE IF NOT EXISTS appointments_new (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			report_id INTEGER NOT NULL,
			psikolog_id INTEGER NOT NULL,
			user_id INTEGER NOT NULL,
			tanggal DATE NOT NULL DEFAULT '',
			jam_mulai TEXT NOT NULL DEFAULT '',
			jam_selesai TEXT NOT NULL DEFAULT '',
			status TEXT DEFAULT 'menunggu_user' CHECK(status IN ('menunggu_user','menunggu_psikolog','diterima','ditolak','reschedule','selesai','batal','no_show_user','no_show_psikolog')),
			tipe_lokasi TEXT DEFAULT 'online',
			link_lokasi TEXT DEFAULT '',
			catatan_reschedule TEXT DEFAULT '',
			created_by_admin_id INTEGER,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(report_id) REFERENCES reports(id),
			FOREIGN KEY(psikolog_id) REFERENCES users(id),
			FOREIGN KEY(user_id) REFERENCES users(id),
			FOREIGN KEY(created_by_admin_id) REFERENCES users(id)
		);
	`)
	DB.Exec(`
		INSERT OR IGNORE INTO appointments_new
		SELECT id, report_id, psikolog_id, user_id, tanggal, jam_mulai, jam_selesai, status,
		       COALESCE(tipe_lokasi, 'online'), COALESCE(link_lokasi, ''),
		       catatan_reschedule, created_by_admin_id, created_at, updated_at
		FROM appointments;
	`)
	DB.Exec(`DROP TABLE IF EXISTS appointments;`)
	DB.Exec(`ALTER TABLE appointments_new RENAME TO appointments;`)
	DB.Exec(`COMMIT;`)
	DB.Exec(`PRAGMA foreign_keys=on;`)



	// ── MIGRASI CHECK CONSTRAINT UNTUK TABEL emergency_incidents ──
	// Karena SQLite tidak mendukung ALTER TABLE untuk mengubah CHECK constraint,
	// kita harus membuat ulang tabel jika constraint lama masih ada.
	// Kita akan membuat tabel baru, copy data, hapus yang lama, rename.
	DB.Exec(`PRAGMA foreign_keys=off;`)
	DB.Exec(`BEGIN TRANSACTION;`)
	DB.Exec(`
		CREATE TABLE IF NOT EXISTS emergency_incidents_new (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			incident_id TEXT UNIQUE NOT NULL,
			korban_id INTEGER NOT NULL,
			lat REAL DEFAULT 0,
			lng REAL DEFAULT 0,
			status TEXT DEFAULT 'active' CHECK(status IN ('active','responding','resolved','cancelled','stopped_by_user')),
			audio_path TEXT DEFAULT '',
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			resolved_at DATETIME,
			cancelled_at DATETIME,
			cancelled_by INTEGER,
			FOREIGN KEY(korban_id) REFERENCES users(id)
		);
	`)
	// Copy data if the table exists (ignoring errors if it fails)
	DB.Exec(`
		INSERT INTO emergency_incidents_new (id, incident_id, korban_id, lat, lng, status, audio_path, created_at, resolved_at, cancelled_at, cancelled_by)
		SELECT id, incident_id, korban_id, lat, lng, status, audio_path, created_at, resolved_at, cancelled_at, cancelled_by FROM emergency_incidents;
	`)
	DB.Exec(`DROP TABLE emergency_incidents;`)
	DB.Exec(`ALTER TABLE emergency_incidents_new RENAME TO emergency_incidents;`)
	DB.Exec(`COMMIT;`)
	DB.Exec(`PRAGMA foreign_keys=on;`)

	// Inisialisasi last_checkin_at untuk sesi lama yang nilainya NULL
	DB.Exec(`
		UPDATE pantau_sessions 
		SET last_checkin_at = created_at 
		WHERE last_checkin_at IS NULL
	`)

	// Pastikan semua report punya tracking_code (isi yang kosong)
	rows, _ := DB.Query("SELECT id FROM reports WHERE tracking_code = '' OR tracking_code IS NULL")
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var id int
			rows.Scan(&id)
			code := fmt.Sprintf("SIGAP-LEGACY%d", id)
			DB.Exec("UPDATE reports SET tracking_code = ? WHERE id = ?", code, id)
		}
	}

	log.Println("[Database] Migrasi selesai — semua tabel siap")
	return nil
}

// Close menutup koneksi database
func Close() {
	if DB != nil {
		DB.Close()
	}
}
