# Tasks: UI Polish

One at a time, verify before the next.

## Task 1: Responsive shell
- **Inputs:** `lib/constants/app_constants.dart`, `lib/screens/main_screen.dart`,
  `lib/tabs/home_tab.dart`, `lib/tabs/reserve_tab.dart`,
  `lib/screens/login_screen.dart`, `lib/screens/register_screen.dart`
- **Outputs:** `AppLayout` tokens; rail at >=1000px; content capped at 1120px;
  grid delegates switched to max-extent; auth forms centered at 460px.
- **Verification:** `flutter analyze` clean; screenshots at 1440x900 and
  390x844 show no overflow and cards 160â€“320px wide.

  **Status: PASS.** `flutter analyze` 0 errors (78 pre-existing infos/warnings),
  `flutter build web --release` succeeds. At 1440x900: rail present, content
  capped at 1120, cards 260px wide, form column ~412px (460 box less 24px
  gutters). At 390x844: bottom nav, 2-up grid, cards 170px wide. No overflow.

## Task 2: Design tokens + contrast
- **Inputs:** `lib/constants/app_constants.dart`, all `AppTextStyles` call sites
- **Outputs:** six-size type scale, `textMuted` -> `#7E97AE`, spacing/radius
  tokens replaces inline values.
- **Verification:** grep shows no font size outside the scale; contrast check
  on `#7E97AE` over `#0D1B2A` >= 4.5:1.

  **Status: PASS.** Remaining `fontSize` values are only 12/14/16/20/28/40.
  `textMuted #4A6278` (2.74:1) replaced by `#7E97AE` â€” 5.74:1 on `#0D1B2A`,
  5.38:1 on `#162032`. No numeric `BorderRadius.circular(N)` left; all use
  `AppRadius.xs|md|lg|xl`. Gaps use `AppSpacing`. Screenshots at 1440x900 and
  390x844 in `screenshots/`; no overflow at either width.

## Task 3: Lot schematic widget
- **Inputs:** `lib/models/parking_slot.dart`, `lib/providers/parking_provider.dart`,
  `lib/widgets/`
- **Outputs:** `lib/widgets/lot_map.dart`; home screen uses it in place of the
  six-card grid.
- **Verification:** all four slot states render correctly against live data;
  screenshot at both widths.
  **Status: PASS (revised after review).** `lib/widgets/lot_map.dart` replaces
  the six-card grid. **Revision:** the first build used a drive aisle with IN/OUT
  gate arms; review rejected it â€” the aisle carried no data and the barrier read
  "Closed" almost permanently, which looks broken. The map is now a row of
  painted bays (six across on desktop, 3+3 under 560px) with shared divider
  lines, the bay number painted on the floor, a faint painted "P" in empty bays,
  and a solid top-view car in occupied (red) and reserved (amber) bays with the
  plate underneath. The signed-in user's own hold shows its countdown instead.
  Barrier state is no longer shown on the dashboard. Read-only: every value
  comes from provider state. Verified at 1440Ã—900 and 390Ã—844
  (`screenshots/task3-home-1440.png`, `task3-home-390.png`); mixed statuses and
  the car rendering were approved from a throwaway mock
  (`screenshots/task3-states.png`), since live Firestore has no reserved or
  occupied bays. `flutter analyze` 0 errors, `flutter build web --release`
  succeeds.

## Task 4: States + copy pass
- **Inputs:** all screens
- **Outputs:** skeleton, empty, and error states; remove emoji greeting, repeated
  row instructions, and warning-triangle role badge.
- **Verification:** toggle Firestore offline to see error and skeleton; copy
  review against `design-anchor.md` banned list.
  **Status: PASS (error banner code-verified, not screenshotted).**
  Home: `LotMapSkeleton` (pulsing placeholder, same footprint as the map) shows
  until the first slot snapshot; a dismissible red "Live data unavailable"
  banner appears on `provider.error`; stat values show `â€“` instead of `0`
  while data is pending; an empty-data panel covers a permanently empty lot.
  Greeting emoji removed. Reserve: 2-up slot grid (1 column under 600px) with
  the repeated "Available â€” Tap to reserve" line removed and a real empty
  state. Profile: horizontal identity card and an icon-based role chip instead
  of the emoji badge. Verified at 1440Ã—900 and 390Ã—844 â€”
  `screenshots/task4-home-1440.png`, `task4-home-390.png`,
  `task4-reserve-1440.png`, `task4-reserve-390.png`,
  `task4-profile-1440.png`, plus the skeleton via a temporary harness
  (`task4-skeleton.png`, harness deleted). `flutter analyze` 0 errors,
  `flutter build web --release` succeeds.
## Task 5: Remove demo credentials from the login screen
- **Inputs:** `lib/screens/login_screen.dart`, `lib/constants/app_constants.dart`
- **Outputs:** `lib/screens/login_screen.dart`
- **Verification:** login page shows no credential hints at 1440px and 375px;
  guest/admin accounts still sign in when typed manually.
  **Status: PASS.** The "Demo Credentials" card, the Guest/Admin tap-to-fill
  buttons, and their `_fillGuest` / `_fillAdmin` helpers were deleted so no
  password is visible anywhere on the login page. The accounts themselves are
  untouched — `lib/services/auth_service.dart` still honours them when typed
  (portfolio preview keeps working, the credentials just aren't advertised).
  Verified at 1440×900 and 375×812 (`screenshots/task5-login-1440.png`,
  `task5-login-375.png`). `flutter analyze` 0 errors, `flutter build web
  --release` succeeds.
