package utils

import (
	"log"
	"net/smtp"
)

// Konfigurasi SMTP
const (
	SMTPHost     = "smtp.gmail.com"
	SMTPPort     = "587"
	SMTPEmail    = "michaelriyadi02@gmail.com"
	SMTPPassword = "ndhw rdaa yztc tozj"
)

// SendEmail mengirim email menggunakan goroutine agar tidak memblokir API response
func SendEmail(to string, subject string, htmlBody string) {
	if to == "" {
		log.Println("[Email] Alamat tujuan kosong, email batal dikirim.")
		return
	}

	go func() {
		log.Printf("[Email] Mencoba mengirim email ke %s...", to)

		auth := smtp.PlainAuth("", SMTPEmail, SMTPPassword, SMTPHost)

		msg := []byte(
			"To: " + to + "\r\n" +
				"Subject: " + subject + "\r\n" +
				"MIME-Version: 1.0\r\n" +
				"Content-Type: text/html; charset=\"UTF-8\"\r\n\r\n" +
				htmlBody + "\r\n")

		err := smtp.SendMail(SMTPHost+":"+SMTPPort, auth, SMTPEmail, []string{to}, msg)
		if err != nil {
			log.Printf("[Email] Gagal mengirim ke %s: %v\n", to, err)
		} else {
			log.Printf("[Email] Berhasil mengirim ke %s\n", to)
		}
	}()
}
