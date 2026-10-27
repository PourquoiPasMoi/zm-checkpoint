# ZM Checkpoint — Project Handoff

> **Start here in a new chat.** This document records the current implementation,
> the decisions behind it, what has been verified in-game, known limitations, and
> the safest next steps.

All future agents must also read and follow `AGENTS.md`. It requires this handoff
and `CHANGELOG.md` to be updated after every meaningful fix, investigation,
failure, installation, or test so the project retains its lessons.

## 1. Current status

- Project: **ZM Checkpoint** for Call of Duty: Black Ops II Zombies on Plutonium T6.
- Workspace: `C:\Users\User\Documents\Projects\Bo2 Zombie Plutonium`
- Current source/package and GitHub release version: **0.4.8-alpha**; local installed version **0.4.7-alpha**, intentionally left unchanged for the next in-game update test.
- Current date of this handoff: **2026-10-28**
- The project is a Git repository with public origin `https://github.com/PourquoiPasMoi/zm-checkpoint`.
- The standalone mod and companion packages are installed locally.
- 0.4.2 moves the per-player remaining-enemy HUD to the upper-left safe area
  (x=12, y=10, left aligned), red RGB (0.85, 0.08, 0.05). Font size 1.6,
  glow, counting and 0/numpad 0 toggle are unchanged. Start a new match to load
  this GSC-only styling update; no full restart required from 0.4.1.
- **Verified in-game:** user's 2026-10-28 screenshot shows the previous
  top-center counter. Exact loaded mod/map not confirmed; count accuracy,
  toggle and special rounds are not established by this screenshot.
- **Validated statically and installed (2026-10-28):** all six 0.4.2 GSC
  outputs parsed; build/install completed for standalone, shared raw scripts
  and three companions. Installed script hashes and IWD contents inspected.
  New placement/color await in-game confirmation. Latest package:
  `dist/zm_checkpoint-0.4.2-alpha.zip`. Co-op retains its 0.4.0 protocol and
  remains unverified in-game.
- Save verification: Buried and TranZit hashes matched the session baseline.
  Nuketown changed to a valid format-3 round-2 checkpoint with END during the
  session; build/install never write scriptdata. Likely a runtime save, not
  independently confirmed. Preserved the newer file without rollback; recorded
  current hashes in `.cache/counter-position-saves-current.json`.
- **Validated statically and installed (2026-10-27):** experimental host-stored
  co-op Save & Exit and separate CO-OP RESUME page. Exact string XUID roster,
  original host, count and map context are checked in the lobby and server.
  No co-op in-game test has occurred. See section 18 and `COOP_TEST_PLAN.md`.
- Nuketown has been tested successfully through the complete workflow:
  **SAVE & EXIT → lobby → RESUME → active round with zombies and round HUD**.
- The shared adapter is built and installed for all six stock physical Zombies
  maps. TranZit launch and its core round/player restore are verified in-game.
  Buried doors/debris/world unlocks are also verified in-game; Die Rise, Mob,
  and Origins still need systematic tests.
- An existing standalone Nuketown checkpoint at round 4 was preserved during the
  multi-map update.
- **Verified in-game failure:** after resuming the round-4 Nuketown checkpoint,
  the player died, Plutonium/game closed during the end sequence, and the old
  Resume row returned on relaunch. Version 0.3.1 now consumes a successfully
  restored checkpoint so that old state cannot loop indefinitely. The cleanup
  behavior is installed and statically validated but still needs an in-game test.
- **Verified in-game failure:** TranZit rejected the initial 0.3.0 generic script
  before map start because Nuketown-only perk functions were unresolved. Version
  0.3.1 physically strips those references from non-Nuketown build outputs. The
  corrected TranZit build is verified in-game: round, weapons, score, position,
  round HUD, and zombie spawning restored successfully.
- **Verified in-game failure:** a TranZit bank vault opened before Save & Exit
  returned closed after Resume. Version 0.3.2 now captures flags from every live
  map entity and replays the vault's stock breach event. The fix is installed and
  statically validated but needs a new post-update save and Resume test.
- **Verified in-game failure:** Buried restored its common doors, debris, and
  opened paths, but Arthur/Leroy respawned in his jail cell. The saved file had
  `jail_door1` but no actor record. Version 0.3.3 adds an optional Buried-only
  `SLOTH` record and reconstructs a released Arthur at the saved transform in a
  stable roam state. This is installed and statically validated; it needs a new
  post-0.3.3 checkpoint and in-game Resume test.
- **Validated statically:** full Easter-egg continuation cannot be implemented
  by collecting every quest flag. A bounded audit found 2 literal quest-related
  flags in TranZit, 34 in Die Rise, 54 in Mob, 34 in Buried, and 56 in Origins,
  while the actual quests also use arrays, counters, entity references, models,
  carried pieces, character/afterlife state, moving systems, and live threads.
  The approved design is a versioned per-map `QUEST` record that preserves
  stable completed milestones, replays their stock side effects, and restarts
  only the currently incomplete step.
- **Validated statically and installed:** 0.3.4 adds an optional format-3
  `QUEST,1,zm_buried,<branch>,tower` record for the selected side and completed
  Buried tower-build milestone. It replays the stock tower visuals, removes the
  consumed branch tower parts, then sets the stock branch flag. Generic replay
  skips Buried `sq_*` and `ftl_*` flags. Both branches are unverified in-game;
  no full Buried Easter-egg support is claimed.
- The existing standalone Buried round-9 save remains valid and unchanged, but
  predates the `QUEST` record. The Nuketown round-4 and TranZit round-7 saves
  also retained their exact SHA-256 hashes during the 0.3.4 install.

## 2. User goal

Allow a solo Zombies run to be stopped and continued later:

1. Open the normal pause menu during a match.
2. Select a native-looking **SAVE & EXIT** row.
3. Serialize stable game and player state.
4. Return to the correct private lobby.
5. Show a **RESUME <MAP> - ROUND N** row above **START MATCH** when the selected
   map has a valid checkpoint.
6. Launch through the normal Zombies session bootstrap.
7. Restart at the beginning of the saved round and restore the saved player and
   persistent world state.

This is intentionally a round checkpoint system. It does not attempt to suspend
live AI, script threads, projectiles, or every transient object in memory.

## 3. Supported maps

| Display name | Internal map name | Slot |
| --- | --- | --- |
| TranZit | `zm_transit` | `zm_checkpoint_zm_transit.sav` |
| Nuketown | `zm_nuked` | `zm_checkpoint_zm_nuked.sav` |
| Die Rise | `zm_highrise` | `zm_checkpoint_zm_highrise.sav` |
| Mob of the Dead | `zm_prison` | `zm_checkpoint_zm_prison.sav` |
| Buried | `zm_buried` | `zm_checkpoint_zm_buried.sav` |
| Origins | `zm_tomb` | `zm_checkpoint_zm_tomb.sav` |

The internal identifiers were confirmed from shipped/extracted T6 LUI map data,
including `ui_mp/t6/zombie/basezombie.lua` from the local reverse-engineering
reference checkout.

### TranZit caveat

TranZit, Town, Farm, and Bus Depot are variants of the `zm_transit` physical map.
They currently share one checkpoint slot. Until mode/location identity is added
to the save format, select the same mode and location before pressing Resume.

## 4. What is currently saved

- Round number
- Score
- Health
- Position and view direction
- Current weapon
- Primary weapons, Pack-a-Punch variants, attachments, clips, and reserve ammo
- Perks
- Frag grenades, sticky grenades, monkeys, EMPs, and claymores
- Held equipment
- Common purchased doors and debris through persistent script flags
- Set `script_flag` values attached to live map entities, excluding Buried
  `sq_*` and `ftl_*` quest flags owned by the typed adapter
- Power flag when exposed through the common flag system
- TranZit bank-vault breach state
- Buried collapsing passages, Arthur-opened barricades, and fountain openings
- Buried Arthur/Leroy released status, position, facing, prior state label, and
  release context; transient actions are restored as stable roaming
- Buried main sidequest selected branch and completed tower-build milestone
  (`QUEST` schema 1; 0.3.4 static validation only)
- Nuketown perk-machine arrival progress

## 5. What is deliberately not saved yet

- Live zombies and their AI state
- Exact partial-round zombie counts
- Projectiles and temporary power-ups
- Rebuilt barriers
- Random-number-generator state
- Easter-egg progress in general
- TranZit bus position/state
- Die Rise elevator positions and active motion
- Mob of the Dead afterlife and map-exclusive systems
- Mob plane/gondola and quest-object state
- Buried Easter-egg progress after the tower-build milestone, carried parts,
  lantern charge, wisp paths, time-bomb snapshots, puzzle state, and endings
- Origins generators, staffs, and other map-exclusive systems

The common adapter covers set entity `script_flag` values beyond the stock
door/debris arrays, except for Buried `sq_*` and `ftl_*` quest flags, which the
typed adapter owns. This captures a much wider class of opened/unlocked state.
It is still not a full engine snapshot: the map-exclusive systems above keep
state in entity arrays, client fields, hidden/deleted models, and running threads.
See `MAP_STATE_AUDIT.md` for the exact coverage matrix and evidence.

## 6. Architecture

### Save path

1. `zmcheckpointingame.lua` inserts **SAVE & EXIT** into the pause menu.
2. The button calls `CoD.ZMCheckpointMenu.SaveAndExit`.
3. Lua sets `zmcp_command save_exit` and also sends the stock `menuresponse`
   bridge named `zm_checkpoint` with response `save_exit`.
4. GSC validates that exactly one living player is active.
5. The player is frozen and temporarily made invulnerable.
6. GSC writes the map-specific checkpoint using Plutonium's `fs_*` API.
7. GSC reopens and validates the completed file.
8. It persists the map-specific Resume dvars with `seta`.
9. It displays a success message and runs `exitlevel(0)`.

Both the dvar bridge and menu-response bridge are intentional. Some total
conversion mods replace or consume the normal pause-menu callback.

### Resume path

1. `privateonlinegamelobby.lua` finishes constructing the stock private lobby.
2. `AddLobbyResumeButton` checks the currently selected map and its archived
   checkpoint dvar.
3. A native lobby button is created, removed from the bottom of the vertical
   list, and reinserted with `addElementToTop`, placing it above **START MATCH**.
4. Clicking Resume runs:

   ```text
   set zmcp_autoload 1
   xpartygo
   ```

5. `xpartygo` uses the normal private-lobby Zombies launch path.
6. At map startup, GSC reads and validates the map-specific checkpoint.
7. The common `_zm::init_levelvars` function is detoured once so the map's round
   controller starts at the saved round.
8. After `initial_blackscreen_passed`, the player and common world state are
   restored. Buried 0.3.4 schedules its quest phase early and waits for the
   stock quest flags and tower buildables; it reconstructs tower effects and
   consumed parts before setting the selected branch flag. The separate Buried
   0.3.3 Arthur adapter waits for Arthur, restores a released actor's saved
   transform, and normalizes him to the stock roaming state.
9. After restoration succeeds, the checkpoint file is overwritten with
   `CONSUMED` and its map-specific Resume dvars are set to zero.
10. A defensive monitor also invalidates the checkpoint when stock Zombies
    notifies `pre_end_game` or `end_game` before restoration can finish.

This is a one-use Resume lifecycle. If the player wants another stopping point,
they must choose **SAVE & EXIT** again, which writes a new valid checkpoint.

**Do not replace `xpartygo` with a raw `map <name>` command.** That earlier
approach loaded the map and restored the player but skipped Zombies session
initialization, leaving no round HUD and no zombie spawner.

## 7. Persistent files and dvars

Each map uses:

```text
File:  zm_checkpoint_<internal-map-name>.sav
Dvar:  zmcp_has_<internal-map-name>
Dvar:  zmcp_round_<internal-map-name>
```

Solo control dvars (co-op controls are documented in section 18):

```text
zmcp_command     save, save_exit, status, clear, or empty
zmcp_autoload    1 only for the next Resume launch; reset to 0 by GSC
zmcp_ui_version  currently 0.4.0
```

The current checkpoint format version is `3`. A valid file begins with:

```text
CHECKPOINT,3,<internal-map-name>
ROUND,<number>
```

It contains `PLAYER`, `WEAPON`, `PERK`, `OFFHAND`, `EQUIPMENT`, `FLAG`, optional
Nuketown `MACHINE`, Buried `SLOTH`, and versioned Buried `QUEST` records, and
must end with:

```text
END
```

The reader rejects incomplete files, wrong format versions, wrong maps, invalid
rounds, and files without player state.

After successful restoration, the file is intentionally replaced with:

```text
CONSUMED
```

That content is invalid by design. The matching `zmcp_has_<map>` and
`zmcp_round_<map>` dvars are also cleared so the lobby does not offer the old run.

## 8. Source layout

| Path | Purpose |
| --- | --- |
| `src/scripts/zm/zm_nuked/zm_checkpoint.gsc` | Shared GSC implementation; despite the historical source folder name, the build copies it to all supported map folders. |
| `src/scripts/zm/zm_checkpoint_coop.gsc` | Co-op protocol, dual-generation reader/writer, host/roster checks and gated restore; appended to the shared source by Build.ps1 before map-only stripping. |
| `src/ui/ui/t6/menus/zmcheckpointcoop.lua` | Separate co-op lobby page and fail-closed host/roster/context gate. |
| `COOP_TEST_PLAN.md` | Co-op setup, scope, evidence and mandatory two-PC test matrix. |
| `tools/Test-CoopLobby.lua` | Executable Lua tests for the shipped lobby checks and launch action. |
| `src/ui/ui/t6/menus/zmcheckpointmenu.lua` | Shared map registry, save action, Resume action, and lobby button construction. |
| `src/ui/ui/t6/menus/zmcheckpointingame.lua` | Hooks the stock/class pause menu and adds **SAVE & EXIT**. |
| `src/ui/ui/t6/menus/privateonlinegamelobby.lua` | Stock private lobby entry point with the Resume hook loaded last. |
| `src/ui/ui_mp/t6/hud/ingamemenus.lua` | Stock in-game loader with the checkpoint hook loaded last. |
| `cfg/zm_checkpoint.cfg` | Legacy diagnostic key binds. |
| `tools/Build.ps1` | Builds the six map-script copies and the UI IWD. |
| `tools/Install.ps1` | Builds, installs standalone/shared scripts, and adds the UI companion to existing mods. |
| `mod.json` | Mod metadata and version. |
| `README.md` | User-facing setup, use, limitations, and troubleshooting. |
| `MAP_STATE_AUDIT.md` | Stock-script evidence, state-coverage matrix, map-only adapters, and known exclusions. |
| `EASTER_EGG_PERSISTENCE_PLAN.md` | Approved staged architecture, map order, safety boundaries, validation gates, and test matrix for quest persistence. |
| `CHANGELOG.md` | Version-by-version development log. |
| `PROJECT_HANDOFF.md` | This complete continuation guide. |
| `AGENTS.md` | Mandatory rules requiring future agents to read and maintain the project memory. |

The historical `src/scripts/zm/zm_nuked` location should eventually be renamed
to a neutral shared source directory. Do that only together with updates to both
PowerShell scripts; the current build is working and intentionally leaves it in
place.

`Build.ps1` treats blocks between `ZMCP_NUKETOWN_ONLY_BEGIN` and
`ZMCP_NUKETOWN_ONLY_END` as Nuketown-only. It preserves those blocks for
`zm_nuked` and removes them from the five generic map outputs. This is necessary
because T6 resolves external function references while linking a map script;
runtime `if (map == "zm_nuked")` guards do not prevent unresolved externals.
The marker-removal regex must use `[ \t]` for horizontal whitespace rather than
`\s`; the latter also consumes newlines/indentation under multiline matching.

## 9. Build and installation

From the project root:

```powershell
.\tools\Build.ps1
.\tools\Install.ps1
```

The standalone package is installed to:

```text
%LOCALAPPDATA%\Plutonium\storage\t6\mods\zm_checkpoint
```

The generated per-map GSC is installed to:

```text
%LOCALAPPDATA%\Plutonium\storage\t6\raw\scripts\zm\<map>\zm_checkpoint.gsc
```

The installer also copies each map script and `zz_zm_checkpoint.iwd` into every
mod directory already present under:

```text
%LOCALAPPDATA%\Plutonium\storage\t6\mods
```

At handoff time, companion coverage was installed into:

- `dlc5`
- `voidzombies_c`
- `zm_nuked_city_of_mars_updated_july_26th_2025`

Run the installer again whenever another mod is added.

Plutonium only loads custom raw LUI while an `fs_game` mod is loaded. The native
menu rows therefore require **ZM Checkpoint** itself or a companion-injected mod
to be loaded. Fully restart Plutonium or unload/reload the selected mod after an
IWD update because LUI is cached.

## 10. Diagnostic controls

Execute `zm_checkpoint.cfg` once to enable the legacy diagnostic bindings:

| Key | Action |
| --- | --- |
| F5 | Save without exiting |
| F6 | Show checkpoint status |
| F8 | Clear current map checkpoint |
| F9 | Set autoload and launch through `xpartygo` from a supported private lobby |

Normal use should go through the visible menu buttons. F9 is only a diagnostic
fallback from the private lobby.

## 11. Development and test log

### Initial prototype

- Implemented a GSC round-checkpoint prototype and keyboard controls.
- Added player inventory, perks, score, position, door/debris, and Nuketown
  perk-machine state.
- Added the first pause-menu and lobby UI integration.

### File-open failure

- In-game error: **Checkpoint file could not be opened**.
- Cause: the early implementation used Treyarch's legacy `openfile` API, which
  current Plutonium builds reject in this context.
- Fix: moved to Plutonium's `fs_fopen`, `fs_writeline`, `fs_readline`,
  `fs_fclose`, and `fs_testfile` APIs.

### Resume button missing

- A checkpoint could be saved, but the lobby did not reliably show Resume.
- Earlier hooks ran before or were replaced by stock/custom lobby construction;
  `ui_mapname` was also unreliable in some frontend states.
- Fixes evolved through direct archived checkpoint dvars, attaching after the
  private lobby was built, and finally using the lobby's native button list.

### Dead map after Resume

- Manual autoload succeeded in restoring the player, but the map had no round
  number and spawned no zombies.
- Cause: launching with raw `map zm_nuked` bypassed the Zombies lobby/session
  bootstrap.
- Fix: Resume now sets `zmcp_autoload 1` and invokes `xpartygo`.
- Result: the saved Nuketown round resumed with the round controller, HUD, and
  zombies working.

### Native Resume row

- The working Resume action was turned into a normal lobby button.
- The native button is inserted above **START MATCH** using
  `removeElement(button)` followed by `addElementToTop(button)`.
- The label includes the selected map and saved round.

### Multi-map foundation

- Replaced the hard-coded Nuketown checkpoint filename and metadata dvars with
  map-derived values.
- Added all six stock physical map identifiers to the UI.
- Kept the Nuketown perk-machine adapter conditional on `zm_nuked`.
- Updated the build/install scripts to deploy the shared source into all six
  map folders.
- Installed version `0.3.0-alpha` and retained the working version-3 Nuketown
  save format.

### Resumed death left an infinite Resume loop

- **Verified in-game:** the user resumed the Nuketown round-4 checkpoint, died,
  and the game/Plutonium closed during the end sequence. On relaunch, the same
  Resume row and old saved state were still present.
- Root cause of the loop: successful restoration never invalidated the source
  checkpoint or its archived Resume dvars.
- Version 0.3.1 fix: consume the checkpoint immediately after restoration and
  defensively on stock `pre_end_game`/`end_game` notifications.
- Additional hardening: restore and Nuketown perk-schedule threads now terminate
  on `end_game`.
- The process-close cause itself is still unknown. `console_zm.log` was empty and
  Windows Application events contained no matching Plutonium application fault.
  Do not claim the crash itself fixed until an in-game death test passes.

### TranZit unresolved Nuketown externals

- **Verified in-game:** launching TranZit with 0.3.0 produced five script-link
  errors, including unresolved `turn_perks_on` and `move_perk`, before map start.
- Root cause: the same full source was copied to every map. T6 resolved the
  Nuketown external calls even though runtime map checks would never execute them.
- Version 0.3.1 fix: the build retains marked Nuketown-only sections for
  `zm_nuked` and physically removes them from all five generic map outputs.
- The corrected TranZit output contains no `zm_nuked_perks` or related calls and
  parses successfully.
- **Verified in-game:** TranZit now launches, spawns zombies, displays the round
  HUD, and restores the saved round, player location, points, and weapons.

### Scripted world objects were not restored

- **Verified in-game:** on TranZit, a bank vault opened before Save & Exit was
  closed after Resume even though the player's other state restored correctly.
- Root cause: the 0.3.1 collector only inspected `zombie_door` and
  `zombie_debris`. The vault uses `town_bunker_door`; its stock script rotates
  the model and connects paths in response to explosive damage, then sets the
  entity's `script_flag` as a side effect.
- Version 0.3.2 fix: enumerate every live entity and collect its attached
  `script_flag`, refreshing that inventory immediately before each save so
  later-spawned entities are included; then use a TranZit-only adapter to replay
  the stock vault damage event when that saved flag is present.
- A static audit at reference commit
  `d02a9efd4382689180aaadcb609452babf5dc4c8` found the same geometry-first
  pattern in Buried collapsing passages and Arthur barricades. Buried fountains
  also require explicit named flags and physical replay. All are handled by a
  Buried-only block in 0.3.2.
- Exact findings, guarantees, and exclusions are maintained in
  `MAP_STATE_AUDIT.md`.

### Buried Arthur returned to jail

- **Verified in-game:** a 0.3.2 Buried Resume kept the opened debris, doors,
  and other reported world progress, but Arthur/Leroy was back inside his cell.
- Evidence: the installed round-9 checkpoint contains `jail_door1` and the
  other opened paths but has no actor-state record.
- Root cause: stock `_zm_ai_sloth.gsc` always creates Arthur at
  `sloth_idle_pos` in `jail_idle`; the jail door and Arthur are separate systems.
- Version 0.3.3 fix: a Buried-only optional `SLOTH` record saves released state,
  transform, prior state label, and booze/release context. Resume waits for the
  stock actor, restores the open-cell context, teleports him, and invokes the
  stock `sloth_set_state("roam")` entry point.
- Transient `berserk`, `crash`, candy/context, and traversal actions are not
  resumed mid-thread. They deliberately normalize to roaming at the saved
  location to avoid half-completed animations and deadlocked state machines.
- Existing pre-0.3.3 checkpoints remain valid but contain no `SLOTH` record, so
  they cannot restore Arthur's old position.
- A static six-map actor search found Arthur as the only persistent map-specific
  allied AI. Hostile bosses, TranZit's bus/driver, Origins robots, elevators,
  and afterlife systems are intentionally not routed through this adapter.
- Full Easter-egg state remains a known limitation: the audited quest scripts
  contain many flags plus mutable `level` fields, arrays, models, carried parts,
  and active waiter threads. Blanket flag replay is unsafe; use dedicated
  per-map milestone reconstruction instead.

### Buried quest milestone checkpoint

- Version 0.3.4 captures only the branch selected by the completed `bt` tower
  stage and the stable milestone token `tower`; the optional typed record is
  `QUEST,1,zm_buried,<maxis|richtofen>,tower`.
- On Resume, a Buried-only early thread waits for the stock tower buildable
  handles and branch flags, then mirrors the stock `init_sidequest` tower
  presentation: tower bolts/effect, consumed tower-piece removal, and branch
  flag set last. If required setup is unavailable or round logic already began,
  it logs the failure, leaves the checkpoint valid, and does not claim quest
  restore success.
- The reader rejects duplicate, malformed, wrong-map, unsupported-schema, or
  unsupported branch/milestone `QUEST` records without rejecting the rest of a
  valid version-3 checkpoint. Existing saves without `QUEST` remain readable.
- Generic Buried flag serialization/replay skips `sq_*` and `ftl_*` names. This
  avoids using the common flag mechanism to advance incomplete quest steps.
- Later stages and all carried pieces are outside the 0.3.4 guarantee. See
  `MAP_STATE_AUDIT.md` for the milestone side-effect table and safe reset rules.
- **In-game result: Not yet tested.** Test the Maxis and Richtofen tower
  branches separately, saving just after each tower is built and before the next
  stage advances. Use an active mod with a separate checkpoint slot so the
  existing standalone Buried round-9 file remains untouched.

## 12. Validation already completed

- GSC source parses successfully with the bundled `gsc-tool` for T6 PC.
- All Lua files passed the local Lua parser during the 0.3.0 update.
- Both PowerShell scripts passed PowerShell parser validation.
- All six built GSC files had identical SHA-256 hashes after the 0.3.0 build.
- All six raw installation folders contained the script.
- The standalone mod and all three companion mods contained six map scripts and
  `zz_zm_checkpoint.iwd`.
- The installed IWD was inspected and contained:
  `SupportedMaps`, `zm_transit`, `zm_tomb`, `0.3.0`, `addElementToTop`, and
  `xpartygo`.
- The 0.3.0 installation reported `0.3.0-alpha`; the current installed
  `mod.json` now reports `0.3.3-alpha`.
- Existing Nuketown checkpoint still began with `CHECKPOINT,3,zm_nuked` and
  `ROUND,4` after installation.
- Project-level continuity rules were added in `AGENTS.md`; future agents must
  record fixes, failed attempts, validation level, and in-game outcomes.
- Version 0.3.1 Nuketown and generic TranZit outputs both passed the T6 GSC
  parser; the modified Lua menu passed `luaparse`; modified PowerShell scripts
  passed parser validation.
- Installed generic map scripts were checked to contain no Nuketown perk
  externals. All five generic scripts shared one hash, while the installed
  Nuketown script retained its adapter and a distinct hash.
- The installer did not modify the existing round-4 checkpoint; it will be
  consumed only by the updated runtime after a successful Resume.
- Version 0.3.2 all six generated scripts passed the T6 PC parser. Build/install
  PowerShell scripts passed parser validation.
- Package inspection confirmed the shared all-entity flag collector on all six
  maps, the vault target only on TranZit, Buried special targets only on Buried,
  and Nuketown perk externals only on Nuketown.
- Version 0.3.2 was installed to the standalone mod, six shared raw map folders,
  and all three current companion mods. Both existing checkpoint files retained
  identical SHA-256 hashes across installation.
- Version 0.3.3 all six generated scripts passed the bundled T6 PC parser; the
  modified Lua and both PowerShell scripts passed their parsers.
- Package/installed-script inspection confirmed the Arthur external and restore
  functions exist only in `zm_buried`; the optional-record reader is common and
  safe on all maps. The first over-broad build guard rejected that common reader,
  was narrowed to actual Buried externals/functions, and then passed all maps.
- Version 0.3.3 was installed to standalone, all six shared raw map folders, and
  all three companion mods. The installed IWD contains UI version `0.3.3`.
- Buried and Nuketown checkpoint hashes remained unchanged. During the session,
  the TranZit slot advanced from a valid round-5 checkpoint to a valid round-7
  checkpoint. The build artifact has no `scriptdata` and the installer performs
  no checkpoint writes/deletes; the newer runtime file was preserved. The final
  reinstall preserved all three current checkpoint hashes exactly.
- Version 0.3.4 all six generated map scripts passed bundled T6 PC parsing;
  modified Lua and both PowerShell scripts passed their parsers. Inspection
  confirmed Buried stock externals appear only in `zm_buried`, with Nuketown and
  TranZit externals confined to their respective outputs.
- Version 0.3.4 package/IWD inspection found the expected five UI Lua files and
  no `scriptdata` or `.sav` files. The build and install completed to the
  standalone mod, six shared raw folders, and all three companion mods. All
  three existing checkpoint SHA-256 hashes matched before and after installation.
- Version 0.3.4 is **installed and statically validated**, not yet tested in a
  match. A Plutonium/mod reload is required to load the updated UI package; a
  new Buried match is required to exercise the updated GSC.

## 13. In-game test plan for the next chat

Test one map at a time. Start with a simple Survival map/variant before testing
complex map mechanics.

1. Fully close and reopen Plutonium after UI changes.
2. Load **ZM Checkpoint**.
3. Select the test map and start a solo match normally.
4. Confirm **SAVE & EXIT** is visible in the pause menu.
5. Advance to round 2 or 3.
6. Record points, weapon/ammo, perks, open doors, and position.
7. Click **SAVE & EXIT**.
8. Confirm both visible messages:
   - `Checkpoint saved - round N`
   - `Returning to the lobby...`
9. In the same map's lobby, confirm the Resume row appears above Start Match.
10. Click Resume.
11. Verify:
    - the round HUD exists;
    - zombies spawn;
    - the restored round matches;
    - points and inventory match;
    - common doors/debris and power behave reasonably;
    - position is valid and does not trap the player.
12. Save again after resuming to test repeated cycles.
13. For the one-use lifecycle test, Resume a checkpoint, confirm the on-screen
    consumed message, die, return/relaunch, and verify the old Resume row is gone.
14. For Buried 0.3.3, release Arthur, move him well outside the cell, Save & Exit,
    Resume, and confirm he appears near the saved position and begins roaming.
    Inspect the new checkpoint for a `SLOTH` line before Resume consumes it.
15. For Buried 0.3.4, load the installed `dlc5` companion (which had no existing
    checkpoint files at this handoff) to keep the standalone save slot intact.
    Start a solo classic Buried match, complete either the Maxis or Richtofen
    tower build, and Save & Exit before completing any amplifier actions. Resume
    through the lobby button. Confirm the matching tower presentation and
    branch remain, consumed
    tower parts stay gone, the quest proceeds to amplifiers, normal round HUD and
    zombie spawning continue, and `console_zm.log` reports
    `adapter=1 phase=world restored branch=<branch> milestone=tower`. Repeat
    once for the other branch. Do not use the existing standalone round-9 save
    for this test because a runtime Save & Exit would replace that map slot.

Record the exact map, mode/location, round, loaded companion mod, observed state,
and `console_zm.log` errors for every failure.

Recommended order:

1. Buried Arthur regression (`zm_buried`)
2. Town/Survival (`zm_transit`)
3. Die Rise (`zm_highrise`)
4. Mob of the Dead (`zm_prison`)
5. Origins (`zm_tomb`)
6. Full TranZit, because its bus and location systems need deeper coverage

## 14. Troubleshooting checklist

### SAVE & EXIT is missing

- Confirm an `fs_game` mod is loaded.
- Confirm its folder contains `zz_zm_checkpoint.iwd`.
- Restart Plutonium or reload the selected mod.
- For a new companion mod, rerun `.\tools\Install.ps1`.
- A total conversion may replace the same menu files and need a specific adapter.

### Clicking SAVE & EXIT does nothing

- Start a fresh match after installing GSC changes; a running match keeps the
  old loaded bytecode.
- Execute `zm_checkpoint.cfg` and try F5 to separate UI failure from file/GSC
  failure.
- Enable `developer 1` before starting the map and inspect `console_zm.log`.

### Checkpoint file could not be opened

- Confirm the installed script uses `fs_fopen`, not legacy `openfile`.
- Confirm the active mod's `scriptdata` location is writable.
- Do not reintroduce the obsolete file API.

### Resume row is missing

- Confirm the currently selected map matches the save.
- Check archived dvars such as `zmcp_has_zm_nuked` and `zmcp_round_zm_nuked`.
- Check the active mod's `scriptdata` directory; saves are scoped to the loaded
  mod environment.
- Fully reload the mod after changing LUI.

### Map loads but has no zombies or round HUD

- The launch path was bypassed. Ensure Resume uses `xpartygo` from the private
  lobby and not `map <name>`.

### Script error or immediate return to menu

- Run with `developer 1`.
- Inspect `console_zm.log` in the active mod folder or `storage\t6\main`.
- Verify the error against the exact map; map-exclusive assets/functions may
  need to be moved into that map's adapter.
- If a non-Nuketown map reports unresolved `turn_perks_on`, `move_perk`, or other
  Nuketown perk functions, confirm its installed generated script contains no
  text matching `zm_nuked_perks`; rerun the 0.3.1 installer and reload the mod.

## 15. Important implementation cautions

- Preserve user checkpoint files under `scriptdata`; the build and installer
  should never delete them.
- Do not close or restart Plutonium automatically. Tell the user when a restart
  is required.
- Do not replace another mod's archives. The companion uses a uniquely named
  `zz_zm_checkpoint.iwd` and loose scripts.
- Keep the `xpartygo` launch path.
- Keep save validation and the final `END` record.
- Keep the one-use Resume lifecycle: consume only after a successful restore,
  with game-end invalidation as a defensive fallback. A later **SAVE & EXIT**
  must still create a fresh checkpoint.
- Keep solo validation until multiplayer synchronization is explicitly designed.
- Treat map-exclusive systems as separate adapters, not assumptions in the
  common serializer.
- The common authoring source contains marked Nuketown-, TranZit-, and
  Buried-only blocks. `Build.ps1` must physically strip every nonmatching block;
  a runtime map check alone does not prevent T6 linker failures.

## 16. Recommended next development milestones

1. Test the 0.3.4 Buried tower milestone on both branches using a separate
   checkpoint slot; collect exact visual and log evidence before expanding its
   supported prefix.
2. Create a new Buried save after Arthur is released and verify the
   `SLOTH` record, saved location/facing, and stable roaming after Resume. The
   existing round-9 save predates the actor record and cannot prove this fix.
3. Resume the current post-0.3.2 TranZit save and verify that both bank-vault
   doors remain open. A pre-0.3.2 save has no vault flag.
4. Verify in-game that resumed death no longer leaves an old Resume row and
   record whether the prior end-sequence process close recurs.
5. Complete and record the remaining new-map smoke tests.
6. Fix any map-specific load errors without regressing Nuketown or TranZit.
7. Add mode/location identity to `zm_transit` checkpoints.
8. Follow `EASTER_EGG_PERSISTENCE_PLAN.md`; add later Buried stable milestones
   one at a time after the tower test evidence is recorded.
9. Expand quest adapters in the audited order: Die Rise, TranZit, Mob, then
   Origins. Never blanket-set every discovered flag without replaying required
   side effects.
10. Continue other dedicated adapters in the priority order in
   `MAP_STATE_AUDIT.md`:
   TranZit bus, Mob afterlife/plane/gondola, Origins generators/staffs, Buried
   quest objects, and Die Rise elevator/quest state.
11. Move the common GSC source to a neutral `src/scripts/zm/common` location.
12. Add timestamped backup/atomic replacement behavior for checkpoint writes.
13. Add a clear-checkpoint action to the visible lobby UI.
14. Initialize Git and commit the known-good Nuketown baseline plus the multi-map
    alpha once the user requests version control.

## 17. Co-op feasibility history

### 2026-10-27 co-op feasibility investigation (proposal only)

- **Validated statically:** installed standalone metadata reports 0.3.4-alpha;
  all six installed standalone map scripts retain the single-player guard.
  Source save/restore uses one player record, server-side file I/O, and no
  account-keyed roster or client-local persistence protocol. Removing the guard
  alone cannot implement co-op. The Buried quest adapter also assumes one player.
- **Expected:** a separate co-op save namespace and Resume page can bind a run
  to its original host account, exact unordered player-ID roster and count,
  map/mode/location, mod compatibility version, and unique save generation.
  Restore must map records by identity, never connection order. Validate the
  lobby before xpartygo and revalidate on the server before releasing gameplay.
- Identity API availability, stable online account mapping, lobby-to-match ID
  equivalence, and host detection need a two-PC probe. Candidate GUID/XUID APIs
  are not yet verified on this installation. Store IDs as strings and names only
  as display labels. Do not obtain launcher credentials or tokens.
- Plutonium's official changelog documents LAN GUIDs derived from usernames
  (r5202); LAN identity cannot be claimed as authenticated account ownership.
  Source: https://plutonium.pw/docs/changelog/ (consulted 2026-10-27).
- **Known limitation:** installing the mod on clients does not make the existing
  host-side fs_* calls write files on those PCs. Per-PC saves require a proven
  client persistence/transport mechanism, potentially a companion component.
  Proposed simpler first version: host stores world state plus every player's
  state; this is an alternative to, not fulfillment of, distributed local saves.
- If distributed copies are required, all must share run ID/generation and be
  durably acknowledged before exit. Interrupted saves/resumes must remain
  recoverable; consume only after the entire team restores successfully. Do not
  reuse solo game-end invalidation for an aborted co-op validation attempt.
- Next co-op step: isolated two-PC identity/host/lobby/client-storage capability
  probe, then design implementation around measured capabilities. Test missing,
  extra, duplicate, renamed and reordered players; wrong host/map/mode/mod;
  disconnects and write failures; host migration; and 2/3/4-player round startup.
  Preserve the existing solo guard until a separate co-op path is designed and
  tested. Existing map/quest exclusions remain applicable.
- In-game result: Not yet tested. Investigation only; no runtime, package,
  install or checkpoint changes, and no restart required for this session.

## 18. Current co-op implementation — 2026-10-27

The user approved host-stored complete checkpoints. Version 0.4.0-alpha is
built and installed to standalone, six shared raw map folders and all three
existing companions. A shareable standalone ZIP is at
`dist/zm_checkpoint-0.4.0-alpha.zip`. No game was closed or restarted.

- **Validated statically:** all six generated GSCs, three modified/new UI Lua
  files and Build/Install PowerShell parsed; 23 actual Lua predicate/action
  cases pass under Fengari with engine mocks. IWD contains six expected Lua
  files, including the co-op page. Installed script/IWD hashes match the build.
  All three existing solo checkpoint SHA-256 hashes remain unchanged.
- Solo format 3 remains unchanged. A new co-op session cannot fall back to
  writing a solo slot when guests leave. Separate COOP schema 1 saves contain
  the host XUID, 2–4 exact member XUIDs, per-member inventory/player state,
  shared world state, mode/group/location/fs_game, difficulty/magic/headshots,
  monotonically increasing generation, and final END.
- Alternating `_a.sav`/`_b.sav` files retain the previous complete generation
  during a write. The latest valid generation is selected; `_used.sav` is a
  generation receipt that also blocks older consumed generations. Corrupt or
  unreadable receipts fail closed and require investigation, not deletion of
  real saves. Snapshot files remain intact when consumption cannot be verified.
- The UI uses Engine.GetPlayersInLobby, string XUIDs and GameHost/party-host
  checks. It compares exact sets regardless of order or display-name changes,
  refreshes every 500 ms and checks again on click. IDs never pass through Lua
  numbers. Missing API/identity data locks Resume; errors are retained in
  `zmcp_coop_ui_error`. Missing members currently display account IDs.
- Resume sets `zmcp_coop_autoload 1`, clears solo autoload, then uses xpartygo.
  GSC resets the request, holds stock round_think, waits for the exact living
  team and matching `hello_040` menu-response handshake, restores shared state
  then each member by XUID, and verifies consumption before releasing the round.
  Everyone must open pause once per match, including on a Resume launch.
  Initial team wait is 120 seconds; overall watchdog is 150 seconds. Failed
  checks exit to lobby; solo game-end consumption is not attached to co-op.
- **Known limitation:** no dedicated server, split-screen identity, host
  migration, competitive mode, custom round controller, co-op character or
  quest-milestone reconstruction guarantee. All previous dynamic-map exclusions
  remain. Normal round-start effects (such as grenade awards) need observation.
  UI handshake declares compatibility; it is not cryptographic file attestation.
- **Expected, unverified:** Plutonium lobby string XUIDs and getxuid() normalize
  to the same online identity, round-think detouring holds multiplayer spawning,
  and existing player/world adapters restore a full team. LAN identity remains
  username-derived. No claim of co-op success on any map is justified yet.
- Next step: reload the mod on both PCs and follow `COOP_TEST_PLAN.md`, beginning
  with two-player Nuketown. Record HUD/spawning, each player's state and ID,
  negative roster/host cases, save/resume repetition and disconnect recovery.
  Guest-only save requests must be rejected. Keep pending solo Buried/TranZit
  regression tests from section 13 on the backlog.

## 19. Ready-to-paste prompt for a new chat

```text
Continue the ZM Checkpoint project in:
C:\Users\User\Documents\Projects\Bo2 Zombie Plutonium

First read and follow AGENTS.md, then read PROJECT_HANDOFF.md, README.md,
CHANGELOG.md, MAP_STATE_AUDIT.md, and EASTER_EGG_PERSISTENCE_PLAN.md completely.
Also read COOP_TEST_PLAN.md. Current installed version is 0.4.2-alpha, with a red upper-left
remaining-enemy counter toggled with 0/numpad 0. New styling is installed
and statically validated, awaiting visual confirmation; the earlier counter
was visible in the user screenshot. It retains the 0.4.0
experimental host-stored co-op path and separate CO-OP RESUME page. All parsers
and 23 mocked Lua lobby/launch cases pass; co-op is not tested in-game. Prioritize
the two-PC Nuketown test, then negative roster/host/timeout cases. Every player
must open pause once per match for hello_040. Preserve solo and co-op files.
Nuketown's original solo workflow,
TranZit's round/player restore, and Buried's common doors/debris restore are
verified in-game. Version 0.3.3
adds an optional Buried `SLOTH` record and restores a released Arthur at the
saved transform in stable roaming state. It is installed and statically
validated but needs an in-game test using a new checkpoint; the existing
round-9 Buried save predates the actor record. Version 0.3.4 statically validates
and installs only the Buried branch plus completed tower milestone record. Test
both branches in the `dlc5` companion's separate save slot before extending that
prefix. Full Easter-egg state is not guaranteed. Preserve existing scriptdata
saves, the native menu buttons, one-use Resume, and the xpartygo launch path. Use
the existing Build.ps1 and Install.ps1 workflow, validate changes, and document
all results back into PROJECT_HANDOFF.md and CHANGELOG.md.
```

- **Published to GitHub (2026-10-28):** public repository
  `https://github.com/PourquoiPasMoi/zm-checkpoint`; source is on `main` and
  release `0.4.2-alpha` includes `dist/zm_checkpoint-0.4.2-alpha.zip`, the
  complete standalone mod folder. Future update requests should rebuild the
  folder ZIP, push source, and update the matching release asset; this workflow
  is recorded in `AGENTS.md`. No general reuse license has been selected; see
  `LICENSE-NOTICE.md`.
- 2026-10-28 updater menu diagnosis: the installed IWD was stale because the
  build did not reliably replace the target archive. Build now explicitly
  replaces `zz_zm_checkpoint.iwd` and embeds the mainlobby hook. Rebuilt and
  reinstalled 0.4.3-alpha; both generated and installed archives contain the
  hook. User screenshot confirms the mod is loaded but did not show the entry
  before this fix. **In-game:** awaiting reload/confirmation. The entry is
  limited to `mods/zm_checkpoint`; companion mods are not detected. The popup
  currently hands off to manually run the Windows updater script; seamless
  launch remains unsupported in T6 LUI.
- 2026-10-28 popup layout correction: screenshots confirm the update button is
  visible below Mods, while the popup's oversized default-font message overflowed
  its small frame. Replaced it with a large popup and short condensed-font text
  rows. Rebuilt/reinstalled package 0.4.3-alpha; Lua parsing passed and save
  hashes were unchanged. **In-game:** new layout awaits confirmation after LUI
  reload. Click still gives instructions; no direct Windows updater launch.

- **Validated statically and installed (2026-10-28):** 0.4.3-alpha adds a
  console-log bridge for CHECK FOR UPDATES. The Windows scheduled task
  `ZM Checkpoint Update Bridge` is running under the current user and watches
  `storage/t6/main/console_zm.log` for `ZMCP_UPDATE_REQUEST_20261028` emitted
  by the in-game button. It launches the update window on detection. The
  companion uses GitHub's releases list (which includes prereleases) and
  copies package-owned files while preserving `scriptdata`. The installed IWD
  contains the marker; six GSC and all Lua parsed; build/install passed;
  before/after save hashes matched. **In-game:** the actual click-to-companion
  handoff is not yet tested. Local ZIP is `dist/zm_checkpoint-0.4.3-alpha.zip`;
  GitHub still publishes 0.4.2-alpha. Reload mod UI before testing.
- REA investigation: opened the shipped `t6zm.exe` (SHA-256
  `2aff340f22f0c68bf46511c7bbc6167e4bb84524817f54cae08e8f60e6f9afc3`).
  Its string table contains `openurl` and it imports `ShellExecuteA`, but no
  configured REA native provider could resolve call sites, so these do not
  establish a usable console command. The log bridge avoids depending on
  an unverified native command. Do not claim direct T6 process launch.
- Bridge verification update: an isolated synthetic Plutonium console-log marker
  launched a harmless companion script successfully. This validates the Windows
  watcher/launch path; whether T6 writes the marker on an actual button press
  remains unverified until the user reloads the mod and clicks it.
- The update window now gives accurate manual unload/reload instructions after
  installation. It does not close or restart Plutonium automatically; the
  earlier Yes/No prompt incorrectly implied it could unload the active mod.
- **Verified in-game failure (2026-10-28, standalone `mods/zm_checkpoint`,
  main menu):** CHECK FOR UPDATES opened a blank, persistent PowerShell window
  and showed no status. Log text was `Unknown command "echo"`; T6 rejected the
  old signal command. Fixed the menu to send the unique unknown command
  `zmcp_update_request_20261028`, which appears in the log and is watched by a
  hidden WScript-launched PowerShell task. The updater's check-only path now
  returns to the window caller, allowing the "up to date" dialog, with an error
  dialog on failures. PowerShell 5.1 output and isolated log-trigger test pass;
  installed saves kept exact hashes. **In-game:** corrected flow needs a click
  after unload/reload. Close the old visible watcher terminal manually; do not
  close/restart Plutonium automatically.
- **Validated statically and installed (2026-10-28):** local 0.4.4-alpha moves
  the normal up-to-date result into the in-game updater panel. The companion
  writes `zmcp_update_status.cfg` under both `storage/t6/main` and
  `mods/zm_checkpoint`, while the panel polls it through T6 `exec` and updates
  its status text. The installed companion wrote `up_to_date` for local
  0.4.4-alpha; Lua/PowerShell parsed, build/install passed, save hashes stayed
  unchanged, bridge restarted. **In-game:** panel refresh/CFG lookup remains
  unverified. GitHub release is still 0.4.2-alpha.


- **2026-10-28 update-download test preparation:** user screenshot verifies in-game
  0.4.4-alpha updater reports latest version in its panel. 0.4.5-alpha changes
  only the up-to-date wording to short lines. It is built for a GitHub release
  without running Install.ps1: the current PC must remain on installed
  0.4.4-alpha so the user can check available-update, download/install, status,
  and reload. Before publishing, compare every installed file hash against
  `.cache/publish-045-installed-before.json`. Do not install 0.4.5 locally as
  part of publishing. Once the user completes the update test, record result.

- **Published (2026-10-28):** GitHub release
  `https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.5-alpha`
  contains `zm_checkpoint-0.4.5-alpha.zip`. The installed 0.4.4 updater now
  reports `UPDATE_AVAILABLE|0.4.4-alpha|0.4.5-alpha`. Every installed file,
  including checkpoint saves, matched its pre-publication SHA-256 baseline.
  Next: user tests the in-game download and install; do not pre-install 0.4.5.

- **Verified in-game (user screenshot, 2026-10-28):** on standalone
  `mods/zm_checkpoint`, the in-game panel displayed "Update available:
  0.4.5-alpha" and the external Windows Yes/No prompt opened. The installed
  metadata now reports 0.4.5-alpha, consistent with an update having been
  applied, but the complete download/copy/reload path was not independently
  captured in-game.
- **Validated statically and installed (2026-10-28):** local 0.4.6-alpha puts
  INSTALL UPDATE and NOT NOW in the same in-game panel. A second unknown-command
  marker (`zmcp_update_install_20261028`) tells the background watcher to run
  the installer without a Windows prompt. Status file states include installing
  and installed. The watcher task was restarted; the current installed
  companion wrote `up_to_date` for 0.4.6; save hashes matched. UI choices and
  install flow still need a future-release in-game test. GitHub remains 0.4.5.

- **Verified in-game (user screenshots, 2026-10-28):** local 0.4.6 updater
  showed both checking and up-to-date states; body text rendered oversized and
  visually soft, and the checking message nearly overlapped disabled buttons.
  Root cause in `zmcheckpointupdater.lua`: body UIText height was 74 UI units,
  which T6 used to scale the glyphs. 0.4.7 changes body height to 28, status
  height to 28, uses the default font for body, and shortens checking/install
  messages. Build and publish as a new release without running Install.ps1;
  keep every installed file at 0.4.6 for the user to test download/install.

- **Published (2026-10-28):** GitHub release
  `https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.7-alpha`
  contains `zm_checkpoint-0.4.7-alpha.zip`. Installed 0.4.6 updater reports
  `UPDATE_AVAILABLE|0.4.6-alpha|0.4.7-alpha`; every installed file, including
  checkpoints, matched its pre-publication SHA-256 baseline. Next: user tests
  in-game Install and visual appearance; do not pre-install 0.4.7.

- **Verified in-game (user screenshot, 2026-10-28):** the in-game update path
  installed 0.4.7-alpha, and the smaller panel text is legible. Installed
  `mods/zm_checkpoint/mod.json` also reports 0.4.7-alpha. In the up-to-date
  state, disabled NOT NOW still held focus and blinked. The 0.4.8-alpha menu
  explicitly removes focus from both disabled update choices and focuses a new
  BACK choice; the Back choice also appears after installed/error states.
  **Validated statically:** Lua parser, build, package inspection. The new
  focus behavior awaits an in-game check. The owner requests that future
  releases be pushed to GitHub without installing into the local game;
  the owner will run the update script. Preserve this workflow.

- **Published (2026-10-28):** GitHub release
  `https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.8-alpha`
  contains `zm_checkpoint-0.4.8-alpha.zip` (79,999 bytes; SHA-256
  `8F09B2D8EF2FC8F47941C86BE262C9FBBA7B4B36AA2FA4CC009342F2BA0BE090`).
  Source was pushed before the release. Installed 0.4.7 updater returned
  `UPDATE_AVAILABLE|0.4.7-alpha|0.4.8-alpha`; no local install was run.
  All three existing `scriptdata` checkpoint hashes still match the session
  baseline. Next: owner downloads 0.4.8 through the updater, unloads/reloads
  the mod, and confirms only BACK holds focus when already current.
