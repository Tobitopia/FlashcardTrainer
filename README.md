# Vocab Trainer (Flutter)

A dynamic and media-rich vocabulary training application built with Flutter. This app allows users to create personalized flashcard sets, incorporating not just text but also videos and images for a more engaging learning experience.

## Key Features

- **Media-Rich Flashcards:** Move beyond simple text. Create cards with a title, a description, and attach a video or image directly from your device's gallery or camera.
- **Organize with Sets:** Group your cards into custom sets for focused study sessions.
- **Dynamic Labeling:** Assign multiple labels to your cards (e.g., "verbs," "chapter 3," "difficult") for powerful filtering and organization.
- **Card Rating:** Rate your confidence with each card on a 1-5 star scale to track your learning progress.
- **Database Powered:** All your sets, cards, and labels are stored locally on your device using a robust SQLite database.
- **Filter and Find:** Quickly find the cards you need on the "All Cards" screen with a label-based filter.
- **Intuitive UI:** A clean, modern interface with a bottom navigation bar for easy access to all features.

## How to Use

1.  **Create a Set:** Navigate to the **Sets** tab and tap the '+' button to create a new vocabulary set.
2.  **Add a Card:** Open a set and tap the '+' button again to open the "New Card" dialog.
3.  **Build Your Card:**
    *   Fill in the **Title** and **Description**.
    *   Tap **"Gallery"** or **"Camera"** to add a video.
    *   Add existing labels or create new ones.
    *   Set a rating with the slider.
4.  **View Your Cards:**
    *   In a set, tap a card to view it. If it has a video, it will open in a video player.
    *   Long-press a card to bring up options to **Edit** or **Delete** it.
    *   Long-press a set on the main screen to delete it (with a confirmation).

## App Structure

- **Bottom Navigation**
    - **Sets**: Create and manage sets, add media cards, and start training.
    - **All Cards**: Browse all cards across all sets, with label filtering.
    - **Stats**: Visualize progress and rating distribution.

- **Floating Action Button (FAB)**
    - On **Sets** screen → Add a new set.
    - Inside a set → Add a new card or start a training session.
    - On **All Cards** screen → Start a training session.

## Project Milestones

### Core Models
- [x] Define `VocabCard` and `VocabSet` classes.
- [x] Add methods for update, filter, and statistics.
- [x] **Update `VocabCard` to support media (title, description, mediaPath).**
- [x] **Update `VocabCard` to include `lastTrained` for smart training.**

### UI: Navigation
- [x] Implement `BottomNavigationBar` with three tabs: Sets, All Cards, Stats.
- [x] Add `FloatingActionButton` behavior per tab.

### UI: Sets
- [x] List existing sets.
- [x] Create new set with dialog prompt.
- [x] **Delete set with a long-press and confirmation.**
- [x] Navigate into a set detail screen.
- [x] **Add media cards to a set (title, description, video, labels, rating).**
- [x] **Edit and Delete cards via long-press menu.**
- [x] Filter cards by labels.
- [x] Start training from a filtered set.

### UI: All Cards
- [x] List all cards across sets.
- [x] Filter by labels.
- [x] Start training.

### UI: Training
- [x] Simple mode: show card front, flip to back.
- [x] Add rating buttons (1–5).
- [x] Implement order-by strategies:
    - [ ] Sequential
    - [x] By rating
    - [x] By time not seen
    - [ ] Intelligent (future work)

### UI: Stats
- [x] Collect card statistics.
- [x] Display rating distribution in chart.
- [ ] Show progress over time.

### Database
- [x] Set up `database_helpers.dart` with SQLite.
- [x] Implement full CRUD (Create, Read, Update, Delete) for Sets and Cards.
- [x] Implement labeling system in the database.
- [x] **Update database schema to support media cards.**
- [x] **Update database schema to include `lastTrained` for smart training.**

## Future Feature: Cloud Sync & Sharing

This feature will allow users to upload their vocabulary sets to the cloud and share them with others via a unique link.

### 1. Backend Setup & Authentication
- [ ] **Choose a Backend:** Firebase is the primary candidate due to its strong Flutter integration.
- [ ] **Set up Authentication:** Implement email/password login and registration. This is necessary to associate cloud sets with a user account.
- [ ] **Create a Login/Register Screen:** Build the UI for users to sign in or create an account.

### 2. Cloud Storage for Sets
- [ ] **Set up Cloud Database:** Use Firebase Firestore to store `VocabSet` and `VocabCard` data.
- [ ] **Develop Cloud Service:** Create a `cloud_services.dart` file to handle communication between the app and Firestore.
- [ ] **Implement "Upload" Functionality:** Add a UI element (e.g., a "share" button) that allows a logged-in user to upload a local set to their cloud account.

### 3. Sharing & Importing
- [ ] **Generate Sharable Links:** For each uploaded set, create a unique identifier and a corresponding link.
- [ ] **Implement Deep Linking:** Configure the app to recognize when it's opened via a shared link.
- [ ] **Implement "Import" Functionality:** When the app is opened with a link, it should fetch the set from the cloud and save it to the user's local SQLite database.
- [ ] **Handle Media Files:** Devise a strategy for uploading and downloading associated images/videos (e.g., using Firebase Cloud Storage).
