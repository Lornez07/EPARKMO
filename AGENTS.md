# Project Constitution — E-Park Mo

## Stack
- Language: Dart 3
- Framework: Flutter (web, Android, iOS targets)
- Database: Firebase — Auth + Cloud Firestore
- Hosting/Deployment: Firebase Hosting — `e-park-mo-fe42a.web.app`
- Hardware: ESP32 (`firmware/eparkmo_v2.ino`) polling Firestore for slots and gates
- AI Tools: OpenCode

## Conventions
- Naming: `snake_case.dart` files, `PascalCase` widgets, `camelCase` members
- File structure: `lib/{constants,models,services,providers,screens,tabs,widgets}`
- Testing: `flutter_test`; domain logic tests live in `test/`
- Error handling: services throw, provider converts to `_error` / nullable String
- State: `provider` package, single `ParkingProvider` `ChangeNotifier`
- UI tokens: spacing, radius, type, and color come from `design-anchor.md` and
  `lib/constants/app_constants.dart`. No inline magic numbers for space or size.

## Rules (AI must obey)
- Do not change `lib/services/` or `lib/providers/` logic during UI work.
- Do not add new dependencies without asking.
- Do not rewrite working code without justification.
- Do not generate placeholder or fake data in production paths.
- All generated code includes error handling.
- Every screen ships loading, empty, error, and success states.
- Verify layout at 375px and 1440px before calling a UI task done.

## Out of Scope (for this project)
- Migrating writes to Cloud Functions (tracked as a separate spec).
- New features: payments, multi-lot, analytics.
- Rewriting the ESP32 firmware.
- Changing the Firestore collection names (`slots`, `reservations`,
  `parkingLogs`, `barrier`, `pendingOtp`, `users`) — firmware depends on them.

## Process
This project follows the Spec -> Plan -> Tasks -> Implement loop defined in the
workspace `AGENTS.md`. UI changes additionally require `design-anchor.md`.
