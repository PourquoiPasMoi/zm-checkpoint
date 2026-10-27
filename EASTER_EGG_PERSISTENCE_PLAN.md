# Easter-Egg Persistence Implementation Plan

This is the approved continuation plan for adding safe Easter-egg and secret
progress preservation to ZM Checkpoint. It is deliberately staged. A future
agent must not attempt to implement every map in one change.

## 1. Required starting context

Before changing code, read these files completely in this order:

1. `AGENTS.md`
2. `PROJECT_HANDOFF.md`
3. `CHANGELOG.md`
4. `README.md`
5. `MAP_STATE_AUDIT.md`
6. This plan

Then inspect the installed package, the active checkpoint files, and the source
files involved. The current installed baseline is **0.3.3-alpha**. The stock
script reference checkout is `.cache\bo2-recompilable-gscs` at commit
`d02a9efd4382689180aaadcb609452babf5dc4c8`.

Do not overwrite or delete any file beneath a `scriptdata` directory. Record
checkpoint hashes before and after build/install work.

## 2. Definition of done

For each supported map, a resumed checkpoint should:

- retain the selected Easter-egg branch when the map has branches;
- retain only completed, stable milestones whose physical side effects can be
  reconstructed safely;
- restore durable quest items and world objects through explicit typed records;
- restart the currently incomplete milestone from a documented safe beginning;
- keep the normal round controller, HUD, zombies, inventory, doors, and existing
  map adapters working;
- consume the checkpoint only after all required restore phases succeed; and
- pass an in-game checkpoint test at every milestone that is claimed supported.

Static parsing or a successful install is not proof that a quest works. Every
claim must use the evidence labels from `AGENTS.md`.

## 3. Non-goals and safety boundaries

Do not serialize or attempt to resume:

- live GSC threads or raw entity references;
- exact AI, boss, projectile, temporary power-up, or RNG state;
- a moving bus, elevator, gondola, robot, or other transport mid-animation;
- a player halfway through afterlife, teleportation, a cutscene, or a scripted
  animation;
- partially completed counters unless the entire step has a proven idempotent
  reconstruction path.

Never blanket-set all discovered quest flags. A flag may signal completion to a
waiter without rebuilding the models, triggers, paths, client fields, inventory,
or threads that the stock transition normally creates.

Preserve the solo guard, `xpartygo` Resume launch, file validation, final `END`
record, one-use checkpoint lifecycle, and all working Nuketown behavior.

## 4. Proposed save-format extension

Keep format version 3 readable while the first adapter is developed. Add only
optional typed records so existing checkpoints remain valid. The exact field
names may be refined from stock-script evidence before implementation, but the
shape should remain explicit and versioned, for example:

```text
QUEST,1,<map>,<branch>,<last-completed-stable-milestone>
QSTATE,<key>,<integer-or-safe-token>
QITEM,<item-id>,<durable-state>
```

Rules:

- `QUEST` has its own adapter/schema version.
- Readers ignore absent optional quest records and preserve old version-3 saves.
- Unknown, duplicate, malformed, or wrong-map quest records must not be applied.
- Use bounded values and stable tokens, never arbitrary strings or references.
- Bump the overall checkpoint format only if backward-compatible optional records
  cannot express a required change.
- The writer must still complete the file with `END` before advertising Resume.

## 5. Restore phases

Quest restoration should be split into explicit phases rather than one late
catch-all function:

1. **Early quest phase:** after the stock quest has initialized its arrays and
   flags, but before round/quest waiter threads can make irreversible decisions.
   Restore branch choice and safe prerequisite values only.
2. **World phase:** after required map entities exist. Replay stock transitions
   or narrowly reproduce their side effects for completed milestones. Rebuild
   models, triggers, collision, paths, and client fields before setting the
   milestone's completion signal.
3. **Player/item phase:** after the player exists and is alive. Restore durable
   carried quest items, character-safe state, and inventory-linked quest data.
4. **Validation phase:** confirm required entities/state exist. If a required
   phase fails, show a clear error and do not consume the checkpoint as a
   successful restore.

Normalize timers, animations, hostile bosses, and moving systems to their
documented safe round-start state.

## 6. Common implementation framework

Add the smallest common framework needed by the first map:

- a writer entry point for optional quest records;
- strict parser fields for quest schema, branch, milestone, state, and items;
- per-map build markers for map-exclusive calls and externals;
- early, world, and player restore dispatch points;
- diagnostic logging that names the map, adapter version, phase, and milestone;
- a failure path that leaves enough evidence in `console_zm.log` and avoids a
  false “restored successfully” claim.

Likely function boundaries are:

```text
zmcp_write_quest_state()
zmcp_parse_quest_record(...)
zmcp_restore_quest_early()
zmcp_restore_quest_world()
zmcp_restore_quest_player()
zmcp_validate_quest_restore()
```

Names are not mandatory; separation of responsibilities is. Extend
`tools\Build.ps1` so Buried, Die Rise, TranZit, Mob, and Origins-only blocks are
physically removed from all nonmatching generated scripts. Runtime map checks
alone do not prevent unresolved external link errors.

## 7. Staged roadmap

### Phase 0 — Framework with no quest claims

- Add parser/writer/dispatch scaffolding.
- Confirm old checkpoints without quest records still Resume.
- Confirm generated scripts contain no foreign map externals.
- Do not install or expose new quest behavior until parsing and package coverage
  are clean.

### Phase 1 — Buried only

Buried is first because it is the active test map and already has dedicated
world and Arthur adapters.

1. Audit `zm_buried_sq*.gsc`, `zm_buried_ee.gsc`, buildable/item scripts, and
   the stock time-bomb save/restore functions.
2. Produce a table of both branches, stable completed milestones, required
   physical side effects, carried items, reset behavior, and unsafe partial
   state. Add it to `MAP_STATE_AUDIT.md` before coding.
3. Implement branch plus one stable milestone at a time.
4. Restore its world transition before setting its completion flag.
5. Restart lantern, wisp, target/order, carried-part, or other unfinished steps
   from a safe beginning unless their partial state has a fully proven restore.
6. Keep Arthur's `SLOTH` adapter separate, but order it correctly relative to
   quest/world restoration.
7. Parse, build, inspect, install, and test after every supported milestone.

Do not claim “Buried Easter egg supported” until both branches and every claimed
milestone have recorded in-game evidence. Until then, document the exact prefix
of supported progress.

### Phase 2 — Die Rise

- Audit branch selection, tower state, tiles/statues, elevator-linked entities,
  carried items, counters, and client fields.
- Preserve completed stable milestones and rebuild their physical tower/world
  effects.
- Normalize moving elevators rather than restoring an in-motion transform.
- Test both branches and mid-step rollback independently.

### Phase 3 — TranZit

- Treat `level.sq_progress["maxis"]` and `["rich"]` as the authoritative branch
  milestone source rather than relying on the two literal quest flags.
- Store completed A/B/C-style milestones only; reset partial counters and raw
  entity references.
- Rebuild power/tower side effects and relevant client fields in stock order.
- Keep the bus/driver system outside the quest adapter until its own normalized
  transport design is implemented.

### Phase 4 — Mob of the Dead

- Audit afterlife, plane parts/build state, gondola, bridge/final battle, soul
  catchers, quest items, and character requirements.
- Resume an active afterlife/cutscene/flight as a documented safe living state.
- Reconstruct completed plane and quest-object state; never restore live ghost,
  boss, or cutscene threads.
- Add narrow milestone tests before expanding coverage.

### Phase 5 — Origins

- Model the eight main steps explicitly.
- Audit generators, four staffs and their upgrades, puzzle models, drone, portal,
  robot dependencies, carried items, and character requirements.
- Rebuild completed stable steps in dependency order.
- Normalize robots, portals, timers, and moving encounters to safe schedules.
- Origins is last because it has the most coupled state and the largest test
  matrix.

Nuketown has no comparable main Easter-egg quest adapter in this plan. It still
requires regression testing whenever common checkpoint code changes.

## 8. Required test matrix for each map

For every newly supported map milestone, record the map, mode/location, branch,
round, loaded mod, save records, visible result, and log errors.

Minimum tests:

1. Fresh match with no checkpoint.
2. Existing 0.3.3 checkpoint with no quest records.
3. Save before the quest begins.
4. Save immediately after each claimed stable milestone.
5. Save halfway through the next step; Resume must restart that step safely.
6. Resume, progress, then use **SAVE & EXIT** again.
7. Resume and die; the consumed checkpoint must not return.
8. Confirm round HUD, zombie spawning, player state, doors, and previous map
   adapters have not regressed.
9. Repeat with the standalone mod and any installed companion mod relevant to
   the test.
10. Inspect `console_zm.log` for silent errors even when gameplay looks correct.

## 9. Validation gates before handoff

- Parse all six generated GSC files with the bundled T6 `gsc-tool`.
- Parse every modified Lua file.
- Parse modified PowerShell scripts.
- Run `tools\Build.ps1` after package-affecting changes.
- Inspect the IWD and all six generated map-script outputs.
- Search every nonmatching map output for forbidden map-exclusive externals.
- Hash existing checkpoint files before and after build/install.
- Run `tools\Install.ps1` only when a test build needs to reach Plutonium.
- Never close or restart Plutonium automatically; tell the user what restart or
  new-match action is required.
- Update `CHANGELOG.md`, `PROJECT_HANDOFF.md`, `MAP_STATE_AUDIT.md`, and README
  user-facing boundaries before declaring the phase complete.

## 10. Stop and rollback rules

Stop expanding the adapter and document the evidence when:

- a stock side effect cannot be reconstructed deterministically;
- a milestone depends on an unbounded live thread or unsafe entity reference;
- a change breaks round startup, spawning, HUD, Save & Exit, Resume, or the
  one-use lifecycle;
- a map-exclusive symbol leaks into another generated script;
- an old checkpoint becomes unreadable without an intentional migration; or
- a test produces a soft lock, corrupted quest, repeated reward, or impossible
  world state.

Revert or disable only the new map adapter, not the known-good common checkpoint
system. Preserve the failed attempt and lesson in `CHANGELOG.md`.

## 11. Immediate next task

Implement **Phase 1, Buried only**, beginning with a written milestone/side-effect
table derived from the pinned stock scripts. Do not begin Die Rise or any later
map in the same change. Stop after static validation and installation, tell the
user that a new match/reload is required, and wait for the user's in-game test
evidence before claiming the milestone works.

