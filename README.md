# Vocab Trainer (Flutter)

A simple vocabulary training app built with Flutter.  
Main features:
- Manage vocab **sets** and add cards.
- Assign **labels** and **ratings (1–5)** to cards.
- Train vocab with different strategies.
- See **statistics** and progress graphs.

## App Structure

- **Bottom Navigation**
    - **Sets**: Create and manage sets, add cards, filter by labels, start training.
    - **All Cards**: Browse all cards across sets, filter, start training.
    - **Stats**: Visualize progress and rating distribution.

- **Floating Action Button (FAB)**
    - On Sets screen → Add new set or start training inside a set.
    - On Cards screen → Start training.
    - On Stats screen → No action.

- **Training Modes**
    - All in order.
    - By rating.
    - By time not seen.
    - Intelligent (smarter scheduling later).

## Issues / Milestones

### Core Models
- [ ] Define `VocabCard` and `VocabSet` classes. ✅
- [ ] Add methods for update, filter, and statistics.

### UI: Navigation
- [ ] Implement `BottomNavigationBar` with three tabs: Sets, All Cards, Stats.
- [ ] Add `FloatingActionButton` behavior per tab.

### UI: Sets
- [ ] List existing sets.
- [ ] Create new set with dialog prompt.
- [ ] Navigate into a set detail screen.
- [ ] Add cards to a set (form with front, back, labels).
- [ ] Filter cards by labels.
- [ ] Start training from a filtered set.

### UI: All Cards
- [ ] List all cards across sets.
- [ ] Filter by labels.
- [ ] Start training.

### UI: Training
- [ ] Simple mode: show card front, flip to back.
- [ ] Add rating buttons (1–5).
- [ ] Implement order-by strategies:
    - [ ] Sequential
    - [ ] By rating
    - [ ] By time not seen
    - [ ] Intelligent (future work)

### UI: Stats
- [ ] Collect card statistics.
- [ ] Display rating distribution in chart.
- [ ] Show progress over time.

## File Stucture
lib/
│ main.dart                # entrypoint, runs MyApp
│
├── app/
│   ├── my_app.dart         # MaterialApp + theme
│   └── navigation.dart     # BottomNavigationBar screen
│
├── models/
│   ├── vocab_card.dart     # VocabCard class
│   └── vocab_set.dart      # VocabSet class
│
├── screens/
│   ├── sets/
│   │   ├── sets_screen.dart        # Lists sets
│   │   ├── set_detail_screen.dart  # Inside a set
│   │   └── add_set_dialog.dart     # Dialog for new set
│   │
│   ├── all_cards/
│   │   └── all_cards_screen.dart
│   │
│   └── stats/
│       └── stats_screen.dart
│
├── widgets/
│   ├── card_tile.dart       # reusable UI for showing a vocab card
│   ├── set_tile.dart        # reusable UI for showing a set
│   └── rating_stars.dart    # example reusable widget
│
└── services/
└── training_service.dart  # logic for training modes
