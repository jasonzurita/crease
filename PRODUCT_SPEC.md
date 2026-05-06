# Crease — Product Specification v1.0

**Lacrosse Game Planner · iOS Application · Swift · SwiftUI**

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Architecture Principles](#2-architecture-principles)
3. [Visual Identity](#3-visual-identity)
4. [Feature Specifications](#4-feature-specifications)
   - [Feature 1: Season Creation](#feature-1-season-creation)
   - [Feature 2: Player Management](#feature-2-player-management)
   - [Feature 3: Game Setup](#feature-3-game-setup)
   - [Feature 4: Rotation Planner](#feature-4-rotation-planner)
   - [Feature 5: Saving and Sharing](#feature-5-saving-and-sharing)
   - [Feature 6: Playing Time Breakdown](#feature-6-playing-time-breakdown)
   - [Feature 7: Game Status and History](#feature-7-game-status-and-history)
   - [Feature 8: App Settings](#feature-8-app-settings)
5. [Post-Game Experience](#5-post-game-experience)
6. [Build Phases](#6-build-phases)
7. [Overall Acceptance Criteria](#7-overall-acceptance-criteria)

---

## 1. Product Overview

Crease is a native iOS application for youth lacrosse coaches. It solves the single most time-consuming problem in coach preparation: building fair, competitive, and constraint-aware rotation plans for games with large rosters.

The core loop is simple: add your players once, set up each game in minutes, generate a rotation plan automatically, adjust if needed, and share the lineup card with your co-coach. On game day the plan is ready to execute.

| | |
|---|---|
| **App Name** | Crease |
| **Platform** | iOS (SwiftUI, Swift) |
| **Target User** | Youth lacrosse coaches managing rosters of 12–25 players |
| **Primary Problem** | Rotation planning with fairness, position eligibility, and attendance constraints |
| **v1 Scope** | Season setup, roster management, game planning, rotation generation, sharing, and post-game summary |

---

## 2. Architecture Principles

These principles must be respected throughout the build. They are not guidelines — they are constraints.

### Season Folder Structure

Every season is a self-contained folder stored in the app's Documents directory. The entire app experience — roster, games, planner — operates within the context of one active season at a time. Swapping seasons in a future version requires no structural changes to views or logic.

```
Documents/
  Seasons/
    {season_id}/
      season.json
      roster.json
      Games/
        game_{id}.json
        game_{id}.json
```

### Persistence

Flat JSON files on disk. No CoreData, no SQLite, no cloud sync in v1.

The `SeasonStore` is an `@Observable` Swift class injected into the SwiftUI environment at the root of the app. All views read from it. All mutations write through it. JSON files are written immediately on every change — there is no manual save action anywhere in the app.

### No Shared State Between Seasons

A season folder contains everything it needs. Nothing leaks between seasons. Deleting a season deletes its folder entirely.

---

## 3. Visual Identity

### 3.1 App Name and Concept

**Crease** — the goal area in lacrosse. Short, sport-specific, immediately recognizable to any lacrosse coach. Professional without being sterile.

### 3.2 Design Principles

- Utility first. Every screen has a job. Decoration serves function.
- Professional and polished. This should feel like a tool a varsity program would use.
- High information density without visual noise. Coaches read data fast under pressure.
- Color is used sparingly and meaningfully. One dominant accent per screen.
- Designed for one-handed sideline use. Large tap targets. Clear hierarchy.

### 3.3 Color Palette

| Token | Hex | Usage |
|---|---|---|
| Primary Background | `#1B2E4B` | Deep navy. All primary surfaces. |
| Secondary Surface | `#243757` | Lighter navy. Cards, sheets, nav bars. |
| Accent | `#3B9EFF` | Sky blue. Buttons, active states, highlights, progress. |
| Success | `#2DD4A7` | Teal green. Met targets, confirmed actions, positive states. |
| Warning | `#F5A623` | Amber. Near-violation states, goalie time bars, cautions. |
| Danger | `#FF4757` | Red. Violations, destructive actions, alerts. |
| Text Primary | `#F0F4F8` | Near white. All primary text. |
| Text Secondary | `#8BA3BC` | Muted blue-grey. Labels, metadata, secondary info. |

### 3.4 Typography

| Role | Font | Usage |
|---|---|---|
| Display / Headers | SF Pro Rounded | Screen titles, large numbers, app name. Approachable without being playful. |
| Body / UI | SF Pro Text | All functional text, labels, data. Native, crisp, readable at small sizes. |
| Monospaced | SF Mono | Jersey numbers and time displays only. Utilitarian precision. |

### 3.5 Component Spec

- Corner radius: 14pt on cards, 10pt on smaller elements, 28pt on primary buttons
- Card borders: 1px at `rgba(255,255,255,0.08)` — subtle depth without heavy shadows
- SF Symbols throughout at medium weight — no custom icons in v1
- Primary buttons: accent blue background, navy text, full width, 28pt radius
- Destructive actions: red tint, always require confirmation alert
- Tab bar: three tabs in v1 — Roster, Games, Settings

---

## 4. Feature Specifications

---

### Feature 1: Season Creation

#### Behavior

On first launch, the app has no seasons. It skips any home screen and drops the user directly into the season creation form. The form cannot be dismissed — a season must exist before any other part of the app is accessible.

The creation form collects:

- **Team name** — free text, required
- **Season name** — free text, required (e.g. Spring 2025)
- **Game format defaults** — all editable, all pre-filled:
  - Quarters: 4
  - Quarter length: 10 minutes
  - Players per side: 7
  - Mid-quarter subs: On

After tapping Create, the user lands on the main season screen. The roster is empty. The games list is empty. A prominent call to action prompts adding the first player.

For subsequent season creation (accessed via Settings), the same form is presented with the same defaults. The new season becomes active immediately after creation. Previous seasons remain accessible via the season switcher in Settings.

---

### Feature 2: Player Management

#### Adding a Player

From the roster screen, a prominent Add Player button opens a player form. Fields:

- **Name** — free text, required
- **Jersey number** — numeric, required
- **Position eligibility** — multi-select: Attack, Midfield, Defense, Goalie. At least one required. A player may select Goalie alongside any field positions — they are treated as a goalie when assigned to the goalie slot and a field player otherwise.
- **Skill tier** — single select, five levels: Elite, Strong, Developing, Learning, Beginner

#### Editing a Player

Tapping any player in the roster list opens the same form pre-filled. All fields are editable. Changes apply to the roster immediately and do not retroactively modify any saved game plans.

#### Deleting a Player

Swipe left to reveal delete on the roster list. A confirmation alert before permanent removal. Historical game plans retain the player's name as an orphaned reference — acceptable in v1.

#### Roster Display

Players grouped by tier: Elite, Strong, Developing, Learning, Beginner. Within each group, goalies are visually distinguished with an amber badge. Each row shows jersey number, name, and position eligibility as secondary text.

---

### Feature 3: Game Setup

#### Flow Overview

From the Games screen, a New Game button initiates a paginated three-step setup flow with a progress indicator. All three steps must be completed before the plan can be generated.

#### Step 1 — Game Details

- Opponent name — free text, required
- Date — date picker, defaults to next Sunday
- Home or Away — segmented toggle

#### Step 2 — Attendance

Full roster displayed as a scrollable grid of large tap targets. Every player defaults to present.

Each attendance card has two distinct tap zones:

- **Left zone (checkmark area)** — single tap toggles present/absent instantly
- **Right zone (rest of card)** — opens a bottom sheet for that player

The player bottom sheet contains:

- Present/absent toggle at the top
- If present: Late Arrival toggle with quarter selector (which quarter they arrive before)
- If present: Early Departure toggle with quarter selector (which quarter they leave after)
- Both conflict toggles can be on simultaneously for the same player
- If absent: conflict options are hidden

Bottom sheet dismisses on swipe down or tap outside. Changes apply immediately — no save button.

#### Step 3 — Format, Fairness, and Priorities

**Format fields** pre-filled from season defaults, all editable:

- Quarters, quarter length, players per side, mid-quarter subs toggle

**Rotation style** — single select:

- **By Quarter** — one substitution at each quarter break. Simple sideline management.
- **By Time Interval** — subs happen on a timer within quarters. Coach sets interval length. App shows a preview: "This gives you 3 sub groups per quarter, 12 rotations total." Adjustable until the count feels right.

**Fairness targets:**

- Minimum playing time per tier — steppers for each of the five tiers
- Goalie time counts as field time — toggle

**Priorities** (optional section, clearly labeled as optional):

- Competitiveness mode — Fair, Balanced, or Competitive (see generation logic below)
- Player boosts — tap players to flag them for elevated playing time this game. Boost is per-game only, does not affect roster tier.
- Anchor rotations — coach manually assigns players to specific position slots for one or more rotations. The planner treats anchored rotations as fixed and builds around them. Multiple anchors supported.

At the bottom of Step 3: a prominent **Generate Plan** button. Tapping it runs the planner and navigates to the rotation output screen.

---

### Feature 4: Rotation Planner

#### 4a — Generation Logic

The planner takes all game setup inputs and produces a valid rotation. Constraints respected in priority order:

1. **Position eligibility** — players are never assigned to positions they are not eligible for
2. **Availability** — players with late arrival or early departure are only assigned to quarters they are present for
3. **Goalie slots** — goalie-eligible players fill goal slots. If goalie time does not count as field time, goalies receive field rotation slots in addition to their goal time.
4. **Tier minimums** — every player's projected minutes meets or exceeds their tier's minimum where mathematically possible
5. **Position variety** — players are not assigned the same position in every rotation
6. **Tier distribution** — higher tier players are not systematically benched in favor of lower tier players

**Competitiveness modes:**

- **Fair** — even playing time prioritized above all else. Tier influences minimums only.
- **Balanced** — default. Stronger players spread across rotations so every rotation has a reasonable mix.
- **Competitive** — one rotation per quarter concentrates the highest tier players together. That rotation gets priority placement. Playing time minimums still respected but secondary.

**Player boosts** — boosted players are treated as having a higher effective minimum for that game. The planner prioritizes additional slots for them above their tier baseline.

**Anchor rotations** — treated as fixed. The planner fills all non-anchored slots around them. If an anchor creates an impossible constraint the planner surfaces a violation rather than silently overriding it.

When constraints cannot all be satisfied the planner produces the best available output and surfaces all violations explicitly. **It never fails silently.**

#### 4b — Rotation Output Display

The rotation is displayed as a horizontal-scrolling grid. Quarters and sub-segments as columns, positions as rows. Each cell contains the assigned player's name.

Anchor rotation columns are visually distinguished with a lock icon in the column header.

**Playing time bars** — every attending player has a horizontal bar showing projected minutes:

- Green — at or above tier minimum
- Amber — within two minutes below tier minimum
- Red — more than two minutes below tier minimum
- Goalies show two bars: amber for goal time, green for field time
- Bars update in real time as manual swaps are made

**Violation banners** — specific and actionable, not generic. Example: "Hannah H. gets 8 min — 2 below her 10 min minimum." A Fix button highlights the relevant cells. Multiple violations stack as separate banners. Each can be individually dismissed and recorded as an accepted exception rather than disappearing.

**Summary strip** at the bottom shows: total players in rotation, min and max projected minutes across field players, violation count, anchor rotation count.

**Collapsible bench section** at the bottom of each column. Collapsed state shows a count: "3 benched" with a chevron. Tapping expands inline to show benched player names. Tapping a benched player name enters the swap-in flow — prompts the coach to select which active player in that rotation they are replacing. Expanded state persists per column while on the rotation screen.

#### 4c — Manual Adjustments

**Cross-rotation swap** — tap a cell to select it (highlighted). Tap a second cell anywhere in the grid to swap the two players. Playing time bars update immediately. Tap the same cell twice to deselect.

**Bench swap** — tap a cell to select it. A Swap from Bench button appears. Opens a bottom sheet showing players sitting out that specific rotation who are present, available, and eligible for that position. Tap a benched player to bring them in; the previously assigned player goes to the bench.

**Long press** on a cell reveals an action sheet with three options:

- Swap with another player — enters cross-rotation swap mode
- Change position — shows eligible positions for that player and reassigns within the same slot
- Remove — empties the slot, flagged as unfilled in violation banner. Tap the empty cell to assign any available eligible player.

**Cell locking** — long press a manually adjusted cell and select Lock. Locked cells survive regeneration. Visually distinguished with a small lock icon. Lightweight alternative to formally defining an anchor rotation.

**Undo** — single level of undo via shake gesture or a small undo button that appears briefly after any change and fades after five seconds.

**Regeneration** — a Regenerate button returns the coach to the Priorities step with current inputs intact. If unsaved manual changes exist (non-locked cells changed since last generation), a warning alert appears: "You have manual changes that will be lost. Save them as anchors or continue." Two explicit options, no silent data loss.

---

### Feature 5: Saving and Sharing

#### Saving

The game plan saves automatically on every change. There is no save button. A game appears in the games list with a **Planned** badge as soon as it is created. Once a rotation is generated the badge updates to **Ready**.

#### Sharing — Lineup Card

A **Share Lineup Card** button lives at the bottom of the rotation output screen. Tapping it presents a brief options sheet with one toggle: Include projected playing time (defaults on). Tapping Share generates a clean designed image and opens the native iOS share sheet.

The lineup card image contains:

- Team name and opponent at the top
- Date and home/away
- Each quarter or segment as a labeled section with position and player name for every slot
- Playing time summary per player (if toggle is on)
- Small "Made with Crease" credit at the bottom

The card is a fixed width optimized for phone screens — readable without zooming when forwarded in a message thread. It is a designed image, not a screenshot of the app UI.

---

### Feature 6: Playing Time Breakdown

A read-only summary tab within the game plan screen, accessible alongside the rotation grid. No interaction — diagnostic only. Changes are made in the rotation grid or by regenerating.

#### Per Player Display

Every attending player listed in one scrollable view. For each player:

- Name and jersey number
- Projected minutes as a number and visual bar
- Tier minimum shown as a marker on the bar
- All positions assigned across the full rotation
- Conflict note if applicable: "Arrives Q2" or "Leaves after Q2"
- Goalies show field time and goal time as distinct values

#### Sorting and Grouping

Default sort: projected minutes descending. Coach can switch to sort by tier or by name. Optional toggle to group by tier.

#### Edge Cases

Players below tier minimum are flagged with red bar and label. Players present but sitting the entire game appear at the bottom at zero minutes — never hidden.

---

### Feature 7: Game Status and History

#### Game Lifecycle

| Status | Meaning |
|---|---|
| **Planned** | Game created. Rotation may or may not exist yet. Fully editable. |
| **Ready** | Rotation generated. Coach is satisfied. Still editable if returned to. Visual distinction only — not a hard lock. |
| **Complete** | Manually marked done by coach. Read only. Final score can be recorded. Post-game summary available. |

The coach manually triggers transitions. The Planned → Ready transition happens implicitly when a rotation is generated. The Ready → Complete transition is explicit via a **Mark Complete** button on the game plan screen. No automatic transitions.

#### Games List

All games for the active season in reverse chronological order. Upcoming and Planned games above a divider. Complete games below. Each card shows: opponent, date, home/away, status badge. Tapping a Planned or Ready game opens the rotation screen. Tapping a Complete game opens the read-only post-game summary.

#### Post-Game Summary

Shown when a game is marked Complete. Contains:

- Opponent, date, final score (if entered)
- Playing time actuals (same as projected in v1)
- The rotation as executed
- Light stats if entered: goals per player, ground balls per player, opponent ground ball total
- Share button generating a clean post-game summary image

#### Deleting a Game

Swipe left to reveal delete on the games list. Confirmation alert before permanent removal. No soft delete.

---

### Feature 8: App Settings

#### Season Management

- Edit active season name and team name
- Edit game format defaults for the active season
- Create New Season — same form as first launch, new season becomes active immediately
- Season switcher — list of all seasons, tap to make active

#### Appearance

Light and dark mode toggle. Defaults to system setting.

#### Data

- **Export Season** — exports the active season folder as a zip via the native iOS share sheet. Covers backup and device transfer without cloud sync.
- **Delete Season** — permanently deletes the active season and all games. Double confirmation required. If only one season exists, app returns to first launch flow after deletion.

---

## 5. Post-Game Experience

### 5.1 Completion Flow

When the coach taps Mark Complete, a bottom sheet appears with two optional fields:

- **Final score** — two numeric steppers, Us and Them
- **Light stats entry** — goals and ground balls attributed per player from memory, plus opponent ground ball total as a single number

Both fields are optional. Tapping Done without filling them archives the game with no stats. Stats can be entered or edited from the post-game summary screen at any time.

### 5.2 Post-Game Summary Screen

Read-only. Accessible by tapping any Complete game in the games list.

#### Header

- Team name vs. opponent name
- Final score displayed prominently
- Date and home/away

#### Playing Time Actuals

Same bar visualization as the planning breakdown, labeled as **Actual Playing Time**. Each player shows their minutes. Goalies show goal and field time separately. Any player who played less than their tier minimum is noted — informational, not a violation at this stage.

#### Stats Summary

Compact per-player rows showing goals and ground balls for players who recorded either. Players with zero stats are not listed here — their playing time still appears in the breakdown above.

Opponent ground ball total shown as a single team-level stat at the bottom.

#### Rotation as Executed

Full rotation grid in a collapsed view. Coach can expand to review positions each player ran.

#### Share

A **Share Game Summary** button generates a clean post-game image. Same options sheet as the lineup card: toggle for including playing time breakdown. The image includes score, stat highlights, and playing time summary.

---

## 6. Build Phases

Each phase is a discrete unit of work. Complete one phase fully — including tests and a clean commit — before starting the next. No phase begins until the previous one passes its acceptance criteria.

**Rules for every phase:**

- Write unit tests for all business logic before or alongside implementation
- UI code is not unit tested — use SwiftUI previews for visual validation
- Each phase ends with a descriptive git commit summarizing what was built
- No TODO comments left in committed code — unfinished items become the next phase
- The app must build and run without errors or warnings at the end of every phase

---

### Phase 1 — Project Foundation

**Features:**
- Xcode project setup with SwiftUI
- Folder structure and file organization
- `SeasonStore` `@Observable` class
- JSON read/write utilities
- Season creation form (first launch flow)
- Seasons folder architecture on disk
- Basic tab navigation shell (Roster, Games, Settings)

**Acceptance criteria:** App launches, creates a season, persists it to disk, reads it back correctly on relaunch.

---

### Phase 2 — Roster Management

**Features:**
- Player model and JSON schema
- Roster list screen grouped by tier
- Add/edit player form with all fields
- Position multi-select including goalie + field eligibility
- Swipe to delete with confirmation alert

**Acceptance criteria:** Full roster CRUD working. All player data persists correctly across app restarts.

---

### Phase 3 — Game Setup Flow

**Features:**
- Game model and JSON schema
- Games list screen with status badges
- Three-step game setup flow with progress indicator
- Attendance grid with two-zone tap behavior
- Player conflict bottom sheet (late arrival, early departure)
- Format and fairness target inputs
- Rotation style selector (by quarter / by time interval)
- Priorities step (competitiveness mode, player boosts, anchor rotations)

**Acceptance criteria:** Coach can create a fully configured game. All inputs persist correctly. Game appears in games list with Planned badge.

---

### Phase 4 — Rotation Generation Engine

**Features:**
- Constraint solver — pure Swift, zero UI dependencies
- Position eligibility enforcement
- Availability window enforcement (late arrivals, early departures)
- Tier minimum enforcement
- Goalie time handling (field time vs. goal time)
- Competitiveness modes (Fair, Balanced, Competitive)
- Player boost logic
- Anchor rotation support
- Violation detection and structured reporting
- Full unit test suite for the solver

**Acceptance criteria:** Solver produces valid rotations for all constraint combinations. All unit tests pass. No invalid position assignments. No players scheduled outside their availability window.

---

### Phase 5 — Rotation Output and Manual Adjustments

**Features:**
- Rotation grid view with horizontal scroll
- Playing time bars with color coding (green / amber / red)
- Violation banners with per-banner dismiss and accept-as-exception
- Summary strip (player count, min/max minutes, violation count, anchor count)
- Collapsible bench rows per column
- Cross-rotation player swap (tap to select, tap to swap)
- Bench swap flow (Swap from Bench button + bottom sheet)
- Long press action sheet (change position, remove, lock cell)
- Cell lock visual indicator
- Single-level undo (shake or fade button)
- Regeneration with unsaved change warning

**Acceptance criteria:** Coach can view, understand, and manually adjust any generated rotation. Playing time bars reflect all changes in real time. Locked cells survive regeneration.

---

### Phase 6 — Playing Time Breakdown

**Features:**
- Breakdown tab on game plan screen alongside rotation grid
- Per-player bar visualization with tier minimum marker
- Sort options (by minutes, by tier, by name)
- Group by tier toggle
- Goalie split display (field time vs. goal time)
- Zero-minutes edge case clearly displayed

**Acceptance criteria:** Breakdown accurately reflects current rotation state. Updates immediately when rotation is changed. Goalie time split is correct based on the goalie time toggle setting.

---

### Phase 7 — Saving, Sharing, and Lineup Card

**Features:**
- Autosave on every mutation confirmed working end to end
- Share Lineup Card button on rotation screen
- Options sheet with playing time toggle
- Lineup card image generation (designed image, not screenshot)
- Native iOS share sheet integration
- Game status badge updates (Planned → Ready on first generation)

**Acceptance criteria:** Coach can generate and share a clean lineup card image in two taps. Card is readable on an iPhone screen without zooming. Playing time section appears and disappears correctly based on toggle.

---

### Phase 8 — Game Completion and Post-Game Summary

**Features:**
- Mark Complete button and completion bottom sheet
- Final score entry (Us / Them steppers)
- Light stats entry (goals and ground balls per player)
- Opponent ground ball total
- Post-game summary screen (read-only)
- Playing time actuals display
- Stats summary section
- Collapsed rotation view with expand
- Share Game Summary image generation

**Acceptance criteria:** Full game lifecycle works end to end — from planning to archived read-only summary. Stats entered on completion appear correctly in the summary. Share image includes all expected sections.

---

### Phase 9 — Settings and Season Management

**Features:**
- Settings screen
- Edit season name and team name
- Edit game format defaults
- Create new season flow (same as first launch)
- Season switcher (list of all seasons, tap to activate)
- Export season as zip via share sheet
- Delete season with double confirmation
- Light/dark mode toggle

**Acceptance criteria:** All settings persist correctly. Season switching works with zero data leakage between seasons. Export produces a valid zip. Delete returns to first launch flow when last season is removed.

---

### Phase 10 — Polish and Edge Cases

**Features:**
- Empty state screens for roster and games list
- Loading states where applicable
- Error handling for corrupt or missing JSON files
- Accessibility — Dynamic Type support, VoiceOver labels on all interactive elements
- iPad layout review and improvements
- Performance review with a roster of 25 players
- Final visual polish pass against the design spec color palette and typography

**Acceptance criteria:** App handles all edge cases gracefully with no crashes. Passes basic accessibility audit. Visually consistent with design spec on both iPhone and iPad.

---

## 7. Overall Acceptance Criteria

The v1 product is considered complete when all of the following are true:

- A coach with 24 players can set up a game, generate a rotation, make adjustments, and share a lineup card in under five minutes
- The rotation solver never produces an invalid rotation — no player in an ineligible position, no player assigned outside their availability window
- All violations are surfaced explicitly — nothing fails silently
- All data persists correctly across app restarts
- Season folder structure is clean — no data leakage between seasons
- The app builds with zero errors and zero warnings
- All unit tests pass
- The app runs correctly on iOS 17 and iOS 18
- The lineup card share image is readable on an iPhone screen without zooming

---

*Crease · Product Specification v1.0 · Confidential*
