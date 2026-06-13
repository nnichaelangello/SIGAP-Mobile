package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"sigap-backend/database"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

// ══════════════════════════════════════════════════════════════
// USER: AJUKAN PERMINTAAN KONSULTASI
// POST /api/reports/request-consultation
// Hanya laporan berstatus 'diterima' yang bisa mengajukan konsultasi.
// Status laporan → 'menunggu_penjadwalan', admin mendapat notifikasi.
// ══════════════════════════════════════════════════════════════

func HandleRequestConsultation(w http.ResponseWriter, r *http.Request) {
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
		ReportID int `json:"report_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.ReportID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "report_id wajib diisi")
		return
	}

	// Cek laporan milik user dan statusnya 'diterima'
	var status string
	var userID int
	var trackingCode string
	err := database.DB.QueryRow(
		"SELECT status, user_id, tracking_code FROM reports WHERE id = ?",
		req.ReportID,
	).Scan(&status, &userID, &trackingCode)

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Laporan tidak ditemukan")
		return
	}
	if userID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Anda tidak memiliki akses ke laporan ini")
		return
	}
	if status != "diterima" {
		utils.ErrorResponse(w, http.StatusBadRequest,
			fmt.Sprintf("Laporan harus berstatus 'diterima' untuk mengajukan konsultasi. Status saat ini: '%s'", status))
		return
	}

	// Update status laporan → menunggu_penjadwalan
	_, err = database.DB.Exec(
		"UPDATE reports SET status = 'menunggu_penjadwalan', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
		req.ReportID,
	)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengajukan permintaan konsultasi")
		return
	}

	// Audit trail
	database.DB.Exec(`
		INSERT INTO audit_trail (report_id, actor_id, action, detail)
		VALUES (?, ?, 'CONSULTATION_REQUESTED', 'User mengajukan permintaan konsultasi')
	`, req.ReportID, claims.UserID)

	// Notifikasi ke semua admin
	var userName string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&userName)

	adminRows, _ := database.DB.Query("SELECT id FROM users WHERE role = 'admin'")
	if adminRows != nil {
		defer adminRows.Close()
		for adminRows.Next() {
			var adminID int
			adminRows.Scan(&adminID)
			database.DB.Exec(`
				INSERT INTO notifications (user_id, title, body, type, payload_json)
				VALUES (?, '📅 Permintaan Konsultasi Baru', ?, 'consultation_request', ?)
			`, adminID,
				fmt.Sprintf("%s mengajukan permintaan konsultasi untuk laporan %s", userName, trackingCode),
				fmt.Sprintf(`{"report_id":%d,"tracking_code":"%s"}`, req.ReportID, trackingCode))
		}
	}

	utils.SuccessResponse(w, "Permintaan konsultasi berhasil diajukan. Admin akan segera menghubungi Anda.", map[string]interface{}{
		"report_id":      req.ReportID,
		"report_status":  "menunggu_penjadwalan",
	})
}

// ══════════════════════════════════════════════════════════════
// PSIKOLOG / ADMIN: BUAT / UPDATE CATATAN SESI
// POST /api/session-notes
// ══════════════════════════════════════════════════════════════

func HandleCreateSessionNote(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role != "psikolog" && claims.Role != "admin" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya psikolog atau admin yang dapat membuat catatan sesi")
		return
	}

	var req struct {
		AppointmentID  int    `json:"appointment_id"`
		Subjective     string `json:"subjective"`
		Objective      string `json:"objective"`
		Assessment     string `json:"assessment"`
		Plan           string `json:"plan"`
		MoodScore      int    `json:"mood_score"`
		RiskLevel      string `json:"risk_level"`
		FollowUpNeeded bool   `json:"follow_up_needed"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.AppointmentID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "appointment_id wajib diisi")
		return
	}

	// Validasi appointment: psikolog hanya bisa buat catatan untuk appointment miliknya
	var psikologID, userID int
	var apptStatus string
	err := database.DB.QueryRow(
		"SELECT psikolog_id, user_id, status FROM appointments WHERE id = ?",
		req.AppointmentID,
	).Scan(&psikologID, &userID, &apptStatus)
	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Appointment tidak ditemukan")
		return
	}
	if claims.Role == "psikolog" && psikologID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Appointment ini bukan milik Anda")
		return
	}

	// Validasi risk_level
	if req.RiskLevel == "" {
		req.RiskLevel = "low"
	}
	validRisk := map[string]bool{"low": true, "medium": true, "high": true, "critical": true}
	if !validRisk[req.RiskLevel] {
		utils.ErrorResponse(w, http.StatusBadRequest, "risk_level tidak valid (low/medium/high/critical)")
		return
	}

	followUp := 0
	if req.FollowUpNeeded {
		followUp = 1
	}

	// Upsert: update jika sudah ada, insert jika belum
	var existingNoteID int
	errExist := database.DB.QueryRow(
		"SELECT id FROM session_notes WHERE appointment_id = ?",
		req.AppointmentID,
	).Scan(&existingNoteID)

	var noteID int64
	if errExist == nil {
		// Update
		database.DB.Exec(`
			UPDATE session_notes
			SET subjective = ?, objective = ?, assessment = ?, plan = ?,
			    mood_score = ?, risk_level = ?, follow_up_needed = ?, updated_at = CURRENT_TIMESTAMP
			WHERE id = ?
		`, req.Subjective, req.Objective, req.Assessment, req.Plan,
			req.MoodScore, req.RiskLevel, followUp, existingNoteID)
		noteID = int64(existingNoteID)
	} else {
		// Insert
		res, insertErr := database.DB.Exec(`
			INSERT INTO session_notes (appointment_id, psikolog_id, user_id, subjective, objective, assessment, plan, mood_score, risk_level, follow_up_needed)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, req.AppointmentID, psikologID, userID,
			req.Subjective, req.Objective, req.Assessment, req.Plan,
			req.MoodScore, req.RiskLevel, followUp)
		if insertErr != nil {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan catatan sesi")
			return
		}
		noteID, _ = res.LastInsertId()
	}

	// Notifikasi ke admin jika risk_level high/critical
	if req.RiskLevel == "high" || req.RiskLevel == "critical" {
		var psikologName string
		database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", psikologID).Scan(&psikologName)
		adminRows, _ := database.DB.Query("SELECT id FROM users WHERE role = 'admin'")
		if adminRows != nil {
			defer adminRows.Close()
			for adminRows.Next() {
				var adminID int
				adminRows.Scan(&adminID)
				database.DB.Exec(`
					INSERT INTO notifications (user_id, title, body, type, payload_json)
					VALUES (?, '⚠️ Risk Level Tinggi Terdeteksi', ?, 'risk_alert', ?)
				`, adminID,
					fmt.Sprintf("Psikolog %s menandai klien dengan risk level '%s'. Perlu perhatian segera.", psikologName, req.RiskLevel),
					fmt.Sprintf(`{"appointment_id":%d,"risk_level":"%s"}`, req.AppointmentID, req.RiskLevel))
			}
		}
	}

	utils.SuccessResponse(w, "Catatan sesi berhasil disimpan", map[string]interface{}{
		"note_id":        noteID,
		"appointment_id": req.AppointmentID,
	})
}

// ══════════════════════════════════════════════════════════════
// GET CATATAN SESI
// GET /api/session-notes?appointment_id=
// ══════════════════════════════════════════════════════════════

func HandleGetSessionNote(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	appointmentIDStr := r.URL.Query().Get("appointment_id")
	if appointmentIDStr == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "appointment_id wajib diisi")
		return
	}
	appointmentID, err := strconv.Atoi(appointmentIDStr)
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "appointment_id harus angka")
		return
	}

	// Cek akses: user hanya bisa lihat catatan sesinya sendiri
	var apptUserID, apptPsikologID int
	errAppt := database.DB.QueryRow(
		"SELECT user_id, psikolog_id FROM appointments WHERE id = ?",
		appointmentID,
	).Scan(&apptUserID, &apptPsikologID)
	if errAppt != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Appointment tidak ditemukan")
		return
	}
	if claims.Role == "user" && apptUserID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Anda tidak memiliki akses ke catatan ini")
		return
	}
	if claims.Role == "psikolog" && apptPsikologID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Appointment ini bukan milik Anda")
		return
	}

	var note struct {
		ID             int
		AppointmentID  int
		PsikologID     int
		UserID         int
		Subjective     string
		Objective      string
		Assessment     string
		Plan           string
		MoodScore      int
		RiskLevel      string
		FollowUpNeeded int
		CreatedAt      string
		UpdatedAt      string
	}

	err = database.DB.QueryRow(`
		SELECT id, appointment_id, psikolog_id, user_id, subjective, objective, assessment, plan,
		       mood_score, risk_level, follow_up_needed, created_at, updated_at
		FROM session_notes WHERE appointment_id = ?
	`, appointmentID).Scan(
		&note.ID, &note.AppointmentID, &note.PsikologID, &note.UserID,
		&note.Subjective, &note.Objective, &note.Assessment, &note.Plan,
		&note.MoodScore, &note.RiskLevel, &note.FollowUpNeeded,
		&note.CreatedAt, &note.UpdatedAt,
	)

	if err != nil {
		// Belum ada catatan — return empty
		utils.JSONResponse(w, http.StatusOK, map[string]interface{}{"data": nil})
		return
	}

	// Ambil nama psikolog
	var psikologName string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", note.PsikologID).Scan(&psikologName)

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"id":              note.ID,
			"appointment_id":  note.AppointmentID,
			"psikolog_id":     note.PsikologID,
			"psikolog_nama":   psikologName,
			"user_id":         note.UserID,
			"subjective":      note.Subjective,
			"objective":       note.Objective,
			"assessment":      note.Assessment,
			"plan":            note.Plan,
			"mood_score":      note.MoodScore,
			"risk_level":      note.RiskLevel,
			"follow_up_needed": note.FollowUpNeeded == 1,
			"created_at":      note.CreatedAt,
			"updated_at":      note.UpdatedAt,
		},
	})
}

// ══════════════════════════════════════════════════════════════
// USER: KIRIM FEEDBACK SETELAH SESI
// POST /api/session-feedback
// ══════════════════════════════════════════════════════════════

func HandleCreateSessionFeedback(w http.ResponseWriter, r *http.Request) {
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
		AppointmentID int    `json:"appointment_id"`
		Rating        int    `json:"rating"`
		Comment       string `json:"comment"`
		IsAnonymous   bool   `json:"is_anonymous"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.AppointmentID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "appointment_id wajib diisi")
		return
	}
	if req.Rating < 1 || req.Rating > 5 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Rating harus antara 1–5")
		return
	}

	// Validasi appointment milik user dan sudah selesai
	var apptUserID int
	var apptStatus string
	err := database.DB.QueryRow(
		"SELECT user_id, status FROM appointments WHERE id = ?",
		req.AppointmentID,
	).Scan(&apptUserID, &apptStatus)
	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Appointment tidak ditemukan")
		return
	}
	if apptUserID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Appointment ini bukan milik Anda")
		return
	}
	if apptStatus != "selesai" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Feedback hanya bisa diberikan setelah sesi selesai")
		return
	}

	// Cek apakah sudah ada feedback
	var existing int
	database.DB.QueryRow(
		"SELECT COUNT(*) FROM session_feedback WHERE appointment_id = ?",
		req.AppointmentID,
	).Scan(&existing)
	if existing > 0 {
		utils.ErrorResponse(w, http.StatusConflict, "Anda sudah memberikan feedback untuk sesi ini")
		return
	}

	isAnon := 1
	if !req.IsAnonymous {
		isAnon = 0
	}

	_, err = database.DB.Exec(`
		INSERT INTO session_feedback (appointment_id, user_id, rating, comment, is_anonymous)
		VALUES (?, ?, ?, ?, ?)
	`, req.AppointmentID, claims.UserID, req.Rating, req.Comment, isAnon)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan feedback")
		return
	}

	utils.SuccessResponse(w, "Terima kasih atas feedback Anda!", map[string]interface{}{
		"appointment_id": req.AppointmentID,
		"rating":         req.Rating,
	})
}

// ══════════════════════════════════════════════════════════════
// GET FEEDBACK SESI
// GET /api/session-feedback?appointment_id=
// ══════════════════════════════════════════════════════════════

func HandleGetSessionFeedback(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	appointmentIDStr := r.URL.Query().Get("appointment_id")
	if appointmentIDStr == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "appointment_id wajib diisi")
		return
	}

	var fb struct {
		ID            int
		AppointmentID int
		UserID        int
		Rating        int
		Comment       string
		IsAnonymous   int
		CreatedAt     string
	}

	err := database.DB.QueryRow(`
		SELECT id, appointment_id, user_id, rating, comment, is_anonymous, created_at
		FROM session_feedback WHERE appointment_id = ?
	`, appointmentIDStr).Scan(
		&fb.ID, &fb.AppointmentID, &fb.UserID, &fb.Rating, &fb.Comment, &fb.IsAnonymous, &fb.CreatedAt,
	)
	if err != nil {
		utils.JSONResponse(w, http.StatusOK, map[string]interface{}{"data": nil})
		return
	}

	// Sembunyikan nama user jika anonim (kecuali admin)
	var userName string
	if fb.IsAnonymous == 0 || claims.Role == "admin" {
		database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", fb.UserID).Scan(&userName)
	} else {
		userName = "Anonim"
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"id":             fb.ID,
			"appointment_id": fb.AppointmentID,
			"rating":         fb.Rating,
			"comment":        fb.Comment,
			"is_anonymous":   fb.IsAnonymous == 1,
			"user_nama":      userName,
			"created_at":     fb.CreatedAt,
		},
	})
}

// ══════════════════════════════════════════════════════════════
// PSIKOLOG UNAVAILABILITY
// GET /api/psikolog/unavailability?psikolog_id=
// POST /api/psikolog/unavailability
// DELETE /api/psikolog/unavailability
// ══════════════════════════════════════════════════════════════

func HandlePsikologUnavailability(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		handleGetUnavailability(w, r)
	case http.MethodPost:
		handleAddUnavailability(w, r)
	case http.MethodDelete:
		handleDeleteUnavailability(w, r)
	default:
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
	}
}

func handleGetUnavailability(w http.ResponseWriter, r *http.Request) {
	psikologIDStr := r.URL.Query().Get("psikolog_id")
	if psikologIDStr == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "psikolog_id wajib diisi")
		return
	}

	rows, err := database.DB.Query(`
		SELECT id, psikolog_id, tanggal, alasan, created_at
		FROM psikolog_unavailability
		WHERE psikolog_id = ? AND tanggal >= DATE('now')
		ORDER BY tanggal ASC
	`, psikologIDStr)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil data")
		return
	}
	defer rows.Close()

	var list []map[string]interface{}
	for rows.Next() {
		var id, pID int
		var tanggal, alasan, createdAt string
		rows.Scan(&id, &pID, &tanggal, &alasan, &createdAt)
		list = append(list, map[string]interface{}{
			"id":          id,
			"psikolog_id": pID,
			"tanggal":     tanggal,
			"alasan":      alasan,
			"created_at":  createdAt,
		})
	}
	if list == nil {
		list = []map[string]interface{}{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{"data": list})
}

func handleAddUnavailability(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "psikolog" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya psikolog yang bisa mengatur ketersediaan")
		return
	}

	var req struct {
		Tanggal string `json:"tanggal"`
		Alasan  string `json:"alasan"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Tanggal == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "tanggal wajib diisi (format YYYY-MM-DD)")
		return
	}

	_, err := database.DB.Exec(`
		INSERT OR IGNORE INTO psikolog_unavailability (psikolog_id, tanggal, alasan)
		VALUES (?, ?, ?)
	`, claims.UserID, req.Tanggal, req.Alasan)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan tanggal tidak tersedia")
		return
	}

	utils.SuccessResponse(w, "Tanggal tidak tersedia berhasil ditambahkan", map[string]interface{}{
		"tanggal": req.Tanggal,
	})
}

func handleDeleteUnavailability(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "psikolog" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya psikolog yang bisa menghapus ketersediaan")
		return
	}

	var req struct {
		ID int `json:"id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.ID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "id wajib diisi")
		return
	}

	res, err := database.DB.Exec(
		"DELETE FROM psikolog_unavailability WHERE id = ? AND psikolog_id = ?",
		req.ID, claims.UserID,
	)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menghapus")
		return
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		utils.ErrorResponse(w, http.StatusNotFound, "Data tidak ditemukan atau bukan milik Anda")
		return
	}

	utils.SuccessResponse(w, "Berhasil dihapus", nil)
}

// ══════════════════════════════════════════════════════════════
// APPOINTMENT: CANCEL / NO-SHOW
// POST /api/appointments/cancel
// POST /api/appointments/noshow
// ══════════════════════════════════════════════════════════════

func HandleCancelAppointment(w http.ResponseWriter, r *http.Request) {
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
		AppointmentID int    `json:"appointment_id"`
		Alasan        string `json:"alasan"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.AppointmentID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "appointment_id wajib diisi")
		return
	}

	// Ambil data appointment
	var apptUserID, apptPsikologID, reportID int
	var apptStatus string
	err := database.DB.QueryRow(
		"SELECT user_id, psikolog_id, report_id, status FROM appointments WHERE id = ?",
		req.AppointmentID,
	).Scan(&apptUserID, &apptPsikologID, &reportID, &apptStatus)
	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Appointment tidak ditemukan")
		return
	}

	// Hanya yang terlibat atau admin yang bisa cancel
	if claims.Role == "user" && apptUserID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Bukan appointment Anda")
		return
	}
	if claims.Role == "psikolog" && apptPsikologID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Bukan appointment Anda")
		return
	}

	// Hanya appointment yang belum selesai/batal yang bisa dibatalkan
	terminalStatuses := map[string]bool{"selesai": true, "batal": true, "no_show_user": true, "no_show_psikolog": true}
	if terminalStatuses[apptStatus] {
		utils.ErrorResponse(w, http.StatusBadRequest, fmt.Sprintf("Appointment sudah dalam status terminal: '%s'", apptStatus))
		return
	}

	// Mulai transaksi database
	tx, err := database.DB.Begin()
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal memulai transaksi")
		return
	}
	defer tx.Rollback()

	_, err = tx.Exec(
		"UPDATE appointments SET status = 'batal', catatan_reschedule = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
		req.Alasan, req.AppointmentID,
	)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal membatalkan appointment")
		return
	}

	// Update status laporan kembali ke 'diterima' agar bisa dijadwalkan ulang
	_, err = tx.Exec(
		"UPDATE reports SET status = 'diterima', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
		reportID,
	)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal update status report")
		return
	}

	// Notifikasi ke semua pihak terkait
	var cancelerName string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&cancelerName)

	for _, recipientID := range []int{apptUserID, apptPsikologID} {
		if recipientID != claims.UserID {
			tx.Exec(`
				INSERT INTO notifications (user_id, title, body, type, payload_json)
				VALUES (?, '❌ Jadwal Konsultasi Dibatalkan', ?, 'appointment_cancelled', ?)
			`, recipientID,
				fmt.Sprintf("Jadwal konsultasi telah dibatalkan oleh %s. Alasan: %s", cancelerName, req.Alasan),
				fmt.Sprintf(`{"appointment_id":%d}`, req.AppointmentID))
		}
	}

	// Notifikasi admin
	adminRows, _ := database.DB.Query("SELECT id FROM users WHERE role = 'admin'")
	if adminRows != nil {
		defer adminRows.Close()
		for adminRows.Next() {
			var adminID int
			adminRows.Scan(&adminID)
			if adminID != claims.UserID {
				tx.Exec(`
					INSERT INTO notifications (user_id, title, body, type, payload_json)
					VALUES (?, '❌ Jadwal Dibatalkan', ?, 'appointment_cancelled', ?)
				`, adminID,
					fmt.Sprintf("Jadwal konsultasi (ID: %d) dibatalkan oleh %s", req.AppointmentID, cancelerName),
					fmt.Sprintf(`{"appointment_id":%d,"report_id":%d}`, req.AppointmentID, reportID))
			}
		}
	}

	if err := tx.Commit(); err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan perubahan ke database")
		return
	}

	utils.SuccessResponse(w, "Jadwal konsultasi berhasil dibatalkan", nil)
}

// ══════════════════════════════════════════════════════════════
// TANDAI NO-SHOW
// POST /api/appointments/noshow
// ══════════════════════════════════════════════════════════════

func HandleMarkNoShow(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role != "psikolog" && claims.Role != "admin" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya psikolog atau admin yang bisa menandai no-show")
		return
	}

	var req struct {
		AppointmentID int    `json:"appointment_id"`
		NoShowType    string `json:"no_show_type"` // 'user' atau 'psikolog'
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.AppointmentID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "appointment_id wajib diisi")
		return
	}
	if req.NoShowType != "user" && req.NoShowType != "psikolog" {
		utils.ErrorResponse(w, http.StatusBadRequest, "no_show_type harus 'user' atau 'psikolog'")
		return
	}

	newStatus := "no_show_" + req.NoShowType

	var apptPsikologID, reportID int
	var dummy string
	errAppt := database.DB.QueryRow(
		"SELECT status, psikolog_id, report_id FROM appointments WHERE id = ?",
		req.AppointmentID,
	).Scan(&dummy, &apptPsikologID, &reportID)
	if errAppt != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Appointment tidak ditemukan")
		return
	}
	if claims.Role == "psikolog" && apptPsikologID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Bukan appointment Anda")
		return
	}

	database.DB.Exec(
		"UPDATE appointments SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
		newStatus, req.AppointmentID,
	)

	// Kembalikan status laporan ke 'diterima' agar bisa dijadwalkan ulang oleh admin
	if req.NoShowType == "psikolog" {
		database.DB.Exec("UPDATE reports SET status = 'diterima', assigned_psikolog_id = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = ?", reportID)
	} else {
		database.DB.Exec("UPDATE reports SET status = 'diterima', updated_at = CURRENT_TIMESTAMP WHERE id = ?", reportID)
	}

	utils.SuccessResponse(w, fmt.Sprintf("No-show '%s' berhasil ditandai", req.NoShowType), nil)
}



// ══════════════════════════════════════════════════════════════
// COMPLETE SESSION
// POST /api/appointments/complete
// ══════════════════════════════════════════════════════════════

func HandleCompleteSession(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil || (claims.Role != "psikolog" && claims.Role != "admin") {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya psikolog atau admin yang bisa menyelesaikan sesi")
		return
	}

	var req struct {
		AppointmentID int  `json:"appointment_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.AppointmentID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "appointment_id wajib diisi")
		return
	}

	// Validasi appointment
	var apptPsikologID, reportID, userID int
	var apptStatus string
	err := database.DB.QueryRow(
		"SELECT status, psikolog_id, report_id, user_id FROM appointments WHERE id = ?",
		req.AppointmentID,
	).Scan(&apptStatus, &apptPsikologID, &reportID, &userID)
	
	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Appointment tidak ditemukan")
		return
	}
	if apptPsikologID != claims.UserID && claims.Role != "admin" {
		utils.ErrorResponse(w, http.StatusForbidden, "Appointment ini bukan milik Anda")
		return
	}
	if apptStatus != "diterima" {
		utils.ErrorResponse(w, http.StatusBadRequest, fmt.Sprintf("Appointment ini tidak dalam status diterima/aktif. Status saat ini: '%s'", apptStatus))
		return
	}

	// Cek apakah catatan sesi sudah diisi (hanya wajib untuk psikolog)
	if claims.Role == "psikolog" {
		var noteCount int
		database.DB.QueryRow("SELECT COUNT(*) FROM session_notes WHERE appointment_id = ?", req.AppointmentID).Scan(&noteCount)
		if noteCount == 0 {
			utils.ErrorResponse(w, http.StatusBadRequest, "Tidak bisa menyelesaikan sesi: Catatan Sesi (SOAP Notes) belum diisi.")
			return
		}
	}

	// Update appointment -> selesai
	database.DB.Exec(
		"UPDATE appointments SET status = 'selesai', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
		req.AppointmentID,
	)

	// Report tetap diproses agar Admin bisa melihat dan menutupnya nanti
	database.DB.Exec(
		"UPDATE reports SET status = 'diproses', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
		reportID,
	)

	// Notifikasi ke User untuk meminta feedback
	var psikologName string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&psikologName)
	
	database.DB.Exec(`
		INSERT INTO notifications (user_id, title, body, type, payload_json)
		VALUES (?, 'Sesi Selesai', ?, 'session_feedback_request', ?)
	`, userID, 
	   fmt.Sprintf("Sesi konsultasi Anda dengan %s telah selesai. Mohon berikan ulasan (Feedback) Anda.", psikologName),
	   fmt.Sprintf(`{"appointment_id":%d,"report_id":%d}`, req.AppointmentID, reportID))

	utils.SuccessResponse(w, "Sesi berhasil diselesaikan", nil)
}

// ══════════════════════════════════════════════════════════════
// HTTP WRAPPERS — dispatch GET/POST
// ══════════════════════════════════════════════════════════════

func HandleSessionNote(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		HandleGetSessionNote(w, r)
	case http.MethodPost:
		HandleCreateSessionNote(w, r)
	default:
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
	}
}

func HandleSessionFeedback(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		HandleGetSessionFeedback(w, r)
	case http.MethodPost:
		HandleCreateSessionFeedback(w, r)
	default:
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
	}
}

// ══════════════════════════════════════════════════════════════
// BACKGROUND WORKER: PENGINGAT SESI OTOMATIS (H-24 & H-1 JAM)
// ══════════════════════════════════════════════════════════════

func CheckSessionReminders() {
	// Cari appointment yang akan berlangsung 24 jam lagi (± 30 menit window)
	rows, err := database.DB.Query(`
		SELECT a.id, a.user_id, a.psikolog_id, a.tanggal, a.jam_mulai,
		       u.nama_lengkap, p.nama_lengkap
		FROM appointments a
		JOIN users u ON a.user_id = u.id
		JOIN users p ON a.psikolog_id = p.id
		WHERE a.status = 'diterima'
		AND a.tanggal = DATE('now', '+1 day')
		AND NOT EXISTS (
			SELECT 1 FROM notifications n
			WHERE n.user_id = a.user_id
			AND n.type = 'session_reminder_h24'
			AND n.payload_json LIKE '%"appointment_id":' || a.id || '%'
		)
	`)
	if err != nil {
		return
	}
	defer rows.Close()

	for rows.Next() {
		var apptID, userID, psikologID int
		var tanggal, jamMulai, userName, psikologName string
		rows.Scan(&apptID, &userID, &psikologID, &tanggal, &jamMulai, &userName, &psikologName)

		payload := fmt.Sprintf(`{"appointment_id":%d}`, apptID)
		body := fmt.Sprintf("Anda memiliki sesi konsultasi dengan %s besok tanggal %s pukul %s. Harap bersiap.", psikologName, tanggal, jamMulai)
		bodyPsikolog := fmt.Sprintf("Anda memiliki sesi konsultasi dengan %s besok tanggal %s pukul %s.", userName, tanggal, jamMulai)

		// Notifikasi ke user
		database.DB.Exec(`
			INSERT INTO notifications (user_id, title, body, type, payload_json)
			VALUES (?, '🔔 Pengingat Sesi Besok', ?, 'session_reminder_h24', ?)
		`, userID, body, payload)

		// Notifikasi ke psikolog
		database.DB.Exec(`
			INSERT INTO notifications (user_id, title, body, type, payload_json)
			VALUES (?, '🔔 Pengingat Sesi Besok', ?, 'session_reminder_h24', ?)
		`, psikologID, bodyPsikolog, payload)
	}
}

// ══════════════════════════════════════════════════════════════
// BACKGROUND WORKER: ESKALASI LAPORAN > 48 JAM TANPA RESPONS
// ══════════════════════════════════════════════════════════════

func CheckOverdueReports() {
	rows, err := database.DB.Query(`
		SELECT r.id, r.tracking_code
		FROM reports r
		WHERE r.status = 'pending'
		AND r.created_at <= DATETIME('now', '-48 hours')
		AND NOT EXISTS (
			SELECT 1 FROM notifications n
			WHERE n.type = 'overdue_report'
			AND n.payload_json LIKE '%"report_id":' || r.id || '%'
		)
	`)
	if err != nil {
		return
	}
	defer rows.Close()

	for rows.Next() {
		var reportID int
		var trackingCode string
		rows.Scan(&reportID, &trackingCode)

		// Notifikasi ke semua admin
		adminRows, _ := database.DB.Query("SELECT id FROM users WHERE role = 'admin'")
		if adminRows != nil {
			defer adminRows.Close()
			for adminRows.Next() {
				var adminID int
				adminRows.Scan(&adminID)
				database.DB.Exec(`
					INSERT INTO notifications (user_id, title, body, type, payload_json)
					VALUES (?, '⚠️ Laporan Menunggu > 48 Jam', ?, 'overdue_report', ?)
				`, adminID,
					fmt.Sprintf("Laporan %s sudah menunggu lebih dari 48 jam tanpa respons. Segera tindaklanjuti!", trackingCode),
					fmt.Sprintf(`{"report_id":%d,"tracking_code":"%s"}`, reportID, trackingCode))
			}
		}
	}
}


// ══════════════════════════════════════════════════════════════
// PSIKOLOG DASHBOARD STATS
// GET /api/dashboard/stats-psikolog
// ══════════════════════════════════════════════════════════════

func HandlePsikologDashboardStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "psikolog" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya psikolog yang bisa mengakses endpoint ini")
		return
	}

	var totalKlien, sesiMingguIni, sesiMenunggu, sesiSelesai int

	database.DB.QueryRow(
		"SELECT COUNT(DISTINCT user_id) FROM appointments WHERE psikolog_id = ?",
		claims.UserID,
	).Scan(&totalKlien)

	database.DB.QueryRow(`
		SELECT COUNT(*) FROM appointments
		WHERE psikolog_id = ? AND status = 'diterima'
		AND tanggal >= DATE('now') AND tanggal <= DATE('now', '+7 days')
	`, claims.UserID).Scan(&sesiMingguIni)

	database.DB.QueryRow(`
		SELECT COUNT(*) FROM appointments
		WHERE psikolog_id = ? AND status IN ('menunggu_psikolog','reschedule')
	`, claims.UserID).Scan(&sesiMenunggu)

	database.DB.QueryRow(`
		SELECT COUNT(*) FROM appointments
		WHERE psikolog_id = ? AND status = 'selesai'
	`, claims.UserID).Scan(&sesiSelesai)

	// Sesi hari ini
	sesiHariIni := 0
	database.DB.QueryRow(`
		SELECT COUNT(*) FROM appointments
		WHERE psikolog_id = ? AND status = 'diterima' AND tanggal = DATE('now')
	`, claims.UserID).Scan(&sesiHariIni)

	// Rating rata-rata
	var ratingRata float64
	database.DB.QueryRow(`
		SELECT COALESCE(AVG(sf.rating), 0)
		FROM session_feedback sf
		JOIN appointments a ON sf.appointment_id = a.id
		WHERE a.psikolog_id = ?
	`, claims.UserID).Scan(&ratingRata)

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"total_klien":     totalKlien,
		"sesi_hari_ini":   sesiHariIni,
		"sesi_minggu_ini": sesiMingguIni,
		"sesi_menunggu":   sesiMenunggu,
		"sesi_selesai":    sesiSelesai,
		"rating_rata":     ratingRata,
	})
}
