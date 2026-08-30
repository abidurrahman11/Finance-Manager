# Testing Guide

## Required Commands
- `flutter analyze`
- `flutter test`

## Priority Tests
- Local repository CRUD for expenses, incomes, bills, bill payments, plans, and plan items.
- Analytics calculations from deterministic local fixtures.
- Routing starts at `/dashboard` without login.
- Collaboration mutation methods throw a clear local-mode error.

## Known Current State
- The existing widget test is a default counter-style placeholder and should be replaced.
- The analyzer currently reports pre-existing style and deprecation issues, mostly `withOpacity` and minor unused symbols.

## Test Data Rules
- Use fixed dates for analytics tests.
- Avoid tests that depend on the real current month unless the test explicitly validates month selection behavior.
- Use an isolated database instance for repository tests; do not touch the real app database.

