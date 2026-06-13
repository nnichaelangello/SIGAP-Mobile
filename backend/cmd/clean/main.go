package main

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"
	"os"

	_ "modernc.org/sqlite"
)

func main() {
	// Dapatkan path absolute ke sigap.db
	cwd, _ := os.Getwd()
	dbPath := filepath.Join(filepath.Dir(filepath.Dir(cwd)), "sigap.db")
	
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	tables := []string{
		"appointments",
		"audit_trail",
		"chat_logs",
		"emergency_audios",
		"emergency_contacts",
		"emergency_incidents",
		"emergency_responses",
		"notifications",
		"pantau_heartbeats",
		"pantau_sessions",
		"psikolog_schedules",
		"psikolog_unavailability",
		"reports",
		"session_feedback",
		"session_notes",
	}

	for _, table := range tables {
		_, err := db.Exec(fmt.Sprintf("DELETE FROM %s", table))
		if err != nil {
			log.Printf("Skip or error clearing %s: %v\n", table, err)
		} else {
			fmt.Printf("Cleared table: %s\n", table)
		}
	}
	fmt.Println("All data cleared except users!")
}
