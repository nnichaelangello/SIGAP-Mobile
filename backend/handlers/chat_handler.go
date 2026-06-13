package handlers

import (
	"encoding/json"
	"net/http"

	"sigap-backend/database"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

// ──────────────────────────────────────────────
// SAVE CHAT LOG
// ──────────────────────────────────────────────

func HandleSaveChatLog(w http.ResponseWriter, r *http.Request) {
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
		Role    string `json:"role"` // "user" or "assistant"
		Content string `json:"content"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
		return
	}

	if req.Content == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Content wajib diisi")
		return
	}

	// Validasi role — hanya user/assistant yang diizinkan
	if req.Role != "user" && req.Role != "assistant" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Role chat harus 'user' atau 'assistant'")
		return
	}

	_, err := database.DB.Exec(`
		INSERT INTO chat_logs (user_id, role, content)
		VALUES (?, ?, ?)
	`, claims.UserID, req.Role, req.Content)

	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan chat log")
		return
	}

	utils.SuccessResponse(w, "Chat log disimpan", nil)
}

// ──────────────────────────────────────────────
// GET CHAT HISTORY
// ──────────────────────────────────────────────

func HandleGetChatHistory(w http.ResponseWriter, r *http.Request) {
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
		SELECT id, role, content, created_at
		FROM chat_logs
		WHERE user_id = ?
		ORDER BY created_at ASC
		LIMIT 200
	`, claims.UserID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil chat history")
		return
	}
	defer rows.Close()

	var logs []map[string]interface{}
	for rows.Next() {
		var id int
		var role, content, createdAt string
		rows.Scan(&id, &role, &content, &createdAt)
		logs = append(logs, map[string]interface{}{
			"id":         id,
			"role":       role,
			"content":    content,
			"created_at": createdAt,
		})
	}

	if logs == nil {
		logs = []map[string]interface{}{}
	}

	utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
		"data":  logs,
		"total": len(logs),
	})
}

// ──────────────────────────────────────────────
// EMERGENCY CONTACTS CRUD
// ──────────────────────────────────────────────

func HandleEmergencyContacts(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	switch r.Method {
	case http.MethodGet:
		rows, err := database.DB.Query(`
			SELECT id, nama, no_hp, hubungan, created_at
			FROM emergency_contacts
			WHERE user_id = ?
			ORDER BY created_at ASC
		`, claims.UserID)
		if err != nil {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal mengambil kontak darurat")
			return
		}
		defer rows.Close()

		var contacts []map[string]interface{}
		for rows.Next() {
			var id int
			var nama, noHP, hubungan, createdAt string
			rows.Scan(&id, &nama, &noHP, &hubungan, &createdAt)
			contacts = append(contacts, map[string]interface{}{
				"id":         id,
				"nama":       nama,
				"no_hp":      noHP,
				"hubungan":   hubungan,
				"created_at": createdAt,
			})
		}
		if contacts == nil {
			contacts = []map[string]interface{}{}
		}
		utils.JSONResponse(w, http.StatusOK, map[string]interface{}{
			"data":  contacts,
			"total": len(contacts),
		})

	case http.MethodPost:
		var req struct {
			Nama     string `json:"nama"`
			NoHP     string `json:"no_hp"`
			Hubungan string `json:"hubungan"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
			return
		}
		if req.Nama == "" || req.NoHP == "" {
			utils.ErrorResponse(w, http.StatusBadRequest, "Nama dan No HP wajib diisi")
			return
		}

		result, err := database.DB.Exec(`
			INSERT INTO emergency_contacts (user_id, nama, no_hp, hubungan)
			VALUES (?, ?, ?, ?)
		`, claims.UserID, req.Nama, req.NoHP, req.Hubungan)
		if err != nil {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menambah kontak darurat")
			return
		}
		contactID, _ := result.LastInsertId()
		utils.JSONResponse(w, http.StatusCreated, map[string]interface{}{
			"message":    "Kontak darurat ditambahkan",
			"contact_id": contactID,
		})

	case http.MethodDelete:
		var req struct {
			ContactID int `json:"contact_id"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			utils.ErrorResponse(w, http.StatusBadRequest, "Format request tidak valid")
			return
		}
		database.DB.Exec("DELETE FROM emergency_contacts WHERE id = ? AND user_id = ?",
			req.ContactID, claims.UserID)
		utils.SuccessResponse(w, "Kontak darurat dihapus", nil)

	default:
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
	}
}
