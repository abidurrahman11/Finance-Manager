# ADR 0001: Offline-First Local Storage

## Status
Accepted

## Context
The original app depended on a Node.js backend for all personal finance features. Expenses, incomes, bills, plans, dashboard summaries, and analytics can be computed and stored locally for a single-user personal finance workflow.

## Decision
Use a local SQLite database accessed through Drift for personal finance data. Keep backend dependency out of personal repositories. Treat collaboration and cloud account workflows as server-only features.

## Consequences
- The app can start and operate without login or network access.
- Personal data is stored on the device.
- Collaboration is not available for local personal groups/plans.
- Future cloud sync should be added as a deliberate sync layer with conflict rules, not as direct backend calls from UI screens.

