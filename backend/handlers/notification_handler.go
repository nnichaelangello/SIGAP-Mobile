package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"sigap-backend/database"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

// ──────────────────────────────────────────────
// GET NOTIFICATIONS
// ──────────────────────────────────────────────

func HandleGetNotifications(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	rows, err := database.DB.Query(`
		SELECT id, title, body, type, payload_json, is_read, created_at
		FROM notifications
		WHERE user_id = ?
		ORDER BY created_at DESC
		LIMIT 50
	`, claims.UserID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil notifikasi")
		return
	}
	defer rows.Close()

	var notifs []map[string]interface{}
	for rows.Next() {
		var id, isRead int
		var title, body, ntype, payload, createdAt string
		rows.Scan(&id, &title, &body, &ntype, &payload, &isRead, &createdAt)
		notifs = append(notifs, map[string]interface{}{
			"id":           id,
			"title":        title,
			"body":         body,
			"type":         ntype,
			"payload_json": payload,
			"is_read":      isRead == 1,
			"created_at":   createdAt,
		})
	}

	if notifs == nil {
		notifs = []map[string]interface{}{}
	}

	// Unread count
	var unreadCount int
	database.DB.QueryRow("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0", claims.UserID).Scan(&unreadCount)

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data":         notifs,
		"unread_count": unreadCount,
		"total":        len(notifs),
	})
}

// ──────────────────────────────────────────────
// MARK NOTIFICATION READ
// ──────────────────────────────────────────────

func HandleMarkNotificationRead(w http.ResponseWriter, r *http.Request) {
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
		NotificationID int  `json:"notification_id"`
		MarkAll        bool `json:"mark_all"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	if req.MarkAll {
		database.DB.Exec("UPDATE notifications SET is_read = 1 WHERE user_id = ?", claims.UserID)
	} else {
		database.DB.Exec("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?",
			req.NotificationID, claims.UserID)
	}

	utils.SuccessResponse(w, "Notifikasi ditandai sudah dibaca", nil)
}

// ══════════════════════════════════════════════════════════════
//                    DATABASE ADMIN API
// ══════════════════════════════════════════════════════════════

// validTables — whitelist tabel yang boleh diakses
var validTables = map[string]bool{
	"users": true, "reports": true, "emergency_incidents": true,
	"emergency_responses": true, "pantau_sessions": true,
	"pantau_heartbeats": true, "emergency_contacts": true,
	"chat_logs": true, "notifications": true, "audit_trail": true,
}

// ──────────────────────────────────────────────
// GET /api/database — List tables or table data
// ──────────────────────────────────────────────

func HandleDatabaseViewer(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	tableName := r.URL.Query().Get("table")
	if tableName == "" {
		// Return list of tables with row counts
		rows, err := database.DB.Query("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
		if err != nil {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil daftar tabel")
			return
		}
		defer rows.Close()

		var tables []map[string]interface{}
		for rows.Next() {
			var name string
			rows.Scan(&name)
			var count int
			database.DB.QueryRow("SELECT COUNT(*) FROM " + name).Scan(&count)
			tables = append(tables, map[string]interface{}{
				"name":  name,
				"count": count,
			})
		}

		if tables == nil {
			tables = []map[string]interface{}{}
		}

		utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
			"tables": tables,
		})
		return
	}

	if !validTables[tableName] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Tabel tidak valid")
		return
	}

	// Pagination
	page := 1
	limit := 100
	if p := r.URL.Query().Get("page"); p != "" {
		if v, err := strconv.Atoi(p); err == nil && v > 0 {
			page = v
		}
	}
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 && v <= 500 {
			limit = v
		}
	}
	offset := (page - 1) * limit

	// Search filter
	search := r.URL.Query().Get("search")

	// Total count
	var totalCount int
	database.DB.QueryRow("SELECT COUNT(*) FROM " + tableName).Scan(&totalCount)

	// Get table schema
	schemaRows, _ := database.DB.Query(fmt.Sprintf("PRAGMA table_info(%s)", tableName))
	var columns []map[string]interface{}
	var columnNames []string
	if schemaRows != nil {
		defer schemaRows.Close()
		for schemaRows.Next() {
			var cid int
			var name, ctype string
			var notnull, pk int
			var dfltValue interface{}
			schemaRows.Scan(&cid, &name, &ctype, &notnull, &dfltValue, &pk)
			columns = append(columns, map[string]interface{}{
				"name":       name,
				"type":       ctype,
				"notnull":    notnull == 1,
				"pk":         pk == 1,
				"default":    dfltValue,
			})
			columnNames = append(columnNames, name)
		}
	}

	// Build query with optional search
	query := "SELECT * FROM " + tableName
	var args []interface{}

	if search != "" && len(columnNames) > 0 {
		var conditions []string
		for _, col := range columnNames {
			conditions = append(conditions, fmt.Sprintf("CAST(%s AS TEXT) LIKE ?", col))
			args = append(args, "%"+search+"%")
		}
		query += " WHERE " + strings.Join(conditions, " OR ")
	}

	query += " ORDER BY id DESC LIMIT ? OFFSET ?"
	args = append(args, limit, offset)

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil data: "+err.Error())
		return
	}
	defer rows.Close()

	cols, _ := rows.Columns()
	var results []map[string]interface{}

	for rows.Next() {
		values := make([]interface{}, len(cols))
		valuePtrs := make([]interface{}, len(cols))
		for i := range values {
			valuePtrs[i] = &values[i]
		}
		rows.Scan(valuePtrs...)

		row := make(map[string]interface{})
		for i, col := range cols {
			val := values[i]
			if b, ok := val.([]byte); ok {
				row[col] = string(b)
			} else {
				row[col] = val
			}
		}
		results = append(results, row)
	}

	if results == nil {
		results = []map[string]interface{}{}
	}

	totalPages := (totalCount + limit - 1) / limit

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"table":       tableName,
		"columns":     columns,
		"column_names": columnNames,
		"data":        results,
		"total":       totalCount,
		"page":        page,
		"limit":       limit,
		"total_pages": totalPages,
	})
}

// ──────────────────────────────────────────────
// POST /api/database/insert — Insert row
// ──────────────────────────────────────────────

func HandleDatabaseInsert(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "admin" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya admin yang dapat mengubah database")
		return
	}

	var req struct {
		Table string                 `json:"table"`
		Data  map[string]interface{} `json:"data"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	if !validTables[req.Table] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Tabel tidak valid")
		return
	}

	if len(req.Data) == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Data tidak boleh kosong")
		return
	}

	var cols []string
	var placeholders []string
	var vals []interface{}
	for k, v := range req.Data {
		cols = append(cols, k)
		placeholders = append(placeholders, "?")
		vals = append(vals, v)
	}

	query := fmt.Sprintf("INSERT INTO %s (%s) VALUES (%s)",
		req.Table, strings.Join(cols, ","), strings.Join(placeholders, ","))

	result, err := database.DB.Exec(query, vals...)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal insert: "+err.Error())
		return
	}

	id, _ := result.LastInsertId()
	utils.JSONResponse(w, http.StatusCreated, map[string]interface{}{
		"message":     "Data berhasil ditambahkan",
		"inserted_id": id,
	})
}

// ──────────────────────────────────────────────
// PUT /api/database/update — Update row by ID
// ──────────────────────────────────────────────

func HandleDatabaseUpdate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "admin" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya admin yang dapat mengubah database")
		return
	}

	var req struct {
		Table string                 `json:"table"`
		ID    int                    `json:"id"`
		Data  map[string]interface{} `json:"data"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	if !validTables[req.Table] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Tabel tidak valid")
		return
	}

	if req.ID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "ID wajib diisi")
		return
	}

	var setClauses []string
	var vals []interface{}
	for k, v := range req.Data {
		setClauses = append(setClauses, k+" = ?")
		vals = append(vals, v)
	}
	vals = append(vals, req.ID)

	query := fmt.Sprintf("UPDATE %s SET %s WHERE id = ?",
		req.Table, strings.Join(setClauses, ", "))

	result, err := database.DB.Exec(query, vals...)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal update: "+err.Error())
		return
	}

	rowsAffected, _ := result.RowsAffected()
	utils.SuccessResponse(w, "Data berhasil diperbarui", map[string]interface{}{
		"rows_affected": rowsAffected,
	})
}

// ──────────────────────────────────────────────
// DELETE /api/database/delete — Delete row by ID
// ──────────────────────────────────────────────

func HandleDatabaseDelete(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost { // Pakai POST agar aman dari CSRF
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "admin" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya admin yang dapat mengubah database")
		return
	}

	var req struct {
		Table string `json:"table"`
		ID    int    `json:"id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	if !validTables[req.Table] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Tabel tidak valid")
		return
	}

	if req.ID == 0 {
		utils.ErrorResponse(w, http.StatusBadRequest, "ID wajib diisi")
		return
	}

	// ── Cascading manual untuk mengatasi Foreign Key Constraint di SQLite ──
	if req.Table == "reports" {
		database.DB.Exec("DELETE FROM audit_trail WHERE report_id = ?", req.ID)
		database.DB.Exec("DELETE FROM appointments WHERE report_id = ?", req.ID)
	} else if req.Table == "emergency_incidents" {
		database.DB.Exec("DELETE FROM emergency_responses WHERE incident_id = ?", req.ID)
		database.DB.Exec("DELETE FROM audit_trail WHERE incident_id = ?", req.ID)
		// Hapus juga audios berdasarkan incident_id string
		var incidentStr string
		database.DB.QueryRow("SELECT incident_id FROM emergency_incidents WHERE id = ?", req.ID).Scan(&incidentStr)
		if incidentStr != "" {
			database.DB.Exec("DELETE FROM emergency_audios WHERE incident_id = ?", incidentStr)
		}
	} else if req.Table == "users" {
		// Proteksi dasar agar tidak langsung menghapus user yang punya relasi vital
		var count int
		database.DB.QueryRow("SELECT count(*) FROM reports WHERE user_id = ?", req.ID).Scan(&count)
		if count > 0 {
			utils.ErrorResponse(w, http.StatusBadRequest, "Gagal delete: User ini memiliki laporan aktif. Hapus laporannya terlebih dahulu.")
			return
		}
	}

	result, err := database.DB.Exec("DELETE FROM "+req.Table+" WHERE id = ?", req.ID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal delete: "+err.Error())
		return
	}

	rowsAffected, _ := result.RowsAffected()
	utils.SuccessResponse(w, "Data berhasil dihapus", map[string]interface{}{
		"rows_affected": rowsAffected,
	})
}

// ──────────────────────────────────────────────
// POST /api/database/query — Execute raw SQL (readonly)
// ──────────────────────────────────────────────

func HandleDatabaseQuery(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil || claims.Role != "admin" {
		utils.ErrorResponse(w, http.StatusForbidden, "Hanya admin yang dapat menjalankan query")
		return
	}

	var req struct {
		SQL string `json:"sql"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	req.SQL = strings.TrimSpace(req.SQL)
	if req.SQL == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "SQL query tidak boleh kosong")
		return
	}

	// Hanya izinkan SELECT dan PRAGMA (readonly)
	upper := strings.ToUpper(req.SQL)
	if !strings.HasPrefix(upper, "SELECT") && !strings.HasPrefix(upper, "PRAGMA") {
		utils.ErrorResponse(w, http.StatusBadRequest, "Hanya SELECT dan PRAGMA query yang diizinkan")
		return
	}

	rows, err := database.DB.Query(req.SQL)
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	cols, _ := rows.Columns()
	var results []map[string]interface{}

	for rows.Next() {
		values := make([]interface{}, len(cols))
		valuePtrs := make([]interface{}, len(cols))
		for i := range values {
			valuePtrs[i] = &values[i]
		}
		rows.Scan(valuePtrs...)

		row := make(map[string]interface{})
		for i, col := range cols {
			val := values[i]
			if b, ok := val.([]byte); ok {
				row[col] = string(b)
			} else {
				row[col] = val
			}
		}
		results = append(results, row)
	}

	if results == nil {
		results = []map[string]interface{}{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"columns": cols,
		"data":    results,
		"total":   len(results),
		"query":   req.SQL,
	})
}
