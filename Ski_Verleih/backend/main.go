package main

import (
	"log"
	"net/http"
	"os"

	"ski-verleih/backend/internal/domain"
	"ski-verleih/backend/internal/handler"
	"ski-verleih/backend/internal/store"
)

func main() {
	dataDir := "data/uploads"
	if err := os.MkdirAll(dataDir, 0750); err != nil {
		log.Fatal(err)
	}
	s := store.New()
	for i := 1; i <= 20; i++ {
		s.AddItem(&domain.Ski{ID: "ski-" + itoa(i), Name: "Ski " + itoa(i), Type: "ski", HourlyRate: 8.50})
	}
	h := handler.New(s, dataDir)
	log.Println("Ski-Verleih Backend läuft auf http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", h.Routes()))
}

func itoa(value int) string {
	const digits = "0123456789"
	if value == 0 { return "0" }
	result := ""
	for value > 0 { result = string(digits[value%10]) + result; value /= 10 }
	return result
}
