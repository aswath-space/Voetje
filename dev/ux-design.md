# Voetje UX Design Reference

This document is the canonical UX design reference for the Voetje carbon tracker app. It defines the visual system, component specifications, screen layouts, animations, and design principles that guide all user-facing implementation. This reference works alongside `architecture.md`, `category-specs.md`, and other dev documentation.

**Last Updated:** 2026-03-18

---

## 1. Design Direction

**Style:** Soft Minimal + Rich Green — a quiet, premium aesthetic with warm organic identity.

**Visual Reference:** Apple Health meets Headspace, with eco personality.

### Core Principles

- **Clean over busy** — fewer elements, more whitespace, stronger hierarchy
- **Empower, don't guilt** — the ring shows budget honestly but logging always feels positive
- **Category identity through color** — blue (transport), orange (food), purple (energy), amber (shopping), teal (waste)
- **Icons over emojis** — consistent thin outlined icon set, no boxy grey frames
- **Progressive disclosure** — show what's needed, reveal depth on tap

---

## 2. Design System

### Typography

**Font:** Plus Jakarta Sans via `google_fonts` package

**Weights:**
- 500 (body)
- 600 (labels/emphasis)
- 700 (headings/numbers)
- 800 (hero numbers)

**Scale:**
- Hero number: 26-30px, weight 700
- Page title: 20px, weight 700, letter-spacing -0.3px
- Section header: 14px, weight 700
- Section label: 11px, weight 700, uppercase, letter-spacing 0.8px
- Body: 13px, weight 500
- Caption: 10-11px, weight 500

**Title Colors:**
- Page titles: #1B5E20 (dark green)
- Content headings: #1a2e1a

### Color Palette

**Backgrounds:**
- App background: #E4F0E2 (rich green)
- Card/surface: #FFFFFF
- Card subtle: #fafafa
- Still-to-log background: rgba(255,255,255,0.6)

**Brand:**
- Primary: #1B5E20 (dark green — titles, selected chips, buttons)
- Primary medium: #2E7D32 (toggles, active nav, "+ Add" text)
- Primary light: #66BB6A (nudge icons, positive indicators)

**Category Identity Colors:**
- Transport: #42A5F5 (blue) — background: #E8F1FC / #E3F2FD
- Food: #FF8A65 (orange) — background: #FBE9E7
- Energy: #9575CD (purple) — background: #EDE7F6
- Shopping: #FFA726 (amber) — background: #FFF3E0
- Waste: #26A69A (teal) — background: #E0F2F1

**Ring Threshold Track Colors:**
- 0–60% used: #e8e8e8 (neutral gray) — subtitle: "of 6.3 kg" in #999
- 60–90% used: #FFE082 (amber) — subtitle: "X.X kg left" in #F9A825
- 90–100% used: #EF9A9A (coral) — subtitle: "X.X kg left" in #EF5350
- 100%+: no track visible — center text switches to "Over budget" header + "+X.X kg" as big number, both in #EF5350

**Neutrals:**
- Text primary: #1a2e1a
- Text secondary: #4a5e4a
- Text muted: #6b8a6b
- Label/caption: #85a085 / #93ab93
- Inactive nav: #a0b8a0
- Borders: #c8dac4
- Dashed borders: #a8c4a4
- Dividers: #f0f4ee

**Destructive:** #EF5350

### Spacing

- Screen edge padding: 22-24px
- Card internal padding: 12-16px
- Between cards: 6-8px
- Between sections: 10-16px
- Icon-to-text gap: 10-12px
- Chip gap: 6px

### Border Radius

- Cards: 14-18px
- Buttons/chips: 16-24px (pill shape)
- Icon containers: 9-12px
- Input fields: 12-14px
- App frame: 28px
- Segmented controls: 8-10px inner, 12px outer

### Elevation

- Near-flat design: box-shadow 0 1px 3px rgba(0,0,0,0.02) for cards
- Buttons: box-shadow 0 2-4px 6-12px with tinted shadow (e.g., rgba(27,94,32,0.25) for green buttons)
- No elevation on AppBars

### Icons

- Style: thin outlined, 1.5-1.8px stroke weight
- Size: 14-18px inline, 24-26px in cards
- Container: rounded square (border-radius 8-12px) with category-tinted background
- Container size: 30-38px

### Components

**Chips (selected):** background #1B5E20, color white, font-weight 600, border-radius 20px

**Chips (unselected):** background rgba(255,255,255,0.6) or #E4F0E2, color #6b8a6b, border 1.5px solid #c8dac4, border-radius 20px

**Buttons (primary):** background #1B5E20, color white, font-weight 700, border-radius 16-24px, shadow 0 4px 12px rgba(27,94,32,0.25)

**Buttons (text):** color #2E7D32, font-weight 600, no background

**Toggles:** track #2E7D32 (on) / #c8dac4 (off), thumb white with subtle shadow

**Input fields:** background white, border 1.5px solid #c8dac4, border-radius 14px, padding 12px 14px

**Section headers:** 11px, weight 700, uppercase, letter-spacing 0.8px, color #85a085

---

## 3. Dashboard (Home Screen)

### Layout (top to bottom)

1. **App bar** — "Voetje" title in #1B5E20, settings gear icon top-right
2. **Hero ring** — category donut chart showing daily budget usage
3. **Category legend** — small colored dots with labels below ring
4. **"This week" pill** — tappable link to weekly view below ring
5. **"TODAY" header + "+ Add" inline** — section header with text button aligned right
6. **Logged entries** — timeline-style cards with category-colored icon containers, neutral checkmark styling, kg value on right
7. **"Still to log" cards** — dashed border cards for unlogged expected items (dinner, shopping), tappable to log
8. **Nudge** — forward-looking suggestion in a subtle green card (e.g., "Cycling tomorrow saves 1.8 kg")

### Hero Ring Specification

- **Type:** Multi-segment donut chart
- **Segments:** One per category, colored by category identity color
- **Track (empty space):** Shows remaining budget — color shifts at thresholds (see Color Palette above)
- **Center text:**
  - Under 100%: large number (kg used today), subtitle "of 6.3 kg" or "X.X kg left"
  - Over 100%: "Over budget" as header, "+X.X kg" as large number, "X.X of 6.3 kg" as small subtitle — all in #EF5350
- **Ring stroke width:** 10-12px
- **Ring size:** ~130-160px diameter

### Navigation

- **No FAB** — replaced by inline "+ Add" text button next to "TODAY" header
- **"Still to log" cards** are tappable shortcuts to log expected items
- **"+ Add"** opens category picker bottom sheet for ad-hoc entries
- **Bottom nav:** 3 tabs — Today, History, Settings — with thin outlined icons

### Removed Elements

- FAB ("+ Log Activity")
- Category breakdown row (emojis + kg values) — replaced by ring legend
- Today's Meals card — replaced by "still to log" cards
- Shopping/Waste/Energy dashboard cards — data lives in the ring segments
- Stat cards (This Week / This Month) — replaced by "This week" pill linking to insights
- 7-day bar chart on dashboard — moved to History screen
- Habit check row — removed from dashboard (could return as a settings feature)
- Recent activity list — the logged entries timeline IS the activity list

---

## 4. History Screen

### Layout

1. **Title** — "History" in #1B5E20
2. **Weekly summary card** — mini bar chart (7 days), total kg, trend vs. last week ("↓ 12%")
3. **Category filter chips** — All / Transport / Food / Energy / Shopping / Waste
4. **Date-grouped entries** — "Today", "Yesterday", date headers with same card style as dashboard
5. **Swipe-to-delete** preserved but hidden (no visible delete button)
6. **Infinite scroll** with pagination (30 per page)

### Key Changes

- Added weekly summary card with bar chart at top
- Added category filter chips
- Same entry card styling as dashboard (consistent icon containers)
- Removed: emoji-based category indicators → replaced with colored icon containers

---

## 5. Settings Screen

### Layout

Grouped in white cards with uppercase section labels. Three card groups: "Your Profile", "Categories", "Data"

**Your Profile:**
- Distance unit — inline segmented toggle (km/mi)
- Diet profile → drilldown (chevron)
- Energy profile → drilldown (chevron)
- Saved places → drilldown (chevron)

**Categories:**
- Transport (always on, labeled "Always on")
- Food & Diet — toggle
- Home Energy — toggle
- Shopping — toggle
- Waste & Recycling — toggle
- Each row has category-colored icon container

**Data:**
- Export → drilldown
- Import → drilldown
- Clear all data — red text, no drilldown
- About Our Data → drilldown
- Support This Project → drilldown
- About Voetje → version number

### Key Changes

- Consolidated into 3 card groups instead of 7+ separate cards
- Inline segmented toggle instead of full SegmentedButton for units
- Removed: Privacy notice card (can be part of About)
- Removed: Waste Setup as separate settings row (integrated into category toggle flow)

---

## 6. Entry Forms (Log Screens)

### Shared Patterns

- **Standalone screens** — no tab bar container. Category picker sheet → single form screen.
- **Back arrow + title** in app bar (e.g., "Log Trip", "Log a Meal", "Log a Purchase")
- **Date picker** — compact card with calendar icon, "Today" badge
- **Selection chips** — grouped by sub-category with section labels, dark fill for selected
- **Input fields** — white background, green border, rounded 14px
- **Quick-tap shortcuts** — small pale chips for common values (5, 10, 25, 50, 100 km)
- **Save button** — full-width, dark green (#1B5E20), rounded 16px, shadow
- **CO₂ preview** — shown AFTER selection as a confirmation detail, not on the selection cards

### Transport Form

1. Date picker card
2. "How did you travel?" with grouped chips (Zero Emission, Public Transport, Car, Other)
3. Route picker (if 2+ saved places)
4. Distance input with unit suffix + quick-tap shortcuts
5. Passenger picker (conditional, for car modes)
6. Note field (optional)
7. Save Trip button
8. CO₂ shown on save confirmation

### Food Form

1. Meal slot selection — pill chips (Breakfast, Lunch, Dinner, Snack) — dark fill for selected
2. "What did you eat?" — 2-column grid of meal type cards with icons + description (NO CO₂ values)
   - Plant-based: "Veg, legumes, tofu"
   - Chicken or fish: "Poultry, seafood, eggs"
   - Red meat: "Beef, pork, lamb"
   - Fast food: "Burgers, pizza, fried food"
   - "Somewhere in between" expandable option
3. Note field (optional)
4. Save button
5. CO₂ shown on save confirmation

### Shopping Form

1. Search field with icon
2. Category filter chips (Clothing, Electronics, Furniture, Other)
3. Item list — same card styling as history entries
4. Condition selector (New / Second-hand / Repaired)
5. Save button
6. CO₂ shown on save confirmation

### Energy Form

1. Electricity / Gas toggle
2. kWh or cost input with unit toggle
3. Billing month picker
4. Save button(s)

### Waste Form

1. Bin selection with checkboxes (from waste setup)
2. Fill-fraction sliders and bag-count inputs (same inputs as current, new styling)
3. Recycling section preserved
4. Save button

---

## 7. Onboarding

### Layout

- **Full green background** (#E4F0E2) — no white cards, the whole screen is the experience
- **Progress bars** at top — thin horizontal bars replacing animated dots, filled segments for completed pages
- **Skip** button top-right, subtle text style
- **4 pages:**
  1. Welcome — app name, tagline, leaf illustration
  2. Track what matters — logging explanation
  3. Privacy & simplicity — on-device, no accounts
  4. Choose categories — toggles for food, energy, shopping, waste (transport always on)
- **Large illustrations** — centered in frosted circle (white at 60% opacity, border-radius 50%)
- **Title + description** — centered below illustration, generous padding
- **Navigation** — Back (text) / Next (filled button) at bottom, evenly spaced

### Key Changes

- Progress bars instead of animated dots
- Full-bleed green background instead of white cards
- Frosted circle illustrations instead of plain emojis
- More generous whitespace and typography hierarchy
- Skip remains for impatient users

---

## 8. Setup Wizards (Energy, Waste)

### Shared Pattern

- **Progress bar** at top (thin, same as onboarding)
- **Full green background**
- **One question per page** with large title
- **Selection cards** — white cards with icon + label + checkbox, green border when selected
- **Next button** — full-width, dark green

### Energy Setup (4 pages)

1. Country picker with search field
2. Heating type — selectable cards with checkboxes
3. Household size — selectable cards or stepper
4. Tracking method — estimate vs. bills

### Waste Setup (2 pages)

1. Bin types — selectable cards (General Waste, Recycling, Food Waste, Compost)
2. Housing type — own bins vs. communal

---

## 9. Splash / Nudge Screen

- Full green background (#E4F0E2)
- "Voetje" in Plus Jakarta Sans, 700 weight, #1B5E20
- Thin progress bar at bottom
- Contextual nudge message in body text
- Tap anywhere to skip (preserved)

---

## 10. Motion & Animation

### Principles

- **Subtle, not showy** — animations serve clarity, not decoration
- **Fast feedback** — micro-interactions < 200ms
- **Meaningful transitions** — page changes 300ms with ease-out curve

### Specific Animations

- **Ring segments:** Animate in on load with staggered timing (each segment draws itself, 400ms total)
- **Threshold color transitions:** Track color and text color animate smoothly (200ms) when crossing thresholds
- **Logging an entry:** New entry slides in from right with a subtle scale-up (150ms). "Still to log" card for that category fades out (200ms).
- **Page transitions:** Shared axis motion — forward navigation slides left, back slides right (300ms, Curves.easeOutCubic)
- **Chip selection:** Quick scale bounce (100ms) on tap + color fill transition (150ms)
- **Bottom sheet:** Slide up with slight overshoot, drag handle area for dismiss (Material 3 default)
- **Ring over-budget:** When crossing 100%, center text cross-fades from number to "Over budget" message (300ms)
- **Onboarding:** Pages cross-fade with slight horizontal parallax on illustration (200ms)

### What NOT to Animate

- No bouncing, pulsing, or attention-seeking loops
- No loading spinners for instant operations
- No hero animations on data that hasn't changed

---

## 11. Dark Mode

### Approach

- Background: #121212 → #1A2E1A (very dark green tint instead of pure dark)
- Cards/surfaces: #1E1E1E → #1E2E1E (dark green-tinted surface)
- Ring track: #2A2A2A for neutral, same threshold logic but colors adjusted for dark backgrounds
- Category colors: slightly desaturated to avoid glare on dark backgrounds
- Text: #E8E8E8 (primary), #A0A0A0 (secondary), #6A6A6A (muted)
- Green accents: use #66BB6A (lighter green) instead of #1B5E20 for visibility
- Buttons: #2E7D32 background with #fff text (same as light, readable on dark)

---

## 12. Dependencies

### New

- `google_fonts` package — for Plus Jakarta Sans

### Unchanged

- `fl_chart` — bar charts in History weekly summary
- `provider` — state management
- All existing packages

### Removed

- None — this is a visual refresh, not an architecture change

---

## 13. Implementation Strategy

This is primarily a visual change. Two items touch navigation/logic:

- **Tab-bar → sheet flow** is a navigation architecture change (removing TabBarView container, changing push behavior). This is the highest-risk item.
- **History weekly summary** requires weekly comparison data from EmissionProvider (may need a new getter if not already exposed).
- **Hero ring** will use CustomPainter for the donut chart (more control than fl_chart PieChart for threshold animations).

### Approach

1. Update theme.dart with new color palette, typography, and component themes
2. Refactor screens one at a time, starting with:
   - Dashboard (highest impact, most complex)
   - Entry forms (transport, food — most used)
   - History
   - Settings
   - Onboarding
   - Setup wizards
   - Splash screen
3. Replace emojis with icons progressively
4. Add `google_fonts` dependency
5. Remove FAB, add inline "+ Add"
6. Convert tab-bar entry flow to sheet → standalone screen flow

### What Stays the Same

- All data models
- All calculators and business logic
- Provider architecture
- Database service
- Named routes structure
- All existing functionality
