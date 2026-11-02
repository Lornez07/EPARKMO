# Design Anchor — E-Park Mo

Locked visual language for the Flutter app. Every UI change must fit this file.
Derived from the shipped build at `https://e-park-mo-fe42a.web.app` (Nov 2026).

## Direction

A real-time control surface for **one physical parking lot**, not a phone mockup
stretched to a browser. Dark, dense, instrument-panel. The lot schematic is the
focal point of every screen; navigation and chrome recede. One accent color
(teal) marks anything interactive. Status colors carry all semantic meaning.

Test for any new element: *would this look at home in a building lobby kiosk?*
If it only makes sense on a phone, it is wrong for this project.

## Palette

| Role | Token | Hex | Usage |
|------|-------|-----|-------|
| Page background | `AppColors.bgDark` | `#0D1B2A` | Scaffold, page base |
| Background mid | `AppColors.bgMid` | `#1B263B` | Gradient end |
| Card surface | `AppColors.bgCard` | `#162032` | Solid cards, rail, dialogs |
| Accent | `AppColors.primary` | `#14C1C7` | Primary action, active nav, focus |
| Accent pressed | `AppColors.primaryDark` | `#109DA2` | Pressed/active states only |
| Available | `AppColors.available` | `#2ECC71` | Slot is free |
| Reserved | `AppColors.reserved` | `#F1C40F` | Slot is held by a user |
| Occupied | `AppColors.occupied` | `#E74C3C` | Car physically present |
| Text primary | `AppColors.textPrimary` | `#E8F4F8` | Headings, values |
| Text secondary | `AppColors.textSecondary` | `#8BA5BE` | Labels, body |
| Text muted | `AppColors.textMuted` | `#7E97AE` | Meta only, never below 12px |
| Hairline | `AppColors.glassBorder` | `#33FFFFFF` | 1px separators, card borders |

**`#4A6278` (the old textMuted) is retired.** It scored 3.0:1 on `#0D1B2A` and
failed WCAG AA. Any text that survives review uses `#7E97AE` or lighter.

Status colors are never decorative. A teal number is interactive; a green
number means free; nothing else.

## Typography

Two families only: **Outfit** for headings and numeric values, **Inter** for
body and UI labels. No third family, ever.

| Role | Family | Size / Weight | Use |
|------|--------|---------------|-----|
| Display | Outfit | 28 / 700 | Screen title |
| Title | Outfit | 20 / 600 | Section title, slot number |
| Subtitle | Outfit | 16 / 600 | Card heading |
| Body | Inter | 14 / 400 | Paragraphs, list rows |
| Meta | Inter | 12 / 400 | Timestamps, captions, units |
| Numeric | Outfit | 28–40 / 700, tabular | Countdown, occupancy count |

The old scale (10, 11, 13, 15, 18, 24, 32) is retired. Six sizes, no exceptions.
Letter spacing: `-0.5` on Display only; `0.6` on uppercase meta labels.

## Spacing & Radius

- **Space scale:** 4 / 8 / 12 / 16 / 24 / 32 / 48. Nothing else.
- **Page gutter:** 20 mobile, `((viewportWidth - 1120) / 2)` desktop (min 20).
- **Card padding:** 16. Dialog padding: 24.
- **Row gap:** 12. Section gap: 24. Screen top: 20.
- **Radius:** 4 progress bars and hairlines, 12 inputs and tiles, 16 cards,
  24 dialogs and sheets. No 8, no 10, no 14, no 18, no 20, no 26.

## Layout

| Breakpoint | Width | Structure |
|------------|-------|-----------|
| Mobile | `< 600` | Bottom glass nav, single column, 2-up slot grid |
| Tablet | `600–999` | Bottom glass nav, 2–3 column grids |
| Desktop | `>= 1000` | 232px left rail, content capped at 1120, 4-up slot grid |

Desktop is the presentation target (laptop + projector). It must never scroll
horizontally and no card may exceed 320px wide.

## Signature Element

**The lot schematic.** A top-down plan of the six bays with a drive aisle and
an entrance and exit gate arm. Bays are color-coded by status; an occupied bay
shows the plate, a reserved bay shows a countdown ring, and the gate arm
animates when `barrierOpen` / `exitBarrierOpen` is true.

This is the one thing a panel should remember. It replaces the six oversized
status cards on the home screen. Built entirely from existing provider state —
no new data, no new logic.

## Motion

- 200–250 ms, `Curves.easeOut` for entry and state change.
- No infinite animations except the gate arm while a barrier is open.
- Stagger slot entries by 40 ms, maximum 6 items.
- Honor `MediaQuery.disableAnimations`.

## Banned List (specific to this project)

- Emoji in UI copy (including the `👋` in the greeting).
- Glassmorphism on more than two surfaces per screen: the nav (mobile) and one
  hero card. Everything else is solid `#162032` with a hairline border.
- Three equal stat cards as a screen's hero element.
- Text smaller than 12px.
- Repeated instructions per row ("Available — Tap to reserve" × 6).
- Gradient fills on ordinary cards; gradients are for the page background and
  the single active/urgent card only.
- Warning-triangle iconography for a neutral role badge (`Guest`).
- Purple, blue-purple, or any second accent hue.

## Required States

Every screen that reads Firestore ships all four:

- **Loading** — skeleton rows in the shape of the final content, not a spinner
  alone.
- **Empty** — says what is true and what to do next ("All 6 bays are taken.
  Free one up from the dashboard.").
- **Error** — names the failed operation and offers retry.
- **Success** — the state itself is the confirmation; no toast required.

## Assets

- Logo: `assets/images/app_logo.png` only. No new image assets without a spec.
- Iconography: Material rounded icons at 18 / 20 / 22. No emoji, no icon fonts.
