# Projekt-Spezifikation: Ski-Verleihsystem und Fahrrad-Verleihsystem (SDD)
## Tech-Stack
- **Backend:** Go (net/http REST API, JSON)
- **Speicher:** In-Memory Store (Go Maps / Slices mit `sync.Mutex` für Thread-Safety)
- **Frontend:** Flutter - **Architektur:** Specification-Driven Development (SDD), saubere Schichtenarchitektur

## Fachliche Anforderungen & Domänenmodell
1. **Plugin-Architektur für Verleihobjekte (`RentalItem`):**
- Basis/Interface: `RentalItem` (ID, Name, Typ, Stundensatz, Status `IsRented`)
- Konkrete Ausprägungen: `Bike` (Hauptfokus) und `Ski`
2. **Kunden- & Ausweisverwaltung:**
- Kundenstruktur mit Ausweisnummer, Ausweistyp (z. B. Personalausweis, Reisepass) und Pfad zum hochgeladenen Ausweisdokument.
3. **Flexibler Verleih & Abrechnung:**
- Ausleihe mit flexiblem Verleihbeginn und **stundenweiser Abrechnung** (`Stundensatz * Stunden`).

## Backend-Struktur (`/backend`)
- `internal/domain`: Enthält Datenstrukturen, Interfaces (`RentalItem`, `Customer`, `Rental`).
- `internal/store`: In-Memory-Verwaltung aller Daten in Go-Maps, abgesichert mit `sync.Mutex`.
- `internal/handler`: HTTP-REST-Endpunkte (JSON API).
- `main.go`: Server-Startpunkt.

## Erforderliche REST-Endpunkte
- `GET /api/dashboard`: Übersichtsdaten (Anzahl verfügbarer Items, ausgeliehene Items, Gesamtbestand, registrierte Personen).
- `GET /api/items`: Liste aller Verleih-Gegenstände.
- `POST /api/customers`: Kundendaten anlegen inklusive Ausweis-Typ/Nummer & Datei-Upload.
- `POST /api/rentals/start`: Ausleihe starten.
- `POST /api/rentals/end`: Ausleihe beenden & Preis berechnen.

## Entwicklungsregeln
- **Keine externe Datenbank** (kein SQL, kein ORM, keine DB-Treiber). Alles im RAM halten.
- Alle Lese- und Schreibzugriffe auf den Store müssen thread-sicher (`sync.Mutex`) sein.
- Einfacher, modularer und leicht verständlicher Code.