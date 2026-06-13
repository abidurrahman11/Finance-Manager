# Architecture Notes

## Layers
- `presentation/screens`: Flutter UI and navigation only.
- `presentation/providers`: Riverpod state, loading states, invalidation, and provider wiring.
- `data/repositories`: feature-level data contracts used by providers and existing direct screen calls.
- `data/local`: local database and persistence infrastructure.
- `core/network`: backend client retained for future account/cloud/collaboration work.

## Local Data
- `AppDatabase` owns the SQLite schema and opens `finance_manager.sqlite` in the app documents directory.
- Repositories use Drift custom SQL over the local database.
- Schema version starts at `1`; future table changes require a migration path.

## Backend Boundary
- Personal finance features must not depend on `ApiClient`.
- Collaboration remains backend-only and should be guarded in UI before a future cloud/collaboration phase.
- If cloud sync is added later, introduce explicit sync repositories instead of mixing local and remote writes inside UI screens.

## Provider Boundary
- Providers should read repositories, not `Dio` or database objects directly.
- Repository constructors may accept an injected database for tests.
- Keep provider invalidation local to affected feature data.

