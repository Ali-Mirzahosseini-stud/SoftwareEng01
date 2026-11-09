package store

import (
	"testing"
	"time"

	"ski-verleih/backend/internal/domain"
)

func TestStartAndEndRentalUpdatesItemStatus(t *testing.T) {
	s := New()
	s.AddItem(&domain.Bike{ID: "bike-1", HourlyRate: 8})
	s.AddCustomer(domain.Customer{ID: "customer-1"})
	started := domain.Rental{ID: "rental-1", ItemID: "bike-1", CustomerID: "customer-1", StartedAt: time.Now()}
	if err := s.StartRental(started); err != nil {
		t.Fatal(err)
	}
	if available, rented, total, _ := s.Dashboard(); available != 0 || rented != 1 || total != 1 {
		t.Fatalf("unexpected dashboard: %d %d %d", available, rented, total)
	}
	endedAt := started.StartedAt.Add(time.Hour)
	ended := started
	ended.EndedAt = &endedAt
	if err := s.EndRental(started.ID, ended); err != nil {
		t.Fatal(err)
	}
	if _, rented, _, _ := s.Dashboard(); rented != 0 {
		t.Fatalf("item should be available")
	}
}
