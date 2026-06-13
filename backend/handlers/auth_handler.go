package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"sigap-backend/database"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

// ──────────────────────────────────────────────
// REQUEST / RESPONSE MODELS
// ──────────────────────────────────────────────

type RegisterRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	NamaLengkap string `json:"nama_lengkap"`
	SubRole     string `json:"sub_role"` // mahasiswa, dosen, karyawan
	NimNidnNik  string `json:"nim_nidn_nik"`
	NoHP        string `json:"no_hp"`
	ProdiUnit   string `json:"prodi_unit"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Token string      `json:"token"`
	User  UserProfile `json:"user"`
}

type UserProfile struct {
	ID          int    `json:"id"`
	Email       string `json:"email"`
	NamaLengkap string `json:"nama_lengkap"`
	Role        string `json:"role"`
	SubRole     string `json:"sub_role"`
	NimNidnNik  string `json:"nim_nidn_nik"`
	NoHP        string `json:"no_hp"`
	ProdiUnit   string `json:"prodi_unit"`
	AvatarURL   string `json:"avatar_url"`
	CreatedAt   string `json:"created_at"`
}

// ──────────────────────────────────────────────
// REGISTER
// ──────────────────────────────────────────────

func HandleRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	// Validasi
	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || req.Password == "" || req.NamaLengkap == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Email, password, dan nama lengkap wajib diisi")
		return
	}
	if len(req.Password) < 4 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Password minimal 4 karakter")
		return
	}
	if !strings.Contains(req.Email, "@") {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format email tidak valid")
		return
	}

	// Validasi sub_role
	validSubRoles := map[string]bool{"mahasiswa": true, "dosen": true, "karyawan": true, "": true}
	if !validSubRoles[req.SubRole] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Sub-role tidak valid")
		return
	}

	// Cek email duplikat
	var count int
	database.DB.QueryRow("SELECT COUNT(*) FROM users WHERE email = ?", req.Email).Scan(&count)
	if count > 0 {
		utils.ErrorResponse(w, http.StatusConflict, "Email sudah terdaftar")
		return
	}

	// Hash password
	hash, err := utils.HashPassword(req.Password)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal memproses password")
		return
	}

	// Insert user
	result, err := database.DB.Exec(`
		INSERT INTO users (email, password_hash, nama_lengkap, role, sub_role, nim_nidn_nik, no_hp, prodi_unit)
		VALUES (?, ?, ?, 'user', ?, ?, ?, ?)
	`, req.Email, hash, req.NamaLengkap, req.SubRole, req.NimNidnNik, req.NoHP, req.ProdiUnit)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mendaftarkan user")
		return
	}

	userID, _ := result.LastInsertId()

	// Generate token
	token, err := utils.GenerateToken(int(userID), req.Email, "user")
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal membuat token")
		return
	}

	utils.JSONResponse(w, http.StatusCreated, AuthResponse{
		Token: token,
		User: UserProfile{
			ID:          int(userID),
			Email:       req.Email,
			NamaLengkap: req.NamaLengkap,
			Role:        "user",
			SubRole:     req.SubRole,
			NimNidnNik:  req.NimNidnNik,
			NoHP:        req.NoHP,
			ProdiUnit:   req.ProdiUnit,
			CreatedAt:   time.Now().Format(time.RFC3339),
		},
	})
}

// ──────────────────────────────────────────────
// LOGIN
// ──────────────────────────────────────────────

func HandleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || req.Password == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Email dan password wajib diisi")
		return
	}

	// Cari user
	var user struct {
		ID           int
		Email        string
		PasswordHash string
		NamaLengkap  string
		Role         string
		SubRole      string
		NimNidnNik   string
		NoHP         string
		ProdiUnit    string
		AvatarURL    string
		IsActive     int
		CreatedAt    string
	}

	err := database.DB.QueryRow(`
		SELECT id, email, password_hash, nama_lengkap, role, sub_role,
		       nim_nidn_nik, no_hp, prodi_unit, avatar_url, is_active, created_at
		FROM users WHERE email = ?
	`, req.Email).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.NamaLengkap,
		&user.Role, &user.SubRole, &user.NimNidnNik, &user.NoHP,
		&user.ProdiUnit, &user.AvatarURL, &user.IsActive, &user.CreatedAt,
	)

	if err != nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Email atau password salah")
		return
	}

	if user.IsActive == 0 {
		utils.ErrorResponse(w, http.StatusForbidden, "Akun dinonaktifkan")
		return
	}

	// Verifikasi password
	if !utils.CheckPassword(req.Password, user.PasswordHash) {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Email atau password salah")
		return
	}

	// Generate token
	token, err := utils.GenerateToken(user.ID, user.Email, user.Role)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal membuat token")
		return
	}

	utils.JSONResponse(w, http.StatusOK, AuthResponse{
		Token: token,
		User: UserProfile{
			ID:          user.ID,
			Email:       user.Email,
			NamaLengkap: user.NamaLengkap,
			Role:        user.Role,
			SubRole:     user.SubRole,
			NimNidnNik:  user.NimNidnNik,
			NoHP:        user.NoHP,
			ProdiUnit:   user.ProdiUnit,
			AvatarURL:   user.AvatarURL,
			CreatedAt:   user.CreatedAt,
		},
	})
}

// ──────────────────────────────────────────────
// GET PROFILE (ME)
// ──────────────────────────────────────────────

func HandleMe(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var user UserProfile
	err := database.DB.QueryRow(`
		SELECT id, email, nama_lengkap, role, sub_role, nim_nidn_nik, no_hp, prodi_unit, avatar_url, created_at
		FROM users WHERE id = ? AND is_active = 1
	`, claims.UserID).Scan(
		&user.ID, &user.Email, &user.NamaLengkap, &user.Role, &user.SubRole,
		&user.NimNidnNik, &user.NoHP, &user.ProdiUnit, &user.AvatarURL, &user.CreatedAt,
	)

	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "User tidak ditemukan")
		return
	}

	utils.SuccessResponse(w, "OK", user)
}

// ──────────────────────────────────────────────
// UPDATE PROFILE
// ──────────────────────────────────────────────

func HandleUpdateProfile(w http.ResponseWriter, r *http.Request) {
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
		NamaLengkap string `json:"nama_lengkap"`
		NoHP        string `json:"no_hp"`
		ProdiUnit   string `json:"prodi_unit"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	_, err := database.DB.Exec(`
		UPDATE users SET nama_lengkap = ?, no_hp = ?, prodi_unit = ?, updated_at = CURRENT_TIMESTAMP
		WHERE id = ?
	`, req.NamaLengkap, req.NoHP, req.ProdiUnit, claims.UserID)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal update profil")
		return
	}

	utils.SuccessResponse(w, "Profil berhasil diperbarui", nil)
}

// ──────────────────────────────────────────────
// LIST USERS (Admin only)
// ──────────────────────────────────────────────

func HandleListUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	roleFilter := r.URL.Query().Get("role")

	query := "SELECT id, email, nama_lengkap, role, sub_role, nim_nidn_nik, no_hp, prodi_unit, is_active, created_at FROM users"
	var args []interface{}

	if roleFilter != "" {
		query += " WHERE role = ?"
		args = append(args, roleFilter)
	}
	query += " ORDER BY created_at DESC"

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil data users")
		return
	}
	defer rows.Close()

	var users []map[string]interface{}
	for rows.Next() {
		var id, isActive int
		var email, nama, role, subRole, nim, hp, prodi, createdAt string
		rows.Scan(&id, &email, &nama, &role, &subRole, &nim, &hp, &prodi, &isActive, &createdAt)
		users = append(users, map[string]interface{}{
			"id":           id,
			"email":        email,
			"nama_lengkap": nama,
			"role":         role,
			"sub_role":     subRole,
			"nim_nidn_nik": nim,
			"no_hp":        hp,
			"prodi_unit":   prodi,
			"is_active":    isActive == 1,
			"created_at":   createdAt,
		})
	}

	if users == nil {
		users = []map[string]interface{}{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data":  users,
		"total": len(users),
	})
}

// ──────────────────────────────────────────────
// DASHBOARD STATS (Admin)
// ──────────────────────────────────────────────

func HandleDashboardStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	stats := make(map[string]interface{})

	// ── Users stats ──
	var totalUsers, totalAdmin, totalPsikolog, activeUsers int
	database.DB.QueryRow("SELECT COUNT(*) FROM users WHERE role='user'").Scan(&totalUsers)
	database.DB.QueryRow("SELECT COUNT(*) FROM users WHERE role='admin'").Scan(&totalAdmin)
	database.DB.QueryRow("SELECT COUNT(*) FROM users WHERE role='psikolog'").Scan(&totalPsikolog)
	database.DB.QueryRow("SELECT COUNT(*) FROM users WHERE is_active = 1").Scan(&activeUsers)

	// ── Reports stats ──
	var totalReports, pendingReports, acceptedReports, processedReports, completedReports, rejectedReports int
	database.DB.QueryRow("SELECT COUNT(*) FROM reports").Scan(&totalReports)
	database.DB.QueryRow("SELECT COUNT(*) FROM reports WHERE status='pending'").Scan(&pendingReports)
	database.DB.QueryRow("SELECT COUNT(*) FROM reports WHERE status='diterima'").Scan(&acceptedReports)
	database.DB.QueryRow("SELECT COUNT(*) FROM reports WHERE status='diproses'").Scan(&processedReports)
	database.DB.QueryRow("SELECT COUNT(*) FROM reports WHERE status='selesai'").Scan(&completedReports)
	database.DB.QueryRow("SELECT COUNT(*) FROM reports WHERE status='ditolak'").Scan(&rejectedReports)

	// ── Emergency stats ──
	var activeEmergencies, respondingEmergencies, resolvedEmergencies, totalEmergencies int
	database.DB.QueryRow("SELECT COUNT(*) FROM emergency_incidents WHERE status='active'").Scan(&activeEmergencies)
	database.DB.QueryRow("SELECT COUNT(*) FROM emergency_incidents WHERE status='responding'").Scan(&respondingEmergencies)
	database.DB.QueryRow("SELECT COUNT(*) FROM emergency_incidents WHERE status='resolved'").Scan(&resolvedEmergencies)
	database.DB.QueryRow("SELECT COUNT(*) FROM emergency_incidents").Scan(&totalEmergencies)

	// ── Pantau stats ──
	var activePantau, totalPantau, emergencyPantau int
	database.DB.QueryRow("SELECT COUNT(*) FROM pantau_sessions WHERE status='active'").Scan(&activePantau)
	database.DB.QueryRow("SELECT COUNT(*) FROM pantau_sessions").Scan(&totalPantau)
	database.DB.QueryRow("SELECT COUNT(*) FROM pantau_sessions WHERE status='emergency'").Scan(&emergencyPantau)

	// ── Today's activity ──
	today := time.Now().Format("2006-01-02")
	var todayReports, todayEmergencies, todayRegistrations int
	database.DB.QueryRow("SELECT COUNT(*) FROM reports WHERE DATE(created_at) = ?", today).Scan(&todayReports)
	database.DB.QueryRow("SELECT COUNT(*) FROM emergency_incidents WHERE DATE(created_at) = ?", today).Scan(&todayEmergencies)
	database.DB.QueryRow("SELECT COUNT(*) FROM users WHERE DATE(created_at) = ?", today).Scan(&todayRegistrations)

	stats["users"] = map[string]int{
		"total":    totalUsers + totalAdmin + totalPsikolog,
		"user":     totalUsers,
		"admin":    totalAdmin,
		"psikolog": totalPsikolog,
		"active":   activeUsers,
	}
	stats["reports"] = map[string]int{
		"total":     totalReports,
		"pending":   pendingReports,
		"accepted":  acceptedReports,
		"processed": processedReports,
		"completed": completedReports,
		"rejected":  rejectedReports,
	}
	stats["emergency"] = map[string]int{
		"active":     activeEmergencies,
		"responding": respondingEmergencies,
		"resolved":   resolvedEmergencies,
		"total":      totalEmergencies,
	}
	stats["pantau"] = map[string]int{
		"active":    activePantau,
		"emergency": emergencyPantau,
		"total":     totalPantau,
	}
	stats["today"] = map[string]int{
		"reports":       todayReports,
		"emergencies":   todayEmergencies,
		"registrations": todayRegistrations,
	}

	utils.JSONResponse(w, http.StatusOK, stats)
}

// ──────────────────────────────────────────────
// CHANGE PASSWORD
// ──────────────────────────────────────────────

func HandleChangePassword(w http.ResponseWriter, r *http.Request) {
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
		OldPassword string `json:"old_password"`
		NewPassword string `json:"new_password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	if req.OldPassword == "" || req.NewPassword == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Password lama dan baru wajib diisi")
		return
	}

	if len(req.NewPassword) < 8 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Password baru minimal 8 karakter")
		return
	}

	// 1. Fetch current password hash from DB
	var currentHash string
	err := database.DB.QueryRow("SELECT password_hash FROM users WHERE id = ?", claims.UserID).Scan(&currentHash)
	if err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "User tidak ditemukan")
		return
	}

	// 2. Verify old password
	if !utils.CheckPassword(req.OldPassword, currentHash) {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Password lama tidak sesuai")
		return
	}

	// 3. Hash new password
	newHash, err := utils.HashPassword(req.NewPassword)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal memproses password baru")
		return
	}

	// 4. Update database
	_, err = database.DB.Exec("UPDATE users SET password_hash = ? WHERE id = ?", newHash, claims.UserID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengubah password")
		return
	}

	utils.SuccessResponse(w, "Password berhasil diubah", nil)
}
