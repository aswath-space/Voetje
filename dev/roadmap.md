# Roadmap

> Last updated: 2026-03-18

## v1.0 — Shipped

All five emission categories, fully audited data, consolidated data layer. Built with Flutter and Claude Code.

**What's in it:**
- Transport tracking (16 modes, carpooling, airport picker, saved routes)
- Food logging (5 meal types, time-of-day slots, diet profile)
- Home energy (24 countries, state/province grid overrides, bill entry or quick estimate, electricity + gas + oil + wood)
- Shopping (25-item catalog, new/second-hand/repaired conditions, savings tracking)
- Waste & recycling (bin fill tracking, recycling rate, daily habit streaks)
- Dashboard with Paris budget bar, 7-day chart, category breakdown, contextual nudge messages
- Full data audit and source verification (see `audit-2026-03.md`)
- JSON export/import with deduplication
- In-app data sources page

**Technical:**
- SQLite schema v4 with forward migrations
- 173 passing tests
- Emission factors from DEFRA 2023/2024, IEA 2024, EPA eGRID 2023
- All country data in a single `CountryDefaults` class
- All emission factors in a single `EmissionFactors` registry

---

## What's next

Rough priority order. None of these are committed — they depend on what people actually ask for.

**Insights & goals** — Annual report, personal carbon budget with goal setting, year-over-year comparison, achievement milestones.

**Quality of life** — Recurring trips (one-tap "my commute"), home screen widgets, calendar integration, smarter suggestions based on usage patterns.

**Health data** — Read walking/cycling distance from Apple Health or Android Health Connect to auto-log zero-emission trips. On-device only.

**Better energy data** — Real-time grid intensity via NESO (UK) or Electricity Maps (international). Smart meter integration for UK users.

**Platform** — Web companion for viewing data in a browser (still local-first). Family/household mode. Teacher/classroom mode.

**Community** — Anonymous benchmarking ("you're in the top 30% in your country"). No accounts — opt-in aggregate statistics only.

---

## What I won't build

Deliberate non-features, documented so contributors don't re-propose them:

| Feature | Why not |
|---------|---------|
| Bank account linking | Conflicts with "no accounts, no servers, no data harvesting" |
| Always-on GPS tracking | Battery drain, surveillance feel, conflicts with privacy values |
| Cloud-based processing | Sends personal data to third-party servers |
| Carbon offset marketplace | Conflict of interest — app would be incentivized to inflate emissions |
| Subscription tiers | Everything works for everyone, always |

---

## Decision Log

| Decision | Reasoning |
|----------|-----------|
| Manual logging, no GPS | Privacy principle; intentional logging builds awareness |
| No carbon offsets | Conflict of interest; focus on reduction not purchasing absolution |
| Paris 2030 daily budget (6.3 kg) | Aspirational but grounded in IPCC science |
| Free + donation model | Near-zero operating costs make it viable |
| Flutter for cross-platform | Single codebase for Android, iOS, desktop |
| Local SQLite, no server | Maximum privacy, zero hosting cost, works offline |
| Progressive category unlock | Reduces cognitive load; users master one category before the next |
| Manufacture-only shopping CO2 | Use-phase emissions occur regardless of purchase decision |
| Repair < second-hand | Repair avoids a transaction entirely; fewer new materials |
