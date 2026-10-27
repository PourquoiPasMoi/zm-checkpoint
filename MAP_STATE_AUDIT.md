# Stock-map state audit

This file records the map-state evidence used by ZM Checkpoint. It prevents a
future change from assuming that every opened object is a stock `zombie_door`.

## Evidence base

- Historical-reference source set:
  `JezuzLizard/Recompilable-gscs-for-BO2-zombies-and-multiplayer`
- Audited checkout commit: `d02a9efd4382689180aaadcb609452babf5dc4c8`
- Decompiled by the source set with xensik `gsc-tool`.
- Local game fastfiles remain the authoritative shipped artifacts. Decompiled
  names and control flow are used as static evidence and require in-game tests.

## Persistence strategy

1. Refresh the entity inventory immediately before every write, then save set
   `script_flag` values attached to live map entities returned by `getentarray()`.
   On Buried, `sq_*` and `ftl_*` quest flags are excluded from this generic path
   and belong to the typed quest adapter. This includes later-spawned non-quest
   entities.
2. Keep the proven stock replay for `zombie_door` and `zombie_debris` triggers.
3. Set saved flags after physical replay so zone adjacency and flag waiters see
   the restored progression.
4. Add a map-only adapter when the stock script changes geometry first and sets
   its flag only as a side effect. Map-only blocks are physically removed from
   all other generated map scripts to prevent unresolved externals.

## Coverage matrix

| Map | Shared coverage | Dedicated state adapter | Status |
| --- | --- | --- | --- |
| TranZit | Normal doors/debris, power, all live entity `script_flag` values | `town_bunker_door` is reopened through the stock explosive-damage event, which rotates the door, sets its map flag, and reconnects its clip paths | Statically validated; user verified the pre-fix vault failure |
| Nuketown | Normal doors/debris, power, all live entity `script_flag` values | Perk-machine arrival schedule and landed-machine set | Verified in-game before 0.3.2; shared collector change still needs regression test |
| Die Rise | Normal doors/debris, power, all live entity `script_flag` values | None yet | Statically validated only; moving elevator position is intentionally not frozen |
| Mob of the Dead | Normal doors/debris, power, all live entity `script_flag` values | None yet | Statically validated only; afterlife, plane, gondola, and quest objects remain outside guaranteed coverage |
| Buried | Normal doors/debris, power, non-quest live entity `script_flag` values | `hole_breakthrough`, `sloth_barricade`, courtyard fountain, maze fountain, released Arthur position/facing with safe roaming-state reconstruction, and optional `QUEST` schema 1 for selected branch plus completed tower-build milestone | Doors/debris verified in-game; Arthur reset-to-cell failure verified; Arthur and 0.3.4 tower adapters statically validated; quest test pending |
| Origins | Normal doors/debris, power, all live entity `script_flag` values | None yet | Statically validated only; generator entity flags, staffs, robots, and quest state remain outside guaranteed coverage |

## Audited special cases

### TranZit bank vault

`zm_transit_classic.gsc` initializes every `town_bunker_door`, waits for
explosive damage, calls `bunkerdoorrotate(1)`, sets the door's `script_flag`, and
connects its clip paths. It is not a `zombie_door` or `zombie_debris`, which is
why the 0.3.1 collector missed it. Version 0.3.2 saves its attached flag and
replays that same damage event during Resume.

### Buried one-way blockers

The static audit found the other clear stock-map instances of the same
"change/delete geometry, then set `self.script_flag`" pattern:

- `hole_breakthrough` triggers delete collapsed boards and collision;
- `sloth_barricade` triggers delete or hide Arthur-opened barriers;
- the courtyard and maze fountains use named flags and map-specific geometry,
  not the common blocker system.

Version 0.3.2 adds silent physical replay for those systems. The maze fountain
uses its stock damage event; the courtyard fountain uses its stock level notify.

### Buried Arthur/Leroy

**Verified in-game:** a 0.3.2 Buried checkpoint retained the opened doors and
debris, including `jail_door1`, but Arthur respawned in his cell. Inspection of
that checkpoint confirmed there was no actor record. The stock
`_zm_ai_sloth.gsc` always spawns Arthur at `sloth_idle_pos` in `jail_idle`, so a
door flag cannot restore the actor.

Version 0.3.3 writes an optional `SLOTH` record containing released status,
origin, angles, the prior state name for diagnostics, and the stock `got_booze`
context. On Resume, the Buried-only adapter waits for `level.sloth`, restores
the open-cell context, teleports him, and invokes the stock `sloth_set_state`
entry point with `roam`. Transient states such as `berserk`, `crash`, `eat`,
context actions, and mansion traversal are intentionally normalized rather than
resuming half-completed animation/script threads.

### Other special actors and moving systems

A static search of the six stock map script sets found Arthur as the only
map-specific persistent AI actor assigned to the allied AI team. Other apparent
equivalents are different classes of state:

- TranZit's T.E.D.D. is part of the continuously moving bus system, not an
  independent companion actor;
- Brutus, the Avogadro, Panzers, Jumping Jacks, and similar entities are hostile
  round enemies and deliberately respawn with the restarted round;
- Origins giant robots and Die Rise elevators are moving map systems whose
  exact transform cannot be restored safely without rebuilding their schedule;
- Mob afterlife and quest ghosts are player/quest state rather than a durable
  allied actor.

This means the Arthur adapter should not be copied generically to those systems.

### Easter-egg and secret progression

The static quest-script audit found dozens of map-specific flags plus mutable
`level` fields across TranZit, Die Rise, Mob of the Dead, Buried, and Origins.
Many steps also depend on arrays, model visibility, carried/buildable pieces,
character identity, and active waiter threads. The shared entity-flag collector
already preserves stable quest flags attached to live map entities, but that is
not enough to claim complete Easter-egg continuity. Blanket-setting every quest
flag after startup could skip required side effects or deadlock a quest.

**Known limitation:** full Easter-egg/secret progression remains outside the
0.3.4 guarantee. Buried has a narrow statically validated prefix: its selected
branch plus the completed `bt` tower-build milestone. Later stages and the
other maps remain outside the guarantee. Each added milestone needs its own
typed record, stock side-effect replay, and in-game test. The Arthur fix is a
dedicated persistent-actor adapter, not proof of a general script-thread
snapshot.

#### 2026-10-25 quest-state inventory

A bounded scan of the reconstructed map quest files found the following literal
`flag_init`/`flag_set`/`flag_wait` names. These are evidence of complexity, not
a complete state count because dynamically generated names and non-flag state
are excluded:

| Map | Literal quest-related flag names | Important non-flag state |
| --- | ---: | --- |
| TranZit | 2 | `level.sq_progress["maxis"]` and `["rich"]` arrays, entity references, counters, power branch, player/global quest stats |
| Die Rise | 34 | branch selection, step-local counters/arrays, tower state, weapons, elevator and tile/entity state |
| Mob of the Dead | 54 | afterlife/player state, plane parts and lifecycle, bridge/final battle actors, soul catchers, quest items |
| Buried | 34 | branch progress, time-bomb snapshots, wisp/entity references, lantern charge, target/order arrays, carried parts |
| Origins | 56 | eight main-step scripts, four staffs and upgrades, generators, puzzle arrays/models, robot/drone/portal state |

TranZit demonstrates why saving flags alone cannot solve this: its main branch
milestones (`A_complete`, `B_complete`, `C_complete`, and partial counters) are
stored in `level.sq_progress`, while its literal flags are mostly common round
and power gates. Conversely, setting an Origins or Mob completion flag without
reconstructing the staff/plane/entity side effects can tell waiter threads that
a step is done while leaving the required world objects in their initial state.

#### Buried Phase 1 milestone and side-effect audit (pinned stock scripts)

**Evidence source:** the local reconstructed checkout at commit
`d02a9efd4382689180aaadcb609452babf5dc4c8`, principally
`ZM/Maps/Buried/maps/mp/zm_buried_sq.gsc`, `zm_buried_sq_bt.gsc`, the nine
`zm_buried_sq_<stage>.gsc` stage scripts, `zm_buried_ee.gsc`,
`zm_buried_buildables.gsc`, and
`ZM/Maps/Buried/maps/mp/zombies/_zm_weap_time_bomb.gsc`. This is static
reconstruction evidence; it does not prove runtime behavior on Plutonium.

The main sidequest has a Maxis and a Richtofen branch. Stock persists the last
fully completed Easter egg in `sq_buried_last_completed` (`1` Richtofen, `2`
Maxis) and reconstitutes tower visuals and consumed tower parts from that value
during `init_sidequest`. The selected branch during an unfinished run is
represented by the mutually exclusive `sq_is_max_tower_built` and
`sq_is_ric_tower_built` flags. A checkpoint adapter must capture that choice as
a stable token and rebuild the world effect before setting the corresponding
flag. Neither branch selection nor the main sequence can be represented by
capturing every `sq_*` flag.

| Order | Stock stage / milestone | Maxis / Richtofen differences | Durable side effects to preserve on completion | Incomplete or unsafe state; Resume treatment |
| ---: | --- | --- | --- | --- |
| 1 | `bt` — build the branch tower | `buried_sq_bt_m_tower` versus `buried_sq_bt_r_tower`; sets exactly one tower-built flag | Selected tower's completed visual/effect, branch choice, and consumed tower build parts. `init_sidequest` replays tower effects and unspawns the corresponding pieces when its completion stat is set. | Partially carried tower parts and active planting/VO waiters are not serialized. Restart `bt`; if the completed-tower record is present, stock stage logic can pass its flag gate. |
| 2 | `mta` — amplifier setup | Branch-specific amplifier interactions/VO | Completed amplifier state includes `sq_amplifiers_on`; stock may also expose the broken state. | Amplifier actions and entity-dependent interaction state restart from `mta`; do not infer completion from a lone flag. |
| 3 | `gl` — acquire lantern | Branch-specific hints/VO; shared lantern buildable path | A stable lantern pickup can be represented only as a typed buildable/item state after proving its player/world ownership semantics. | Carried lantern is not a raw entity reference; this phase does not serialize it. Restart `gl` and reacquire. |
| 4 | `ftl` — charge lantern and place oil lamp | Same milestone with branch-specific dialogue | `ftl_lantern_charged` plus placed `buried_sq_oillamp` and normalized lantern marker/generator-unit positions. | Fuel count, zombie-death charge progress, holder, and active watchers reset. Restart `ftl` from zero charge. |
| 5 | `ll` — light lantern / generator | Branch-specific instructions; generator interaction | `sq_ll_generator_on` and the resulting stable generator/world lighting. | Interaction/animation threads restart from `ll`; only preserve after stock world side effects are reconstructed. |
| 6 | `ts` — shoot tunnel targets | Branch has a different target pattern/sequence | Completed target puzzle signal `sq_ts_quicktest` is a candidate only if its target/clientfield visuals are also rebuilt. | Target ordering, partial hits, active weapon/target threads restart from `ts`. |
| 7 | `ctw` — guide the wisp | Maxis vehicle/path and energy; Richtofen randomized path followed by five powered-zombie captures | Only final `sq_wisp_success` is a candidate milestone; successful tower/power side effects must be replayed. | Wisp entity, randomized route, energy, timers, powered zombies, and orb count are transient. Restart `ctw` from its beginning. |
| 8 | `tpo` — time-bomb / special-round step | Branch-specific time-bomb objective | `sq_tpo_found_item`, `sq_tpo_generator_powered`, and eventual stage completion are separate signals; preserve only after item/world effects are known. | Time Bomb snapshots include round, doors, player state, and enemy arrays/raw entity-linked data plus custom callbacks. Never serialize or restore those snapshots. Restart `tpo` safely. |
| 9 | `ip` — end-game machine puzzle | Branch-specific puzzle/VO; uses per-slot clientfields and puzzle state | `sq_ip_puzzle_complete` plus the matching machine/clientfield/model state, rebuilt in stock order. | Partial puzzle positions, machine interaction threads, and animations reset. Restart `ip`. |
| 10 | `ows` — launch final wisp/target sequence | Branch-specific final completion route and tower target | `sq_ows_success`, completed tower presentation, and stock completion notifications/reward/stat changes. | Wisp/target references, launch timing, target-missed counter, and active threads are unsafe. Restart `ows`; do not replay the final reward as if complete. |
| 11 | Overall completion / ending | Maxis or Richtofen ending and reward | Completion stat `sq_buried_last_completed`, branch completion stat, ending tower effect, and reward state are coupled; this requires its own later milestone implementation. | Ending animation, reward threads, and active cutscene/ending state are not resumed. |

Other Buried secrets are separate from this main sidequest. The ghost piano in
`zm_buried_ee.gsc` uses a temporary song flag, spawned ghost model, player
eligibility flag, and one-time reward field; it is not a resumable main-quest
milestone in this phase. Buildable pieces are stored against player/buildable
zone state and must not be persisted as entity references. Stock Time Bomb saves
round state, enemy arrays, player state, door transforms, and registered custom
callbacks, then runs long restore threads; that snapshot is intentionally
excluded from ZM Checkpoint's save format.

**Phase 1 initial supported prefix:** selected branch plus completed `bt`
(tower) milestone only. Later completed stages remain outside the guarantee
until their physical side effects have a narrow replay and their milestone has
in-game test evidence. A partially completed current stage is restarted at its
first safe action. This is not a claim that either full Buried Easter egg is
supported.

#### Safe implementation design

Future quest support should use a versioned, per-map `QUEST` record rather than
adding every discovered flag to the common collector:

1. Save the selected branch and only completed, stable milestones. A partially
   completed current step restarts from that step's beginning.
2. Save carried quest items and durable entity state as separate typed records;
   never serialize raw entity references or live threads.
3. Restore milestone prerequisites before `start_zombie_round_logic` when the
   stock quest initializes early.
4. Invoke or reproduce the stock transition that creates each milestone's
   models, triggers, client fields, and pathing; set its completion flag last.
5. Normalize active animations, boss encounters, timers, and moving systems to
   a documented safe state.
6. Add one map at a time and require an in-game checkpoint at every supported
   milestone before expanding its guarantee.

Recommended implementation order is Buried (current test map), Die Rise,
TranZit, Mob of the Dead, then Origins. Mob and Origins are last because their
quests have the largest coupled physical-state graphs.

The executable roadmap, restore phases, format-extension rules, validation
gates, and per-map test matrix are maintained in
`EASTER_EGG_PERSISTENCE_PLAN.md`. Future work must follow that staged plan and
must not implement multiple quest adapters in one untested change.

## Important limits

This audit does not prove a full engine snapshot. The checkpoint deliberately
restarts the saved round and does not serialize live script threads, AI,
projectiles, RNG state, temporary effects, or continuously moving vehicles.
Complex quest systems keep state in arrays, entity flags, model visibility,
client fields, and active threads; restoring only one piece can corrupt a run.
They require dedicated, map-specific reconstruction and in-game validation.

When a new mismatch is reported, record the exact object and map here, trace the
stock transition that produced it, add the narrowest map-only adapter, and keep
the failure in `CHANGELOG.md` even after it is fixed.
