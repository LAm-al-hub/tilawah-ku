# Technical Architecture Document - TilawahKU

## 1. Technology Stack
- **Framework:** Flutter (Material 3)
- **Language:** Dart
- **State Management:** Provider (or Riverpod)
- **Local Storage:**
  - `shared_preferences`: Simple key-value pairs (Settings, Last Read pointer).
  - `sqflite`: Structured data (Tasks, Bookmarks, History).
- **Networking:** `http` package.
- **Scrolling:** `scrollable_positioned_list` (for precise Ayah jumping).

## 2. System Architecture
The app will follow a **Service-Oriented Architecture** with a clear separation of concerns, suitable for a solo developer.

```mermaid
graph TD
    UI[UI Layer (Screens/Widgets)] --> VM[State Management (Providers)]
    VM --> Service[Service Layer]
    Service --> API[Quran API Service]
    Service --> DB[Local Database Service]
    Service --> Prefs[Shared Preferences Service]
```

## 3. Data Models

### 3.1 Surah
```dart
class Surah {
  final int number;
  final String name;
  final String latinName;
  final int totalAyah;
  final String translation;
  // ... factory methods
}
```

### 3.2 Ayah
```dart
class Ayah {
  final int number; // In Surah
  final String arabicText;
  final String latinText;
  final String translation;
  final int juzu;
  // ... factory methods
}
```

### 3.3 Task
```dart
class Task {
  final int? id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime dueDate;
  // ... toMap / fromMap for SQLite
}
```

### 3.4 LastRead
```dart
class LastRead {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final DateTime timestamp;
}
```

## 4. API Integration
**Base URL:** `https://equran.id/api/v2`

### Endpoints
- **List of Surahs:** `GET /surat`
- **Surah Detail:** `GET /surat/{nomor}`

### Error Handling
- Timeout handling.
- Try-catch blocks in service layer.
- User-friendly error messages (SnackBar/Dialog).

## 5. Local Storage Design

### 5.1 Shared Preferences
- `daily_target_ayahs`: int (e.g., 20)
- `last_read_surah`: int
- `last_read_ayah`: int
- `last_read_surah_name`: String

### 5.2 SQLite Database
**Table: `tasks`**
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| title | TEXT | Task title |
| description | TEXT | Details |
| is_completed | INTEGER | 0 or 1 |
| date | TEXT | ISO8601 String |

## 6. Key Implementation Details

### 6.1 Jump to Ayah Logic
- Use `scrollable_positioned_list`.
- When loading Surah Detail, check if `last_read_surah` matches current Surah.
- If yes, pass `initialScrollIndex` or use `ItemScrollController.jumpTo(index: last_read_ayah - 1)`.

### 6.2 Progress Tracking
- A `ProgressProvider` will listen to Ayah completion events.
- Update `daily_progress_count` in memory/local storage.
- Recalculate circular progress bar percentage.
