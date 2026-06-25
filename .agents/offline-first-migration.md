# Offline-First & Online Integration

## Goal
A seamless hybrid experience where personal finance features are offline-first, but automatically merge and sync with cloud data when a user is logged in.

## Offline Features (Guest Mode)
- Expenses, Incomes, Bills, Plans: Full CRUD available locally.
- Analytics: Computed from local SQLite data.
- Personal mode uses `userId = 1`.

## Online Integration (Authenticated Mode)
- Data Unification: Analytics and lists merge local records with remote cloud records.
- Shared Groups: Real-time collaboration on shared expenses, incomes, and plans.
- Cloud Identity: Persistent account across devices.

## Acceptance Criteria
- App starts in Guest Mode (unauthenticated) without requiring backend.
- Login/Register works without resetting the app state or router prematurely.
- Once logged in, the Dashboard shows a unified view of both local and remote data.
- Collaborative features (Shared Groups) are enabled only when authenticated.

