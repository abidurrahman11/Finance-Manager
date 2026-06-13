# Offline-First Migration

## Goal
Reduce backend dependency by making personal finance features local-only and offline-first while preserving the current app functionality for single-user personal use.

## Offline Features
- Expenses: CRUD, category filtering, group filtering, pagination, notes, local receipt image paths.
- Incomes: CRUD, category filtering, group filtering, pagination, notes, local receipt image paths.
- Bills: recurring bill CRUD and monthly paid/pending tracking.
- Plans: personal plan CRUD, category budget items, spent amount add/subtract.
- Analytics: cash flow, category breakdown, monthly trends, and dashboard summaries computed from local data.

## Server-Only Features
- Account registration, email verification, password reset, and cloud identity.
- Expense group collaborators.
- Income group collaborators.
- Plan collaborators.

## Implementation Notes
- Local personal mode uses `userId = 1`.
- Local groups and plans always use `role = owner`.
- Collaboration repository methods should return empty collaborator lists for local records and throw a clear `ApiException` for mutating collaborator actions.
- Routing must not block personal app usage behind login.

## Acceptance Criteria
- Fresh install opens to dashboard without backend availability.
- Creating, editing, deleting, and listing personal records works with airplane mode enabled.
- Analytics and dashboard reflect local transactions and bill payments.
- Collaboration actions do not call the backend for local personal records.

