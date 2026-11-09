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
	bikes := []struct {
		id         string
		name       string
		itemType   string
		hourlyRate float64
	}{
		{"bike-1", "City-Bike 1", "Fahrrad", 6.00},
		{"bike-2", "City-Bike 2", "Fahrrad", 6.00},
		{"bike-3", "Trekking-Bike 1", "Fahrrad", 8.50},
		{"bike-4", "Trekking-Bike 2", "Fahrrad", 8.50},
		{"bike-5", "Mountainbike 1", "Mountainbike", 10.00},
		{"bike-6", "Mountainbike 2", "Mountainbike", 10.00},
		{"ebike-1", "E-Bike 1", "E-Bike", 12.00},
		{"ebike-2", "E-Bike 2", "E-Bike", 12.00},
		{"ebike-3", "E-Bike 3", "E-Bike", 14.00},
		{"bike-7", "Rennrad 1", "Rennrad", 11.00},
	}
	for _, bike := range bikes {
		s.AddItem(&domain.Bike{
			ID: bike.id, Name: bike.name, Type: bike.itemType, HourlyRate: bike.hourlyRate,
		})
	}
	h := handler.New(s, dataDir)
	log.Println("Fahrrad-Verleih Backend läuft auf http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", h.Routes()))
}
