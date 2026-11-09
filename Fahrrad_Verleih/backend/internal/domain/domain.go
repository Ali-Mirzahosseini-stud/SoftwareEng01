package domain

import "time"

// RentalItem is implemented by every item that can be rented.
type RentalItem interface {
	ItemID() string
	ItemName() string
	ItemType() string
	HourlyRateValue() float64
	Rented() bool
	SetRented(bool)
}

type Ski struct {
	ID         string  `json:"id"`
	Name       string  `json:"name"`
	Type       string  `json:"type"`
	HourlyRate float64 `json:"hourly_rate"`
	IsRented   bool    `json:"is_rented"`
}

func (s *Ski) ItemID() string          { return s.ID }
func (s *Ski) ItemName() string        { return s.Name }
func (s *Ski) ItemType() string        { return s.Type }
func (s *Ski) HourlyRateValue() float64 { return s.HourlyRate }
func (s *Ski) Rented() bool            { return s.IsRented }
func (s *Ski) SetRented(value bool)    { s.IsRented = value }

type Bike struct {
	ID         string  `json:"id"`
	Name       string  `json:"name"`
	Type       string  `json:"type"`
	HourlyRate float64 `json:"hourly_rate"`
	IsRented   bool    `json:"is_rented"`
}

func (b *Bike) ItemID() string          { return b.ID }
func (b *Bike) ItemName() string        { return b.Name }
func (b *Bike) ItemType() string        { return b.Type }
func (b *Bike) HourlyRateValue() float64 { return b.HourlyRate }
func (b *Bike) Rented() bool            { return b.IsRented }
func (b *Bike) SetRented(value bool)    { b.IsRented = value }

type Customer struct {
	ID                   string    `json:"id"`
	Name                 string    `json:"name"`
	DocumentType         string    `json:"document_type"`
	DocumentNumber       string    `json:"document_number"`
	DocumentPath         string    `json:"document_path,omitempty"`
	CreatedAt            time.Time `json:"created_at"`
}

type Rental struct {
	ID                   string     `json:"id"`
	ItemID               string     `json:"item_id"`
	CustomerID           string     `json:"customer_id"`
	StartedAt            time.Time  `json:"started_at"`
	PlannedDurationHours *float64   `json:"planned_duration_hours,omitempty"`
	EndedAt              *time.Time `json:"ended_at,omitempty"`
	BilledHours          *int       `json:"billed_hours,omitempty"`
	TotalPrice           *float64   `json:"total_price,omitempty"`
}
