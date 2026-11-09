package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"time"

	"ski-verleih/backend/internal/domain"
	"ski-verleih/backend/internal/store"
)

type Handler struct {
	store       *store.Store
	uploadDir   string
	idCounter   uint64
}

func New(s *store.Store, uploadDir string) *Handler {
	return &Handler{store: s, uploadDir: uploadDir}
}

func (h *Handler) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/dashboard", h.dashboard)
	mux.HandleFunc("/api/items", h.items)
	mux.HandleFunc("/api/customers", h.createCustomer)
	mux.HandleFunc("/api/customers/list", h.customers)
	mux.HandleFunc("/api/rentals/start", h.startRental)
	mux.HandleFunc("/api/rentals/end", h.endRental)
	mux.HandleFunc("/api/rentals", h.rentals)
	return cors(mux)
}

func (h *Handler) dashboard(w http.ResponseWriter, r *http.Request) {
	if !requireMethod(w, r, http.MethodGet) { return }
	available, rented, total, customers := h.store.Dashboard()
	writeJSON(w, http.StatusOK, map[string]int{
		"available_items": available, "rented_items": rented,
		"total_items": total, "registered_customers": customers,
	})
}

func (h *Handler) items(w http.ResponseWriter, r *http.Request) {
	if !requireMethod(w, r, http.MethodGet) { return }
	writeJSON(w, http.StatusOK, h.store.Items())
}

func (h *Handler) customers(w http.ResponseWriter, r *http.Request) {
	if !requireMethod(w, r, http.MethodGet) { return }
	writeJSON(w, http.StatusOK, h.store.Customers())
}

func (h *Handler) rentals(w http.ResponseWriter, r *http.Request) {
	if !requireMethod(w, r, http.MethodGet) { return }
	writeJSON(w, http.StatusOK, h.store.Rentals())
}

func (h *Handler) createCustomer(w http.ResponseWriter, r *http.Request) {
	if !requireMethod(w, r, http.MethodPost) { return }
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "multipart form data is required")
		return
	}
	customer := domain.Customer{
		ID:             h.newID("customer"),
		Name:           strings.TrimSpace(r.FormValue("name")),
		DocumentType:   strings.TrimSpace(r.FormValue("document_type")),
		DocumentNumber: strings.TrimSpace(r.FormValue("document_number")),
		CreatedAt:      time.Now().UTC(),
	}
	if customer.Name == "" || customer.DocumentType == "" || customer.DocumentNumber == "" {
		writeError(w, http.StatusBadRequest, "name, document_type and document_number are required")
		return
	}
	file, header, err := r.FormFile("document")
	if err == nil {
		defer file.Close()
		if err := os.MkdirAll(h.uploadDir, 0750); err != nil {
			writeError(w, http.StatusInternalServerError, "could not prepare upload directory")
			return
		}
		extension := filepath.Ext(filepath.Base(header.Filename))
		target := filepath.Join(h.uploadDir, customer.ID+extension)
		output, err := os.OpenFile(target, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not save document")
			return
		}
		defer output.Close()
		if _, err := output.ReadFrom(file); err != nil {
			writeError(w, http.StatusInternalServerError, "could not save document")
			return
		}
		customer.DocumentPath = target
	} else if !errors.Is(err, http.ErrMissingFile) {
		writeError(w, http.StatusBadRequest, "invalid document upload")
		return
	}
	h.store.AddCustomer(customer)
	writeJSON(w, http.StatusCreated, customer)
}

type startRentalRequest struct {
	ItemID               string   `json:"item_id"`
	CustomerID           string   `json:"customer_id"`
	StartedAt            string   `json:"started_at"`
	PlannedDurationHours *float64 `json:"planned_duration_hours"`
}

func (h *Handler) startRental(w http.ResponseWriter, r *http.Request) {
	if !requireMethod(w, r, http.MethodPost) { return }
	var request startRentalRequest
	if !decodeJSON(w, r, &request) { return }
	startedAt := time.Now().UTC()
	if request.StartedAt != "" {
		parsed, err := time.Parse(time.RFC3339, request.StartedAt)
		if err != nil { writeError(w, http.StatusBadRequest, "started_at must be RFC3339"); return }
		startedAt = parsed
	}
	if request.ItemID == "" || request.CustomerID == "" {
		writeError(w, http.StatusBadRequest, "item_id and customer_id are required")
		return
	}
	if request.PlannedDurationHours != nil && *request.PlannedDurationHours <= 0 {
		writeError(w, http.StatusBadRequest, "planned_duration_hours must be positive")
		return
	}
	rental := domain.Rental{ID: h.newID("rental"), ItemID: request.ItemID, CustomerID: request.CustomerID,
		StartedAt: startedAt, PlannedDurationHours: request.PlannedDurationHours}
	if err := h.store.StartRental(rental); err != nil {
		if errors.Is(err, store.ErrAlreadyRented) { writeError(w, http.StatusConflict, err.Error()) } else { writeError(w, http.StatusNotFound, "item or customer not found") }
		return
	}
	writeJSON(w, http.StatusCreated, rental)
}

type endRentalRequest struct { RentalID string `json:"rental_id"`; EndedAt string `json:"ended_at"` }

func (h *Handler) endRental(w http.ResponseWriter, r *http.Request) {
	if !requireMethod(w, r, http.MethodPost) { return }
	var request endRentalRequest
	if !decodeJSON(w, r, &request) { return }
	if request.RentalID == "" { writeError(w, http.StatusBadRequest, "rental_id is required"); return }
	rental, ok := h.store.Rental(request.RentalID)
	if !ok { writeError(w, http.StatusNotFound, "rental not found"); return }
	endedAt := time.Now().UTC()
	if request.EndedAt != "" {
		parsed, err := time.Parse(time.RFC3339, request.EndedAt)
		if err != nil { writeError(w, http.StatusBadRequest, "ended_at must be RFC3339"); return }
		endedAt = parsed
	}
	if !endedAt.After(rental.StartedAt) { writeError(w, http.StatusBadRequest, "ended_at must be after started_at"); return }
	hours := int(math.Ceil(endedAt.Sub(rental.StartedAt).Hours()))
	if hours < 1 { hours = 1 }
	rate, ok := h.store.RentalRate(rental.ItemID)
	if !ok {
		writeError(w, http.StatusNotFound, "rental item not found")
		return
	}
	total := float64(hours) * rate
	ended := rental
	ended.EndedAt = &endedAt
	ended.BilledHours = &hours
	ended.TotalPrice = &total
	if err := h.store.EndRental(request.RentalID, ended); err != nil {
		if errors.Is(err, store.ErrAlreadyEnded) { writeError(w, http.StatusConflict, err.Error()) } else { writeError(w, http.StatusNotFound, "rental or item not found") }
		return
	}
	writeJSON(w, http.StatusOK, ended)
}

func (h *Handler) newID(prefix string) string {
	return fmt.Sprintf("%s-%d-%d", prefix, time.Now().UnixNano(), atomic.AddUint64(&h.idCounter, 1))
}

func requireMethod(w http.ResponseWriter, r *http.Request, method string) bool {
	if r.Method == method { return true }
	w.Header().Set("Allow", method)
	writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	return false
}

func decodeJSON(w http.ResponseWriter, r *http.Request, target any) bool {
	if err := json.NewDecoder(r.Body).Decode(target); err != nil { writeError(w, http.StatusBadRequest, "invalid JSON body"); return false }
	return true
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}

func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		if r.Method == http.MethodOptions { w.WriteHeader(http.StatusNoContent); return }
		next.ServeHTTP(w, r)
	})
}
