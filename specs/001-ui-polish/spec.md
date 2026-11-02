# Spec: UI Polish — Responsive Shell and Lot Schematic

## Problem Statement
The app is a phone layout rendered full-bleed in a desktop browser. At 1440px
the login inputs stretch to 1340px, the home slot cards become 690x570px, and
the bottom nav spans the full window. Demos run on a laptop and projector, so
this is the first thing a panel sees. The home screen also spends ~340px per
card to communicate two facts ("P1", "Available").

## Target User
Panel members and end users viewing the deployed app on a laptop browser, and
drivers using it on a phone.

## Core User Journey
A visitor opens the app on any screen size, immediately sees which bays are
free, and reserves one without the layout breaking.

## Success Metrics
- No horizontal scroll and no element wider than 1120px at 1440px viewport.
- Slot cards are 160–320px wide at every breakpoint.
- Login form is 460px wide and horizontally centered on desktop.
- Home screen conveys slot status without scrolling on a 900px-tall laptop.

## Features: Must-Have (v1)
- [ ] Responsive shell — Given a 1440px viewport, When the app loads, Then a
      232px left rail replaces the bottom nav and content is capped at 1120px.
- [ ] Responsive grids — Given any viewport, When slots render, Then each card
      is between 160 and 320px wide.
- [ ] Centered auth forms — Given a 1440px viewport, When login renders, Then
      the form column is 460px wide and centered vertically and horizontally.
- [ ] Lot schematic on home — Given slot state, When home renders, Then six
      bays, an aisle, and two gate arms are drawn from existing provider state.

## Features: Out of Scope (NOT v1)
- Any change to services, provider logic, or Firestore documents.
- New dependencies.
- Light theme.
- Animations beyond entry stagger and gate state.

## Edge Cases & Error States
- Narrow 320px window: grids fall to one column, never overflow.
- No slots loaded yet: skeleton cards in the same grid shape.
- Firestore error: error banner with retry, rail/nav stays usable.
- Long plates or names: single line with ellipsis, never wrap the card.
