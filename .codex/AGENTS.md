# Finance Manager Codex Instructions

## Project Shape
- Flutter app using Riverpod, GoRouter, Dio, and a local Drift/SQLite database.
- Personal finance features must work offline without backend access.
- Backend-dependent behavior is limited to account/cloud and collaboration features.

## Architecture Rules
- Keep UI screens thin. State belongs in Riverpod providers, data access belongs in repositories.
- Personal data repositories must use local storage first and must not require `ApiClient`.
- Do not add direct backend calls from screens. If a screen needs data, expose it through a provider or repository method.
- Keep local personal records owner-only with `userId = 1` unless a deliberate multi-profile migration is planned.
- Collaboration actions should be explicit about requiring backend support and must not silently fail.

## Flutter Rules
- Run `flutter analyze` before handing off changes.
- Run `flutter test` when provider, repository, routing, or model behavior changes.
- Prefer small repository-level tests with an isolated local database for offline logic.
- Do not edit generated platform files unless the task explicitly requires platform configuration.

## Safety
- Do not delete user data or reset the local database as part of normal feature work.
- Database schema changes require a migration note and a schema version bump.
- Do not restore backend dependency for personal expenses, incomes, bills, plans, dashboard, or analytics.

