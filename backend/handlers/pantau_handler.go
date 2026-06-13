package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"sigap-backend/database"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

// ══════════════════════════════════════════════════════════════
// START PANTAU SESSION
//
// ALUR LOGIKA:
//   1. Validasi auth dan body
//   2. Tutup semua session aktif milik user ini (cegah duplikat)
//   3. Buat session baru dengan status 'active'
//   4. Notifikasi ke admin bahwa ada user yang memulai pantauan
//   5. Return session_id untuk dipakai client
// ══════════════════════════════════════════════════════════════

func HandleStartPantau(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		IntervalMenit   int    `json:"interval_menit"`
		LokasiDeskripsi string `json:"lokasi_deskripsi"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Validasi interval: minimal 5 menit, maksimal 120 menit
	if req.IntervalMenit < 5 {
		req.IntervalMenit = 45 // default
	}
	if req.IntervalMenit > 120 {
		req.IntervalMenit = 120
	}

	// Tutup session lama yang masih aktif (cegah duplikat)
	database.DB.Exec(`
		UPDATE pantau_sessions SET status = 'resolved', ended_at = CURRENT_TIMESTAMP
		WHERE user_id = ? AND status IN ('active','checkin')
	`, claims.UserID)

	// Buat session baru
	result, err := database.DB.Exec(`
		INSERT INTO pantau_sessions (user_id, interval_menit, lokasi_deskripsi, status)
		VALUES (?, ?, ?, 'active')
	`, claims.UserID, req.IntervalMenit, req.LokasiDeskripsi)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal memulai pantauan")
		return
	}

	sessionID, _ := result.LastInsertId()

	// Notifikasi ke admin
	var userName string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&userName)
	rows, _ := database.DB.Query("SELECT id FROM users WHERE role = 'admin' AND is_active = 1")
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var adminID int
			rows.Scan(&adminID)
			database.DB.Exec(`
				INSERT INTO notifications (user_id, title, body, type)
				VALUES (?, '👁️ Pantauan Dimulai', ?, 'pantau_start')
			`, adminID, fmt.Sprintf("%s memulai pantauan di %s (interval %d menit)",
				userName, req.LokasiDeskripsi, req.IntervalMenit))
		}
	}

	utils.JSONResponse(w, http.StatusCreated, map[string]interface{}{
		"message":    "Pantauan dimulai",
		"session_id": sessionID,
	})
}

// ══════════════════════════════════════════════════════════════
// HEARTBEAT — Kirim GPS setiap interval
//
// ALUR: Simpan koordinat GPS ke tabel pantau_heartbeats
//       untuk tracking riwayat lokasi user
// ══════════════════════════════════════════════════════════════

func HandlePantauHeartbeat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		SessionID int     `json:"session_id"`
		Lat       float64 `json:"lat"`
		Lng       float64 `json:"lng"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Validasi session milik user ini dan masih aktif
	var sessionStatus string
	err := database.DB.QueryRow(
		"SELECT status FROM pantau_sessions WHERE id = ? AND user_id = ?",
		req.SessionID, claims.UserID,
	).Scan(&sessionStatus)

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Session pantauan tidak ditemukan")
		return
	}
	if sessionStatus != "active" && sessionStatus != "checkin" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Session sudah tidak aktif")
		return
	}

	// Simpan heartbeat
	_, err = database.DB.Exec(`
		INSERT INTO pantau_heartbeats (session_id, lat, lng)
		VALUES (?, ?, ?)
	`, req.SessionID, req.Lat, req.Lng)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan heartbeat")
		return
	}

	utils.SuccessResponse(w, "Heartbeat diterima", nil)
}

// ══════════════════════════════════════════════════════════════
// CHECK-IN — Konfirmasi AMAN
//
// ALUR LOGIKA:
//   1. Validasi auth dan body
//   2. Validasi session milik user dan masih aktif
//   3. Update status session kembali ke 'active' (reset timer)
//   4. Catat heartbeat lokasi (jika dikirim)
// ══════════════════════════════════════════════════════════════

func HandlePantauCheckin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		SessionID int     `json:"session_id"`
		Lat       float64 `json:"lat"`
		Lng       float64 `json:"lng"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Update status kembali ke 'active' dan perbarui last_checkin_at untuk server-side timeout
	res, _ := database.DB.Exec(`
		UPDATE pantau_sessions 
		SET status = 'active', last_checkin_at = CURRENT_TIMESTAMP
		WHERE id = ? AND user_id = ? AND status IN ('active','checkin')
	`, req.SessionID, claims.UserID)

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Session tidak ditemukan atau sudah berakhir")
		return
	}

	// Simpan lokasi checkin jika dikirim
	if req.Lat != 0 || req.Lng != 0 {
		database.DB.Exec(`
			INSERT INTO pantau_heartbeats (session_id, lat, lng)
			VALUES (?, ?, ?)
		`, req.SessionID, req.Lat, req.Lng)
	}

	utils.SuccessResponse(w, "Check-in berhasil — Anda aman", map[string]interface{}{
		"session_id": req.SessionID,
		"status":     "active",
		"next_checkin_required_in_minutes": nil, // Client bisa menampilkan ini
	})
}

// ══════════════════════════════════════════════════════════════
// EMERGENCY dari Pantau — User tidak check-in tepat waktu
//
// ALUR LOGIKA:
//   1. Update session status → 'emergency'
//   2. OTOMATIS buat SOS incident (eskalasi ke darurat)
//   3. Notifikasi ke semua admin + psikolog
//   4. Catat audit trail
//
// Ini adalah fitur keamanan kunci: jika user tidak merespon
// check-in dalam waktu yang ditentukan, sistem menganggap
// user dalam bahaya dan langsung memicu protokol darurat.
// ══════════════════════════════════════════════════════════════

func HandlePantauEmergency(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		SessionID int     `json:"session_id"`
		Lat       float64 `json:"lat"`
		Lng       float64 `json:"lng"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Update session status → emergency
	database.DB.Exec(`
		UPDATE pantau_sessions SET status = 'emergency'
		WHERE id = ? AND user_id = ? AND status IN ('active','checkin')
	`, req.SessionID, claims.UserID)

	// ── Otomatis buat SOS incident (eskalasi) ──
	incidentID := fmt.Sprintf("PANTAU-SOS-%d-%d", claims.UserID, time.Now().UnixMilli())
	var incidentDBID int64

	// Cek dulu apakah sudah ada incident aktif
	var existingID int
	err := database.DB.QueryRow(`
		SELECT id FROM emergency_incidents 
		WHERE korban_id = ? AND status IN ('active','responding') LIMIT 1
	`, claims.UserID).Scan(&existingID)

	if err != nil {
		// Belum ada → buat baru
		result, err := database.DB.Exec(`
			INSERT INTO emergency_incidents (incident_id, korban_id, lat, lng, status)
			VALUES (?, ?, ?, ?, 'active')
		`, incidentID, claims.UserID, req.Lat, req.Lng)
		if err == nil {
			incidentDBID, _ = result.LastInsertId()
		}
	} else {
		incidentDBID = int64(existingID)
	}

	// Notifikasi ke semua admin + psikolog
	var userName string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&userName)
	notifBody := fmt.Sprintf("⚠️ %s TIDAK MERESPON check-in pantauan! Kemungkinan dalam bahaya.", userName)

	staffRows, _ := database.DB.Query("SELECT id FROM users WHERE role IN ('admin','psikolog') AND is_active = 1")
	if staffRows != nil {
		defer staffRows.Close()
		for staffRows.Next() {
			var staffID int
			staffRows.Scan(&staffID)
			database.DB.Exec(`
				INSERT INTO notifications (user_id, title, body, type, payload_json)
				VALUES (?, '🚨 Pantau DARURAT!', ?, 'pantau_emergency', ?)
			`, staffID, notifBody, fmt.Sprintf(`{"session_id":%d,"incident_db_id":%d}`, req.SessionID, incidentDBID))
		}
	}

	// Audit trail
	database.DB.Exec(`
		INSERT INTO audit_trail (incident_id, actor_id, action, detail)
		VALUES (?, ?, 'PANTAU_EMERGENCY', ?)
	`, incidentDBID, claims.UserID, fmt.Sprintf("Pantauan otomatis eskalasi ke SOS karena tidak check-in"))

	utils.SuccessResponse(w, "Darurat pantauan tercatat — SOS otomatis dikirim", map[string]interface{}{
		"session_id":     req.SessionID,
		"incident_db_id": incidentDBID,
		"incident_id":    incidentID,
	})
}

// ══════════════════════════════════════════════════════════════
// STOP PANTAU
//
// ALUR: Hentikan semua session aktif milik user
// ══════════════════════════════════════════════════════════════

func HandleStopPantau(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	res, _ := database.DB.Exec(`
		UPDATE pantau_sessions SET status = 'resolved', ended_at = CURRENT_TIMESTAMP
		WHERE user_id = ? AND status IN ('active', 'checkin', 'emergency')
	`, claims.UserID)

	rowsAffected, _ := res.RowsAffected()

	utils.SuccessResponse(w, "Pantauan dihentikan", map[string]interface{}{
		"sessions_stopped": rowsAffected,
	})
}

// ══════════════════════════════════════════════════════════════
// GET ACTIVE SESSION — Untuk client cek session yang sedang berjalan
// ══════════════════════════════════════════════════════════════

func HandleActivePantau(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var sessionID, interval int
	var lokasi, status, createdAt string
	err := database.DB.QueryRow(`
		SELECT id, interval_menit, lokasi_deskripsi, status, created_at
		FROM pantau_sessions
		WHERE user_id = ? AND status IN ('active', 'checkin')
		ORDER BY created_at DESC LIMIT 1
	`, claims.UserID).Scan(&sessionID, &interval, &lokasi, &status, &createdAt)

	if err != nil {
		utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
			"active": false,
		})
		return
	}

	// Hitung jumlah heartbeats
	var heartbeatCount int
	database.DB.QueryRow("SELECT COUNT(*) FROM pantau_heartbeats WHERE session_id = ?", sessionID).Scan(&heartbeatCount)

	// Ambil lokasi terakhir
	var lastLat, lastLng float64
	database.DB.QueryRow(`
		SELECT lat, lng FROM pantau_heartbeats 
		WHERE session_id = ? ORDER BY created_at DESC LIMIT 1
	`, sessionID).Scan(&lastLat, &lastLng)

	// Hitung sisa waktu hingga checkin berikutnya (dari last_checkin_at)
	var lastCheckinAt string
	database.DB.QueryRow(`
		SELECT COALESCE(last_checkin_at, created_at) FROM pantau_sessions WHERE id = ?
	`, sessionID).Scan(&lastCheckinAt)

	// Hitung menit sejak checkin terakhir
	var minutesSinceLastCheckin float64
	if t, err := time.Parse("2006-01-02 15:04:05", lastCheckinAt); err == nil {
		minutesSinceLastCheckin = time.Since(t).Minutes()
	}
	remainingMinutes := float64(interval) - minutesSinceLastCheckin
	if remainingMinutes < 0 {
		remainingMinutes = 0
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"active":           true,
		"session_id":       sessionID,
		"interval_menit":   interval,
		"lokasi_deskripsi": lokasi,
		"status":           status,
		"created_at":       createdAt,
		"heartbeat_count":  heartbeatCount,
		"last_lat":              lastLat,
		"last_lng":              lastLng,
		"last_checkin_at":       lastCheckinAt,
		"remaining_minutes":     remainingMinutes,
	})
}

// CheckPantauTimeouts runs as a background goroutine every minute.
// It auto-escalates Pantau sessions to emergency when the user hasn't
// checked in within their set interval � even if their phone is offline.
func CheckPantauTimeouts() {
	rows, err := database.DB.Query(`
		SELECT ps.id, ps.user_id, ps.interval_menit,
		       COALESCE(ps.last_checkin_at, ps.created_at) AS last_checkin,
		       u.nama_lengkap
		FROM pantau_sessions ps
		JOIN users u ON ps.user_id = u.id
		WHERE ps.status IN ('active', 'checkin')
		AND (
			CAST(strftime('%s', 'now') AS INTEGER) -
			CAST(strftime('%s', COALESCE(ps.last_checkin_at, ps.created_at)) AS INTEGER)
		) > (ps.interval_menit * 60)
	`)
	if err != nil {
		return
	}
	defer rows.Close()

	for rows.Next() {
		var sessionID, userID, intervalMenit int
		var lastCheckin, userName string
		if err := rows.Scan(&sessionID, &userID, &intervalMenit, &lastCheckin, &userName); err != nil {
			continue
		}

		database.DB.Exec(`
			UPDATE pantau_sessions SET status = 'emergency'
			WHERE id = ? AND status IN ('active', 'checkin')
		`, sessionID)

		var existingIncidentID int
		checkErr := database.DB.QueryRow(`
			SELECT id FROM emergency_incidents
			WHERE korban_id = ? AND status IN ('active','responding') LIMIT 1
		`, userID).Scan(&existingIncidentID)

		var incidentDBID int64
		if checkErr != nil {
			var lastLat, lastLng float64
			database.DB.QueryRow(`
				SELECT lat, lng FROM pantau_heartbeats
				WHERE session_id = ? ORDER BY created_at DESC LIMIT 1
			`, sessionID).Scan(&lastLat, &lastLng)

			newIncidentID := fmt.Sprintf("PANTAU-AUTO-%d-%d", userID, time.Now().UnixMilli())
			result, insertErr := database.DB.Exec(`
				INSERT INTO emergency_incidents (incident_id, korban_id, lat, lng, status)
				VALUES (?, ?, ?, ?, 'active')
			`, newIncidentID, userID, lastLat, lastLng)
			if insertErr == nil {
				incidentDBID, _ = result.LastInsertId()
			}
		} else {
			incidentDBID = int64(existingIncidentID)
		}

		notifBody := fmt.Sprintf(
			"SERVER ALERT: %s TIDAK MERESPON check-in pantauan sejak %s (interval: %d menit). Kemungkinan dalam bahaya!",
			userName, lastCheckin, intervalMenit,
		)

		staffRows, _ := database.DB.Query("SELECT id FROM users WHERE role IN ('admin','psikolog') AND is_active = 1")
		if staffRows != nil {
			defer staffRows.Close()
			for staffRows.Next() {
				var staffID int
				staffRows.Scan(&staffID)
				database.DB.Exec(`
					INSERT INTO notifications (user_id, title, body, type, payload_json)
					VALUES (?, 'Pantau DARURAT (Server Timeout)!', ?, 'pantau_emergency', ?)
				`, staffID, notifBody,
					fmt.Sprintf(`{"session_id":%d,"incident_db_id":%d,"triggered_by":"server_timeout"}`, sessionID, incidentDBID))
			}
		}

		database.DB.Exec(`
			INSERT INTO audit_trail (incident_id, actor_id, action, detail)
			VALUES (?, ?, 'PANTAU_AUTO_EMERGENCY', ?)
		`, incidentDBID, userID,
			fmt.Sprintf("Server otomatis eskalasi sesi pantau %d ke darurat (timeout %d menit)", sessionID, intervalMenit))
	}
}
