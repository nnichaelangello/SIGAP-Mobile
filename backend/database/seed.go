package database

import (
	"log"
	"sigap-backend/utils"
)

// SeedDefaultAccounts membuat akun admin dan psikolog default jika belum ada
func SeedDefaultAccounts() error {
	accounts := []struct {
		Email    string
		Password string
		Nama     string
		Role     string
	}{
		{
			Email:    "admin@gmail.com",
			Password: "admin",
			Nama:     "Administrator SIGAP",
			Role:     "admin",
		},
		{
			Email:    "psikolog@gmail.com",
			Password: "psikolog",
			Nama:     "Psikolog SIGAP",
			Role:     "psikolog",
		},
	}

	for _, acc := range accounts {
		// Cek apakah sudah ada
		var count int
		err := DB.QueryRow("SELECT COUNT(*) FROM users WHERE email = ?", acc.Email).Scan(&count)
		if err != nil {
			return err
		}

		if count > 0 {
			log.Printf("[Seed] Akun %s sudah ada, skip", acc.Email)
			continue
		}

		// Hash password
		hash, err := utils.HashPassword(acc.Password)
		if err != nil {
			return err
		}

		// Insert
		_, err = DB.Exec(`
			INSERT INTO users (email, password_hash, nama_lengkap, role, sub_role)
			VALUES (?, ?, ?, ?, '')
		`, acc.Email, hash, acc.Nama, acc.Role)

		if err != nil {
			return err
		}

		log.Printf("[Seed] ✅ Akun %s (%s) berhasil dibuat", acc.Email, acc.Role)
	}

	return nil
}
