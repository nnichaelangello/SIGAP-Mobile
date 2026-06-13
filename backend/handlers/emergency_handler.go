package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"sigap-backend/database"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

// ══════════════════════════════════════════════════════════════
// SOS — Korban trigger darurat
//
// ALUR LOGIKA:
//   1. Validasi auth dan body
//   2. Cek apakah user sudah punya incident aktif (cegah duplikat)
//   3. Jika ada → return incident yang sudah ada (idempotent)
//   4. Jika belum → buat incident baru
//   5. Notifikasi ke semua admin + psikolog
//   6. Catat audit trail
// ══════════════════════════════════════════════════════════════

func HandleSOS(w http.ResponseWriter, r *http.Request) {
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
		Lat float64 `json:"lat"`
		Lng float64 `json:"lng"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// ── Cegah duplikat: cek apakah user sudah punya incident aktif ──
	var existingID int
	var existingIncidentID string
	err := database.DB.QueryRow(`
		SELECT id, incident_id FROM emergency_incidents 
		WHERE korban_id = ? AND status IN ('active','responding') 
		LIMIT 1
	`, claims.UserID).Scan(&existingID, &existingIncidentID)

	if err == nil {
		// Sudah ada incident aktif → update lokasi terbaru & kembalikan
		database.DB.Exec(`
			UPDATE emergency_incidents SET lat = ?, lng = ? WHERE id = ?
		`, req.Lat, req.Lng, existingID)

		utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
			"message":     "SOS sudah aktif — lokasi diperbarui",
			"incident_id": existingIncidentID,
			"db_id":       existingID,
			"is_existing": true,
		})
		return
	}

	// ── Buat incident baru ──
	incidentID := fmt.Sprintf("SOS-%d-%d", claims.UserID, time.Now().UnixMilli())

	result, err := database.DB.Exec(`
		INSERT INTO emergency_incidents (incident_id, korban_id, lat, lng, status)
		VALUES (?, ?, ?, ?, 'active')
	`, incidentID, claims.UserID, req.Lat, req.Lng)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal membuat incident darurat")
		return
	}

	dbID, _ := result.LastInsertId()

	// ── Notifikasi ke semua admin DAN psikolog ──
	var korbanNama string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&korbanNama)

	notifBody := fmt.Sprintf("DARURAT! %s membutuhkan bantuan segera!", korbanNama)
	payloadJSON := fmt.Sprintf(`{"incident_id":"%s","db_id":%d,"lat":%f,"lng":%f}`, incidentID, dbID, req.Lat, req.Lng)

	rows, _ := database.DB.Query("SELECT id FROM users WHERE role IN ('admin','psikolog') AND id != ? AND is_active = 1", claims.UserID)
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var userID int
			rows.Scan(&userID)
			database.DB.Exec(`
				INSERT INTO notifications (user_id, title, body, type, payload_json)
				VALUES (?, '🚨 DARURAT! SOS Diterima', ?, 'emergency', ?)
			`, userID, notifBody, payloadJSON)
		}
	}

	// ── Notifikasi ke emergency contacts korban (log untuk integrasi SMS) ──
	contactRows, _ := database.DB.Query("SELECT nama, no_hp FROM emergency_contacts WHERE user_id = ?", claims.UserID)
	if contactRows != nil {
		defer contactRows.Close()
		for contactRows.Next() {
			var nama, noHP string
			contactRows.Scan(&nama, &noHP)
			_ = nama // TODO: integrasi SMS gateway
			_ = noHP
		}
	}

	// ── Audit trail ──
	database.DB.Exec(`
		INSERT INTO audit_trail (incident_id, actor_id, action, detail)
		VALUES (?, ?, 'SOS_TRIGGERED', ?)
	`, dbID, claims.UserID, fmt.Sprintf("SOS dipicu oleh %s di lat=%f, lng=%f", korbanNama, req.Lat, req.Lng))

	utils.JSONResponse(w, http.StatusCreated, map[string]interface{}{
		"message":     "SOS berhasil dikirim",
		"incident_id": incidentID,
		"db_id":       dbID,
		"is_existing": false,
	})
}

// ══════════════════════════════════════════════════════════════
// CANCEL EMERGENCY — Korban membatalkan SOS secara manual
//
// ALUR LOGIKA:
//   1. Validasi auth
//   2. Cari incident aktif milik user ini
//   3. Update status → 'stopped_by_user' (bukan resolved)
//   4. Notifikasi ke semua responder dan admin
//   5. Audit trail
//
// Ini BERBEDA dari resolve:
//   - 'stopped_by_user' = korban membatalkan sendiri (false alarm / aman) tapi admin masih bisa lihat
//   - 'resolved' = admin/responder mengakhiri setelah situasi benar-benar ditangani
// ══════════════════════════════════════════════════════════════

func HandleCancelEmergency(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	// Auto-cari incident aktif milik user ini
	var incidentID int
	var currentStatus string
	err := database.DB.QueryRow(
		`SELECT id, status FROM emergency_incidents 
		 WHERE korban_id = ? AND status IN ('active','responding') 
		 ORDER BY id DESC LIMIT 1`,
		claims.UserID,
	).Scan(&incidentID, &currentStatus)

	if err != nil {
		// Tidak ada incident aktif — mungkin sudah cancelled/resolved sebelumnya
		utils.SuccessResponse(w, "Tidak ada incident aktif yang perlu dibatalkan", nil)
		return
	}

	// Update status → stopped_by_user
	database.DB.Exec(`
		UPDATE emergency_incidents 
		SET status = 'stopped_by_user'
		WHERE id = ?
	`, incidentID)

	// Update semua responder → status resolved (misi dibatalkan)
	database.DB.Exec(`
		UPDATE emergency_responses SET status = 'resolved'
		WHERE incident_id = ?
	`, incidentID)

	// Tutup pantau session korban yang nyangkut di status emergency (jika ada)
	// Hal ini mencegah state desync jika SOS dipicu oleh kegagalan check-in Pantau
	database.DB.Exec(`
		UPDATE pantau_sessions SET status = 'resolved', ended_at = CURRENT_TIMESTAMP
		WHERE user_id = ? AND status IN ('active','checkin','emergency')
	`, claims.UserID)

	// Notifikasi ke semua responder yang sudah merespon
	respRows, _ := database.DB.Query(
		"SELECT DISTINCT responder_id FROM emergency_responses WHERE incident_id = ?",
		incidentID,
	)
	if respRows != nil {
		defer respRows.Close()
		for respRows.Next() {
			var respID int
			respRows.Scan(&respID)
			database.DB.Exec(`
				INSERT INTO notifications (user_id, title, body, type)
				VALUES (?, '🔔 SOS Dibatalkan', 'Korban membatalkan sinyal darurat. Situasi aman.', 'emergency_cancelled')
			`, respID)
		}
	}

	// Notifikasi ke semua admin
	adminRows, _ := database.DB.Query("SELECT id FROM users WHERE role IN ('admin','psikolog') AND is_active = 1")
	if adminRows != nil {
		defer adminRows.Close()
		var korbanNama string
		database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&korbanNama)
		for adminRows.Next() {
			var adminID int
			adminRows.Scan(&adminID)
			database.DB.Exec(`
				INSERT INTO notifications (user_id, title, body, type)
				VALUES (?, '✅ SOS Dibatalkan', ?, 'emergency_cancelled')
			`, adminID, fmt.Sprintf("%s membatalkan sinyal darurat. Situasi dilaporkan aman.", korbanNama))
		}
	}

	// Audit trail
	database.DB.Exec(`
		INSERT INTO audit_trail (incident_id, actor_id, action, detail)
		VALUES (?, ?, 'SOS_CANCELLED', 'Korban membatalkan sinyal darurat secara manual')
	`, incidentID, claims.UserID)

	utils.SuccessResponse(w, "SOS berhasil dibatalkan", map[string]interface{}{
		"incident_id": incidentID,
		"status":      "stopped_by_user",
	})
}

// ══════════════════════════════════════════════════════════════
// GET PENDING EMERGENCIES — Untuk responder/admin polling
//
// ALUR: Ambil semua incident aktif/responding, termasuk count responder
// Filter: ?status=active|all|resolved|cancelled
// PENTING: Caller tidak akan melihat SOS miliknya sendiri
//          agar tidak mengganggu alur UI responder.
// ══════════════════════════════════════════════════════════════

func HandlePendingEmergencies(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	// Support filter: ?status=active atau ?status=all
	statusFilter := r.URL.Query().Get("status")

	var whereClause string
	switch statusFilter {
	case "all":
		// Semua status kecuali milik sendiri
		whereClause = fmt.Sprintf("WHERE e.korban_id != %d", claims.UserID)
	case "resolved":
		whereClause = fmt.Sprintf("WHERE e.status = 'resolved' AND e.korban_id != %d", claims.UserID)
	case "cancelled":
		whereClause = fmt.Sprintf("WHERE e.status = 'cancelled' AND e.korban_id != %d", claims.UserID)
	case "stopped":
		whereClause = fmt.Sprintf("WHERE e.status = 'stopped_by_user' AND e.korban_id != %d", claims.UserID)
	default:
		// Default: active, responding, stopped_by_user (jadi admin tetap bisa lihat yang distop user sebelum diresolve)
		whereClause = fmt.Sprintf("WHERE e.status IN ('active', 'responding', 'stopped_by_user') AND e.korban_id != %d", claims.UserID)
	}

	query := fmt.Sprintf(`
		SELECT e.id, e.incident_id, e.korban_id, u.nama_lengkap, u.no_hp,
		       e.lat, e.lng, e.status, e.audio_path, e.created_at, e.resolved_at
		FROM emergency_incidents e
		JOIN users u ON e.korban_id = u.id
		%s
		ORDER BY e.created_at DESC
	`, whereClause)

	rows, err := database.DB.Query(query)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil data darurat")
		return
	}
	defer rows.Close()

	var incidents []map[string]interface{}
	for rows.Next() {
		var id, korbanID int
		var incidentID, nama, status, createdAt string
		var noHP, audioPath, resolvedAt *string
		var lat, lng float64
		rows.Scan(&id, &incidentID, &korbanID, &nama, &noHP,
			&lat, &lng, &status, &audioPath, &createdAt, &resolvedAt)

		// Hitung jumlah responder
		var responderCount int
		database.DB.QueryRow("SELECT COUNT(*) FROM emergency_responses WHERE incident_id = ?", id).Scan(&responderCount)

		// Hitung durasi
		var duration string
		if t, err := time.Parse("2006-01-02 15:04:05", createdAt); err == nil {
			duration = time.Since(t).Round(time.Second).String()
		}

		entry := map[string]interface{}{
			"id":              id,
			"incident_id":     incidentID,
			"korban_id":       korbanID,
			"nama_korban":     nama,
			"no_hp_korban":    noHP,
			"lat":             lat,
			"lng":             lng,
			"status":          status,
			"audio_path":      audioPath,
			"responder_count": responderCount,
			"created_at":      createdAt,
			"resolved_at":     resolvedAt,
			"duration":        duration,
		}
		incidents = append(incidents, entry)
	}

	if incidents == nil {
		incidents = []map[string]interface{}{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data":  incidents,
		"total": len(incidents),
	})
}

// ══════════════════════════════════════════════════════════════
// RESPOND — Responder menerima misi
//
// ALUR LOGIKA:
//   1. Validasi auth dan body
//   2. Cek incident masih aktif (bukan resolved/cancelled)
//   3. Cek belum pernah merespon (cegah duplikat)
//   4. Insert response record
//   5. Update status incident → 'responding'
//   6. Notifikasi ke korban bahwa bantuan sedang datang
//   7. Audit trail
// ══════════════════════════════════════════════════════════════

func HandleRespondEmergency(w http.ResponseWriter, r *http.Request) {
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
		IncidentDBID int     `json:"incident_db_id"`
		IncidentID   string  `json:"incident_id"` // string alias dari mobile
		Lat          float64 `json:"lat"`
		Lng          float64 `json:"lng"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// ── Resolve incident DB ID ──
	// Jika incident_db_id tidak dikirim tapi incident_id string dikirim → cari dari DB
	incidentDBID := req.IncidentDBID
	if incidentDBID == 0 && req.IncidentID != "" {
		err := database.DB.QueryRow(
			"SELECT id FROM emergency_incidents WHERE incident_id = ?",
			req.IncidentID,
		).Scan(&incidentDBID)
		if err != nil {
			utils.ErrorResponse(w, http.StatusNotFound, "Incident tidak ditemukan berdasarkan incident_id")
			return
		}
	}
	if incidentDBID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "incident_db_id atau incident_id wajib diisi")
		return
	}

	// Cek incident masih aktif (tidak boleh respond ke cancelled atau resolved)
	var status string
	var korbanID int
	err := database.DB.QueryRow(
		"SELECT status, korban_id FROM emergency_incidents WHERE id = ?",
		incidentDBID,
	).Scan(&status, &korbanID)

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Incident tidak ditemukan")
		return
	}
	if status == "resolved" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Incident sudah diselesaikan")
		return
	}
	if status == "cancelled" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Incident sudah dibatalkan oleh korban")
		return
	}

	// Cegah korban merespon dirinya sendiri
	if claims.UserID == korbanID {
		utils.ErrorResponse(w, http.StatusBadRequest, "Korban tidak bisa menjadi responder untuk dirinya sendiri")
		return
	}

	// Cek apakah sudah pernah merespon
	var existingPrimary int
	errResp := database.DB.QueryRow(
		"SELECT is_primary FROM emergency_responses WHERE incident_id = ? AND responder_id = ?",
		incidentDBID, claims.UserID,
	).Scan(&existingPrimary)

	if errResp == nil {
		// Sudah pernah merespon, anggap sukses agar user bisa masuk kembali (rejoin) ke halaman tracking
		utils.SuccessResponse(w, "Membuka kembali sesi respon darurat", map[string]interface{}{
			"incident_db_id": incidentDBID,
			"responder_id":   claims.UserID,
			"is_primary":     existingPrimary == 1,
		})
		return
	}

	tx, err := database.DB.Begin()
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal memulai transaksi")
		return
	}
	defer tx.Rollback()

	// Tentukan apakah ini responder pertama (primary) menggunakan transaksi
	var totalResponders int
	tx.QueryRow(
		"SELECT COUNT(*) FROM emergency_responses WHERE incident_id = ?",
		incidentDBID,
	).Scan(&totalResponders)
	
	isPrimary := 0
	if totalResponders == 0 {
		isPrimary = 1
	}

	// Insert response
	_, err = tx.Exec(`
		INSERT INTO emergency_responses (incident_id, responder_id, responder_lat, responder_lng, is_primary, status)
		VALUES (?, ?, ?, ?, ?, 'navigating')
	`, incidentDBID, claims.UserID, req.Lat, req.Lng, isPrimary)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mencatat respon")
		return
	}

	// Update status incident → 'responding'
	tx.Exec("UPDATE emergency_incidents SET status = 'responding' WHERE id = ? AND status = 'active'", incidentDBID)

	if err := tx.Commit(); err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan data respon")
		return
	}

	// Notifikasi ke korban
	var responderNama string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&responderNama)
	database.DB.Exec(`
		INSERT INTO notifications (user_id, title, body, type, payload_json)
		VALUES (?, '🏃 Bantuan Sedang Datang!', ?, 'emergency_response', ?)
	`, korbanID,
		fmt.Sprintf("%s sedang menuju lokasi Anda", responderNama),
		fmt.Sprintf(`{"incident_db_id":%d,"responder":"%s"}`, incidentDBID, responderNama))

	// Audit
	database.DB.Exec(`
		INSERT INTO audit_trail (incident_id, actor_id, action, detail)
		VALUES (?, ?, 'EMERGENCY_RESPONDED', ?)
	`, incidentDBID, claims.UserID, fmt.Sprintf("%s merespon sebagai responder", responderNama))

	utils.SuccessResponse(w, "Respon darurat tercatat", map[string]interface{}{
		"incident_db_id": incidentDBID,
		"responder_id":   claims.UserID,
		"is_primary":     isPrimary == 1,
	})
}

// ══════════════════════════════════════════════════════════════
// HEARTBEAT KORBAN — Update lokasi real-time
// ══════════════════════════════════════════════════════════════

func HandleEmergencyHeartbeat(w http.ResponseWriter, r *http.Request) {
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
		IncidentID string  `json:"incident_id"`
		Lat        float64 `json:"lat"`
		Lng        float64 `json:"lng"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Update lokasi korban (hanya jika masih aktif, bukan cancelled/resolved)
	res, _ := database.DB.Exec(`
		UPDATE emergency_incidents SET lat = ?, lng = ? 
		WHERE incident_id = ? AND korban_id = ? AND status IN ('active','responding')
	`, req.Lat, req.Lng, req.IncidentID, claims.UserID)

	rowsAffected, _ := res.RowsAffected()

	utils.SuccessResponse(w, "Heartbeat diterima", map[string]interface{}{
		"updated": rowsAffected > 0,
	})
}

// ══════════════════════════════════════════════════════════════
// GET KORBAN LOCATION — Untuk responder real-time tracking
// ══════════════════════════════════════════════════════════════

func HandleGetEmergencyLocation(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	// Extract incident_id from path: /api/emergency/{id}/location
	// {id} bisa berupa integer (db id) atau string (incident_id seperti "SOS-123-...")
	cleanPath := strings.Trim(r.URL.Path, "/")
	parts := strings.Split(cleanPath, "/")
	if len(parts) < 4 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Path tidak valid")
		return
	}
	idParam := parts[2]

	var lat, lng float64
	var status, incidentID, nama, noHP string
	var incidentDBID int
	var err error

	// Coba parse sebagai integer (db_id) dulu
	if numID, parseErr := strconv.Atoi(idParam); parseErr == nil {
		// Adalah integer: cari by db id
		incidentDBID = numID
		err = database.DB.QueryRow(`
			SELECT e.id, e.incident_id, e.lat, e.lng, e.status, u.nama_lengkap, u.no_hp
			FROM emergency_incidents e
			JOIN users u ON e.korban_id = u.id
			WHERE e.id = ?
		`, incidentDBID).Scan(&incidentDBID, &incidentID, &lat, &lng, &status, &nama, &noHP)
	} else {
		// Bukan integer: cari by string incident_id
		err = database.DB.QueryRow(`
			SELECT e.id, e.incident_id, e.lat, e.lng, e.status, u.nama_lengkap, u.no_hp
			FROM emergency_incidents e
			JOIN users u ON e.korban_id = u.id
			WHERE e.incident_id = ?
		`, idParam).Scan(&incidentDBID, &incidentID, &lat, &lng, &status, &nama, &noHP)
	}

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Incident tidak ditemukan")
		return
	}

	// Get all responders
	respRows, _ := database.DB.Query(`
		SELECT r.responder_id, u.nama_lengkap, r.responder_lat, r.responder_lng, r.is_primary, r.status
		FROM emergency_responses r
		JOIN users u ON r.responder_id = u.id
		WHERE r.incident_id = ?
	`, incidentDBID)
	defer respRows.Close()

	var responders []map[string]interface{}
	for respRows.Next() {
		var respID, isPrimary int
		var respNama, respStatus string
		var respLat, respLng float64
		respRows.Scan(&respID, &respNama, &respLat, &respLng, &isPrimary, &respStatus)
		responders = append(responders, map[string]interface{}{
			"responder_id": respID,
			"nama":         respNama,
			"lat":          respLat,
			"lng":          respLng,
			"is_primary":   isPrimary == 1,
			"status":       respStatus,
		})
	}

	if responders == nil {
		responders = []map[string]interface{}{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"incident_id":  incidentID,
		"korban_nama":  nama,
		"korban_no_hp": noHP,
		"korban_lat":   lat,
		"korban_lng":   lng,
		"status":       status,
		"responders":   responders,
	})
}

// ══════════════════════════════════════════════════════════════
// UPDATE RESPONDER LOCATION — Real-time GPS responder
// ══════════════════════════════════════════════════════════════

func HandleUpdateResponderLocation(w http.ResponseWriter, r *http.Request) {
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
		IncidentDBID int     `json:"incident_db_id"`
		Lat          float64 `json:"lat"`
		Lng          float64 `json:"lng"`
		Status       string  `json:"status"` // navigating, arrived
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Update lokasi dan opsional status
	if req.Status == "arrived" {
		database.DB.Exec(`
			UPDATE emergency_responses SET responder_lat = ?, responder_lng = ?, status = 'arrived'
			WHERE incident_id = ? AND responder_id = ?
		`, req.Lat, req.Lng, req.IncidentDBID, claims.UserID)

		// Notifikasi ke korban bahwa responder sudah tiba
		var korbanID int
		database.DB.QueryRow("SELECT korban_id FROM emergency_incidents WHERE id = ?", req.IncidentDBID).Scan(&korbanID)
		var responderNama string
		database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&responderNama)
		database.DB.Exec(`
			INSERT INTO notifications (user_id, title, body, type)
			VALUES (?, '✅ Responder Tiba!', ?, 'emergency_arrived')
		`, korbanID, fmt.Sprintf("%s sudah tiba di lokasi Anda", responderNama))
	} else {
		database.DB.Exec(`
			UPDATE emergency_responses SET responder_lat = ?, responder_lng = ?
			WHERE incident_id = ? AND responder_id = ?
		`, req.Lat, req.Lng, req.IncidentDBID, claims.UserID)
	}

	utils.SuccessResponse(w, "Lokasi responder diperbarui", nil)
}

// ══════════════════════════════════════════════════════════════
// RESOLVE INCIDENT
//
// ALUR LOGIKA:
//   1. Support incident_db_id (mobile) DAN id (web dashboard)
//   2. Validasi incident exists
//   3. Cek belum resolved/cancelled (idempotent)
//   4. Update incident → resolved
//   5. Update semua responder → resolved
//   6. Notifikasi ke korban + semua responder
//   7. Audit trail
// ══════════════════════════════════════════════════════════════

func HandleResolveEmergency(w http.ResponseWriter, r *http.Request) {
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
		IncidentDBID int `json:"incident_db_id"`
		ID           int `json:"id"` // Alias dari web dashboard
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Support kedua field
	incidentID := req.IncidentDBID
	if incidentID == 0 {
		incidentID = req.ID
	}
	if incidentID == 0 {
		// Auto-detect active incident for this user if ID is not provided
		err := database.DB.QueryRow(
			"SELECT id FROM emergency_incidents WHERE korban_id = ? AND status IN ('active','responding') ORDER BY id DESC LIMIT 1",
			claims.UserID,
		).Scan(&incidentID)
		if err != nil {
			utils.ErrorResponse(w, http.StatusBadRequest, "Tidak ada incident aktif")
			return
		}
	}

	// Validasi incident exists dan belum resolved/cancelled
	var currentStatus string
	var korbanID int
	err := database.DB.QueryRow(
		"SELECT status, korban_id FROM emergency_incidents WHERE id = ?",
		incidentID,
	).Scan(&currentStatus, &korbanID)

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Incident tidak ditemukan")
		return
	}
	if currentStatus == "resolved" {
		utils.SuccessResponse(w, "Incident sudah diselesaikan sebelumnya", nil)
		return
	}
	if currentStatus == "cancelled" {
		utils.SuccessResponse(w, "Incident sudah dibatalkan sebelumnya", nil)
		return
	}

	// Update incident
	database.DB.Exec(`
		UPDATE emergency_incidents SET status = 'resolved', resolved_at = CURRENT_TIMESTAMP
		WHERE id = ?
	`, incidentID)

	// Update semua responder
	database.DB.Exec(`
		UPDATE emergency_responses SET status = 'resolved'
		WHERE incident_id = ?
	`, incidentID)

	// Tutup pantau session korban yang masih aktif (jika ada)
	database.DB.Exec(`
		UPDATE pantau_sessions SET status = 'resolved', ended_at = CURRENT_TIMESTAMP
		WHERE user_id = ? AND status IN ('active','checkin','emergency')
	`, korbanID)

	// Notifikasi ke korban
	database.DB.Exec(`
		INSERT INTO notifications (user_id, title, body, type)
		VALUES (?, '✅ Situasi Aman', 'Insiden darurat telah ditangani. Anda aman sekarang.', 'emergency_resolved')
	`, korbanID)

	// Notifikasi ke semua responder
	respRows, _ := database.DB.Query(
		"SELECT DISTINCT responder_id FROM emergency_responses WHERE incident_id = ?",
		incidentID,
	)
	if respRows != nil {
		defer respRows.Close()
		for respRows.Next() {
			var respID int
			respRows.Scan(&respID)
			database.DB.Exec(`
				INSERT INTO notifications (user_id, title, body, type)
				VALUES (?, '✅ Insiden Selesai', 'Insiden darurat telah diselesaikan. Terima kasih atas bantuan Anda.', 'emergency_resolved')
			`, respID)
		}
	}

	// Audit trail
	var resolverNama string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&resolverNama)
	database.DB.Exec(`
		INSERT INTO audit_trail (incident_id, actor_id, action, detail)
		VALUES (?, ?, 'EMERGENCY_RESOLVED', ?)
	`, incidentID, claims.UserID, fmt.Sprintf("Incident diselesaikan oleh %s", resolverNama))

	utils.SuccessResponse(w, "Incident berhasil diselesaikan", map[string]interface{}{
		"incident_id": incidentID,
		"resolved_by": resolverNama,
	})
}

// HandleGetEmergencyAudio returns the list of audio chunks for a given incident_id
func HandleGetEmergencyAudio(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	incidentID := r.URL.Query().Get("incident_id")
	if incidentID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "incident_id dibutuhkan")
		return
	}

	rows, err := database.DB.Query(`
		SELECT id, file_path, created_at
		FROM emergency_audios
		WHERE incident_id = ?
		ORDER BY created_at ASC
	`, incidentID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil data audio")
		return
	}
	defer rows.Close()

	var audios []map[string]interface{}
	for rows.Next() {
		var id int
		var filePath, createdAt string
		rows.Scan(&id, &filePath, &createdAt)
		audios = append(audios, map[string]interface{}{
			"id":         id,
			"file_path":  filePath, // format: audio_records/sos_audio_...m4a
			"created_at": createdAt,
		})
	}

	if audios == nil {
		audios = []map[string]interface{}{}
	}

	utils.SuccessResponse(w, "Data audio berhasil diambil", map[string]interface{}{
		"data":  audios,
		"total": len(audios),
	})
}
