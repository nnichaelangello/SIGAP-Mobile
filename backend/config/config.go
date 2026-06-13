package config

import (
	"fmt"
	"net"
	"os"
)

// Config menyimpan konfigurasi server
type Config struct {
	Port       string
	DBPath     string
	JWTSecret  string
	WebPort    string
	UploadDir  string
	AudioDir   string
}

// DefaultConfig mengembalikan konfigurasi default
func DefaultConfig() *Config {
	return &Config{
		Port:      getEnv("PORT", "8080"),
		DBPath:    getEnv("DB_PATH", "sigap.db"),
		JWTSecret: getEnv("JWT_SECRET", "sigap-secret-key-2024-very-secure"),
		WebPort:   getEnv("WEB_PORT", "8081"),
		UploadDir: getEnv("UPLOAD_DIR", "uploads"),
		AudioDir:  getEnv("AUDIO_DIR", "audio_records"),
	}
}

// GetLocalIP mendapatkan IP lokal laptop untuk diakses device mobile
func GetLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "localhost"
	}
	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return "localhost"
}

// PrintServerInfo mencetak informasi server saat startup
func (c *Config) PrintServerInfo() {
	localIP := GetLocalIP()
	fmt.Println("╔══════════════════════════════════════════════════╗")
	fmt.Println("║           🛡️  SIGAP Server Started  🛡️           ║")
	fmt.Println("╠══════════════════════════════════════════════════╣")
	fmt.Printf("║  API Server  : http://localhost:%s            ║\n", c.Port)
	fmt.Printf("║  Local Net   : http://%s:%s   ║\n", padRight(localIP, 14), c.Port)
	fmt.Println("║                                                  ║")
	fmt.Println("║  📱 Untuk Flutter, gunakan IP Local Net di atas  ║")
	fmt.Println("║  🌐 Web Dashboard buka di browser laptop         ║")
	fmt.Println("╠══════════════════════════════════════════════════╣")
	fmt.Printf("║  Database    : %s                          ║\n", padRight(c.DBPath, 16))
	fmt.Println("╚══════════════════════════════════════════════════╝")
}

func padRight(s string, length int) string {
	for len(s) < length {
		s += " "
	}
	return s
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
