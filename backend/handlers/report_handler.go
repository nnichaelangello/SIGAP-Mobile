package handlers

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"sigap-backend/database"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

func generateTrackingCode() string {
	bytes := make([]byte, 3)
	if _, err := rand.Read(bytes); err != nil {
		return fmt.Sprintf("SIGAP-%d", time.Now().UnixMilli()%1000000)
	}
	return fmt.Sprintf("SIGAP-%s", strings.ToUpper(hex.EncodeToString(bytes)))
}

// ──────────────────────────────────────────────
// SUBMIT REPORT
// ──────────────────────────────────────────────

func HandleSubmitReport(w http.ResponseWriter, r *http.Request) {
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
		JenisPenyintas       string `json:"jenis_penyintas"`
		KategoriKekhawatiran string `json:"kategori_kekhawatiran"`
		GenderPelaku         string `json:"gender_pelaku"`
		HubunganPelaku       string `json:"hubungan_pelaku"`
		DetailKejadian       string `json:"detail_kejadian"`
		EmailPenyintas       string `json:"email_penyintas"`
		BuktiPath            string `json:"bukti_path"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Server-side validation
	if len(strings.TrimSpace(req.DetailKejadian)) < 10 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Detail kejadian minimal 10 karakter")
		return
	}

	var trackingCode string
	var reportID int64
	maxRetries := 5

	for i := 0; i < maxRetries; i++ {
		trackingCode = generateTrackingCode()

		// Cek collision
		var count int
		database.DB.QueryRow("SELECT COUNT(*) FROM reports WHERE tracking_code = ?", trackingCode).Scan(&count)
		if count > 0 {
			continue // Bentrok, coba lagi
		}

		result, err := database.DB.Exec(`
			INSERT INTO reports (tracking_code, user_id, jenis_penyintas, kategori_kekhawatiran, gender_pelaku, hubungan_pelaku, detail_kejadian, email_penyintas, bukti_path)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, trackingCode, claims.UserID, req.JenisPenyintas, req.KategoriKekhawatiran, req.GenderPelaku,
			req.HubunganPelaku, req.DetailKejadian, req.EmailPenyintas, req.BuktiPath)

		if err == nil {
			reportID, _ = result.LastInsertId()
			break
		}

		// Jika error karena constraint unik (race condition antar goroutine), loop akan mencoba ulang.
		// Jika loop berakhir tanpa hasil, lemparkan error di luar.
	}

	if reportID == 0 {
		log.Printf("[ERROR] HandleSubmitReport INSERT gagal setelah %d percobaan", maxRetries)
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan laporan karena collision internal")
		return
	}

	// Audit trail
	database.DB.Exec(`
		INSERT INTO audit_trail (report_id, actor_id, action, detail)
		VALUES (?, ?, 'CREATED', 'Laporan baru dibuat')
	`, reportID, claims.UserID)

	// Notifikasi ke semua admin
	adminRows, _ := database.DB.Query("SELECT id FROM users WHERE role = 'admin'")
	if adminRows != nil {
		defer adminRows.Close()
		for adminRows.Next() {
			var adminID int
			adminRows.Scan(&adminID)
			database.DB.Exec(`
				INSERT INTO notifications (user_id, title, body, type, payload_json)
				VALUES (?, 'Laporan Baru', 'Ada laporan baru masuk yang menunggu review', 'report', ?)
			`, adminID, fmt.Sprintf(`{"report_id":%d}`, reportID))
		}
	}

	// Tentukan alamat email tujuan (utamakan email penyintas jika diisi, jika tidak gunakan email login)
	targetEmail := req.EmailPenyintas
	if targetEmail == "" {
		targetEmail = claims.Email
	}

	// Kirim Email Notifikasi via Goroutine
	emailSubject := "Laporan Diterima - " + trackingCode
	emailBody := fmt.Sprintf(`
		<div style="font-family: Arial, sans-serif; color: #333;">
			<h2 style="color: #2F80ED;">Terima Kasih Atas Laporan Anda</h2>
			<p>Laporan Anda telah berhasil masuk ke dalam sistem SIGAP.</p>
			<div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px; margin: 20px 0;">
				<p style="margin: 0;"><strong>Kode Pelacakan:</strong></p>
				<h3 style="margin: 5px 0 0 0; color: #d32f2f; letter-spacing: 2px;">%s</h3>
			</div>
			<p>Harap simpan kode ini baik-baik. Anda dapat menggunakannya di menu <b>Pantau</b> pada aplikasi SIGAP untuk melihat status laporan Anda.</p>
			<br>
			<p>Salam hangat,<br><b>Tim Satgas SIGAP</b></p>
		</div>
	`, trackingCode)
	utils.SendEmail(targetEmail, emailSubject, emailBody)

	utils.JSONResponse(w, http.StatusCreated, map[string]interface{}{
		"message":       "Laporan berhasil dikirim",
		"report_id":     reportID,
		"tracking_code": trackingCode,
	})
}

// ──────────────────────────────────────────────
// LIST REPORTS
// ──────────────────────────────────────────────

func HandleListReports(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	statusFilter := r.URL.Query().Get("status")

	var query string
	var args []interface{}

	switch claims.Role {
	case "admin":
		query = `SELECT r.id, r.tracking_code, r.user_id, u.nama_lengkap, u.email, r.jenis_penyintas, r.kategori_kekhawatiran,
		         r.gender_pelaku, r.hubungan_pelaku, r.detail_kejadian, r.status, r.alasan_tolak,
		         r.catatan_admin, r.catatan_psikolog, r.assigned_psikolog_id, r.created_at, r.updated_at
		         FROM reports r JOIN users u ON r.user_id = u.id`
	case "psikolog":
		query = `SELECT r.id, r.tracking_code, r.user_id, u.nama_lengkap, u.email, r.jenis_penyintas, r.kategori_kekhawatiran,
		         r.gender_pelaku, r.hubungan_pelaku, r.detail_kejadian, r.status, r.alasan_tolak,
		         r.catatan_admin, r.catatan_psikolog, r.assigned_psikolog_id, r.created_at, r.updated_at
		         FROM reports r JOIN users u ON r.user_id = u.id WHERE r.assigned_psikolog_id = ?`
		args = append(args, claims.UserID)
	default:
		query = `SELECT r.id, r.tracking_code, r.user_id, u.nama_lengkap, u.email, r.jenis_penyintas, r.kategori_kekhawatiran,
		         r.gender_pelaku, r.hubungan_pelaku, r.detail_kejadian, r.status, r.alasan_tolak,
		         r.catatan_admin, r.catatan_psikolog, r.assigned_psikolog_id, r.created_at, r.updated_at
		         FROM reports r JOIN users u ON r.user_id = u.id WHERE r.user_id = ?`
		args = append(args, claims.UserID)
	}

	if statusFilter != "" {
		if len(args) > 0 {
			query += " AND r.status = ?"
		} else {
			query += " WHERE r.status = ?"
		}
		args = append(args, statusFilter)
	}

	query += " ORDER BY r.created_at DESC LIMIT 1000"

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		log.Printf("[ERROR] HandleListReports query gagal: %v", err)
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil laporan: "+err.Error())
		return
	}
	defer rows.Close()

	var reports []map[string]interface{}
	for rows.Next() {
		var id, userID int
		var assignedPsikologID *int
		var trackingCode, nama, email, jenis, kategori, gender, hubungan, detail, status string
		// Kolom berikut bisa NULL di database (laporan baru belum diproses)
		var alasanTolak, catatanAdmin, catatanPsikolog, updatedAt sql.NullString
		var createdAt string

		if err := rows.Scan(
			&id, &trackingCode, &userID, &nama, &email, &jenis, &kategori, &gender, &hubungan,
			&detail, &status, &alasanTolak, &catatanAdmin, &catatanPsikolog,
			&assignedPsikologID, &createdAt, &updatedAt,
		); err != nil {
			log.Printf("[WARN] HandleListReports scan error (row skipped): %v", err)
			continue
		}

		reports = append(reports, map[string]interface{}{
			"id":                    id,
			"tracking_code":         trackingCode,
			"user_id":               userID,
			"nama_pelapor":          nama,
			"email_pelapor":         email,
			"jenis_penyintas":       jenis,
			"kategori_kekhawatiran": kategori,
			"gender_pelaku":         gender,
			"hubungan_pelaku":       hubungan,
			"detail_kejadian":       detail,
			"status":                status,
			"alasan_tolak":          alasanTolak.String,
			"catatan_admin":         catatanAdmin.String,
			"catatan_psikolog":      catatanPsikolog.String,
			"assigned_psikolog_id":  assignedPsikologID,
			"created_at":            createdAt,
			"updated_at":            updatedAt.String,
		})
	}

	if reports == nil {
		reports = []map[string]interface{}{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data":  reports,
		"total": len(reports),
	})
}

// ──────────────────────────────────────────────
// GET REPORT DETAIL
// ──────────────────────────────────────────────

func HandleGetReport(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	// Extract ID from path: /api/reports/{id}
	cleanPath := strings.Trim(r.URL.Path, "/")
	parts := strings.Split(cleanPath, "/")
	if len(parts) < 3 {
		utils.ErrorResponse(w, http.StatusBadRequest, "ID tidak ditemukan di URL")
		return
	}
	reportID, err := strconv.Atoi(parts[len(parts)-1])
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "ID laporan harus angka")
		return
	}

	var report struct {
		ID, UserID                                                    int
		TrackingCode, Nama, Email, Jenis, Kategori, Gender, Hubungan, Detail string
		Status, AlasanTolak, CatatanAdmin, CatatanPsikolog           string
		BuktiPath, CreatedAt, UpdatedAt                               string
		AssignedPsikologID                                            *int
	}

	err = database.DB.QueryRow(`
		SELECT r.id, r.tracking_code, r.user_id, u.nama_lengkap, u.email, r.jenis_penyintas, r.kategori_kekhawatiran,
		       r.gender_pelaku, r.hubungan_pelaku, r.detail_kejadian, r.status, r.alasan_tolak,
		       r.catatan_admin, r.catatan_psikolog, r.bukti_path, r.assigned_psikolog_id, r.created_at, r.updated_at
		FROM reports r JOIN users u ON r.user_id = u.id WHERE r.id = ?
	`, reportID).Scan(
		&report.ID, &report.TrackingCode, &report.UserID, &report.Nama, &report.Email,
		&report.Jenis, &report.Kategori, &report.Gender, &report.Hubungan,
		&report.Detail, &report.Status, &report.AlasanTolak,
		&report.CatatanAdmin, &report.CatatanPsikolog, &report.BuktiPath,
		&report.AssignedPsikologID, &report.CreatedAt, &report.UpdatedAt,
	)

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Laporan tidak ditemukan")
		return
	}

	// ── Access Control: user biasa hanya bisa lihat laporan sendiri ──
	if claims.Role == "user" && report.UserID != claims.UserID {
		utils.ErrorResponse(w, http.StatusForbidden, "Anda tidak memiliki akses ke laporan ini")
		return
	}

	// Get audit trail
	auditRows, _ := database.DB.Query(`
		SELECT a.action, a.detail, u.nama_lengkap, a.created_at
		FROM audit_trail a JOIN users u ON a.actor_id = u.id
		WHERE a.report_id = ? ORDER BY a.created_at DESC
	`, reportID)
	defer auditRows.Close()

	var audits []map[string]string
	for auditRows.Next() {
		var action, detail, actor, createdAt string
		auditRows.Scan(&action, &detail, &actor, &createdAt)
		audits = append(audits, map[string]string{
			"action":     action,
			"detail":     detail,
			"actor":      actor,
			"created_at": createdAt,
		})
	}

	if audits == nil {
		audits = []map[string]string{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"id":                    report.ID,
			"tracking_code":         report.TrackingCode,
			"user_id":               report.UserID,
			"nama_pelapor":          report.Nama,
			"email_pelapor":         report.Email,
			"jenis_penyintas":       report.Jenis,
			"kategori_kekhawatiran": report.Kategori,
			"gender_pelaku":         report.Gender,
			"hubungan_pelaku":       report.Hubungan,
			"detail_kejadian":       report.Detail,
			"status":               report.Status,
			"alasan_tolak":         report.AlasanTolak,
			"catatan_admin":        report.CatatanAdmin,
			"catatan_psikolog":     report.CatatanPsikolog,
			"bukti_path":           report.BuktiPath,
			"assigned_psikolog_id": report.AssignedPsikologID,
			"created_at":           report.CreatedAt,
			"updated_at":           report.UpdatedAt,
			"audit_trail":          audits,
		},
	})
}

// ──────────────────────────────────────────────
// UPDATE REPORT STATUS (Admin/Psikolog)
// ──────────────────────────────────────────────

func HandleUpdateReportStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		ReportID      int    `json:"report_id"`
		Status        string `json:"status"`
		AlasanTolak   string `json:"alasan_tolak"`
		CatatanAdmin  string `json:"catatan_admin"`
		CatatanPsikolog string `json:"catatan_psikolog"`
		PsikologID    *int   `json:"psikolog_id"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Validasi status
	validStatuses := map[string]bool{
		"pending": true, "diterima": true, "menunggu_penjadwalan": true,
		"dijadwalkan": true, "ditolak": true, "diproses": true, "selesai": true,
	}
	if !validStatuses[req.Status] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Status tidak valid")
		return
	}

	// ── State Machine: Validasi transisi status ──
	// Alur yang diizinkan:
	//   pending      → diterima | ditolak
	//   diterima     → dijadwalkan | diproses | ditolak
	//   dijadwalkan  → diproses | ditolak
	//   diproses     → selesai
	//   selesai      → (final)
	//   ditolak      → (final)
	var currentStatus string
	err := database.DB.QueryRow("SELECT status FROM reports WHERE id = ?", req.ReportID).Scan(&currentStatus)
	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Laporan tidak ditemukan")
		return
	}

	allowedTransitions := map[string][]string{
		"pending":              {"diterima", "ditolak"},
		"diterima":            {"menunggu_penjadwalan", "dijadwalkan", "diproses", "ditolak"},
		"menunggu_penjadwalan": {"dijadwalkan", "ditolak"},
		"dijadwalkan":         {"diproses", "ditolak"},
		"diproses":            {"selesai"},
		"selesai":             {},
		"ditolak":             {},
	}

	allowed := false
	for _, next := range allowedTransitions[currentStatus] {
		if next == req.Status {
			allowed = true
			break
		}
	}
	if !allowed {
		utils.ErrorResponse(w, http.StatusBadRequest,
			fmt.Sprintf("Transisi status tidak valid: '%s' → '%s'. Status '%s' hanya boleh diubah ke: %s",
				currentStatus, req.Status, currentStatus, strings.Join(allowedTransitions[currentStatus], ", ")))
		return
	}

	// Validasi: ditolak wajib punya alasan
	if req.Status == "ditolak" && req.AlasanTolak == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Alasan penolakan wajib diisi")
		return
	}

	// Validasi: Selesai hanya jika appointment terakhir berstatus selesai
	if req.Status == "selesai" {
		var apptStatus string
		errAppt := database.DB.QueryRow("SELECT status FROM appointments WHERE report_id = ? ORDER BY id DESC LIMIT 1", req.ReportID).Scan(&apptStatus)
		if errAppt == nil && apptStatus != "selesai" {
			utils.ErrorResponse(w, http.StatusBadRequest, "Sesi konsultasi psikolog belum diselesaikan. Psikolog harus mengakhiri sesi terlebih dahulu.")
			return
		}
	}

	// Mulai Transaksi Database
	tx, err := database.DB.Begin()
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal memulai transaksi")
		return
	}
	defer tx.Rollback()

	// Update report
	query := "UPDATE reports SET status = ?, updated_at = CURRENT_TIMESTAMP"
	args := []interface{}{req.Status}

	// Auto-assign admin yang menerima laporan
	if req.Status == "diterima" {
		query += ", assigned_admin_id = ?"
		args = append(args, claims.UserID)
	}

	if req.AlasanTolak != "" {
		query += ", alasan_tolak = ?"
		args = append(args, req.AlasanTolak)
	}
	if req.CatatanAdmin != "" {
		query += ", catatan_admin = ?"
		args = append(args, req.CatatanAdmin)
	}
	if req.CatatanPsikolog != "" {
		query += ", catatan_psikolog = ?"
		args = append(args, req.CatatanPsikolog)
	}
	if req.PsikologID != nil {
		query += ", assigned_psikolog_id = ?"
		args = append(args, *req.PsikologID)
	}

	query += " WHERE id = ?"
	args = append(args, req.ReportID)

	_, err = tx.Exec(query, args...)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal update status")
		return
	}

	// Audit trail
	_, err = tx.Exec(`
		INSERT INTO audit_trail (report_id, actor_id, action, detail)
		VALUES (?, ?, ?, ?)
	`, req.ReportID, claims.UserID, "STATUS_CHANGED",
		fmt.Sprintf("Status diubah menjadi '%s' oleh %s", req.Status, claims.Email))
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mencatat audit trail")
		return
	}

	// Notifikasi ke pelapor
	var pelaporrID int
	var trackingCode string
	var emailPenyintas string
	database.DB.QueryRow("SELECT user_id, tracking_code, email_penyintas FROM reports WHERE id = ?", req.ReportID).Scan(&pelaporrID, &trackingCode, &emailPenyintas)

	var pelaporEmail string
	database.DB.QueryRow("SELECT email FROM users WHERE id = ?", pelaporrID).Scan(&pelaporEmail)

	targetEmail := emailPenyintas
	if targetEmail == "" {
		targetEmail = pelaporEmail
	}

	statusMsg := map[string]string{
		"diterima": "Laporan Anda telah diterima dan sedang diproses",
		"ditolak":  "Laporan Anda ditolak: " + req.AlasanTolak,
		"diproses": "Laporan Anda sedang ditangani oleh tim",
		"selesai":  "Laporan Anda telah selesai ditangani",
	}

	if msg, ok := statusMsg[req.Status]; ok {
		// Simpan notifikasi ke database in-app
		_, err = tx.Exec(`
			INSERT INTO notifications (user_id, title, body, type, payload_json)
			VALUES (?, 'Update Laporan', ?, 'report_update', ?)
		`, pelaporrID, msg, fmt.Sprintf(`{"report_id":%d,"status":"%s"}`, req.ReportID, req.Status))
		if err != nil {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengirim notifikasi internal")
			return
		}
		
		// Kirim Email Update via SMTP
		emailSubject := "Pembaruan Status Laporan - " + trackingCode
		
		// Buat rincian tambahan (jika ada catatan dsb)
		rincian := "Tidak ada catatan tambahan."
		if req.AlasanTolak != "" {
			rincian = "Alasan Penolakan: " + req.AlasanTolak
		} else if req.CatatanAdmin != "" || req.CatatanPsikolog != "" {
			rincian = ""
			if req.CatatanAdmin != "" {
				rincian += "<p><b>Catatan Admin:</b> " + req.CatatanAdmin + "</p>"
			}
			if req.CatatanPsikolog != "" {
				rincian += "<p><b>Catatan Psikolog:</b> " + req.CatatanPsikolog + "</p>"
			}
		}

		emailBody := fmt.Sprintf(`
			<div style="font-family: Arial, sans-serif; color: #333;">
				<h2 style="color: #2F80ED;">Pembaruan Status Laporan</h2>
				<p>Halo, ada pembaruan pada laporan Anda dengan Kode Pelacakan <strong>%s</strong>.</p>
				<div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px; margin: 20px 0;">
					<p style="margin: 0;"><strong>Status Baru:</strong> <span style="color: #d32f2f; text-transform: uppercase;">%s</span></p>
					<p style="margin: 5px 0 0 0;">%s</p>
				</div>
				<div style="background-color: #fff3e0; padding: 15px; border-left: 4px solid #ff9800; margin: 20px 0;">
					<h4 style="margin: 0 0 10px 0;">Rincian:</h4>
					%s
				</div>
				<p>Gunakan aplikasi SIGAP untuk memantau detail lebih lanjut.</p>
				<br>
				<p>Salam hangat,<br><b>Tim Satgas SIGAP</b></p>
			</div>
		`, trackingCode, req.Status, msg, rincian)
		utils.SendEmail(targetEmail, emailSubject, emailBody)
	}

	if err := tx.Commit(); err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan perubahan ke database")
		return
	}

	utils.SuccessResponse(w, "Status laporan berhasil diperbarui", map[string]interface{}{
		"report_id":  req.ReportID,
		"new_status": req.Status,
		"updated_at": time.Now().Format(time.RFC3339),
	})
}

// ----------------------------------------------
// DOWNLOAD REPORT RECEIPT
// ----------------------------------------------

func HandleDownloadReportPDF(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	parts := strings.Split(r.URL.Path, "/")
	if len(parts) < 4 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid URL")
		return
	}
	// /api/reports/download/{id}
	reportIDStr := parts[len(parts)-1]
	reportID, err := strconv.Atoi(reportIDStr)
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid Report ID")
		return
	}

	// Ambil data laporan dari DB
	var trackingCode, jenisPenyintas, kategori, detail, status, createdAt string
	var userNama, userEmail string
	err = database.DB.QueryRow(`
		SELECT r.tracking_code, r.jenis_penyintas, r.kategori_kekhawatiran, 
		       r.detail_kejadian, r.status, r.created_at,
		       u.nama_lengkap, u.email
		FROM reports r JOIN users u ON r.user_id = u.id
		WHERE r.id = ?
	`, reportID).Scan(&trackingCode, &jenisPenyintas, &kategori, &detail, &status, &createdAt, &userNama, &userEmail)

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Laporan tidak ditemukan")
		return
	}

	// Cek akses: user biasa hanya boleh download laporan sendiri
	if claims.Role == "user" {
		var ownerID int
		database.DB.QueryRow("SELECT user_id FROM reports WHERE id = ?", reportID).Scan(&ownerID)
		if ownerID != claims.UserID {
			utils.ErrorResponse(w, http.StatusForbidden, "Anda tidak memiliki akses ke laporan ini")
			return
		}
	}

	// Kembalikan sebagai HTML yang bisa dicetak / disimpan
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`inline; filename="Laporan-%s.html"`, trackingCode))
	w.WriteHeader(http.StatusOK)

	html := fmt.Sprintf(`<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title>Bukti Laporan %s - SIGAP</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 800px; margin: 40px auto; color: #333; }
    .header { background: #c0392b; color: white; padding: 20px; text-align: center; border-radius: 8px; }
    .code-box { background: #f8f8f8; border: 2px solid #c0392b; padding: 15px; text-align: center; margin: 20px 0; border-radius: 6px; }
    .code { font-size: 28px; font-weight: bold; color: #c0392b; letter-spacing: 3px; }
    table { width: 100%%; border-collapse: collapse; margin: 20px 0; }
    td { padding: 10px 15px; border-bottom: 1px solid #eee; }
    td:first-child { font-weight: bold; width: 200px; background: #fafafa; }
    .status { display: inline-block; padding: 4px 12px; border-radius: 20px; background: #e8f5e9; color: #2e7d32; font-weight: bold; }
    .footer { text-align: center; margin-top: 30px; color: #888; font-size: 12px; }
    @media print { body { margin: 0; } }
  </style>
</head>
<body>
  <div class="header">
    <h1>SIGAP</h1>
    <p>Sistem Informasi Gawat Darurat &amp; Perlindungan</p>
  </div>
  <div class="code-box">
    <p style="margin:0;font-size:14px;color:#555;">Kode Pelacakan Laporan:</p>
    <div class="code">%s</div>
  </div>
  <table>
    <tr><td>ID Laporan</td><td>#%d</td></tr>
    <tr><td>Nama Pelapor</td><td>%s</td></tr>
    <tr><td>Email Pelapor</td><td>%s</td></tr>
    <tr><td>Jenis Penyintas</td><td>%s</td></tr>
    <tr><td>Kategori</td><td>%s</td></tr>
    <tr><td>Status Laporan</td><td><span class="status">%s</span></td></tr>
    <tr><td>Tanggal Laporan</td><td>%s</td></tr>
    <tr><td>Detail Kejadian</td><td style="white-space:pre-wrap;">%s</td></tr>
  </table>
  <div class="footer">
    <p>Dokumen ini diterbitkan otomatis oleh sistem SIGAP.<br>
    Simpan kode pelacakan ini sebagai bukti laporan Anda.<br>
    &copy; SIGAP — Sistem Darurat &amp; Perlindungan</p>
  </div>
</body>
</html>`,
		trackingCode, trackingCode, reportID,
		userNama, userEmail, jenisPenyintas, kategori, status, createdAt, detail,
	)
	fmt.Fprint(w, html)
}

