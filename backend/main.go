package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"sigap-backend/config"
	"sigap-backend/database"
	"sigap-backend/handlers"
	"sigap-backend/middleware"
	"sigap-backend/utils"
)

func main() {
	cfg := config.DefaultConfig()

	// Init JWT
	utils.InitJWT(cfg.JWTSecret)

	// Init database
	if err := database.InitDB(cfg.DBPath); err != nil {
		log.Fatalf("❌ Gagal inisialisasi database: %v", err)
	}
	defer database.Close()

	// Seed default accounts
	if err := database.SeedDefaultAccounts(); err != nil {
		log.Printf("⚠️ Gagal seed akun default: %v", err)
	}

	// Buat directory upload dan audio
	os.MkdirAll(cfg.UploadDir, 0755)
	os.MkdirAll(cfg.AudioDir, 0755)

	// Setup router
	mux := http.NewServeMux()

	// ══════════════════════════════════════════
	// AUTH ROUTES (public)
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/auth/register", handlers.HandleRegister)
	mux.HandleFunc("/api/auth/login", handlers.HandleLogin)

	// ══════════════════════════════════════════
	// AUTH ROUTES (protected)
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/auth/me", middleware.Auth(handlers.HandleMe))
	mux.HandleFunc("/api/auth/profile", middleware.Auth(handlers.HandleUpdateProfile))
	mux.HandleFunc("/api/auth/change-password", middleware.Auth(handlers.HandleChangePassword))

	// ══════════════════════════════════════════
	// USER ROUTES (admin only)
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/users", middleware.AdminOnly(handlers.HandleListUsers))

	// ══════════════════════════════════════════
	// DASHBOARD STATS (staff only)
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/dashboard/stats", middleware.StaffOnly(handlers.HandleDashboardStats))

	// ══════════════════════════════════════════
	// REPORT ROUTES
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/reports", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPost:
			middleware.Auth(handlers.HandleSubmitReport)(w, r)
		case http.MethodGet:
			middleware.Auth(handlers.HandleListReports)(w, r)
		default:
			utils.ErrorResponse(w, http.StatusMethodNotAllowed, "Method tidak diizinkan")
		}
	})
	mux.HandleFunc("/api/reports/", middleware.Auth(handlers.HandleGetReport))
	mux.HandleFunc("/api/reports/download/", middleware.Auth(handlers.HandleDownloadReportPDF))
	mux.HandleFunc("/api/reports/status", middleware.StaffOnly(handlers.HandleUpdateReportStatus))

	// ══════════════════════════════════════════
	// SCHEDULE & APPOINTMENT ROUTES
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/schedules/psikolog", middleware.Auth(handlers.HandlePsikologSchedules))
	mux.HandleFunc("/api/appointments/initiate", middleware.AdminOnly(handlers.HandleInitiateAppointment))
	mux.HandleFunc("/api/appointments/select", middleware.Auth(handlers.HandleSelectAppointment))
	mux.HandleFunc("/api/appointments/respond", middleware.Auth(handlers.HandleRespondAppointment))
	mux.HandleFunc("/api/appointments/cancel", middleware.Auth(handlers.HandleCancelAppointment))
	mux.HandleFunc("/api/appointments/noshow", middleware.Auth(handlers.HandleMarkNoShow))
	mux.HandleFunc("/api/appointments/complete", middleware.Auth(handlers.HandleCompleteSession))
	mux.HandleFunc("/api/appointments", middleware.Auth(handlers.HandleListAppointments))

	// ══════════════════════════════════════════
	// SESSION NOTES, FEEDBACK & CONSULTATION
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/reports/request-consultation", middleware.Auth(handlers.HandleRequestConsultation))
	mux.HandleFunc("/api/session-notes", middleware.Auth(handlers.HandleSessionNote))
	mux.HandleFunc("/api/session-feedback", middleware.Auth(handlers.HandleSessionFeedback))
	mux.HandleFunc("/api/psikolog/unavailability", middleware.Auth(handlers.HandlePsikologUnavailability))
	mux.HandleFunc("/api/dashboard/stats-psikolog", middleware.Auth(handlers.HandlePsikologDashboardStats))

	// ══════════════════════════════════════════
	// EMERGENCY ROUTES
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/emergency/sos", middleware.Auth(handlers.HandleSOS))
	mux.HandleFunc("/api/emergency/cancel", middleware.Auth(handlers.HandleCancelEmergency))
	mux.HandleFunc("/api/emergency/pending", middleware.Auth(handlers.HandlePendingEmergencies))
	mux.HandleFunc("/api/emergency/respond", middleware.Auth(handlers.HandleRespondEmergency))
	mux.HandleFunc("/api/emergency/heartbeat", middleware.Auth(handlers.HandleEmergencyHeartbeat))
	mux.HandleFunc("/api/emergency/audio", middleware.Auth(handlers.HandleGetEmergencyAudio))
	mux.HandleFunc("/api/emergency/responder-location", middleware.Auth(handlers.HandleUpdateResponderLocation))
	mux.HandleFunc("/api/emergency/resolve", middleware.Auth(handlers.HandleResolveEmergency))
	// GET /api/emergency/{id}/location
	mux.HandleFunc("/api/emergency/", middleware.Auth(handlers.HandleGetEmergencyLocation))

	// ══════════════════════════════════════════
	// PANTAU ROUTES
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/pantau/start", middleware.Auth(handlers.HandleStartPantau))
	mux.HandleFunc("/api/pantau/heartbeat", middleware.Auth(handlers.HandlePantauHeartbeat))
	mux.HandleFunc("/api/pantau/checkin", middleware.Auth(handlers.HandlePantauCheckin))
	mux.HandleFunc("/api/pantau/emergency", middleware.Auth(handlers.HandlePantauEmergency))
	mux.HandleFunc("/api/pantau/stop", middleware.Auth(handlers.HandleStopPantau))
	mux.HandleFunc("/api/pantau/active", middleware.Auth(handlers.HandleActivePantau))

	// ══════════════════════════════════════════
	// NOTIFICATION ROUTES
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/notifications", middleware.Auth(handlers.HandleGetNotifications))
	mux.HandleFunc("/api/notifications/read", middleware.Auth(handlers.HandleMarkNotificationRead))

	// ══════════════════════════════════════════
	// DATABASE VIEWER (admin only)
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/database", middleware.AdminOnly(handlers.HandleDatabaseViewer))
	mux.HandleFunc("/api/database/insert", middleware.AdminOnly(handlers.HandleDatabaseInsert))
	mux.HandleFunc("/api/database/update", middleware.AdminOnly(handlers.HandleDatabaseUpdate))
	mux.HandleFunc("/api/database/delete", middleware.AdminOnly(handlers.HandleDatabaseDelete))
	mux.HandleFunc("/api/database/query", middleware.AdminOnly(handlers.HandleDatabaseQuery))

	// ══════════════════════════════════════════
	// UPLOAD ROUTES
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/upload/audio", middleware.Auth(handlers.HandleAudioUpload))
	mux.HandleFunc("/api/upload/file", middleware.Auth(handlers.HandleFileUpload))

	// ══════════════════════════════════════════
	// CHAT & CONTACTS ROUTES
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/chat/logs", middleware.Auth(handlers.HandleSaveChatLog))
	mux.HandleFunc("/api/chat/history", middleware.Auth(handlers.HandleGetChatHistory))
	mux.HandleFunc("/api/contacts", middleware.Auth(handlers.HandleEmergencyContacts))

	// ══════════════════════════════════════════
	// STATIC FILE SERVING (uploads & audio)
	// ══════════════════════════════════════════
	mux.Handle("/uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir("uploads"))))
	mux.Handle("/audio_records/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, ".m4a") {
			w.Header().Set("Content-Type", "audio/mp4")
		} else if strings.HasSuffix(r.URL.Path, ".mp3") {
			w.Header().Set("Content-Type", "audio/mpeg")
		} else if strings.HasSuffix(r.URL.Path, ".wav") {
			w.Header().Set("Content-Type", "audio/wav")
		}
		http.StripPrefix("/audio_records/", http.FileServer(http.Dir("audio_records"))).ServeHTTP(w, r)
	}))

	// ══════════════════════════════════════════
	// HEALTH CHECK (public)
	// ══════════════════════════════════════════
	mux.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		utils.JSONResponse(w, http.StatusOK, map[string]string{
			"status":  "ok",
			"service": "sigap-backend",
		})
	})

	// ══════════════════════════════════════════
	// DB ADMIN WEBSITE (separate site)
	// ══════════════════════════════════════════
	dbAdminDir := "../db-admin"
	if _, err := os.Stat(dbAdminDir); err == nil {
		mux.Handle("/db-admin/", http.StripPrefix("/db-admin/", http.FileServer(http.Dir(dbAdminDir))))
		log.Println("[Web] DB Admin tersedia di http://localhost:" + cfg.Port + "/db-admin/")
	}

	// ══════════════════════════════════════════
	// WEB DASHBOARD (static files)
	// ══════════════════════════════════════════
	webDir := "../web-dashboard"
	if _, err := os.Stat(webDir); err == nil {
		fs := http.FileServer(http.Dir(webDir))
		mux.Handle("/", fs)
		log.Println("[Web] Dashboard Admin tersedia di http://localhost:" + cfg.Port)
	} else {
		mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path == "/" {
				w.Header().Set("Content-Type", "text/html")
				w.Write([]byte("<h1>SIGAP Server</h1><p>Web dashboard belum tersedia.</p>"))
			}
		})
	}

	// ══════════════════════════════════════════
	// PSIKOLOG PORTAL (static files)
	// ══════════════════════════════════════════
	psikologDir := "../psikolog-portal"
	if _, err := os.Stat(psikologDir); err == nil {
		mux.Handle("/psikolog/", http.StripPrefix("/psikolog/", http.FileServer(http.Dir(psikologDir))))
		log.Println("[Web] Psikolog Portal tersedia di http://localhost:" + cfg.Port + "/psikolog/")
	}

	// Apply middleware chain
	handler := middleware.CORS(middleware.Logger(mux))

	// Print info
	cfg.PrintServerInfo()

	// ── Background Worker: Pantau Server-Side Timeout ──
	// Cek setiap menit apakah ada sesi pantau yang melewati batas waktu.
	// Ini krusial untuk kasus di mana app user mati/offline.
	go func() {
		ticker := time.NewTicker(1 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			handlers.CheckPantauTimeouts()
		}
	}()

	// ── Background Worker: Session Reminder (H-24 dan H-1 jam) ──
	// Cek setiap 30 menit apakah ada sesi yang perlu pengingat.
	go func() {
		ticker := time.NewTicker(30 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			handlers.CheckSessionReminders()
		}
	}()

	// ── Background Worker: Eskalasi laporan tidak direspons > 48 jam ──
	go func() {
		ticker := time.NewTicker(1 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			handlers.CheckOverdueReports()
		}
	}()

	// Graceful shutdown
	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
		<-sigChan
		fmt.Println("\n🛑 Shutting down server...")
		database.Close()
		os.Exit(0)
	}()

	// Start server
	addr := "0.0.0.0:" + cfg.Port
	log.Printf("🚀 Server listening on %s", addr)
	if err := http.ListenAndServe(addr, handler); err != nil {
		log.Fatalf("❌ Server gagal: %v", err)
	}
}
