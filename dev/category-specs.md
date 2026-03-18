# Category Specs — All Shipped

> All five categories shipped by 2026-03-14. Built with Claude Code.
> This file is a post-implementation design record documenting the "why" behind each category.

---

## Transport ✅ Shipped

> Status: Implemented
> See: `lib/models/transport_mode.dart`, `lib/screens/add_entry_screen.dart`

### What It Tracks

Daily transport-related CO2 emissions from walking, cycling, public transit, car, motorcycle, taxi, and aviation.

### User Flow

1. Tap "+" on home screen → opens Add Entry screen
2. Select date (defaults to today)
3. Pick transport mode from categorized grid (zero-emission, public, car, other)
4. Enter distance in km or miles
5. Quick-fill buttons: 5, 10, 25, 50, 100
6. For car modes: set number of passengers (1–8) for carpooling split
7. See live CO2 preview with comparison ("like charging 500 smartphones")
8. See smart suggestion if a greener alternative exists
9. Optional: add a note
10. Save → returns to home screen with updated dashboard

### Data Model

- `EmissionEntry` with category=transport, subCategory=mode enum name
- Value = distance in km (stored internally, converted for display)
- co2Kg = calculated at save time using mode factor / passengers

### Emission Factors

16 modes ranging from 0.000 (walking) to 0.210 (large car/taxi). See `dev/data-sources.md` → Transport Emission Factors.

### Dashboard Integration

- Today's total CO2 (transport + all unlocked categories)
- This week / this month totals
- 7-day bar chart
- Mode breakdown (list showing which modes contribute most)
- Daily budget meter (Paris Agreement 2030 target: 6.3 kg CO2/day)

### Normal Person Journey

**2-tap minimum path:** tap mode → tap distance chip → glance at result → tap Save. Total: 4–8 seconds.

Key design decisions:
- Top 6 modes (car, bus, walk, bike, metro, train) cover ~90% of trips — visible without scrolling
- "Medium Car" pre-highlighted as default (most common vehicle type)
- Quick-fill chips for distance (5, 10, 25, 50, 100 km)
- Passengers shown AFTER distance (don't front-load complexity)
- Flights: offer hour-based entry ("2 hrs") since users know duration not distance

### Resolved Open Questions

| Question | Decision |
|----------|----------|
| Round-trip shortcut? | v2.2 "My Commute" feature |
| Flight distance UX? | Flight hours, not km (users know hours, not great-circle distance) |
| Car sub-type default? | Pre-highlight "Medium Car" |
| Coach vs bus? | Merged under "Bus" |

---

## Food & Diet ✅ Shipped

> Status: Implemented
> See: `lib/models/meal_type.dart`, `lib/screens/add_food_screen.dart`

### Goal

Track the carbon impact of diet without requiring users to weigh ingredients or scan barcodes. Simplicity and behavior awareness over precision.

### Data Model

```dart
enum MealType {
  plantBased('Plant-based', 0.5),
  chickenOrFish('Chicken or fish', 1.0),
  inBetween('In between', 1.5),
  redMeat('Red meat', 3.3),
  fastFood('Fast food', 2.5),
  snack('Snack', 0.2);
}

enum MealSlot { breakfast, lunch, dinner, snack }
```

EmissionEntry: category=food, subCategory=mealType.name, value=1.0, co2Kg=factor.

### Tracking Methods

**Method 1: Meal Logging (Primary)**
1. Tap "+" → Food tab
2. Meal slot pre-selected by time of day (breakfast 5–10am, lunch 10am–3pm, dinner 3–9pm, snack 9pm–5am)
3. Pick from 5 options: Plant-based / Chicken or fish / Red meat / Fast food / In between
4. Snack slot: zero-decision, auto-logs at 0.2 kg
5. Save

**Method 2: Weekly Diet Profile (Secondary)**
Settings → Diet Profile → steppers for each meal type (21 meals/week) → auto-populates food baseline.
Activated automatically if no meal logged in 5+ days.

### Why 5 options instead of 9

| Merged from | Into | Why |
|-------------|------|-----|
| Vegan (0.4) + Vegetarian (0.6) | Plant-based (0.5) | Normal people don't distinguish |
| Chicken (1.2) + Pescatarian (0.8) | Chicken or fish (1.0) | Both are "lighter" proteins |
| Beef (3.5) + Lamb (3.0) | Red meat (3.3) | No meaningful CO2 distinction for users |
| Pork (1.5) | In between (1.5) | Catches mixed meals ("pasta with a bit of bacon") |

### Dashboard Integration

- "Today's Meals" card: 3 slot icons (breakfast/lunch/dinner), empty = gentle prompt, filled = checkmark + kg
- Daily food CO2 alongside transport under the budget bar
- Weekly food chart: stacked bar by meal type

### UX Principles

1. No food shaming — celebrate greener choices, don't shame heavier ones
2. Speed over precision — a meal log should take <5 seconds
3. "In between" is crucial — catches meals that don't fit neatly
4. No calorie counting — this is a carbon app, not a diet app

### Resolved Open Questions

| Question | Decision |
|----------|----------|
| Homemade vs. restaurant modifier? | No — too much friction |
| Ingredient-level logging? | No — violates speed principle |
| Mixed meals? | "In between" option (1.5 kg) |
| Food waste in Food or Waste? | Waste category owns it |
| Too many meal types? | Reduced from 9 to 5 |

---

## Home Energy ✅ Shipped

> Status: Implemented
> See: `lib/services/energy_calculator.dart`, `lib/screens/energy_setup_screen.dart`

### Goal

Help users understand the carbon impact of home energy use. Set-and-review category — monthly bill entry, not daily logging.

### Setup Flow (4-screen wizard)

1. **Country / Region** → determines grid intensity (most impactful variable)
2. **What heats your home?** → checkboxes: Electric / Gas / Oil / Wood / Not sure
3. **Who lives with you?** → visual household size (1 / 2 / 3–4 / 5+)
4. **How do you want to track?** → Estimate (popular) or Enter bills

State/region picker shown only for US, CA, AU (significant intra-country variation).

### Tracking Methods

**Method 1: Monthly Bill Entry**
- Electricity: kWh or cost (cost → kWh via country average price)
- Gas: kWh, m³, or therms (auto-converted)
- Monthly nudge card on dashboard around 1st–5th of month
- "Skip this month" uses last month's value

**Method 2: Quick Estimate (default for most users)**
- Country average consumption × heating type × household scaling factor
- Shows as steady monthly figure: "Estimated: 85 kg CO₂/month"
- Adjust slider: 0.5x–2.0x multiplier for "less/more than average"

**Method 3: Smart Meter (future — v2.x)**

### Data Model

```dart
// Singleton profile (DELETE + INSERT in transaction)
EnergyProfile { country, region, heatingType, householdSize, trackingMode }

// Monthly bill entry
EmissionEntry.energy(
  date: DateTime(2026, 2, 1), // first of billing month
  subCategory: 'electricity' | 'gas',
  value: kWhConsumed,
  co2Kg: kWh × gridIntensity × scalingFactor,
)
```

Dashboard shows `dailyAvgCO2` (monthly ÷ days) so it's comparable to daily transport/food.

### Household Scaling

Non-linear — a single person still needs heating and lighting:

| Size | Factor | Meaning |
|------|--------|---------|
| 1 | 0.47 | Uses ~47% of avg household energy |
| 2 | 0.42 | Each uses ~42% |
| 3 | 0.33 | Each uses ~33% |
| 4 | 0.28 | Each uses ~28% |
| 5+ | 0.22 | Each uses ~22% |

See `EmissionFactors.householdScale` in `lib/data/emission_factors.dart`.

### Dashboard Integration

Energy shows as daily average ("2.8 kg/day, avg from bill") alongside transport/food. Seasonal pattern visible in month-over-month trend. Grid context: "Your electricity is X% cleaner than global average."

### Resolved Open Questions

| Question | Decision |
|----------|----------|
| Dynamic/spot pricing? | Ignore; use average |
| Heating degree days? | No — too complex for normal users |
| Solar self-generation? | "Enter net consumption from bill" |
| Users who don't know heating type? | "Not sure" defaults to country average |

---

## Shopping & Consumption ✅ Shipped

> Status: Implemented
> See: `lib/models/shopping_item.dart`, `lib/screens/add_shopping_screen.dart`

### Goal

Make users see the carbon cost of purchasing habits. Most discretionary category → most responsive to behavior change.

### Data Model

```dart
// Condition multipliers
enum ShoppingCondition {
  newItem(1.0),
  secondHand(0.10),   // transport + resale processing
  repaired(0.05);     // parts + labour; lower than second-hand
}

// EmissionEntry
value = co2KgNew (manufacture-only, new item)
co2Kg = item.co2Kg(condition)
savings = value − co2Kg
subCategory = "ItemName__conditionName" (double underscore)
```

Note: `repaired` condition excluded from UI for now (no flow designed yet — see `add_shopping_screen.dart`).

### Item Catalog (25 items, synonym search)

| Category | Item | kg CO2e (new) |
|----------|------|--------------|
| Electronics | Smartphone | 70 |
| Electronics | Laptop | 200 |
| Electronics | Tablet | 100 |
| Electronics | TV | 150 |
| Electronics | Gaming console | 100 |
| Electronics | Headphones | 10 |
| Clothing | T-shirt | 3 |
| Clothing | Jeans | 14 |
| Clothing | Winter jacket | 20 |
| Clothing | Shoes | 10 |
| Furniture | Sofa | 150 |
| Furniture | Mattress | 100 |
| Furniture | Wooden table | 50 |
| Other | Book | 1.5 |
| Other | Online package (avg) | 0.5 |

### UX: Search-first catalog

"What did you buy?" → search field + 4 category tiles (Clothing / Tech / Home / Other). Fuzzy matching: "trainers" → Shoes, "telly" → TV.

After selection: show "NEW = X kg" vs "SECOND-HAND = X×0.10 kg" side by side. The 10x difference is visceral. No lecture needed.

### Second-Hand Celebration

On saving a second-hand item: full-screen celebration via `pushReplacement`. Shows savings vs. new + lifetime total. Running "lifetime second-hand savings" metric on dashboard.

### Resolved Open Questions

| Question | Decision |
|----------|----------|
| Barcode scanning? | No — massive complexity, category-level is good enough for awareness |
| Gifts? | Log as normal purchase; skip if received |
| Services? | No — hard to quantify, not worth friction |
| Price-based estimation? | No — item-type is better proxy than price |

---

## Waste & Recycling ✅ Shipped

> Status: Implemented
> See: `lib/models/waste_setup.dart`, `lib/screens/add_waste_screen.dart`

### Goal

Make waste visible. Even though waste is a smaller fraction of total emissions, tracking it creates an awareness loop that influences upstream behavior (buying less packaging, choosing recyclable materials).

### Setup Flow (2 screens)

1. **What bins do you have?** → General waste ✓, Recycling ✓, Food waste, Compost (pre-check most common)
2. **Own bins or communal?** → determines tracking method (fill slider vs. bag count)

### Emission Factors (EPA WARM)

| BinType | kg CO2e/kg |
|---------|-----------|
| generalWaste | 0.58 |
| recycling | −0.30 (net saving vs. landfill) |
| foodWaste | 0.70 |
| compost | 0.05 |

Recycling entries have `co2Kg < 0` — signed totals are intentional.

### Data Model

```dart
// EmissionEntry.waste stores kgWeight in value (not fill fraction)
// so recycling rate and CO2 can be computed without setup context at query time
value = kgWeight
co2Kg = kgWeight × disposalFactor (negative for recycling)
```

Volume → mass:
```
own bins:   kgWeight = capacity_L × fill_fraction × 0.2 kg/L
communal:   kgWeight = bag_count × 3 kg
```

### Habit Tracking Layer

Daily quick-check habits (reusable bag / bottle / cup) tracked via `HabitLog`. Streak: active only if today or yesterday appears in log (expired → 0). All habit types enabled by default; each can be toggled in settings.

### Dashboard Integration

Compact two-line row: "2.1 kg CO₂ | Recycling: 52%" + optional habit streak. Recycling rate is the primary metric (more motivating than absolute CO2 for this category).

### Resolved Open Questions

| Question | Decision |
|----------|----------|
| Weekly-only or daily habits too? | Both — weekly bin log primary, daily habits opt-in |
| Poor recycling infrastructure? | Recycling rate metric hidden; focus on waste reduction |
| Communal bins? | Bag count method (1 bag ≈ 3 kg) |
| Food waste overlap with Food? | Waste owns it — clean separation |
