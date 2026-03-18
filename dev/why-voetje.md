# Why I Built Voetje

> Last updated: 2026-03-18

## The gap

I wanted a daily carbon tracker — something I could use to understand my personal emissions across transport, food, energy, shopping, and waste. When I looked at what existed:

- **Earth Hero** — great app, but it's a pledge/challenge system, not a quantitative tracker. You don't log actual emissions.
- **Klima** — polished, but it's a subscription offset store. Pay to "neutralize" your footprint. Not what I wanted.
- **Commons** — requires linking your bank account. Hard no.
- **Capture** — used GPS to auto-track transport. Died in 2023.
- **Ecofy** — closest to what I wanted (local storage, no accounts). Added ads that contradicted its privacy pitch. One review. Dead.

On Android specifically, there is no maintained, private, quantitative daily carbon tracker. The space is empty.

## What I built instead

Voetje: free, local-only, offline, open-source, covers all five emission categories, no account, no ads, no offsets. Built with Flutter and Claude Code.

The name is Dutch for "little footprint" (pronounced roughly "foot-yuh"). It felt right for what this is — a small, personal tool for understanding your impact.

## How I built it

I have a Master's in Sustainability — the methodology decisions (scope boundaries, factor selection, how to handle things like grid-dependent EV emissions or manufacture-only vs. lifecycle CO2) come from that background. I used [Claude Code](https://claude.ai/claude-code) (Anthropic's AI coding assistant) for the development itself. The architecture, data layer, UI, tests, and documentation were built through conversation with Claude.

I'm transparent about this because I think it matters. The domain knowledge is mine; the code was AI-assisted. Every emission factor is sourced from DEFRA, IEA, EPA, or peer-reviewed research. The code has 179 passing tests.

## How I fund it

Voetje is free. Not "free tier" — free. The app has optional support links (GitHub Sponsors, Buy Me a Coffee, Wise) but they're buried in Settings, never shown as popups, and the app works identically whether you donate or not.

What it costs to run:

| Item | Cost |
|------|------|
| Hosting | $0 (no server) |
| Play Store | $25 one-time |
| Apple Developer | $99/year (if someone builds for iOS) |
| Data sources | $0 (all public/open) |
| Claude Code (Max plan) | Used for daily work + development, not a separate cost |

I won't sell user data, show ads, sell offsets, gate features, or take VC money. Documented here so it's a commitment, not just a claim.

## Where it's behind

Being honest:

| Area | Reality |
|------|---------|
| Social/community | No accounts means no social features. Streaks and export-to-share are my substitute. |
| iOS | I don't have a Mac. The app should work on iOS via Flutter but it's untested. |
| Polished brand | v1 with a custom design system (Plus Jakarta Sans, category-colored donut ring, rich green palette). Room to grow but intentionally designed. |
| User testing | Needs real-world testing with people who aren't me. |
