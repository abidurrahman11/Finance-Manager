# Architecture Notes

## Layers
- `presentation/screens`: Flutter UI and navigation only.
- `presentation/providers`: Riverpod state, loading states, invalidation, and provider wiring.
- `data/repositories`: feature-level data contracts used by providers and existing direct screen calls.
- `data/local`: local database and persistence infrastructure.
- `core/network`: backend client used for account/cloud/collaboration work. Data providers now unify local and remote data when a remote session is active.

## Local Data
- `AppDatabase` owns the SQLite schema and opens `finance_manager.sqlite` in the app documents directory.
- Repositories use Drift custom SQL over the local database.
- Schema version starts at `1`; future table changes require a migration path.
- Local data is always available and acts as the primary source when offline.
- When online (has remote session), data providers merge local personal data with remote data (from shared groups or cloud account).

## Auth Logic
- `AuthStatus.unauthenticated`: User is in local-only mode (Guest). Features like Shared Groups and Cloud Sync are disabled but personal usage remains frictionless.
- `AuthStatus.authenticated`: User is logged in to a remote account. Remote data is fetched and merged with local data.
- `hasRemoteSession` getter in `AuthState` is the source of truth for online feature availability.

## Backend Boundary
- Personal finance features are offline-first but can merge remote data when authenticated.
- Collaboration is handled via Shared Groups which are remote-only.

## Provider Boundary
- Providers should read repositories, not `Dio` or database objects directly.
- Repository constructors may accept an injected database for tests.
- Keep provider invalidation local to affected feature data.

