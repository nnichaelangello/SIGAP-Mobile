package handlers

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"sigap-backend/database"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

// HandleAudioUpload menerima file audio recording dari SOS
func HandleAudioUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	// Parse multipart form (max 50MB)
	err := r.ParseMultipartForm(50 << 20)
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "File terlalu besar (max 50MB)")
		return
	}

	file, header, err := r.FormFile("audio")
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "File audio tidak ditemukan dalam request")
		return
	}
	defer file.Close()

	incidentID := r.FormValue("incident_id")

	// Validasi tipe konten sebenarnya menggunakan 512 byte pertama file
	buffer := make([]byte, 512)
	file.Read(buffer)
	// Kembalikan pointer file ke awal setelah dibaca
	file.Seek(0, io.SeekStart)

	contentType := http.DetectContentType(buffer)
	ext := strings.ToLower(filepath.Ext(header.Filename))

	// Jika tidak ada ekstensi atau ekstensi generik, coba tebak dari contentType
	if ext == "" || ext == ".tmp" || ext == ".bin" {
		if strings.Contains(contentType, "audio/mpeg") {
			ext = ".mp3"
		} else if strings.Contains(contentType, "audio/wav") || strings.Contains(contentType, "audio/x-wav") {
			ext = ".wav"
		} else if strings.Contains(contentType, "audio/aac") {
			ext = ".aac"
		} else if strings.Contains(contentType, "audio/ogg") {
			ext = ".ogg"
		} else if strings.Contains(contentType, "video/webm") || strings.Contains(contentType, "audio/webm") {
			ext = ".webm"
		} else if strings.Contains(contentType, "audio/mp4") || strings.Contains(contentType, "video/mp4") {
			ext = ".m4a" // m4a is audio-only mp4
		} else {
			ext = ".m4a" // fallback default
		}
	}

	// Validasi ekstensi akhir
	allowedAudio := map[string]bool{".m4a": true, ".mp3": true, ".wav": true, ".aac": true, ".ogg": true, ".webm": true}
	if !allowedAudio[ext] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Tipe file audio tidak didukung")
		return
	}
	filename := fmt.Sprintf("sos_audio_%d_%s%s", claims.UserID, time.Now().Format("20060102_150405"), ext)
	audioDir := "audio_records"
	os.MkdirAll(audioDir, 0755)
	savePath := filepath.Join(audioDir, filename)

	// Simpan file
	dst, err := os.Create(savePath)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan file audio")
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menulis file audio")
		return
	}

	// Insert audio chunk ke emergency_audios jika ada incident_id
	if incidentID != "" {
		// Gunakan forward slash agar bisa diakses langsung via URL /audio_records/filename
		dbPath := "audio_records/" + filename
		
		_, errDB := database.DB.Exec(`
			INSERT INTO emergency_audios (incident_id, file_path) VALUES (?, ?)
		`, incidentID, dbPath)
		
		if errDB != nil {
			log.Printf("[ERROR] Gagal insert emergency_audios: %v", errDB)
		}
		
		// Update juga audio_path terakhir di emergency_incidents (untuk backward compatibility)
		database.DB.Exec(`
			UPDATE emergency_incidents SET audio_path = ? WHERE incident_id = ?
		`, dbPath, incidentID)
	}

	utils.SuccessResponse(w, "Audio berhasil diupload", map[string]interface{}{
		"filename": filename,
		"path":     savePath,
		"size":     header.Size,
	})
}

// HandleFileUpload menerima file bukti laporan
func HandleFileUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		return
	}

	claims := middleware.GetUserClaims(r)
	if claims == nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	err := r.ParseMultipartForm(20 << 20) // max 20MB
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "File terlalu besar (max 20MB)")
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "File tidak ditemukan dalam request")
		return
	}
	defer file.Close()

	ext := strings.ToLower(filepath.Ext(header.Filename))
	// Validasi tipe file — hanya gambar, PDF, dokumen
	allowedFiles := map[string]bool{
		".jpg": true, ".jpeg": true, ".png": true, ".gif": true, ".webp": true,
		".pdf": true, ".doc": true, ".docx": true, ".txt": true,
		".mp4": true, ".mov": true, ".avi": true,
	}
	if !allowedFiles[ext] {
		utils.ErrorResponse(w, http.StatusBadRequest, "Tipe file tidak didukung. Gunakan gambar, PDF, dokumen, atau video.")
		return
	}
	filename := fmt.Sprintf("bukti_%d_%s%s", claims.UserID, time.Now().Format("20060102_150405"), ext)
	uploadDir := "uploads"
	os.MkdirAll(uploadDir, 0755)
	savePath := filepath.Join(uploadDir, filename)

	dst, err := os.Create(savePath)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menyimpan file")
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Gagal menulis file")
		return
	}

	utils.SuccessResponse(w, "File berhasil diupload", map[string]interface{}{
		"filename": filename,
		"path":     savePath,
		"size":     header.Size,
	})
}
