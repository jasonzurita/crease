# Crease

A native iOS app for youth lacrosse coaches. Solves the single most time-consuming problem in coach prep: building fair, competitive, and constraint-aware rotation plans for games with large rosters (12–25 players).

App Store: (add when published)
Website: (add when published)

---

## Build & Workspace

- Open `Crease.xcworkspace` (at the project root) — this is the correct entry point
- The workspace includes both `modules/` (the SPM package) and `crease/crease.xcodeproj`
- Primary scheme: **crease**
- Swift Package dependencies live under `modules/`
- Test plans live in `TestPlans/` — one `.xctestplan` per module (plus `crease.xctestplan` which runs all)

## Running Tests

```
xcodebuild test \
  -workspace Crease.xcworkspace \
  -scheme crease \
  -testPlan crease \
  -destination 'platform=iOS Simulator,id=1392154F-5060-4F2B-A354-94B386551032'
```

## Module Architecture

```
CRApp
├── CRWorld
│   ├── ApplicationClient
│   ├── FileManagerClient
│   └── UserDefaultsClient
├── CRModel
├── CRDesign
└── Features/          ← added per phase; see Build Phases below
    ├── CRSeasonCreation
    ├── CRRoster
    ├── CRGameSetup
    ├── CRRotationOutput
    ├── CRPlayingTimeBreakdown
    ├── CRPostGameSummary
    └── CRSettings

BasicClients/          ← injected directly per feature, not via World
└── CodablePersistenceClient   ← generic JSON read/write, used by SeasonStore
```

## Module Naming Convention

All products and targets use the `CR` prefix. BasicClients omit the prefix.

## Dependency Injection

Dependencies use the struct-of-closures (client) pattern. Use `/create-swift-client` to scaffold new clients.

`World` holds broadly-needed system abstractions (`currentDate`, `fileManagerClient`, `userDefaultsClient`, `applicationClient`). Add to `World` only if 3+ modules need the same client directly.

`CodablePersistenceClient<A>` is generic and instantiated per-model-type inside `SeasonStore` — it is not in `World`.

## State Management

Default: `@Observable` MVVM. `SeasonStore` is the central `@Observable` class injected into the SwiftUI environment at the app root. All mutations go through it and immediately write to disk.

Use an action-based reducer only for features with complex, interdependent state transitions (e.g. the rotation output screen with undo, locking, and swap modes).

## Testing

Tests are mandatory for all feature work and bug fixes. Each module has a `.testTarget` in `Package.swift` and a `.xctestplan` in `TestPlans/`.

The rotation solver (Phase 4) is pure Swift with zero UI dependencies and requires a full unit test suite covering all constraint combinations before it is considered done.

---

## Domain Vocabulary

| Term | Meaning |
|------|---------|
| Season | A self-contained folder representing one coaching season (e.g. "Spring 2025"). Only one season is active at a time. |
| Roster | The full list of players for the active season. |
| Player | An athlete with a name, jersey number, position eligibility set, and skill tier. |
| Tier | Skill classification: Elite, Strong, Developing, Learning, Beginner. Drives playing-time minimums. |
| Position | Attack, Midfield, Defense, or Goalie. A player's eligibility set determines where they can appear in a rotation. |
| Game | A single match with an opponent, date, attendance record, format settings, and an associated rotation plan. |
| Game Plan | The rotation plan for a game — generated assignments of players to positions across all rotation slots. |
| Rotation | One assignment of players to field positions (and bench) for a given time slot. Multiple rotations make a full plan. |
| Quarter | A time division of a game. Rotations may occur at quarter breaks or on a timer within quarters. |
| Attendance | Which players are present, absent, or present with constraints (late arrival, early departure) for a specific game. |
| Conflict | A scheduling constraint on a player's availability within a game: Late Arrival or Early Departure, each with a quarter selector. |
| Boost | A per-game flag that elevates a player's effective playing-time minimum above their tier baseline for that game only. |
| Anchor | A manually pre-assigned rotation slot that the planner treats as fixed when generating around it. |
| Violation | A constraint the planner could not satisfy. Always surfaced explicitly — the solver never fails silently. |
| Competitiveness Mode | Fair, Balanced, or Competitive — controls how tier strength is distributed across rotations. |
| Rotation Style | By Quarter (one sub per quarter break) or By Time Interval (sub on a timer within quarters). |
| Lineup Card | A shareable image of the full rotation plan, designed for sideline distribution. |
| SeasonStore | The `@Observable` class that owns all in-memory season state and writes to disk on every mutation. |
| Cell Lock | A manually adjusted rotation cell that survives regeneration. Visually distinct from a formal Anchor. |

---

## Data Persistence

Flat JSON files on disk. No CoreData, no SQLite, no cloud sync in v1.

```
Documents/
└── Seasons/
    └── {season_id}/
        ├── season.json
        ├── roster.json
        └── Games/
            └── game_{id}.json
```

- Every season is a self-contained folder. Deleting a season deletes its folder entirely.
- Nothing leaks between seasons — no shared state, no shared files.
- `SeasonStore` is injected into the SwiftUI environment at the app root. All views read from it. All mutations write through it. JSON files are written immediately on every change — there is no manual save anywhere in the app.
- `CodablePersistenceClient<A>` handles the encode/decode/write/read cycle. Instantiated by `SeasonStore` for each model type.
- JSON dates use ISO 8601 encoding (`JSONEncoder.dateEncodingStrategy = .iso8601`).

---

## Build Phases

Each phase is a discrete unit of work. Complete one phase fully — including tests and a clean commit — before starting the next.

| Phase | Name | Key Deliverable |
|-------|------|-----------------|
| 1 | Project Foundation | App launches, creates a season, persists it to disk, reads it back |
| 2 | Roster Management | Full player CRUD, persists across restarts |
| 3 | Game Setup Flow | Coach creates a fully configured game, all inputs persist |
| 4 | Rotation Generation Engine | Solver produces valid rotations for all constraint combinations; full unit test suite passes |
| 5 | Rotation Output & Manual Adjustments | Coach can view, understand, and manually adjust any rotation |
| 6 | Playing Time Breakdown | Breakdown tab reflects rotation state and updates with manual changes |
| 7 | Saving, Sharing & Lineup Card | Coach shares a lineup card image in two taps |
| 8 | Game Completion & Post-Game | Full game lifecycle from planning to archived summary |
| 9 | Settings & Season Management | All settings persist; season switching works without data leakage |
| 10 | Polish & Edge Cases | Production-ready; all edge cases handled |

General rules for every phase:
- Write unit tests for all business logic before or alongside implementation
- SwiftUI views are not unit tested — use `#Preview` blocks for visual validation
- **Before committing:** verify the app builds and runs via the Xcode MCP (`BuildProject`, `RunAllTests`) — zero errors, zero warnings required
- Each phase ends with a descriptive git commit
- The app must build and run with zero errors and zero warnings at the end of every phase

---

## Visual Identity

### Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| Primary Background | `#1B2E4B` | All primary surfaces |
| Secondary Surface | `#243757` | Cards, sheets, nav bars |
| Accent | `#3B9EFF` | Buttons, active states, highlights |
| Success | `#2DD4A7` | Met targets, confirmed actions |
| Warning | `#F5A623` | Near-violation states, goalie time bars |
| Danger | `#FF4757` | Violations, destructive actions |
| Text Primary | `#F0F4F8` | All primary text |
| Text Secondary | `#8BA3BC` | Labels, metadata, secondary info |

### Typography

- **Display / Headers**: SF Pro Rounded
- **Body / UI**: SF Pro Text
- **Monospaced** (jersey numbers, time displays): SF Mono

### Component Spec

- Corner radius: 14pt on cards, 10pt on smaller elements, 28pt on primary buttons
- Card borders: 1px at `rgba(255,255,255,0.08)`
- SF Symbols throughout at medium weight — no custom icons in v1
- Tab bar: three tabs — Roster, Games, Settings

---

## Key Conventions

- **One type per file** — even small helpers
- **No default parameter values** unless there is a clear, obvious reason
- **Constants must be `private`** unless part of a public interface
- **No `TODO` comments in committed code** — use GitHub issues instead
- **Logging**: use `os.Logger` per module — never `print()`
- **iOS 26 only** — no backwards-compatibility shims for earlier versions
- **Offline-first** — no network calls in v1; all data is local
- The rotation solver must have zero UI dependencies — pure Swift, fully unit-testable in isolation
