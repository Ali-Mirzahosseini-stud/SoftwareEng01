package store

import (
	"errors"
	"sync"

	"ski-verleih/backend/internal/domain"
)

var (
	ErrNotFound       = errors.New("resource not found")
	ErrAlreadyRented  = errors.New("item is already rented")
	ErrAlreadyEnded   = errors.New("rental is already ended")
)

type Store struct {
	mu        sync.RWMutex
	items     map[string]domain.RentalItem
	customers map[string]domain.Customer
	rentals   map[string]domain.Rental
}

func New() *Store {
	return &Store{
		items:     make(map[string]domain.RentalItem),
		customers: make(map[string]domain.Customer),
		rentals:   make(map[string]domain.Rental),
	}
}

func (s *Store) AddItem(item domain.RentalItem) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.items[item.ItemID()] = item
}

func (s *Store) Items() []domain.RentalItem {
	s.mu.RLock()
	defer s.mu.RUnlock()
	items := make([]domain.RentalItem, 0, len(s.items))
	for _, item := range s.items {
		items = append(items, cloneItem(item))
	}
	return items
}

func (s *Store) Dashboard() (available, rented, total, customers int) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	total = len(s.items)
	customers = len(s.customers)
	for _, item := range s.items {
		if item.Rented() {
			rented++
		} else {
			available++
		}
	}
	return
}

func (s *Store) AddCustomer(customer domain.Customer) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.customers[customer.ID] = customer
}

func (s *Store) Customers() []domain.Customer {
	s.mu.RLock()
	defer s.mu.RUnlock()
	customers := make([]domain.Customer, 0, len(s.customers))
	for _, customer := range s.customers {
		customers = append(customers, customer)
	}
	return customers
}

func (s *Store) StartRental(rental domain.Rental) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	item, ok := s.items[rental.ItemID]
	if !ok {
		return ErrNotFound
	}
	if _, ok := s.customers[rental.CustomerID]; !ok {
		return ErrNotFound
	}
	if item.Rented() {
		return ErrAlreadyRented
	}
	item.SetRented(true)
	s.rentals[rental.ID] = rental
	return nil
}

func (s *Store) EndRental(id string, ended domain.Rental) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	rental, ok := s.rentals[id]
	if !ok {
		return ErrNotFound
	}
	if rental.EndedAt != nil {
		return ErrAlreadyEnded
	}
	item, ok := s.items[rental.ItemID]
	if !ok {
		return ErrNotFound
	}
	item.SetRented(false)
	s.rentals[id] = ended
	return nil
}

func (s *Store) Rental(id string) (domain.Rental, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	rental, ok := s.rentals[id]
	return rental, ok
}

func (s *Store) Rentals() []domain.Rental {
	s.mu.RLock()
	defer s.mu.RUnlock()
	rentals := make([]domain.Rental, 0, len(s.rentals))
	for _, rental := range s.rentals {
		rentals = append(rentals, rental)
	}
	return rentals
}

func (s *Store) RentalRate(itemID string) (float64, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	item, ok := s.items[itemID]
	if !ok {
		return 0, false
	}
	return item.HourlyRateValue(), true
}

func cloneItem(item domain.RentalItem) domain.RentalItem {
	switch value := item.(type) {
	case *domain.Ski:
		copy := *value
		return &copy
	case *domain.Bike:
		copy := *value
		return &copy
	default:
		return item
	}
}
