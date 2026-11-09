# Fahrrad-Verleihsystem

Das Backend stellt eine JSON-REST-API für Dashboard, Verleihgegenstände,
Kunden und Ausleihen bereit. Die Daten werden ausschließlich im RAM gehalten;
hochgeladene Ausweisdokumente werden unter `data/uploads` gespeichert.

## Start

```bash
cd backend
go run .
```

Der Server läuft anschließend auf `http://localhost:8080`.

## Flutter-Frontend

Voraussetzung ist ein installiertes Flutter-SDK:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Das Frontend verwendet standardmäßig `http://localhost:8080` als Backend.
Das Backend muss deshalb vorher gestartet werden. Beim Android-Emulator muss
stattdessen in `frontend/lib/api.dart` meist `http://10.0.2.2:8080` verwendet
werden; auf einem echten Gerät die IP-Adresse des Entwicklungsrechners.

Die Flutter-Dateien sind bewusst einfach getrennt:

- `lib/models.dart`: Dart-Datenmodelle für Dashboard, Fahrräder, Kunden und Ausleihen
- `lib/api.dart`: HTTP-Kommunikation mit dem Go-Backend
- `lib/main.dart`: UI, Navigation über Dialoge und Benutzeraktionen

## API-Beispiele

Dashboard und Gegenstände:

```bash
curl http://localhost:8080/api/dashboard
curl http://localhost:8080/api/items
```

Kunde mit Ausweis:

```bash
curl -X POST http://localhost:8080/api/customers \
  -F 'name=Max Mustermann' \
  -F 'document_type=Personalausweis' \
  -F 'document_number=L1234567' \
  -F 'document=@/pfad/zum/ausweis.jpg'
```

Eine Ausleihe startet mit einem optionalen Beginn und einer optionalen
geplanten Dauer in Stunden. Beim Beenden wird jede angefangene Stunde berechnet.

```bash
curl -X POST http://localhost:8080/api/rentals/start \
  -H 'Content-Type: application/json' \
  -d '{"item_id":"bike-1","customer_id":"customer-1","started_at":"2026-11-03T14:00:00Z","planned_duration_hours":3}'

curl -X POST http://localhost:8080/api/rentals/end \
  -H 'Content-Type: application/json' \
  -d '{"rental_id":"rental-...","ended_at":"2026-11-03T17:15:00Z"}'
```
