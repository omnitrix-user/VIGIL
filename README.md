# VIGIL

**An AI witness to human transformation.**

A design specification for an iOS application. This repository contains
the product architecture, design decisions, and authored copy for VIGIL —
a behavioral software product currently in the design phase.

This is not a shipped product. The README, design documents, and
specifications in this repository represent approximately 30 hours of
structured product design work, paused intentionally to focus on other
projects. Build phase is planned for a future cycle.

---

## What VIGIL is

VIGIL is not a habit tracker. It is not a productivity app. It is not a
streak-based gamification product.

It is an AI system that remembers what a user said they wanted to become,
tracks whether their behavior matches that stated identity over time, and
reflects this back to them with restraint, specificity, and emotional
weight.

The product is designed for a specific user — the serious self-improvement
audience, roughly ages 19–26, who has already tried and abandoned multiple
productivity systems and is looking for something that takes their
ambition seriously without embarrassing them.

The product thesis is one line:

> **VIGIL remembers who you said you wanted to be.**

---

## Why this exists

Most behavioral software optimizes for engagement metrics: daily active
users, session length, streak retention. The mechanisms used to achieve
these metrics — manufactured urgency, streak anxiety, dopamine loops,
social performance theater — produce short-term retention but rarely
produce real behavior change.

VIGIL is designed around an opposite hypothesis: that the deepest form of
behavioral software does not maximize engagement, it maximizes
*transformation*, and that a product which successfully transforms a user
should become less necessary to them over time, not more.

This requires rejecting most conventional product design patterns. No
streaks. No leaderboards. No notifications designed to manufacture FOMO.
No gamification of identity. The product is designed to fade in
importance as the user's stated values and observed behavior come into
alignment — and to do so without losing the user's long-term attachment
to the *record* of their transformation.

---

## Core architecture

VIGIL is structured around three primary systems.

### 1. The daily ritual

A two-beat structure that brackets the user's day:

- **Morning Directive.** The AI issues one named directive for the day,
  derived from the user's stated commitments, recent behavior, and current
  arc. Two sentences. The user accepts, modifies, or rejects.
- **Evening Reckoning.** The user marks the day as done, partial, or
  missed, optionally with a brief note. The AI responds.

Everything else in the product is available but optional. The two-beat
ritual is the only required interaction.

### 2. The layered memory system

The AI's intelligence is built on a structured, multi-layered memory
rather than naive context-stuffing or vector search.

- **Charter.** The user's stated values, commitments, fears, and
  aspirations, stored verbatim with timestamps. Updated only through
  explicit user-initiated supersession; old versions are preserved.
- **Ledger.** Append-only behavioral log of every directive, response,
  and reckoning, with reasons and outcomes.
- **Observed Patterns.** Weekly-generated prose observations about the
  user's behavior, written in clinical third-person voice.
- **Tension Map.** Cross-references stated values against observed
  behavior, scored by severity. The basis for the contradiction
  mechanic.
- **Behavioral Gravity.** Monthly-generated propositions about the
  user's conditions of strength and weakness — environments, states,
  and contexts that influence adherence.

The AI's outputs are not generated against a generic conversation
history. They are generated against this structured memory, with each
layer playing a specific role.

### 3. The dossier

A prose document the system maintains about the user, organized into
sections of varying update cadence:

- Identification and intake synthesis (frozen from day zero)
- Current Charter, with full supersession history
- Phase history
- Behavioral gravity observations
- Active tensions between stated values and observed behavior
- The Record (chronological access to the full Ledger)
- Transformations (quarterly comparative observations across time)

The dossier is the artifact that survives even when the user stops
opening the app daily. It is designed as the durable evidence of the
user's transformation — the thing the user does not delete, even years
after they stop using the product actively.

---

## Key design decisions

These decisions are documented in detail in `/docs/design-decisions.md`.
Summary:

| Decision | Choice | Rationale |
|---|---|---|
| Streaks | None | Streak anxiety reinforces performance theater rather than identity change. The only counter is "days on record" — incremented continuously, never reset. |
| Phase recognition | Observational, not awarded | The system *recognizes* phase transitions based on evidence. Users cannot earn or unlock phases. |
| Contradiction firing | Rare, gated, evening-only | The AI surfaces contradictions between stated values and observed behavior with a 14-day cooldown per commitment and a 21-day minimum spacing across all contradictions. Frequency is the enemy of weight. |
| AI voice | Quiet, observational, third-person about the user | The AI never praises, never hypes, never uses emoji. The default register is closer to a clinician's case notes than a coach's pep talk. |
| Recovery from collapse | Named without shame, met with reduced friction | When a user goes silent for 5+ days, the system stops issuing directives and stops notifying. On return, the gap is acknowledged factually and the next directive is intentionally smaller. |
| Engagement model | Fade-out, not maximization | The product is designed to require less interaction over time as the user's behavior stabilizes. Quiet engagement is treated as graduation, not churn. |

---

## What this repository contains

This is a design specification repository, not a code repository. Current
contents:

- `README.md` — this document
- `/docs/product-thesis.md` — the full product philosophy and target user
- `/docs/architecture.md` — detailed system architecture across all
  layers
- `/docs/onboarding.md` — the 5-movement intake interview specification
- `/docs/daily-ritual.md` — morning directive and evening reckoning
  mechanics
- `/docs/memory-system.md` — the five-layer memory architecture
- `/docs/dossier.md` — dossier structure, sections, and update cadences
- `/docs/contradiction-mechanic.md` — when and how the AI surfaces
  contradictions between stated values and behavior
- `/docs/recovery.md` — collapse detection and re-entry handling
- `/docs/phase-system.md` — phase recognition criteria and transition
  messages
- `/docs/ai-voice.md` — the AI's tonal constraints, forbidden patterns,
  and authored examples
- `/docs/visual-register.md` — typography, color, spacing, and animation
  specifications
- `/copy/` — hand-authored copy for the highest-stakes screens

---

## Planned implementation

When the build phase begins, the stack will be:

- **iOS:** Native, SwiftUI, iOS 17+
- **Backend:** Supabase (auth, Postgres, edge functions)
- **AI:** Anthropic Claude API, server-side. Opus for high-stakes
  generation (witnessing synthesis), Sonnet for everyday generation
  (morning directives, reckoning responses).
- **Distribution:** TestFlight for alpha, App Store for release

The implementation is intentionally not started yet. The design work in
this repository is the foundation; the implementation will follow once
time and resources allow it to be built with the care the design
requires.

---

## Status

**Phase: Design complete, build deferred**

Active design work paused at the end of the architecture and copy
specification phase. Resumption planned post other portfolio commitments.

This document and the specifications in this repository represent the
state of thinking as of the design pause. They are not yet a built
product. They are the product as designed — sufficient detail that the
build phase, when it begins, will not require redesigning the system,
only implementing it.

---

## Acknowledgements

The product design was developed through extended structured conversation
with Claude (Anthropic), used as a thinking partner rather than as a
generation tool. The voice of VIGIL itself, when it eventually ships, will
be hand-authored — not generated.

---

## Author

Ayush Srivastava

First-year CS student
---
