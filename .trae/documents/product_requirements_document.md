# Product Requirements Document (PRD) - TilawahKU

## 1. Product Overview
**App Name:** TilawahKU  
**Platform:** Flutter (Android & iOS)  
**Target Audience:** Muslims who want a modern, focused, and gamified Quran reading experience.  
**Core Value Proposition:** A spiritual companion that helps users build a consistent Quran reading habit through daily targets, progress tracking, and a seamless reading experience.

## 2. User Personas
- **The Busy Professional:** Wants to read a few verses daily but needs reminders and easy progress tracking.
- **The Dedicated Reader:** Wants to complete the Quran (Khatam) regularly and needs a tool to track their completion.
- **The Learner:** Wants to read with translation and correct pronunciation (transliteration).

## 3. Functional Requirements

### 3.1 Dashboard (Home Screen)
- **Header:**
  - Greeting "Assalamualaikum".
  - Daily motivational Quran verse (random or scheduled).
- **Last Read Card:**
  - Displays current Surah Name and Ayah Number.
  - "Continue Reading" button to jump to the exact saved position.
- **Progress Overview:**
  - Circular progress bar showing daily target achievement (e.g., 15/20 Ayahs).
- **Task Summary:**
  - Preview of today's to-do list items (e.g., "Read Surah Al-Mulk").

### 3.2 Targeting & Task System
- **Daily Target Setting:**
  - User can configure a daily goal (e.g., 20 Ayahs/day, 1 Juz/day).
- **Task Management:**
  - Add/Edit/Delete spiritual tasks.
  - Examples: "Read Surah Yasin after Maghrib", "Listen to Al-Kahf".
- **Goal Logic:**
  - Progress updates automatically when verses are marked as read.

### 3.3 Quran Reader (Tilawah)
- **Data Source:** `https://equran.id/api/v2/surat/{nomor}`
- **Display:**
  - Arabic Text (Uthmani script).
  - Latin Transliteration.
  - Indonesian Translation.
- **Navigation:**
  - Jump to specific Ayah.
  - Smooth scrolling.
- **Interaction:**
  - "Mark as Last Read" button on every Ayah.
  - "Mark as Completed" for daily target tracking.

### 3.4 Advanced Save & Load
- **Auto-Save:** Saves `surah_id` and `ayah_id` on scroll/exit.
- **Manual Save:** User explicitly marks position.
- **Resume Capability:** App launches or resumes directly to the saved Ayah using `ScrollController` or `ItemScrollController`.

## 4. Non-Functional Requirements
- **Performance:** Fast load times for Surah text; efficient caching.
- **Offline Capability:** Cache Surah data after first load (optional but recommended).
- **UI/UX:**
  - **Theme:** Modern Spiritual.
  - **Colors:** Deep Teal (#00695C), Soft Mint (#E0F2F1), Gold Accents.
  - **Typography:** Poppins (UI), Amiri/LPMQ Misbah (Arabic).

## 5. UI/UX Guidelines
- **Layout:** Card-based design with subtle shadows.
- **Navigation:** Bottom Navigation Bar (Dashboard, Quran, Tasks, Settings).
- **Accessibility:** Readable font sizes, clear contrast.

## 6. Future Scope (Post-MVP)
- Audio recitation playback.
- Tafsir integration.
- Gamification badges.
