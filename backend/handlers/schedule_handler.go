package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"sigap-backend/database"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

// ══════════════════════════════════════════════════════════════
// PSIKOLOG: KELOLA SLOT JADWAL
// ══════════════════════════════════════════════════════════════

// HandlePsikologSchedules — GET: list slot, POST: tambah slot, DELETE: hapus slot
func HandlePsikologSchedules(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		handleGetSchedules(w, r)
	case http.MethodPost:
		handleAddSchedule(w, r)
	case http.MethodDelete:
		handleDeleteSchedule(w, r)
	default:
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
	}
}

func handleGetSchedules(w http.ResponseWriter, r *http.Request) {
	psikologIDStr := r.URL.Query().Get("psikolog_id")
	if psikologIDStr == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "psikolog_id wajib diisi")
		return
	}

	rows, err := database.DB.Query(`
		SELECT id, psikolog_id, hari, jam_mulai, jam_selesai, is_active, created_at
		FROM psikolog_schedules
		WHERE psikolog_id = ? AND is_active = 1
		ORDER BY 
			CASE hari
				WHEN 'senin' THEN 1 WHEN 'selasa' THEN 2 WHEN 'rabu' THEN 3
				WHEN 'kamis' THEN 4 WHEN 'jumat' THEN 5 WHEN 'sabtu' THEN 6
			END, jam_mulai
	`, psikologIDStr)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil jadwal")
		return
	}
	defer rows.Close()

	var schedules []map[string]interface{}
	for rows.Next() {
		var id, psikologID, isActive int
		var hari, jamMulai, jamSelesai, createdAt string
		rows.Scan(&id, &psikologID, &hari, &jamMulai, &jamSelesai, &isActive, &createdAt)
		schedules = append(schedules, map[string]interface{}{
			"id":           id,
			"psikolog_id":  psikologID,
			"hari":         hari,
			"jam_mulai":    jamMulai,
			"jam_selesai":  jamSelesai,
			"is_active":    isActive,
			"created_at":   createdAt,
		})
	}
	if schedules == nil {
		schedules = []map[string]interface{}{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data":  schedules,
		"total": len(schedules),
	})
}

func handleAddSchedule(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "psikolog" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya psikolog yang bisa menambah jadwal")
		return
	}

	var req struct {
		Hari       string `json:"hari"`
		JamMulai   string `json:"jam_mulai"`
		JamSelesai string `json:"jam_selesai"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Validasi hari
	validDays := map[string]bool{
		"senin": true, "selasa": true, "rabu": true,
		"kamis": true, "jumat": true, "sabtu": true,
	}
	req.Hari = strings.ToLower(strings.TrimSpace(req.Hari))
	if !validDays[req.Hari] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Hari tidak valid. Gunakan: senin-sabtu")
		return
	}


	// Validasi jam format HH:MM
	if req.JamMulai == "" || req.JamSelesai == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Jam mulai dan selesai wajib diisi (format HH:MM)")
		return
	}
	if req.JamMulai >= req.JamSelesai {
		utils.ErrorResponse(w, http.StatusBadRequest, "Jam mulai harus sebelum jam selesai")
		return
	}

	// Cek overlap dengan jadwal yang sudah ada
	var count int
	database.DB.QueryRow(`
		SELECT COUNT(*) FROM psikolog_schedules
		WHERE psikolog_id = ? AND hari = ? AND is_active = 1
		AND NOT (jam_selesai <= ? OR jam_mulai >= ?)
	`, claims.UserID, req.Hari, req.JamMulai, req.JamSelesai).Scan(&count)
	if count > 0 {
		utils.ErrorResponse(w, http.StatusConflict, "Jadwal tumpang tindih dengan slot yang sudah ada")
		return
	}

	result, err := database.DB.Exec(`
		INSERT INTO psikolog_schedules (psikolog_id, hari, jam_mulai, jam_selesai)
		VALUES (?, ?, ?, ?)
	`, claims.UserID, req.Hari, req.JamMulai, req.JamSelesai)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan jadwal")
		return
	}

	scheduleID, _ := result.LastInsertId()

	utils.JSONResponse(w, http.StatusCreated, map[string]interface{}{
		"message":     "Slot jadwal berhasil ditambahkan",
		"schedule_id": scheduleID,
	})
}

func handleDeleteSchedule(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "psikolog" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya psikolog yang bisa menghapus jadwal")
		return
	}

	var req struct {
		ScheduleID int `json:"schedule_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Soft delete — hanya nonaktifkan
	res, err := database.DB.Exec(`
		UPDATE psikolog_schedules SET is_active = 0
		WHERE id = ? AND psikolog_id = ?
	`, req.ScheduleID, claims.UserID)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menghapus jadwal")
		return
	}

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		utils.ErrorResponse(w, http.StatusNotFound, "Jadwal tidak ditemukan atau bukan milik Anda")
		return
	}

	utils.SuccessResponse(w, "Jadwal berhasil dihapus", nil)
}

// ══════════════════════════════════════════════════════════════
// ADMIN: INITIATE APPOINTMENT
//
// Admin menunjuk psikolog dan memicu proses penjadwalan.
// Report status → dijadwalkan, Appointment status → menunggu_user
// User mendapat notifikasi + email untuk memilih slot.
// ══════════════════════════════════════════════════════════════

func HandleInitiateAppointment(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "admin" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya admin yang bisa menjadwalkan")
		return
	}

	var req struct {
		ReportID   int `json:"report_id"`
		PsikologID int `json:"psikolog_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Validasi: report harus berstatus 'diterima'
	var currentStatus string
	var userID int
	err := database.DB.QueryRow("SELECT status, user_id FROM reports WHERE id = ?", req.ReportID).Scan(&currentStatus, &userID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Laporan tidak ditemukan")
		return
	}
	if currentStatus != "diterima" && currentStatus != "diproses" {
		utils.ErrorResponse(w, http.StatusBadRequest,
			fmt.Sprintf("Laporan harus berstatus 'diterima' atau 'diproses' untuk dijadwalkan. Status saat ini: '%s'", currentStatus))
		return
	}

	// Jika diproses, pastikan sesi sebelumnya sudah selesai dan meminta lanjutan
	if currentStatus == "diproses" {
		var apptID int
		var apptStatus string
		err := database.DB.QueryRow("SELECT id, status FROM appointments WHERE report_id = ? ORDER BY id DESC LIMIT 1", req.ReportID).Scan(&apptID, &apptStatus)
		if err == nil {
			if apptStatus != "selesai" {
				utils.ErrorResponse(w, http.StatusBadRequest, "Sesi konsultasi psikolog sebelumnya belum diselesaikan.")
				return
			}
			var followUp int
			errNote := database.DB.QueryRow("SELECT follow_up_needed FROM session_notes WHERE appointment_id = ?", apptID).Scan(&followUp)
			if errNote != nil || followUp != 1 {
				utils.ErrorResponse(w, http.StatusBadRequest, "Psikolog tidak merekomendasikan sesi lanjutan untuk laporan ini.")
				return
			}
		}
	}

	// Validasi: psikolog_id harus valid dan berperan psikolog
	var psikologRole string
	err = database.DB.QueryRow("SELECT role FROM users WHERE id = ?", req.PsikologID).Scan(&psikologRole)
	if err != nil || psikologRole != "psikolog" {
		utils.ErrorResponse(w, http.StatusBadRequest, "ID psikolog tidak valid")
		return
	}

	// Cek apakah psikolog memiliki minimal 1 slot jadwal aktif
	var slotCount int
	database.DB.QueryRow("SELECT COUNT(*) FROM psikolog_schedules WHERE psikolog_id = ? AND is_active = 1", req.PsikologID).Scan(&slotCount)
	if slotCount == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Psikolog ini belum memiliki slot jadwal aktif. Minta psikolog untuk mengatur jadwalnya terlebih dahulu.")
		return
	}

	// Update report: status → dijadwalkan, assign psikolog
	_, err = database.DB.Exec(`
		UPDATE reports SET status = 'dijadwalkan', assigned_psikolog_id = ?, assigned_admin_id = ?, updated_at = CURRENT_TIMESTAMP
		WHERE id = ?
	`, req.PsikologID, claims.UserID, req.ReportID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal update status laporan")
		return
	}

	// Buat appointment awal (tanggal & jam kosong, menunggu user pilih)
	result, err := database.DB.Exec(`
		INSERT INTO appointments (report_id, psikolog_id, user_id, status, created_by_admin_id)
		VALUES (?, ?, ?, 'menunggu_user', ?)
	`, req.ReportID, req.PsikologID, userID, claims.UserID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal membuat appointment")
		return
	}

	appointmentID, _ := result.LastInsertId()

	// Audit trail
	database.DB.Exec(`
		INSERT INTO audit_trail (report_id, actor_id, action, detail)
		VALUES (?, ?, 'SCHEDULED', ?)
	`, req.ReportID, claims.UserID,
		fmt.Sprintf("Admin menjadwalkan konsultasi dengan psikolog ID %d", req.PsikologID))

	// Notifikasi ke User
	database.DB.Exec(`
		INSERT INTO notifications (user_id, title, body, type, payload_json)
		VALUES (?, 'Jadwalkan Konsultasi', 'Admin telah mengatur konsultasi untuk laporan Anda. Silakan pilih jadwal pertemuan.', 'appointment', ?)
	`, userID, fmt.Sprintf(`{"report_id":%d,"appointment_id":%d}`, req.ReportID, appointmentID))

	// Email ke User
	var trackingCode, emailPenyintas, userEmail string
	database.DB.QueryRow("SELECT tracking_code, email_penyintas FROM reports WHERE id = ?", req.ReportID).Scan(&trackingCode, &emailPenyintas)
	database.DB.QueryRow("SELECT email FROM users WHERE id = ?", userID).Scan(&userEmail)

	targetEmail := emailPenyintas
	if targetEmail == "" {
		targetEmail = userEmail
	}

	var psikologName string
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", req.PsikologID).Scan(&psikologName)

	emailBody := fmt.Sprintf(`
		<div style="font-family: Arial, sans-serif; color: #333;">
			<h2 style="color: #2F80ED;">Jadwalkan Konsultasi Anda</h2>
			<p>Halo, laporan Anda dengan kode <strong>%s</strong> telah ditindaklanjuti.</p>
			<div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px; margin: 20px 0;">
				<p><strong>Psikolog yang ditunjuk:</strong> %s</p>
				<p><strong>Langkah selanjutnya:</strong> Buka aplikasi SIGAP dan pilih jadwal konsultasi yang tersedia.</p>
			</div>
			<p>Salam hangat,<br><b>Tim Satgas SIGAP</b></p>
		</div>
	`, trackingCode, psikologName)
	utils.SendEmail(targetEmail, "Pilih Jadwal Konsultasi - "+trackingCode, emailBody)

	utils.JSONResponse(w, http.StatusCreated, map[string]interface{}{
		"message":        "Penjadwalan berhasil dimulai",
		"appointment_id": appointmentID,
		"report_status":  "dijadwalkan",
	})
}

// ══════════════════════════════════════════════════════════════
// USER: PILIH SLOT JADWAL
//
// User memilih tanggal + slot jam dari jadwal psikolog yang tersedia.
// Appointment status → menunggu_psikolog
// Psikolog mendapat notifikasi + email.
// ══════════════════════════════════════════════════════════════

func HandleSelectAppointment(w http.ResponseWriter, r *http.Request) {
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
		Tanggal       string `json:"tanggal"`
		JamMulai      string `json:"jam_mulai"`
		JamSelesai    string `json:"jam_selesai"`
		TipeLokasi    string `json:"tipe_lokasi"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}
	if req.TipeLokasi != "online" && req.TipeLokasi != "offline" {
		req.TipeLokasi = "online" // default fallback
	}

	// Validasi: appointment harus milik user dan berstatus menunggu_user
	var apptStatus string
	var apptUserID, psikologID, reportID int
	err := database.DB.QueryRow(
		"SELECT status, user_id, psikolog_id, report_id FROM appointments WHERE id = ?", req.AppointmentID,
	).Scan(&apptStatus, &apptUserID, &psikologID, &reportID)

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Appointment tidak ditemukan")
		return
	}
	if apptUserID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Appointment ini bukan milik Anda")
		return
	}
	if apptStatus != "menunggu_user" && apptStatus != "reschedule" {
		utils.ErrorResponse(w, http.StatusBadRequest,
			fmt.Sprintf("Appointment tidak dalam status memilih jadwal. Status saat ini: '%s'", apptStatus))
		return
	}

	if req.TipeLokasi != "online" && req.TipeLokasi != "offline" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Tipe lokasi tidak valid. Harus 'online' atau 'offline'.")
		return
	}

	// Validasi tanggal tidak di masa lalu
	selectedDate, parseErr := time.Parse("2006-01-02", req.Tanggal)
	if parseErr != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format tanggal tidak valid. Gunakan YYYY-MM-DD")
		return
	}
	today := time.Now().Truncate(24 * time.Hour)
	if selectedDate.Before(today) {
		utils.ErrorResponse(w, http.StatusBadRequest, "Tidak bisa memilih tanggal di masa lalu")
		return
	}

	// Validasi: slot jam ada di jadwal psikolog dan hari sesuai
	dayNames := map[time.Weekday]string{
		time.Monday: "senin", time.Tuesday: "selasa", time.Wednesday: "rabu",
		time.Thursday: "kamis", time.Friday: "jumat", time.Saturday: "sabtu",
	}
	selectedDay := dayNames[selectedDate.Weekday()]
	if selectedDay == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Konsultasi tidak tersedia di hari Minggu")
		return
	}

	var slotExists int
	database.DB.QueryRow(`
		SELECT COUNT(*) FROM psikolog_schedules
		WHERE psikolog_id = ? AND hari = ? AND jam_mulai = ? AND jam_selesai = ? AND is_active = 1
	`, psikologID, selectedDay, req.JamMulai, req.JamSelesai).Scan(&slotExists)
	if slotExists == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Slot jadwal yang dipilih tidak tersedia")
		return
	}

	// Gunakan Transaksi SQL untuk mencegah Race Condition (Double Booking)
	tx, err := database.DB.Begin()
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal memulai transaksi")
		return
	}
	defer tx.Rollback()

	// Cek apakah slot sudah terisi oleh appointment lain di tanggal yang sama
	var conflictCount int
	tx.QueryRow(`
		SELECT COUNT(*) FROM appointments
		WHERE psikolog_id = ? AND tanggal = ? AND jam_mulai = ? AND jam_selesai = ?
		AND status IN ('menunggu_psikolog','diterima') AND id != ?
	`, psikologID, req.Tanggal, req.JamMulai, req.JamSelesai, req.AppointmentID).Scan(&conflictCount)
	if conflictCount > 0 {
		utils.ErrorResponse(w, http.StatusConflict, "Slot ini sudah terisi oleh jadwal lain. Silakan pilih slot lain.")
		return
	}

	// Update appointment
	_, err = tx.Exec(`
		UPDATE appointments SET tanggal = ?, jam_mulai = ?, jam_selesai = ?, tipe_lokasi = ?, status = 'menunggu_psikolog', updated_at = CURRENT_TIMESTAMP
		WHERE id = ?
	`, req.Tanggal, req.JamMulai, req.JamSelesai, req.TipeLokasi, req.AppointmentID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan pilihan jadwal")
		return
	}

	if err := tx.Commit(); err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyelesaikan pemesanan jadwal")
		return
	}

	// Audit trail
	database.DB.Exec(`
		INSERT INTO audit_trail (report_id, actor_id, action, detail)
		VALUES (?, ?, 'SLOT_SELECTED', ?)
	`, reportID, claims.UserID,
		fmt.Sprintf("User memilih jadwal: %s %s-%s", req.Tanggal, req.JamMulai, req.JamSelesai))

	// Notifikasi ke Psikolog
	database.DB.Exec(`
		INSERT INTO notifications (user_id, title, body, type, payload_json)
		VALUES (?, 'Jadwal Menunggu Konfirmasi', 'Ada jadwal konsultasi baru yang perlu Anda konfirmasi.', 'appointment', ?)
	`, psikologID, fmt.Sprintf(`{"appointment_id":%d,"report_id":%d}`, req.AppointmentID, reportID))

	// Email ke Psikolog
	var psikologEmail, userName, trackingCode string
	database.DB.QueryRow("SELECT email FROM users WHERE id = ?", psikologID).Scan(&psikologEmail)
	database.DB.QueryRow("SELECT nama_lengkap FROM users WHERE id = ?", claims.UserID).Scan(&userName)
	database.DB.QueryRow("SELECT tracking_code FROM reports WHERE id = ?", reportID).Scan(&trackingCode)

	emailBody := fmt.Sprintf(`
		<div style="font-family: Arial, sans-serif; color: #333;">
			<h2 style="color: #2F80ED;">Konfirmasi Jadwal Konsultasi</h2>
			<p>Pelapor telah memilih jadwal konsultasi:</p>
			<div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px; margin: 20px 0;">
				<p><strong>Kode Laporan:</strong> %s</p>
				<p><strong>Tanggal:</strong> %s</p>
				<p><strong>Jam:</strong> %s - %s</p>
			</div>
			<p>Buka aplikasi SIGAP untuk <b>menerima</b> atau <b>meminta reschedule</b>.</p>
			<p>Salam hangat,<br><b>Tim Satgas SIGAP</b></p>
		</div>
	`, trackingCode, req.Tanggal, req.JamMulai, req.JamSelesai)
	utils.SendEmail(psikologEmail, "Konfirmasi Jadwal - "+trackingCode, emailBody)

	utils.SuccessResponse(w, "Jadwal berhasil dipilih. Menunggu konfirmasi psikolog.", map[string]interface{}{
		"appointment_id": req.AppointmentID,
		"status":         "menunggu_psikolog",
	})
}

// ══════════════════════════════════════════════════════════════
// PSIKOLOG: RESPOND TO APPOINTMENT
//
// Psikolog bisa: terima, reschedule, atau tolak.
// ══════════════════════════════════════════════════════════════

func HandleRespondAppointment(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "psikolog" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya psikolog yang bisa merespons")
		return
	}

	var req struct {
		AppointmentID int    `json:"appointment_id"`
		Action        string `json:"action"` // "terima", "reschedule", "tolak"
		Catatan       string `json:"catatan"`
		LinkLokasi    string `json:"link_lokasi"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	validActions := map[string]bool{"terima": true, "reschedule": true, "tolak": true}
	if !validActions[req.Action] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Action tidak valid. Gunakan: terima, reschedule, tolak")
		return
	}

	// Validasi appointment
	var apptStatus string
	var apptPsikologID, userID, reportID int
	var tanggal, jamMulai, jamSelesai string
	err := database.DB.QueryRow(
		"SELECT status, psikolog_id, user_id, report_id, tanggal, jam_mulai, jam_selesai FROM appointments WHERE id = ?",
		req.AppointmentID,
	).Scan(&apptStatus, &apptPsikologID, &userID, &reportID, &tanggal, &jamMulai, &jamSelesai)

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Appointment tidak ditemukan")
		return
	}
	if apptPsikologID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Appointment ini bukan untuk Anda")
		return
	}
	if apptStatus != "menunggu_psikolog" {
		utils.ErrorResponse(w, http.StatusBadRequest,
			fmt.Sprintf("Appointment tidak dalam status menunggu konfirmasi. Status: '%s'", apptStatus))
		return
	}

	var trackingCode, emailPenyintas, userEmail string
	database.DB.QueryRow("SELECT tracking_code, email_penyintas FROM reports WHERE id = ?", reportID).Scan(&trackingCode, &emailPenyintas)
	database.DB.QueryRow("SELECT email FROM users WHERE id = ?", userID).Scan(&userEmail)

	targetEmail := emailPenyintas
	if targetEmail == "" {
		targetEmail = userEmail
	}

	switch req.Action {
	case "terima":
		// Update appointment → diterima dan set link_lokasi
		database.DB.Exec(`UPDATE appointments SET status = 'diterima', link_lokasi = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`, req.LinkLokasi, req.AppointmentID)
		// Update report → diproses (laporan sekarang resmi "masuk" ke psikolog)
		database.DB.Exec(`UPDATE reports SET status = 'diproses', updated_at = CURRENT_TIMESTAMP WHERE id = ?`, reportID)

		database.DB.Exec(`
			INSERT INTO audit_trail (report_id, actor_id, action, detail)
			VALUES (?, ?, 'APPOINTMENT_ACCEPTED', ?)
		`, reportID, claims.UserID, fmt.Sprintf("Psikolog menerima jadwal: %s %s-%s", tanggal, jamMulai, jamSelesai))

		// Notifikasi + Email ke User
		database.DB.Exec(`
			INSERT INTO notifications (user_id, title, body, type, payload_json)
			VALUES (?, 'Jadwal Dikonfirmasi', ?, 'appointment', ?)
		`, userID,
			fmt.Sprintf("Konsultasi Anda dijadwalkan pada %s pukul %s-%s", tanggal, jamMulai, jamSelesai),
			fmt.Sprintf(`{"appointment_id":%d,"report_id":%d}`, req.AppointmentID, reportID))

		emailBody := fmt.Sprintf(`
			<div style="font-family: Arial, sans-serif; color: #333;">
				<h2 style="color: #27ae60;">Jadwal Konsultasi Dikonfirmasi ✓</h2>
				<p>Psikolog telah mengkonfirmasi jadwal pertemuan Anda:</p>
				<div style="background-color: #e8f5e9; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #27ae60;">
					<p style="margin: 0;"><strong>Kode:</strong> %s</p>
					<p style="margin: 5px 0 0 0;"><strong>Tanggal:</strong> %s</p>
					<p style="margin: 5px 0 0 0;"><strong>Jam:</strong> %s - %s</p>
					<p style="margin: 5px 0 0 0;"><strong>Lokasi/Link:</strong> %s</p>
				</div>
				<p>Harap hadir tepat waktu. Salam hangat,<br><b>Tim Satgas SIGAP</b></p>
			</div>
		`, trackingCode, tanggal, jamMulai, jamSelesai, req.LinkLokasi)
		utils.SendEmail(targetEmail, "Jadwal Dikonfirmasi - "+trackingCode, emailBody)

		utils.SuccessResponse(w, "Jadwal diterima. Laporan masuk ke tahap penanganan.", map[string]interface{}{
			"appointment_status": "diterima",
			"report_status":      "diproses",
		})

	case "reschedule":
		if req.Catatan == "" {
			utils.ErrorResponse(w, http.StatusBadRequest, "Catatan/alasan reschedule wajib diisi")
			return
		}

		// Gunakan Transaksi SQL agar update appointment dan report sinkron
		tx, err := database.DB.Begin()
		if err != nil {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal memulai transaksi reschedule")
			return
		}
		defer tx.Rollback()

		// Update appointment → reschedule (user harus pilih ulang)
		tx.Exec(`
			UPDATE appointments SET status = 'reschedule', catatan_reschedule = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?
		`, req.Catatan, req.AppointmentID)

		// Sync ke reports: kembalikan laporan ke status agar user bisa memilih ulang jadwal
		tx.Exec(`
			UPDATE reports SET status = 'menunggu_penjadwalan', updated_at = CURRENT_TIMESTAMP WHERE id = ?
		`, reportID)

		tx.Commit()

		database.DB.Exec(`
			INSERT INTO audit_trail (report_id, actor_id, action, detail)
			VALUES (?, ?, 'APPOINTMENT_RESCHEDULE', ?)
		`, reportID, claims.UserID, "Psikolog meminta reschedule: "+req.Catatan)

		// Notifikasi + Email ke User
		database.DB.Exec(`
			INSERT INTO notifications (user_id, title, body, type, payload_json)
			VALUES (?, 'Reschedule Konsultasi', ?, 'appointment', ?)
		`, userID,
			"Psikolog meminta perubahan jadwal: "+req.Catatan,
			fmt.Sprintf(`{"appointment_id":%d,"report_id":%d}`, req.AppointmentID, reportID))

		emailBody := fmt.Sprintf(`
			<div style="font-family: Arial, sans-serif; color: #333;">
				<h2 style="color: #f39c12;">Permintaan Perubahan Jadwal</h2>
				<p>Psikolog meminta Anda untuk memilih jadwal baru:</p>
				<div style="background-color: #fff3e0; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #f39c12;">
					<p style="margin: 0;"><strong>Alasan:</strong> %s</p>
				</div>
				<p>Buka aplikasi SIGAP untuk memilih jadwal baru. Kode laporan: <strong>%s</strong></p>
				<p>Salam hangat,<br><b>Tim Satgas SIGAP</b></p>
			</div>
		`, req.Catatan, trackingCode)
		utils.SendEmail(targetEmail, "Reschedule Konsultasi - "+trackingCode, emailBody)

		utils.SuccessResponse(w, "Permintaan reschedule terkirim ke user.", map[string]interface{}{
			"appointment_status": "reschedule",
		})

	case "tolak":
		if req.Catatan == "" {
			utils.ErrorResponse(w, http.StatusBadRequest, "Catatan/alasan penolakan wajib diisi")
			return
		}

		database.DB.Exec(`UPDATE appointments SET status = 'ditolak', catatan_reschedule = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
			req.Catatan, req.AppointmentID)

		// PENTING: Kembalikan status report ke 'diterima' agar admin bisa menjadwalkan ulang
		// Tanpa ini, laporan akan terjebak di status 'dijadwalkan' selamanya.
		database.DB.Exec(`
			UPDATE reports SET status = 'diterima', assigned_psikolog_id = NULL, updated_at = CURRENT_TIMESTAMP 
			WHERE id = ?
		`, reportID)

		database.DB.Exec(`
			INSERT INTO audit_trail (report_id, actor_id, action, detail)
			VALUES (?, ?, 'APPOINTMENT_REJECTED', ?)
		`, reportID, claims.UserID, "Psikolog menolak jadwal: "+req.Catatan)

		// Notifikasi ke user
		database.DB.Exec(`
			INSERT INTO notifications (user_id, title, body, type, payload_json)
			VALUES (?, 'Jadwal Ditolak', ?, 'appointment', ?)
		`, userID, "Psikolog menolak jadwal konsultasi: "+req.Catatan,
			fmt.Sprintf(`{"appointment_id":%d,"report_id":%d}`, req.AppointmentID, reportID))

		// Notifikasi ke admin agar menjadwalkan ulang
		adminNotifRows, _ := database.DB.Query("SELECT id FROM users WHERE role = 'admin' AND is_active = 1")
		if adminNotifRows != nil {
			defer adminNotifRows.Close()
			for adminNotifRows.Next() {
				var aID int
				adminNotifRows.Scan(&aID)
				database.DB.Exec(`
					INSERT INTO notifications (user_id, title, body, type, payload_json)
					VALUES (?, 'Jadwal Ditolak — Perlu Dijadwalkan Ulang', ?, 'appointment', ?)
				`, aID,
					fmt.Sprintf("Psikolog menolak jadwal untuk laporan #%d. Silakan tugaskan psikolog lain.", reportID),
					fmt.Sprintf(`{"report_id":%d,"appointment_id":%d}`, reportID, req.AppointmentID))
			}
		}

		utils.SuccessResponse(w, "Jadwal ditolak. Laporan dikembalikan ke antrian admin.", map[string]interface{}{
			"appointment_status": "ditolak",
			"report_status":      "diterima",
		})
	}
}

// ══════════════════════════════════════════════════════════════
// LIST APPOINTMENTS (all roles)
// ══════════════════════════════════════════════════════════════

func HandleListAppointments(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var query string
	var args []interface{}

	baseQuery := `
		SELECT a.id, a.report_id, a.psikolog_id, a.user_id, a.tanggal, a.jam_mulai, a.jam_selesai,
		       a.status, a.catatan_reschedule, a.tipe_lokasi, a.link_lokasi, a.created_at, a.updated_at,
		       r.tracking_code, up.nama_lengkap AS nama_psikolog, uu.nama_lengkap AS nama_user
		FROM appointments a
		JOIN reports r ON a.report_id = r.id
		JOIN users up ON a.psikolog_id = up.id
		JOIN users uu ON a.user_id = uu.id
	`

	switch claims.Role {
	case "admin":
		query = baseQuery + " ORDER BY a.updated_at DESC"
	case "psikolog":
		query = baseQuery + " WHERE a.psikolog_id = ? ORDER BY a.updated_at DESC"
		args = append(args, claims.UserID)
	default: // user
		query = baseQuery + " WHERE a.user_id = ? ORDER BY a.updated_at DESC"
		args = append(args, claims.UserID)
	}

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil data appointment")
		return
	}
	defer rows.Close()

	var appointments []map[string]interface{}
	for rows.Next() {
		var id, reportID, psikologID, apptUserID int
		var tanggal, jamMulai, jamSelesai, status, catatan, tipeLokasi, linkLokasi, createdAt, updatedAt string
		var trackingCode, namaPsikolog, namaUser string

		rows.Scan(&id, &reportID, &psikologID, &apptUserID, &tanggal, &jamMulai, &jamSelesai,
			&status, &catatan, &tipeLokasi, &linkLokasi, &createdAt, &updatedAt, &trackingCode, &namaPsikolog, &namaUser)

		appointments = append(appointments, map[string]interface{}{
			"id":                  id,
			"report_id":           reportID,
			"psikolog_id":         psikologID,
			"user_id":             apptUserID,
			"tanggal":             tanggal,
			"jam_mulai":           jamMulai,
			"jam_selesai":         jamSelesai,
			"status":              status,
			"catatan_reschedule":  catatan,
			"tipe_lokasi":         tipeLokasi,
			"link_lokasi":         linkLokasi,
			"tracking_code":       trackingCode,
			"nama_psikolog":       namaPsikolog,
			"nama_user":           namaUser,
			// Alias for compatibility with psikolog portal (uses a.user_nama)
			"user_nama":           namaUser,
			"psikolog_nama":       namaPsikolog,
			"created_at":          createdAt,
			"updated_at":          updatedAt,
		})
	}
	if appointments == nil {
		appointments = []map[string]interface{}{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data":  appointments,
		"total": len(appointments),
	})
}
