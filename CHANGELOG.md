# Changelog

All notable ZM Checkpoint changes and important test results are recorded here.
The package is experimental, so versions before a stable release use alpha
semantics.

## 0.4.38-alpha — 2026-11-01

### 2026-11-01 — Typed starting points (Claude Code)

- Request: owner asked to keep moving through the idea list ("I will do my tests later").
- Change or investigation: the STARTING POINTS row now accepts any amount from 1 to 1,000,000 instead of nine fixed choices. The lobby hook that already replaces the stock starting-round selector (verified in-game) also matches a selector named `STARTING POINTS` and swaps it in place for a number held in the archived dvar `zmcp_start_points` (0 shows DEFAULT). Left/right and the mouse wheel step by 5,000, a click or Enter opens the stock on-screen keyboard (title "STARTING POINTS (0 = DEFAULT, MAX 1000000)", up to 7 characters), typed digits are validated and clamped, and the value is shown with thousands separators. No new row (lobby stays at 13); the hint became "New match: start with this many points. Click to type." (53 characters, two lines). If the hook cannot attach, the row keeps its old fixed list. `RefreshLoadoutOptions` now clamps the dvar to 0-1,000,000 instead of resetting unknown values. The GSC side already read any 1-1,000,000 value.
- Files affected: `src/ui/ui/t6/menus/privateonlinegamelobby.lua`, `zmcheckpointloadout.lua`, `tools/Test-StartRound.lua`, `tools/Test-Loadout.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses; nine Lua suites pass (new cases: step, wheel, keyboard command, typed values, clamps, formatting). The same mechanism for the starting round is **verified in-game**; its reuse for points is **expected, not verified**.
- Published: [GitHub release 0.4.38-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.38-alpha) (source commit `3e836dbc669aa7bdb73ff5c295ce68f23ead5315`; 166,430-byte ZIP, 20 entries, no saves/caches, SHA-256 `F00C98975DFB9F026B590A39471554E81351AD1DA3F246EA4CE833A67C3464DE`, matches GitHub). No local install was run.
- In-game result: Not yet tested (0.4.37 backup also untested). **Expected, unverified:** the stock lobby passes the literal name `STARTING POINTS` to the selector constructor (if not, the row silently stays on the fixed list).
- Remaining risk/next step: owner to click STARTING POINTS, type an amount, start a match and compare the score.

## 0.4.37-alpha — 2026-11-01

### 2026-11-01 — Solo save backup (Claude Code)

- Request: owner said the Pack-a-Punch option worked and to move to the next item, save backup.
- Change or investigation: every solo Save now first copies the slot's existing complete checkpoint (must contain its `END` record) to `<slot file>_backup.sav` (`zm_checkpoint_<map>_backup.sav` for slot 1, `zm_checkpoint_<map>_slotN_backup.sav` for 2-4) using new `zmcp_copy_save`/`zmcp_solo_backup_path`. If the new write then fails read-back validation ("Checkpoint write failed"), the backup is copied back over the slot and the player is told. SOLO RESUME DELETE also overwrites the slot's backup with `EMPTY`, so a deleted slot keeps nothing. Backups are not read by the game; to return to an earlier save, close the game and copy the backup over the slot file. Not done on purpose: no change to the one-use Resume lifecycle (a consumed save is not backed up, since it is no longer a complete checkpoint), no backup of co-op sessions (they already keep generations), no loader change.
- Files affected: `src/scripts/zm/zm_checkpoint_slots.gsc`, `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses (helpers present in all six); nine Lua suites pass. No save file touched by build or tests.
- Published: [GitHub release 0.4.37-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.37-alpha) (source commit `1c3c9a41a19a918b7424d1fabb3642f13cdd80b9`; 165,993-byte ZIP, 20 entries, no saves/caches, SHA-256 `A608975ECF944738469604041E9E171D7DEFE44DD39C1C753077CE8B0769E233`, matches GitHub). No local install was run.
- In-game result: Not yet tested. **Expected, unverified:** `fs_fopen` accepts the `_backup.sav` name; `fs_readline` lines copy back identically; the backup appears next to the slot file after a second Save in the same slot.
- Remaining risk/next step: owner to Save twice in one slot on any map and check `scriptdata` for the `_backup.sav` file.

## 0.4.36-alpha — 2026-11-01

### 2026-11-01 — Pack-a-Punched starting weapons (Claude Code)

- Request: owner said "go" on the proposed next item, a Pack-a-Punched random starting weapon, without adding another lobby row.
- Change or investigation: STARTING WEAPONS gained two choices, **1 PACKED WEAPON** and **2 PACKED WEAPONS** (dvar `zmcp_start_weapons` values 3 and 4). `zmcp_starting_loadout` maps 3/4 to 1/2 random weapons plus a `packed` flag; `zmcp_give_starting_loadout` upgrades each pick with the stock `can_upgrade_weapon` / `get_upgrade_weapon` (so default attachments follow the stock rules) and gives it with `weapon_give( pick, 1, 0, 1 )`. A weapon with no upgrade on the map, or whose upgrade the player already has, is given unpacked. Two weapons still replace the starting pistol. Lobby clamp maximum is now 4. The lobby stays at 13 rows and the labels are the same length as the longest existing one.
- Files affected: `src/scripts/zm/zm_checkpoint_slots.gsc`, `src/ui/ui/t6/menus/privateonlinegamelobby.lua`, `zmcheckpointloadout.lua`, `tools/Test-Loadout.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses; nine Lua suites pass (loadout test extended to five labels and clamp 4). Stock `get_upgrade_weapon`, `can_upgrade_weapon` and `weapon_give` were read from the Core source in `.cache`.
- Published: [GitHub release 0.4.36-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.36-alpha) (source commit `250895adb039ae0c48a17fb9667ab4179516ec38`; 163,097-byte ZIP, 20 entries, no saves/caches, SHA-256 `37C9849665FAF8059152DDF905AA826215CEFEBDBD5AF9E751AF819DD70E8E35`, matches GitHub). No local install was run.
- In-game result: **Verified in-game (owner, 2026-11-01): "it worked"** for the packed starting weapons. Original expectations: the upgraded weapon appears with its Pack-a-Punch camo and full ammo; the `+attachment` suffix for weapons with a default attachment gives a valid weapon; the label fits the selector.
- Remaining risk/next step: owner to start a match with 1 and 2 PACKED WEAPONS on a map and report the weapons received and any error text in the log.

## 0.4.35-alpha — 2026-11-01

### 2026-11-01 — Stop the lobby hint overlapping ESC Back (Claude Code)

- Request: with the new rows the focused-row description under the last option wraps to three lines and overlaps the ESC Back prompt (owner screenshot, OPENING focused, 0.4.34).
- Change or investigation: the stock lobby draws the focused row's hint just below the last row, about 40 characters per line, and the gap above the bottom prompts fits two lines. The 0.4.33 hints for STARTING WEAPONS, STARTING PERK, STARTING POINTS and OPENING were 70 to 90 characters (three lines). All five added hints are now at most about 55 characters so they wrap to two lines at most: "Allow every perk at once (normally four).", "New match: random map weapons. Two replace the M1911.", "New match: one random perk from this map.", "New match: start with this many points.", "New match: power on and/or all doors and debris open." This keeps the single-column layout and the stock row spacing; rearranging or removing rows was judged riskier without a way to test the stock layout, and the lobby fits (owner: crowded but okay).
- Files affected: `src/ui/ui/t6/menus/privateonlinegamelobby.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; nine Lua suites pass (no test asserts hint text). Fit is **expected, not verified in-game**.
- Published: [GitHub release 0.4.35-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.35-alpha) (source commit `143ac22f9b37fe7fa97f4bbfc244b278883fd925`; 162,167-byte ZIP, 20 entries, no saves/caches, SHA-256 `0326F98470C74CE464EED6DE444A66E12F1E183328C019F4709D415BAAB6379C`, matches GitHub). No local install was run.
- In-game result: Not yet tested.
- Remaining risk/next step: owner to focus each added row and check the text clears ESC Back. If it still collides, the next options are shortening further or moving the ESC prompt/hint area; adding more rows later will need a different layout.

## 0.4.34-alpha — 2026-11-01

### 2026-11-01 — Fix debris not clearing with OPENING (Claude Code)

- Request: owner's 0.4.33 test on Nuketown (screenshot, POWER + DOORS, 500 points): doors opened but debris stayed ("Hold F to clear Debris (Cost: 1250)"); make sure it is removed on all maps.
- Change or investigation: **Root cause (from the stock source in `.cache`):** the stock door handler returns early for a forced trigger, but `debris_think` (and Nuketown's own `custom_debris_function` in `zm_nuked.gsc`) still tests `who.score >= cost` after a forced trigger and denies the purchase when the player cannot afford it (500 points against 1250). All six maps use the shared `_zm_blockers.gsc` debris handler; only Nuketown adds a custom one, and both honour the same free-purchase dvar that the stock `open_sesame` debug command sets (`zombie_unlock_all`). **Fix:** `zmcp_open_all_doors` now raises `zombie_unlock_all` to 1 while it sends the triggers and restores the previous value afterwards (also on `end_game`, via `zmcp_unlock_all_restore`), makes three passes one second apart so triggers that were not listening yet are caught, skips entities deleted meanwhile, and POWER + DOORS waits one second after setting the power so power-gated doors and Nuketown's electric debris are listening before they are triggered. Static review of the other maps found no extra blockers: Transit's local/electric doors carry `power_door_ignore_flag_wait` (already notified), Buried and Die Rise notify `electric_door` from their own power scripts, Origins and Mob of the Dead use the shared handlers. **Known limitation:** DOORS OPEN without POWER leaves doors that are power-gated by the map shut (use POWER + DOORS); `zombie_airlock_buy` triggers have no handler in this game version and are not used.
- Files affected: `src/scripts/zm/zm_checkpoint_slots.gsc`, `mod.json`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses; nine Lua suites pass. The 0.4.33 lobby screenshot **verified in-game** that the new rows STARTING POINTS and OPENING appear and fit (owner: "crowded but okay") and that doors open with POWER + DOORS. Debris removal after this fix is **expected, not verified in-game**.
- Published: [GitHub release 0.4.34-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.34-alpha) (source commit `75b245cd6c0568f1bf18bf9f821aaddb0c58b0b4`; 162,203-byte ZIP, 20 entries, no saves/caches, SHA-256 `82C05CD64B9E1F7D62CD902F5791F5A97C38CDD22EA22A0BFC80ADED6B22A593`, matches GitHub). No local install was run.
- In-game result: 0.4.33: doors opened, debris did not (the bug above). 0.4.34: not yet tested.
- Remaining risk/next step: owner to test POWER + DOORS at default points on Nuketown and one more map (Transit or Origins); report any door or debris that stays.

## 0.4.33-alpha — 2026-11-01

### 2026-11-01 — Starting points and opening (power/doors) rows (Claude Code)

- Request: after the owner asked for feature ideas, go ahead with custom starting points and power/doors at start (items 1 and 3 of the suggested list).
- Change or investigation: two new Custom Games rows after STARTING PERK. **STARTING POINTS** (dvar `zmcp_start_points`; DEFAULT, 5,000, 10,000, 25,000, 50,000, 100,000, 250,000, 500,000, 1,000,000) sets `level.player_starting_points` inside the existing `init_levelvars` detour (`zmcp_apply_custom_start_round`, now also installs the detour when only points are set; the round parse moved to `zmcp_custom_round_value`). Points win over the round-based 500 per round. **OPENING** (dvar `zmcp_start_world`; NORMAL, POWER ON, DOORS OPEN, POWER + DOORS = bit values 0 to 3) runs `zmcp_starting_world` one second after `initial_blackscreen_passed`: `flag_set( "power_on" )` and `zmcp_open_all_doors`, which notifies every `zombie_door` and `zombie_debris` trigger with the stock force flag (the same calls the stock `open_sesame` debug command makes, copied from the Core `_zm_devgui.gsc`/`_zm_blockers.gsc` sources in `.cache`). Both apply to fresh matches only (not resumed checkpoints). **Design choice:** points are a fixed list, not typed, because a typed hook on an appended row would depend on unknown stock behavior for out-of-list dvar values; typed entry is a possible follow-up. The two rows were merged into one OPENING row to keep the lobby list short. `zmcheckpointloadout.lua` clamps stored values (unknown points reset to DEFAULT).
- Files affected: `src/scripts/zm/zm_checkpoint_slots.gsc`, `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`, `src/ui/ui/t6/menus/privateonlinegamelobby.lua`, `zmcheckpointloadout.lua`, `tools/Test-Loadout.lua`, `tools/Test-LobbyOption.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses (new functions present in all six outputs); all nine Lua suites pass (loadout/lobby tests extended for the two rows and clamping). No save, game file or local install touched.
- Published: [GitHub release 0.4.33-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.33-alpha) (source commit `c2a7c73e82c6a0a32a118a0e91404c4ea96d09ff`; 160,393-byte ZIP, 20 entries, no saves/caches, SHA-256 `5335F39AA965A8154C78D006C5E7F882388B9E55BDCB14A23FC0AF0F2466682E`, matches GitHub). The installed updater returned `UPDATE_AVAILABLE|0.4.32-alpha|0.4.33-alpha`, so the owner is on 0.4.32. No local install was run.
- In-game result: Not yet tested. **Expected, unverified:** the lobby list now has 8 rows (vertical fit of the lobby unknown); power on by flag only (the Transit switch animation and lights may not play, as with the stock debug command); doors needing a map-specific flag may stay shut; opening many doors at once could briefly stress a map such as Origins or Buried.
- Remaining risk/next step: owner to check the new rows' labels and fit, then start a match with each combination (round 50 + 100,000 points; POWER + DOORS on Nuketown and Transit). Report anything that stays closed so the notify list can be extended.

## 0.4.32-alpha — 2026-11-01

### 2026-11-01 — Fix missing weapon icons in SOLO RESUME (Claude Code)

- Request: some weapon icons do not show in the SOLO RESUME preview. The owner's screenshot (slot 4) shows SAIGA12 with its picture but FNFAL as text only; the owner reports other missing ones too.
- Change or investigation: the preview looks a weapon up in a table of stock front-end materials by base name, but several table keys were not the game's real weapon names (the table has `fal`, the game saves `fnfal_zm`). The 31 stock weapon materials are the ones recorded from `ui_zm.ff` in `.cache/oat-ui-zm`. Added aliases from the real names to those materials: `fnfal`, `mp5k`, `beretta93r`, `dsr50`, `barretm82`, `usrpg`, `m32`, `qcw05`, `fivesevendw`, `m16_gl`, `ak74u_extclip`, `beretta93r_extclip`. The lookup moved into `weaponBase`/`weaponMaterial` (also strips `+attachments`, exported as `C.Ui.WeaponMaterial`). **Known limitation:** weapons with no stock front-end material still show text only: M27 (`hk416`), LSAT, SVU-AS, AN-94, PDW-57, Thompson, UZI, AK-47, MG08/15, STG-44, SCAR-H, KSG, MP40, Skorpion EVO, Ballista, Mauser C96, Blundergat, REMINGTON NMA and the Ray Gun Mark II (deliberately not aliased to the Ray Gun art). Only `ui_zm.ff` is present in the local game's `zonell`, so adding those pictures would need extracting images from other fastfiles with OpenAssetTools into `mod.ff`.
- Files affected: `src/ui/ui/t6/menus/zmcheckpointsolo.lua`, new `tools/Test-WeaponIcons.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses; luaparse; all nine Lua suites pass (new `Test-WeaponIcons.lua` checks the real game weapon names, upgraded and attachment forms, and that no-icon weapons return nil). The pictures themselves are **expected, not verified in-game**: the materials were already confirmed loadable in 0.4.20 (the SAIGA12 icon renders).
- In-game result: Not yet tested.
- Published: [GitHub release 0.4.32-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.32-alpha) (source commit `e38cbc422659c2fdf9f63889cfd339abfff9cb61`; 156,633-byte ZIP, 20 entries, no saves/caches, SHA-256 `F3D1DADE2362BF43BAEE84BA8FFD06A1286DCBE361080AA459F016655FAEE834`, matches GitHub). The installed updater returned `UPDATE_AVAILABLE|0.4.31-alpha|0.4.32-alpha`, so the owner is on 0.4.31. No local install was run.
- Remaining risk/next step: after updating and reloading the mod, SOLO RESUME slot 4 should show a FAL picture. If the owner wants pictures for the remaining weapons, extract them from other fastfiles (needs the right source zone) as a follow-up.

## 0.4.31-alpha — 2026-11-01

### 2026-11-01 — Fix the 40-second wait for the update companion (Claude Code)

- Request: after pressing install the owner waited 42 to 43 s ("Waiting for the update companion... 30s" on screen) before the download started and asked whether that is normal.
- Change or investigation: **Verified from the new timing log (`%TEMP%\zmcp_update_timing.log`, owner's 0.4.29 session):** the install worker took about 2.6 s from `install marker seen` (14:16:10.164) to `install finished` (14:16:12.787), and the check worker about 0.7 s, so all the waiting is the request marker reaching the watcher (check marker seen 14:15:13, install marker seen 14:16:10, nothing in between). **Verified by sampling `console_zm.log` while the game ran:** the game writes it in blocks of about 4.1 KB (four consecutive growths of 4,191, 4,179, 4,149 and 4,186 bytes, then one large dump) and nothing in between, so a roughly 50-byte marker waits in the game's buffer until about 4 KB of other console output arrives. **Fix:** `zmcheckpointupdater.lua` adds `C.FlushConsoleLog`, which sends six commands of 20 identical long unknown-command lines (about 7.8 KB of command text) right after the check marker and right after the install marker, so the block containing the marker is written immediately. The padding contains no `zmcp_update_` text, so it can never be mistaken for a marker. `tools/Test-UpdaterRequestId.lua` now finds the marker among the commands and asserts at least 6 KB of padding follows it.
- Files affected: `src/ui/ui/t6/menus/zmcheckpointupdater.lua`, `tools/Test-UpdaterRequestId.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses; luaparse; all eight Lua suites pass. The padding's effect on the real log is **expected, not verified in-game**: it assumes each unknown command prints at least its own text to the log (the request marker itself is detected that way).
- In-game result: Not yet tested. The page code comes from the installed IWD, so the first update to 0.4.31 still uses the old 0.4.30 page and may wait as before; the next update after it should show the difference.
- Published: [GitHub release 0.4.31-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.31-alpha) (source commit `6be689b699b9bdabcc68edcb7da12005a8317b08`; 156,201-byte ZIP, 20 entries, no saves/caches, SHA-256 `596F1CA46B03747FA71B2006B662B43DC000683BC0447E9E79E5603E2AEFF07D`, matches GitHub). The installed updater returned `UPDATE_AVAILABLE|0.4.30-alpha|0.4.31-alpha`. No local install was run.
- Remaining risk/next step: after installing 0.4.31 and unloading/reloading the mod, open the updater again. The marker lines in `zmcp_update_timing.log` should follow the click within about a second. If the wait persists, check the log growth again (the padding should cause an immediate growth of 4 KB or more).

## 0.4.30-alpha — 2026-11-01

### 2026-11-01 — Random starting weapons and a single random perk (Claude Code)

- Request: no weapon list to pick from; the owner wants STARTING WEAPONS to mean 1 or 2 weapons chosen at random by the game, and the perk option to offer only 1 random perk.
- Change or investigation: the lobby rows STARTING WEAPON 1 and STARTING WEAPON 2 are replaced by one row, **STARTING WEAPONS** (NONE, 1 RANDOM WEAPON, 2 RANDOM WEAPONS; dvar `zmcp_start_weapons`), and **STARTING PERKS** becomes **STARTING PERK** (NONE, 1 RANDOM PERK; dvar `zmcp_start_perks`, now 0 to 1). The per-map weapon lists moved from the Lua file into GSC (`zmcp_loadout_pool` in `zm_checkpoint_slots.gsc`, same curated lists as 0.4.28), where each entry is checked with `is_weapon_included` after the map has loaded. Each player rolls their own random weapons from that pool (distinct picks, skipping weapons they already hold); with two, the starting pistol is taken first; perks still use the map's perk machines. `zmcheckpointloadout.lua` now only clamps stored values when the lobby opens, so a previously stored 2 to 4 random perks becomes 1 and an oversized weapon count becomes 2. The old `zmcp_start_weapon1/2` dvars are no longer read.
- Files affected: `src/ui/ui/t6/menus/zmcheckpointloadout.lua`, `privateonlinegamelobby.lua`, `src/scripts/zm/zm_checkpoint_slots.gsc`, `tools/Test-Loadout.lua`, `tools/Test-LobbyOption.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses (the old per-weapon validator is gone and the pool function appears in the generated scripts); luaparse; all eight Lua suites pass, with `Test-Loadout.lua` rewritten for the two new rows and clamping. GSC parsed only. No save, game file or local install touched.
- In-game result: Not yet tested. Still unverified from 0.4.28: the first-spawn grants on each map and the new random pool behavior (including that `switch` and array building in the pool function behave in the game's GSC runtime).
- Published: [GitHub release 0.4.30-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.30-alpha) (source commit `06049c99369859def0ce26d71a838cdcf0b71a14`; 155,787-byte ZIP, 20 entries, no saves/caches, SHA-256 `0F246734F26FA50120E3379EDC843A49B7E9441CC51EC92FE39C71FDAB8A0D80`, matches GitHub). The installed updater returned `UPDATE_AVAILABLE|0.4.29-alpha|0.4.30-alpha`, so the owner is on 0.4.29. No local install was run.
- Remaining risk/next step: start Survival matches with 1 and with 2 random weapons and with the random perk, on Nuketown and one other map, and report the console line `ZMCP: starting loadout`.

## 0.4.29-alpha — 2026-11-01

### 2026-11-01 — Faster updater and timing diagnostics (Claude Code)

- Request: the owner reports the in-game updater takes very long to check, download and install, even though the package is small, and wondered if the new release-notes panel caused it.
- Change or investigation: **Measured on this PC (Validated statically/by script, outside the game):** a full check in a fresh worker is about 1.1 s; the watcher-to-result path for a check marker is about 2.4 s; a bare `powershell.exe` start is 0.28 s; the GitHub release query (10 releases, 64 KB JSON) 0.6 s; `Invoke-WebRequest` of the 102 KB package took 0.99 s with PowerShell's progress bar and 0.18 s without; `Expand-Archive` 0.75 s versus 0.065 s with `ZipFile.ExtractToDirectory`; hash 0.08 s. The release-notes panel is not the cause of the PC-side time. **Changes:** `Update-ZMCheckpoint.ps1` sets `$ProgressPreference = 'SilentlyContinue'`, requests 3 releases instead of 10, caches the release for 5 minutes so the install right after a check (`-UseCachedRelease`, passed by the window script) skips a second GitHub call, extracts with .NET `ZipFile`, and appends timestamped steps to `%TEMP%\zmcp_update_timing.log`; `Watch-ZMCheckpointUpdates.ps1` polls every 100 ms instead of 500 ms with a cheap `FileInfo` length check and logs when it sees each marker; `Update-ZMCheckpoint-Status.ps1` writes only the used release-note lines instead of 64 (the game executes and logs every line on each poll); `zmcheckpointupdater.lua` polls every 1 s (was 1.5 s), shows the seconds waited for the companion, and keeps the 45 s still-working message threshold. A scratch-root test installed the real 0.4.28 package in 0.85 s (check 0.73 s) with a preserved dummy `.sav`. **Suspected remaining cause (not confirmed):** the game appears to buffer `console_zm.log`; the log was seen ending mid-line while the game was running and idle for minutes, so a request marker may reach the watcher late. That cannot be measured without the game; the new timing log and the on-screen seconds counter are meant to show it.
- Files affected: `tools/Update-ZMCheckpoint.ps1`, `tools/Update-ZMCheckpoint-Window.ps1`, `tools/Update-ZMCheckpoint-Status.ps1`, `tools/Watch-ZMCheckpointUpdates.ps1`, `src/ui/ui/t6/menus/zmcheckpointupdater.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: four PowerShell scripts parse; Build.ps1 passed; six T6 GSC parses; luaparse; all eight Lua suites pass; scratch-root check and install run with timings. No game, no save and no local install touched.
- In-game result: Not yet tested. The new scripts run only after the owner has installed 0.4.29 (the updater uses its installed copy), so the first update to 0.4.29 is still on the old path.
- Published: [GitHub release 0.4.29-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.29-alpha) (source commit `568e51cec2bc92f03e67d11d9e035ce23bbef004`; 153,216-byte ZIP, 20 entries, no saves/caches, SHA-256 `B7B851D1783F41D6DB5E2F69C696761DD432800EEF92B902A9D251DE85231E20`, matches GitHub). The installed updater returned `UPDATE_AVAILABLE|0.4.28-alpha|0.4.29-alpha`. No local install was run.
- Remaining risk/next step: after updating to 0.4.29, the next update check should be much faster on the PC side. If the page still waits long, send the seconds shown on the page and `%TEMP%\zmcp_update_timing.log`; a gap between clicking and `check marker seen` means game-side log buffering, and a different request channel (for example a file written by a console command) would be the next step.

## 0.4.28-alpha — 2026-11-01

### 2026-11-01 — Standing instruction: always publish

- Request: owner asked that finished versions always be published without asking, unless told not to. Recorded in `AGENTS.md` (Publishing updates). Local installation still requires an explicit request. Files affected: `AGENTS.md`, `CHANGELOG.md`. No code change.

### 2026-11-01 — Starting weapons and random starting perks (Claude Code)

- Request: add Custom Games options to start with 1 or 2 weapons (any weapon found on the map or in the box) and with random perks.
- Change or investigation: new `zmcheckpointloadout.lua` holds per-map weapon lists taken from each stock map's `include_weapon` calls (base versions only; upgraded, melee, grenades, equipment, buildable and quest weapons such as the Thrustodyne, Sliquifier, Paralyzer and staffs are excluded) with short display names. `privateonlinegamelobby.lua` appends three rows after UNLIMITED PERKS through the existing `CoD.PrivateGameLobby.Dvars` mechanism: `zmcp_start_weapon1`, `zmcp_start_weapon2` (string values such as `python_zm`, default `none`) and `zmcp_start_perks` (0 to 4). Each time the lobby is created the weapon rows are rebuilt for the shown map, and a stored choice that is not on that map (or an invalid perk count) is reset so the row and dvar agree. GSC (`zm_checkpoint_slots.gsc`, started from `init()` only when no solo or co-op resume is loading) waits for `initial_blackscreen_passed`, re-validates each weapon (token, `_zm` suffix, not upgraded, `is_weapon_included`), and for every player gives them with the stock `weapon_give`; with two weapons the starting pistol is taken first so both fit. Perks come from this map's `zombie_vending` triggers (the pool the stock random-perk reward uses, excluding Pack-a-Punch and perks already owned) and are granted with `give_perk( perk, 0 )`. Failures are logged and skipped, never fatal.
- Files affected: new `src/ui/ui/t6/menus/zmcheckpointloadout.lua`, `privateonlinegamelobby.lua`, `zmcheckpointmenu.lua`, `src/scripts/zm/zm_checkpoint_slots.gsc`, `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`, new `tools/Test-Loadout.lua`, `tools/Test-LobbyOption.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses; luaparse on the three Lua files; all eight Lua suites pass (new `Test-Loadout.lua`: rows appended once in order, per-map lists, uniqueness, exclusions, stale-choice and perk-count resets); the IWD contains the new Lua file. GSC is parsed only. Eight save hashes: seven matched the earlier baseline and solo `zm_nuked` slot 3 differed (owner's own play, no agent write). Nothing installed.
- In-game result: Not yet tested. **Unverified:** that the stock lobby builds the selector rows from string values and per-map rebuilt label lists; whether changing the map with the lobby open refreshes the weapon rows (GSC validation protects either way); that `weapon_give` and `give_perk` behave at the first spawn on every map (Nuketown's late-moving perk machines, Origins' differing weapon registration); whether the longest weapon names fit the value column; the lists were derived from the reconstructed stock scripts, so a weapon missing from a real map is skipped at runtime.
- Remaining risk/next step: after the owner updates, check the three new rows, start a Survival match with one and with two weapons, and with 1 to 4 random perks, on at least Nuketown and one more map, and report the HUD, weapons and the `ZMCP: starting loadout` console line. Published: [GitHub release 0.4.28-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.28-alpha) (source commit `d1aa90626c97f88b29efa3845c2f192adb2d6946`; 151,981-byte ZIP, 20 entries, no saves/caches, SHA-256 `1785B9A0979F59AA757451905594DF195FB96CBDF5D5DF35696EE984D85ABD5C`, matches GitHub). The installed updater returned `UPDATE_AVAILABLE|0.4.27-alpha|0.4.28-alpha`, so the owner is on 0.4.27 via the updater. No local install was run by the agent.

## 0.4.27-alpha — 2026-11-01

### 2026-11-01 — Owner confirms CUSTOM STARTING ROUND in-game

- **Verified in-game (owner screenshot and report, 2026-11-01):** in the Nuketown Survival lobby the row reads **CUSTOM STARTING ROUND** with value 110 and fits its column; the owner reports it "worked perfectly". This confirms the selector hook matched, the label fits and a typed or stepped value displays. Not itemized: wheel versus keyboard entry, the match actually starting at the chosen round, and starting points/HUD. Files affected: `CHANGELOG.md`, `PROJECT_HANDOFF.md` only.

### 2026-11-01 — CUSTOM STARTING ROUND (Claude Code)

- Request: replace the stock STARTING ROUND choices with any round number (click and type, or mouse wheel), renamed "Custom Starting Round", without crashing the game. The owner's screenshot shows the Nuketown Survival lobby with the stock row (value 1) between DIFFICULTY and MAGIC.
- Change or investigation: the stock lobby builder is not in the local reference copies, so the row is patched where it is created: `privateonlinegamelobby.lua` wraps `CoD.LeftRightSelector.new` once and, for a selector labelled STARTING ROUND (localized or raw `ZMUI_STARTING_ROUND_CAPS`), builds it as **CUSTOM STARTING ROUND** and replaces its behavior: left/right and the mouse wheel (`mwheel` button events, same pattern as the stock server list) step by one; click or Enter opens the stock on-screen keyboard (`ui_keyboard_new`, answered by `ui_keyboard_input`, same pattern as the stock server-browser filter) and accepts digits only. Values clamp to 1-255 (the engine's own round limit); invalid text is ignored. The number lives in archived dvar `zmcp_start_round`, created only when the row was successfully replaced so an unpatched lobby keeps the stock behavior. The stock `startRound` gametype setting is never written, the same situation as a resumed checkpoint, which the round HUD already handles (`startRound < roundsPlayed` branch). GSC `zmcp_apply_custom_start_round` (Survival only, called from `main()` when no solo/co-op resume is loading) validates the dvar and detours `init_levelvars` to set `level.start_round`, `level.round_number` and starting points (`round * 500`, the stock rule). Stock `ai_calculate_health` already stops growth if the health value would overflow. Resume always uses its saved round.
- Files affected: `src/ui/ui/t6/menus/privateonlinegamelobby.lua`, `src/scripts/zm/zm_checkpoint_slots.gsc`, `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`, new `tools/Test-StartRound.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: **Validated statically:** Build.ps1 passed; six T6 GSC parses; luaparse; all seven Lua suites pass, including the new mocked test (relabel, no change from stock choice building, steps, clamps at 1 and 255, wheel only while focused, keyboard command text, typed/invalid/overlong input, stored values). GSC parsed only. Seven of eight save hashes matched the earlier baseline; the solo `zm_nuked` slot 1 file changed again during the owner's own play (no agent write). Nothing installed.
- In-game result: Not yet tested. **Unverified assumptions:** the stock row's selector is built through `CoD.LeftRightSelector.new` with a label matching the check; the mouse wheel event reaches the focused row; `CoD.KEYBOARD_TYPE_TEXT_MESSAGE` exists in the lobby; the label fits its column; very high rounds (above roughly 100) may be slow or unstable because of the engine, not this mod. If the row still reads STARTING ROUND, the hook did not match and the stock row is unchanged and harmless.
- Published: source commit `562a0656348f7d9a7ff0f9bc02fcc4f1df70d690` was pushed before [GitHub release 0.4.27-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.27-alpha) (created after the owner approved it); the 144,071-byte ZIP (20 entries, no saves/caches) has SHA-256 `84A9BBFAB4C981F7202A24EBC5C71C22FEEA33E7AE64229428C383FADB5DFA54`, matching GitHub. The installed updater returned `UPDATE_AVAILABLE|0.4.26-alpha|0.4.27-alpha`, so the owner has since updated to 0.4.26 through it. No local install was run by the agent.
- Remaining risk/next step: owner updates via the updater, unloads/reloads the mod, opens a Survival lobby, tries arrows, wheel and click-to-type, then starts a match and checks the round, points and HUD.

## 0.4.26-alpha — 2026-11-01

### 2026-11-01 — CO-OP RESUME redesigned like SOLO RESUME (Claude Code)

- Request: CO-OP RESUME should list the host's co-op sessions even when the other players are absent (greyed, not startable), show players with points, weapons and perks plus saved settings, and offer select-first, OPTIONS, START and DEL; several sessions per map; existing co-op files must keep working.
- Change or investigation: **Sessions:** up to four per map. Session 1 keeps the original files `zm_checkpoint_coop_<map>_a/_b/_used.sav` (no rename, no copy, no format change, so the owner's existing files need no migration); sessions 2 to 4 use `zm_checkpoint_coop_<map>_sN_a/_b/_used.sav`. A resumed session saves back into its own slot; a fresh match uses the first slot with no usable files, then the first consumed one, and refuses (never overwrites) when all four hold live saves. New generation = `max(latest file, receipt) + 1`; a damaged receipt blocks the save. GSC publishes `zmcp_coop_<map>_sN_*` (summary, `count`, and per player `mK_pts`, `mK_w`, `mK_p` as bounded comma lists of display tokens) and still mirrors session 1 to the old dvar names for older UI packages. Player names are remembered in `zmcp_coop_name_<id>` at save time (sanitized to `A-Za-z0-9_-`, 16 chars) so offline players show a name. `zmcp_coop_slot` (set by START) selects the session; an invalid slot fails closed. **Page:** session rows (dimmed while the exact host and team are not present, but still selectable so details can be read), OPTIONS and START greyed until a session is selected, START enabled only when the exact-roster/original-host/context gate passes, details panel per player, saved-settings panel, DEL with the existing confirmation popup. START now applies the saved (or overridden) difficulty, Magic and Headshots Only with read-back, so RESTORE SAVED SETTINGS was removed and a settings difference no longer blocks the gate (the server still compares the effective settings). **OPTIONS:** difficulty, Magic, Headshots Only, target assist, cheats, unlimited perks as `zmcp_ovr_coop_<map>_sN_*` dvars; GSC applies only difficulty/Magic/Headshots to the in-memory checkpoint; assist, cheats and unlimited perks are applied by the lobby at START (co-op files do not store assist or cheats). Overrides clear on save-over, consumption and delete. **DEL:** tombstone `zmcp_del_coop_<map>_sN` hides the session now; on the next load of that map GSC overwrites only that session's `_a` and `_b` with `EMPTY` (receipt untouched) and clears the tombstone, keeping it if a write fails. **Also fixed:** the `UNKNOWN` second weapon: `zmcp_display_token` drops `+attachments` before publishing, for solo and co-op previews.
- Files affected: `src/scripts/zm/zm_checkpoint_coop.gsc`, `src/scripts/zm/zm_checkpoint_slots.gsc`, `src/ui/ui/t6/menus/zmcheckpointcoop.lua`, `zmcheckpointsolo.lua` (exports `C.Ui`), `tools/Test-CoopLobby.lua`, new `tools/Test-CoopResume.lua`, `mod.json`, `README.md`, `COOP_TEST_PLAN.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`. The main shared GSC is unchanged.
- Validation: **Validated statically:** Build.ps1 passed; all six generated T6 GSC files parsed; both modified Lua files passed luaparse; all six Lua suites pass (the 25 co-op lobby cases were adapted to the `_s1_` dvars, and "changed settings" is now expected to be startable because START applies them; the new `Test-CoopResume.lua` covers rows and greying, details text, offline names, select/START gate, wrong host, replacement player, wrong mod, invalid settings, second session slot, OPTIONS, DEL and the empty-host message). GSC is parsed only, never executed. All eight installed save hashes were identical before and after the build; nothing was installed.
- In-game result: Not yet tested; every co-op item is also still unverified on two PCs. Expected only: the dimmed look, row fit with four players, and that a disabled-looking row still takes focus.
- Published: source commit `a171facb5a342093c1db04e3941cf85a5c428f8f` was pushed before [GitHub release 0.4.26-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.26-alpha); the 140,423-byte ZIP (20 entries, no saves/caches) has SHA-256 `0A6816C1EC69756D47A1944F06CE0D7A080D886D8F0739ECB4D0D7CFCEB795B3`, matching GitHub. The installed 0.4.25 updater returned `UPDATE_AVAILABLE|0.4.25-alpha|0.4.26-alpha`. All three co-op files and the other slot files kept their hashes through build and packaging; the solo `zm_nuked` slot 1 file changed from a 635-byte round-11 checkpoint to the 9-byte consumed marker (same hash as the empty Buried file) during the owner's own play, not from any agent action. No local install was run.
- Remaining risk/next step: owner updates through the updater and unloads/reloads the mod, then follows the new checks at the end of `COOP_TEST_PLAN.md`. Currently all existing co-op generations are consumed, so a new two-player Save & Exit is needed before any session appears.

### 2026-11-01 — CO-OP RESUME redesign: read-only investigation and plan (Claude Code)

- Request: redesign CO-OP RESUME to match SOLO RESUME (host-visible greyed sessions with per-player points/weapons/perks and settings; select-first flow, OPTIONS, START, DEL); state the plan first, especially several sessions per map and migration of existing co-op files.
- Change or investigation: read AGENTS.md, PROJECT_HANDOFF.md (sections 1 to 18, 31 to 36), CHANGELOG.md head, COOP_TEST_PLAN.md, `zm_checkpoint_coop.gsc`, `zm_checkpoint_slots.gsc`, `zmcheckpointcoop.lua`, `zmcheckpointsolo.lua`, `zmcheckpointmenu.lua`, `Test-CoopLobby.lua` and the `main()` flow of the shared GSC. Inspected the installed mod and all eight save files read-only. **Installed state (read-only):** `mods/zm_checkpoint/mod.json` reports 0.4.25-alpha. Co-op files for `zm_nuked`: `_a` is generation 3 (round 4, 2 players, settings 1/1/0), `_b` is generation 2 (round 2), and `_used.sav` is `USED,3`, so **every existing co-op generation is already consumed and no co-op session is currently offered**. Nothing was modified. **Found (validated statically):** the `UNKNOWN` second weapon in the solo preview is caused by `zmcp_coop_token` rejecting `+`: weapon names with attachments such as `galil_upgraded_zm+reflex` (present in the owner's slot 1) are published as `unknown`. Also found: generation numbering uses only the latest valid file, so deleting both files while a `USED,n` receipt remained would make a new save look already used; the redesign must number from `max(latest, receipt) + 1`.
- Files affected: `CHANGELOG.md`, `PROJECT_HANDOFF.md` (section 36) only. No code, build, install, publish or save change.
- Validation: documentation only. Eight checkpoint hashes recorded at start (co-op `a` 42AFE4CF..., `b` A2205C7E..., `used` 28EC24CB...) were only read.
- In-game result: n/a (investigation).
- Remaining risk/next step: plan presented to the owner for approval; implementation as 0.4.26-alpha after approval.

### 2026-11-01 — Plan the CO-OP RESUME redesign and record 0.4.25 evidence

- Request: prepare the best prompt for a new chat to make CO-OP RESUME like SOLO RESUME (host-visible, greyed-out sessions with per-player points, weapons and perks, plus select, OPTIONS, START and delete).
- Change or investigation: read-only review of `zmcp_coop_publish` and the co-op save format. **Verified in-game (owner screenshots):** 0.4.25 SOLO RESUME shows greyed OPTIONS/START until selection, updated hint text, the `UNLIMITED PERKS ON` settings line after an OPTIONS change, and the DEL prompt; the non-host co-op page shows its "No team checkpoint on this PC" message with a disabled resume row. A second weapon showed `UNKNOWN` in the preview (cosmetic, to investigate). Found that co-op currently stores one session per map and publishes only summary dvars, so the redesign needs multiple sessions per map and a bounded per-player publish. Full notes and the ready-to-paste prompt are in `PROJECT_HANDOFF.md` section 36.
- Files affected: `CHANGELOG.md`, `PROJECT_HANDOFF.md` only.
- Validation: documentation only; no build, install, publish or save change.
- In-game result: n/a for the plan; observations above are from the owner's screenshots.
- Remaining risk/next step: start the new chat with the section 36 prompt. Nothing in the co-op code has changed.

### 2026-11-01 — Claude Code session log: setup, tooling and workflow

- Request: join the project alongside ChatGPT, read all project memory, install REA, then build the features recorded in 0.4.22 to 0.4.25, and keep everything logged for continuation in any new chat.
- Change or investigation: read AGENTS.md, PROJECT_HANDOFF.md, CHANGELOG.md and README.md in full. **REA (`morluto/rea`):** `rea-agents` 6.7.0 was already installed globally from a local clone at `Documents\Projects\noise cancelation\rea` (6.8.0 exists, not updated). At the owner's request, `rea setup --client claude_code --yes` registered its MCP server with Claude Code (edits `~/.claude.json`, backup `~/.claude.json.rea.backup`, refreshed the REA skill). `rea doctor` still reports no analysis engine (Hopper, Ghidra, IDA, Jadx, Kuna), so native analysis of `t6zm.exe` remains unavailable. Nothing in the project tree changed for this. Feature work this session is in the 0.4.22, 0.4.23, 0.4.24 and 0.4.25 entries; each release was built, pushed to `main`, published as a GitHub prerelease with its ZIP, and never installed locally, per the owner's standing rule.
- Files affected: this entry and `PROJECT_HANDOFF.md` section 35 only.
- Validation: documentation only. The eight checkpoint file hashes were checked before and after every package; the TranZit slot changed once during the owner's own gameplay (recorded in 0.4.23).
- In-game result: see each version entry. Verified in-game by the owner this session: 0.4.22 UNLIMITED PERKS, 0.4.23 DEL prompt and delete, 0.4.24 OPTIONS row visible.
- Remaining risk/next step: test 0.4.25 (select, OPTIONS, START) and the 0.4.24 OPTIONS page effects. See section 35 of the handoff for tooling lessons.

## 0.4.25-alpha — 2026-11-01

### 2026-11-01 — Select a save first, then OPTIONS or START

- Request: make OPTIONS act on an explicitly selected save (greyed out until one is chosen, so it is clear which save is being edited), and add a START button that launches the selected save.
- Change or investigation: **Verified in-game (owner screenshot, 2026-11-01):** the 0.4.24 SOLO RESUME page shows the OPTIONS row under the four slots with `DEL Delete` bottom right; in that version OPTIONS acted on the last highlighted slot and was never greyed out, which is what the owner objected to. Now clicking a saved slot only selects it (its row gains " - SELECTED", the status line names it, and focus returns to it); it no longer resumes. OPTIONS and START, in that order below the slots, stay greyed out until a slot is selected. OPTIONS opens the options page for the selected slot; START runs the existing `C.Resume` for it (same settings checks, `zmcp_autoload` + `xpartygo` path). The list is rebuilt from a one-shot `UITimer` after the click so no button is destroyed during its own event. DEL still deletes the highlighted slot and is hidden while OPTIONS or START is focused; deleting the selected slot clears the selection. Slot hint text now reads "Select this checkpoint, then use START or OPTIONS."
- Files affected: `src/ui/ui/t6/menus/zmcheckpointsolo.lua`, `tools/Test-SoloDelete.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`. No GSC, save-format or save-file change.
- Validation: modified Lua parsed; Build.ps1 passed; six T6 GSC parses passed; all five Lua suites pass, including updated mocked cases for greyed-out rows, select-then-rebuild with focus returning, START launching the selected slot, OPTIONS targeting it, and ignoring OPTIONS/START with no selection. Nothing installed; no `scriptdata` written.
- In-game result: Not yet tested. Focus restoring to the selected row uses `selectElementIndex` and is expected, not verified.
- Published: source commit `c7c7603b2a18ce64dc353f25df7d69b7cd88fe21` was pushed before [GitHub release 0.4.25-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.25-alpha); the 126,375-byte ZIP (20 entries, no saves/caches) has SHA-256 `B29C84D315672E5DE32C593051BE7EA476364B1B3F813D7C4EFE86E46DCC4A07`, matching GitHub. The installed 0.4.24 updater returned `UPDATE_AVAILABLE|0.4.24-alpha|0.4.25-alpha`; all eight checkpoint hashes were identical before and after packaging. No local install was run.
- Remaining risk/next step: confirm the click selects without resuming, the SELECTED marker fits, OPTIONS/START enable, START launches the match, and DEL/Back still behave. Mouse click versus Enter should both be tried.

## 0.4.24-alpha — 2026-11-01

### 2026-11-01 — Per-save OPTIONS on SOLO RESUME

- Request: add an OPTIONS entry on SOLO RESUME to change each save's stored settings (e.g. turn cheats off, add the new unlimited-perks setting) without breaking save data.
- Change or investigation: **Verified in-game (owner screenshot, 2026-11-01):** 0.4.23 SOLO RESUME shows the bottom-right `DEL Delete` prompt next to `ESC Back` while a saved slot is highlighted, and the owner reports deletion worked. Not itemized: the confirmation popup visuals, restart persistence and the file-erase-on-next-map-load step. The Resume list now ends with an OPTIONS row (disabled when no slot is saved) that opens `ZMCheckpointSoloOptions` for the most recently highlighted saved slot: DIFFICULTY, MAGIC, HEADSHOTS ONLY, TARGET ASSIST, CHEATS and UNLIMITED PERKS selectors (stock dvar selectors on temporary `zmcp_edit_*` dvars) with APPLY CHANGES and CANCEL. The save file is never rewritten: APPLY stores archived override dvars `zmcp_ovr_<map>_slotN_*` (plus `_set`, and a separate `_perks` choice) and updates the published meta dvars the lobby reads. `zmcp_apply_solo_overrides` (shared GSC) applies a complete, valid override to the in-memory checkpoint whenever it is read, so the match-settings check and published values agree; any invalid value ignores the whole override. Overrides are dropped when the slot is saved over, consumed, cleared or deleted (`zmcp_solo_clear_overrides`; deletion also clears them in Lua). Resume applies a per-save UNLIMITED PERKS choice by setting `zmcp_all_perks` before `xpartygo`; saves without a choice leave the lobby row alone. Older saves without a SETTINGS record can change only UNLIMITED PERKS. The saved-settings panel shows an UNLIMITED PERKS line when a choice exists. DEL is hidden while OPTIONS is focused.
- Files affected: `src/ui/ui/t6/menus/zmcheckpointsolo.lua`, `zmcheckpointmenu.lua`, `src/scripts/zm/zm_checkpoint_slots.gsc`, `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`, `tools/Test-SoloDelete.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: modified Lua parsed; Build.ps1 passed; all six generated T6 GSC files parsed and contain the override code. All five Lua suites pass, including new mocked cases: OPTIONS row and event, selector seeding from the slot, apply storing only overrides and published values, save metadata untouched, Resume applying overridden cheats and perks, older-save perks-only page, refusal of invalid values and empty slots, and override removal on delete. GSC override handling is parsed only, not executed. Nothing installed; no `scriptdata` written by this work.
- In-game result: Not yet tested. Selector appearance and row fit are expected only.
- Published: source commit `06446baa3099e37f81952dbdc518bead98dd7c30` was pushed before [GitHub release 0.4.24-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.24-alpha); the 126,059-byte ZIP (20 entries, no saves/caches) has SHA-256 `A2759EAA73800D52C6CF229120C2BB25CDBFC2CBC32602E265DEC97032AB7F4B`, matching GitHub. The installed 0.4.23 updater returned `UPDATE_AVAILABLE|0.4.23-alpha|0.4.24-alpha`; all eight checkpoint hashes were identical before and after packaging. No local install was run.
- Remaining risk/next step: confirm the page layout, that APPLY changes the preview and the resumed match (cheats/difficulty/magic/headshots/assist), that UNLIMITED PERKS carries into the match, and that a new Save & Exit over the slot clears its override. If the settings check rejects Resume, `console_zm.log` will say so and the checkpoint is retained.

## 0.4.23-alpha — 2026-11-01

### 2026-11-01 — Delete saves from SOLO RESUME

- Request: let the player delete a solo save from the Resume page with a bottom-right DEL prompt shown while a save is highlighted, followed by a BO2-style confirmation.
- Change or investigation: **Verified in-game (owner report and screenshot):** 0.4.22 UNLIMITED PERKS worked; the screenshot shows five perks on the HUD. The map and which maps were exercised were not recorded, so only that run counts as verified. The SOLO RESUME page now adds a stock `ButtonPrompt` (`alt1`, label Delete, keyboard shortcut `DEL`) in the bottom-right prompt bar, shown only while a saved slot is highlighted. It opens a small stock popup, DELETE SAVE?, naming the slot and round with "This cannot be undone." NO, KEEP is focused by default; Esc also keeps the save. YES, DELETE rebuilds the slot list in place. The lobby has no GSC, so deletion hides the slot at once by zeroing its archived `zmcp_has/round/preview/settings` dvars and sets an archived tombstone `zmcp_del_<map>_slotN`; the shared GSC (`zmcp_apply_solo_deletes`) overwrites that slot's file with `EMPTY` at the start of the next load of that map, before any checkpoint is read or republished, then clears the tombstone. A failed write leaves the tombstone and the slot stays hidden.
- Files affected: `src/ui/ui/t6/menus/zmcheckpointsolo.lua`, `src/scripts/zm/zm_checkpoint_slots.gsc`, `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`, new `tools/Test-SoloDelete.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: modified Lua parsed; Build.ps1 passed; all six generated T6 GSC files parsed and contain the new function. All five Lua suites pass, including the new mocked test of the DEL prompt, popup, tombstone dvars, list rebuild and popup NO/Esc/YES events. Nothing installed; no `scriptdata` written.
- In-game result: Not yet tested. Layout, the `DEL` key name, and the popup look are expected only. `DEL` relies on the engine reporting that key name to `key_shortcut` events; if the Delete key does nothing, the prompt may still be clickable and the key name needs adjusting.
- Publication: source commit `c05a8eb52c42f1ff1eb532ae9c502f9dad0aee42` was pushed before [GitHub release 0.4.23-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.23-alpha); the 121,250-byte ZIP (20 entries, no saves/caches) has SHA-256 `D68A9EDB5637D29F18CAEB7F109E46A8CDD06F53F15AF3EDF5C03503684ACB0B`, matching GitHub. The installed 0.4.22 updater returned `UPDATE_AVAILABLE|0.4.22-alpha|0.4.23-alpha`. Seven of eight checkpoint hashes matched the pre-0.4.22 baseline; the TranZit slot file changed to SHA-256 `E00AFB588DE27D8CD396033F9FB3512E98304E9B73799ea6fdf5d85838d35add` (normalized to lowercase in the check) during the owner's 0.4.22 gameplay, not from any build, publish or agent write. No local install was run.
- Remaining risk/next step: the file itself is only overwritten the next time that map loads; until then the old file remains on disk but hidden and unusable from the menus. Test deleting a slot, reopening the page, restarting the game, then loading that map and confirming the slot stays empty. Save slots in the in-game SAVE & EXIT page cannot be deleted from there.

## 0.4.22-alpha — 2026-11-01

### 2026-11-01 — Add UNLIMITED PERKS lobby option

- Request: add a Custom Games option, under CHEATS, that lifts the four-perk limit on every map, with a layout that does not overlap anything.
- Change or investigation: stock `_zm_perks` sets `level.perk_purchase_limit = 4` and gates every perk purchase through `get_player_perk_purchase_limit()` (Origins' per-player getter falls back to the same level value). `privateonlinegamelobby.lua` now appends a `zmcp_all_perks` entry to the stock `CoD.PrivateGameLobby.Dvars` table, so the stock lobby builds a normal DISABLED/ENABLED selector row directly under CHEATS with the stock spacing, hint and focus handling; the dvar is created at 0 if missing. The shared GSC adds `zmcp_unlimited_perks`, which sets the limit to 99 at init and again after `initial_blackscreen_passed` when the dvar is 1, and prints a one-line confirmation. The same shared source ships to all six maps. Not saved in checkpoints: Resume uses the lobby's current value (restored perks bypass the limit either way).
- Files affected: `src/ui/ui/t6/menus/privateonlinegamelobby.lua`, `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`, new `tools/Test-LobbyOption.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: lobby Lua parsed; `tools/Build.ps1` passed; all six generated T6 GSC files parsed and contain the new function. Co-op (25 cases), solo Resume and updater-ID suites still pass; the new mocked test confirms the row is appended once after CHEATS and the dvar is initialized without resetting an existing value. Nothing was installed or published; no `scriptdata` written.
- In-game result: **Verified in-game (owner, 2026-11-01):** "It worked" with a screenshot showing five perks; the exact map and the lobby layout were not itemized. Other maps not yet tested. Original expectation: the extra row lengthens the left list by one row and the map card sits in the separate lower-right area.
- Publication: source commit `8a857d4ee9789dfd5fce391a0327514014c0deda` was pushed before [GitHub release 0.4.22-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.22-alpha). The 117,725-byte ZIP (20 entries, no saves/caches) has SHA-256 `E1C8537FC073415898F9F79142AD3868849CEE691B67D10B619F3C9D0F07B045`, matching GitHub's digest. The installed 0.4.21 updater returned `UPDATE_AVAILABLE|0.4.21-alpha|0.4.22-alpha`; all eight checkpoint hashes matched before and after. No local install was run.
- Remaining risk/next step: confirm the row renders without overlap, that the label fits its column, that buying a fifth perk works on each map (Origins uses a per-player getter and Buried/Die Rise perk machines should be checked), and that perk icons stay on screen with many perks. A perk HUD overflow with very many perks is possible and unobserved.

## 0.4.21-alpha — 2026-10-30

### 2026-10-31 — Continuation baseline inspection

- Request: resume project work, read the complete project memory, inspect source and installed state, and preserve GitHub-only publication unless local installation is explicitly requested.
- Change or investigation: read AGENTS.md, PROJECT_HANDOFF.md, CHANGELOG.md, README.md and updater Lua. Installed metadata changed from 0.4.20-alpha at the initial inspection to 0.4.21-alpha at the continuation check; this agent performed no local installation. The installed updater IWD matches the built IWD and includes the Esc confirmation. All six standalone map scripts and the 12,992-byte mod.ff are present.
- Files affected: CHANGELOG.md and PROJECT_HANDOFF.md only.
- Validation: read-only installed inventory and eight checkpoint SHA-256 hashes inspected; no game or checkpoint files written. No runtime change, so parser/build checks are not applicable.
- In-game result: Not yet tested; installed files do not establish loaded UI or successful confirmation behavior.
- Remaining risk/next step: unload/reload the updated mod, then test default NO, STAY, confirmation Esc, and YES, LEAVE. Active-install behavior needs a subsequent update while the 0.4.21 UI is loaded. No Plutonium restart required. No new release needed for this documentation-only session.

### 2026-10-30 — Confirm Esc before leaving the updater

- Request: prevent an accidental Esc press from immediately closing the updater during installation.
- Change or investigation: the updater's back-button event now opens a small in-game confirmation. **NO, STAY** has initial focus; only **YES, LEAVE** closes the updater. The popup states when an active installation will continue in the background. The updater's explicit BACK and NOT NOW actions retain their normal behavior.
- Files affected: `src/ui/ui/t6/menus/zmcheckpointupdater.lua`, `mod.json`, `README.md`, `CHANGELOG.md`, `PROJECT_HANDOFF.md`.
- Validation: modified Lua parsed; `tools/Build.ps1` passed; all six generated T6 GSC scripts parsed. The 20-entry ZIP contains the confirmation Lua, `mod.ff`, six map scripts, and no saves (SHA-256 `981779C7888B936841D4A5AF0B4DA7FC587F3021B6E6F7BE4976736C8A2D39B7`). All eight installed checkpoint hashes matched task start; the local mod stayed at 0.4.20-alpha.
- In-game result: Not yet tested. Installed metadata at task start reports 0.4.20-alpha, confirming the previous release reached the local mod through the owner's updater; the new confirmation has not been exercised in-game.
- Remaining risk/next step: test Esc during an active install and after it finishes, check that No or Esc on the confirmation returns to the updater, and verify Yes returns to the Zombies menu. The owner installs this release through the updater.
- Publication: source commit `5287399db0dea4c8c20328b8d9c192bc6eb28078` was pushed before [GitHub release 0.4.21-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.21-alpha). The 115,726-byte asset digest matches the local ZIP. A read-only check on installed 0.4.20-alpha returned `UPDATE_AVAILABLE|0.4.20-alpha|0.4.21-alpha`. No local install was run.

## 0.4.20-alpha — 2026-10-30

### 2026-10-30 — Show real perk and weapon art in save slots

- Request: find a working menu image route and replace the Solo slot's letter badges with real perk and weapon images.
- Change or investigation: OpenAssetTools inspection of the installed T6 fastfiles found weapon menu materials in `ui_zm.ff` and perk HUD textures in the map fastfiles. The previous HUD-material attempt failed because those map materials were unavailable in the front-end. A new `mod.ff` embeds 12 perk textures under unique `zmcp_perk_*` material names; the Lua preview uses stock front-end weapon materials when available, plus text for weapons without a front-end material. Corrected Tombstone/Who's Who perk ID mapping. An initial asset-link attempt failed because OAT requires embedded image names to begin with `*`; retrying with that format compiled. DLC images initially failed to extract because their `dlczm*` IPaks were not loaded; loading those IPaks first yielded the missing art.
- Files affected: `assets/menu`, `src/ui/ui/t6/menus/zmcheckpointsolo.lua`, `tools/Build.ps1`, `tools/Build-MenuAssets.ps1`, `mod.json`, `.gitignore`, `README.md`, `THIRD_PARTY_NOTICES.md`, project memory.
- Validation: modified Lua and PowerShell parsed; `tools/Build-MenuAssets.ps1` compiled a 12,992-byte `mod.ff` with 12 materials and 12 embedded images; all 12 DDS files decode and have nonempty pixels. `tools/Build.ps1` passed and all six generated T6 GSC scripts parsed. The 20-entry ZIP includes `mod.ff`, the UI IWD, and six map scripts, with no save files (SHA-256 `4D07184454311F0FFF4874C4C18893BD9D41F90AE6D0BE627044AD9343DD0A8B`). At the first post-build check all six existing save hashes matched. At the final check, five still matched; the co-op `a` save had been rewritten and co-op `b` plus `used` appeared during the active game session. The build and release did not write to `scriptdata`, and no local install was run.
- In-game result: Not yet tested. The owner will update through the in-game updater; 0.4.20 is not copied to the local game.
- Remaining risk/next step: confirm the Solo slot preview shows perk and weapon art after unloading and reloading the updated mod. Some map-specific weapons have no stock front-end material and display their names only. The co-op Resume and updater fixes in 0.4.19 still need an in-game retest.
- Publication: source commit `54f5e5d0a19e489d73891f67957f20cee704c580` was pushed first. [GitHub release 0.4.20-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.20-alpha) has `zm_checkpoint-0.4.20-alpha.zip` (115,164 bytes) with the same SHA-256 digest as the local ZIP. A first release-create attempt using an abbreviated commit ID returned `Release.target_commitish is invalid`; retrying with the full commit ID succeeded. A direct read-only updater check from the locally installed 0.4.19-alpha returned `UPDATE_AVAILABLE|0.4.19-alpha|0.4.20-alpha`. No local install was run.

## 0.4.19-alpha — 2026-10-30

### 2026-10-30 — Keep updater results ordered and expose saved co-op settings

- Request: install the latest release locally, repair delayed update checks and installs, unlock the existing two-player checkpoint, and replace Solo preview badges with real perk and weapon images.
- Change or investigation: **Verified in-game (owner screenshots):** the updater displayed a timeout and later a valid result; CO-OP RESUME recognized Sharelocked and wathson but blocked Resume. The host PC now has a complete `zm_nuked` co-op checkpoint with both IDs and saved `0/1/0` settings. The earlier no-save finding was from an earlier inspection, before this checkpoint existed. **Expected:** the lobby setting mismatch is the remaining blocker, based on the saved file and console dvars. The co-op page now identifies each context mismatch and offers RESTORE SAVED SETTINGS for difficulty, Magic, and Headshots Only when those settings differ. The updater now waits for its own request's terminal result instead of declaring failure after 45 seconds. The watcher handles console markers split between reads, and a successful update restarts the background watcher so future checks use the newly installed script.
- Files affected: co-op/updater menu Lua, watcher/status PowerShell, co-op test, mod.json, README.md, COOP_TEST_PLAN.md, PROJECT_HANDOFF.md, CHANGELOG.md.
- Validation: Build.ps1 passed; all six generated T6 GSC scripts, three modified Lua files, and two modified PowerShell scripts parsed. The 25-case co-op suite, an exact host-checkpoint settings scenario, updater request-ID test, and split-marker regression check passed. The complete 20-entry ZIP (102,181 bytes; SHA-256 `71F7771988591C014C7E3228CC99DF2AF56FA37ED5AADDECA42E5626E2FC3686`) has six map scripts and a ten-entry UI IWD; no save files are included. The latest published 0.4.18-alpha was installed locally at the owner's explicit request before these source changes; all six existing checkpoints were preserved.
- In-game result: 0.4.19 changes not yet tested. The user screenshots establish the failures on the previously installed version. The owner must unload/reload the mod to use the new menu; Plutonium itself was not closed or restarted.
- Remaining risk/next step: test RESTORE SAVED SETTINGS and exact-team Resume with both PCs. Confirm that a new update check and install remain pending until the matching result arrives. **Known limitation:** no real perk or weapon images are in this build. Plutonium T6's documented `.iwi` route replaces existing game textures, and the earlier HUD-material attempt produced checkerboards in this menu. A working, distributable menu image pipeline is still needed; colored badges remain for now rather than shipping broken images.
- Publication and install: source commit `22c1f4e` was pushed before [GitHub release 0.4.19-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.19-alpha). GitHub reports the same 102,181-byte asset and SHA-256 digest as the local ZIP. At the owner's explicit request, Install.ps1 then installed the same build locally. Installed `mod.json` is 0.4.19-alpha, the IWD SHA-256 matches the package (`4DEA61024DEFF20B15E94E55EF0BA1B515184B8FC86C5978E91799A7477077DD`), and all six shared raw map scripts match. The watcher was restarted once (PID 48960), a direct check returned `UP_TO_DATE|0.4.19-alpha`, and all six original checkpoint hashes remained unchanged.

## 0.4.18-alpha — 2026-10-28

### 2026-10-28 — Clarify host-only co-op saves and repair slot previews

- Request: investigate a two-player Resume ID rejection and missing weapon/perk images.
- Change or investigation: **Verified in-game (owner screenshots):** after a successful co-op Save & Exit, the current PC's CO-OP RESUME page said no team checkpoint; the Solo slot preview showed checkerboard perk materials and text-only weapons. The current PC has no co-op checkpoint file, consistent with the friend hosting Save & Exit. The complete team snapshot belongs on that host PC. **Expected:** a decimal lobby XUID versus hexadecimal saved XUID can cause an exact-team rejection; the lobby gate now compares both forms using string arithmetic without 64-bit rounding, while retaining host, count, duplicate and exact-roster checks. The missing-save message names the host PC. The preview now uses menu-renderable colored text badges for perks and weapons instead of HUD-only textures or absent weapon item art.
- Files affected: co-op and solo menu Lua, co-op lobby test, mod.json, README.md, COOP_TEST_PLAN.md, PROJECT_HANDOFF.md, CHANGELOG.md.
- Validation: modified Lua parsed; 25 co-op lobby and launch cases, including decimal/hex 64-bit IDs, and solo Resume regression suite passed. Build.ps1 and all six generated T6 GSC parses passed. The 20-entry release ZIP has the complete folder and no `scriptdata`, save, cache, or tool files; SHA-256 `4179597D44BDC8DE133D5CB0BC74F621488E5A22E1B0B25C503A32D89F4DDE87`. All five local solo save hashes remained unchanged; no local install was run.
- In-game result: 0.4.18-alpha not yet tested; owner screenshots document the prior version's failures.
- Remaining risk/next step: have the original Save & Exit host open CO-OP RESUME with the same friend connected. If IDs still disagree, collect the host save and console log for diagnosis. Check badges on both Solo pages after updating.
- Publication: source commit `06335dc` was pushed before [GitHub release 0.4.18-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.18-alpha). The uploaded ZIP is 100,815 bytes and GitHub reports the same SHA-256 digest as the local package. Local Plutonium remains on 0.4.17-alpha for the owner to update in-game.

## 0.4.17-alpha — 2026-10-28

### 2026-10-28 — Repair companion request IDs and local update flow

- Request: fix 0.4.15's endless "Waiting for the update companion" screen,
  publish the repair, and install it locally for testing.
- Change or investigation: **Verified in-game (owner screenshot):** the updater
  kept checking and waiting despite a published 0.4.16 release. The 0.4.15
  `console_zm.log` shows requests such as
  `zmcp_update_request_20261028_1.5688346e+0081`. T6's Lua `tostring` used
  scientific notation for the random part of the request ID. The watcher and
  worker accept only 9–16 digits, so the request went unmatched. The status
  file had 0.4.16 available but an empty request ID, which the menu correctly
  refused as a reply to its pending check. Request IDs now use fixed-width
  decimal formatting. Missing replies show a retry message after about 45
  seconds instead of three minutes. The installer now touches other mod
  folders only with an explicit `-InstallCompanionMods` switch; the local
  repair install is scoped to ZM Checkpoint and its shared raw map scripts.
- Files affected: zmcheckpointupdater.lua, Install.ps1,
  Test-UpdaterRequestId.lua, mod.json, README.md, PROJECT_HANDOFF.md,
  CHANGELOG.md and release package.
- Validation: a focused test loads the shipped updater Lua and confirms
  digit-only 15-character request markers across repeat checks and rollover.
  Updater Lua and installer PowerShell parse; Build.ps1, six T6 map-script
  parses, and the solo Resume regression suite pass. A direct GitHub check
  from installed 0.4.15 reports `UPDATE_AVAILABLE|0.4.15-alpha|0.4.16-alpha`.
  The 20-entry ZIP includes all six map scripts and IWD, with no saves/caches:
  100,019 bytes, SHA-256
  `4E1A295CE99B1BE050A603F4A0DBCB98A65544A57EFF6312F66E946326A73E43`.
  GitHub confirms the matching size/digest. Install.ps1 completed locally;
  installed IWD matches dist SHA-256
  `8374DC3B9DDE29C1EF87C78D6E4C5590B2D28B721255ED3E10F33C5E6CF6A3B2`.
  The background bridge was restarted (new PID 33372). A fresh direct check
  now reports `UP_TO_DATE|0.4.17-alpha`. All four checkpoint hashes still
  match the task-start values. Each of the six installed mod and raw map
  scripts matches its package hash; the installed IWD contains the updater Lua.
- In-game result: the 0.4.17 fix is not yet tested in-game. The owner must
  unload and reload the mod; Plutonium need not restart.
- Remaining risk/next step: open the updater after reloading. It should show
  0.4.17 current, then detect the next release without waiting for a timeout.
  If the bridge does not reply, inspect its running task and console log.
- Publication: source commit `c3419f3` was pushed before
  [GitHub release 0.4.17-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.17-alpha)
  and its matching ZIP asset. Local 0.4.17 is installed by explicit owner
  request; other mod folders were not updated.

## 0.4.16-alpha — 2026-10-28

### 2026-10-28 — Show solo slot equipment and points

- Request: distinguish saves at the same round by showing points, weapons,
  perks, and compact game-style artwork on the Solo Save and Solo Resume pages.
- Change or investigation: validated solo checkpoint files already contain the
  score, primary weapon records, and perk records. The server now publishes
  bounded, token-checked preview metadata to per-map, per-slot archived dvars
  whenever it reads or saves a checkpoint. The disk format is unchanged.
  Each solo slot page shows a right-side details panel for the selected slot:
  points, weapons with BO2 item art when available, and perks using stock
  zombie shaders where a verified shader exists. Names remain visible as
  fallback. Saved settings have their own compact section below the slot list
  instead of the long hint that wrapped under the list.
- Files affected: zm_checkpoint_slots.gsc, zmcheckpointsolo.lua, mod.json,
  README.md, PROJECT_HANDOFF.md, CHANGELOG.md and release package.
- Validation: Build.ps1 succeeded; all six generated T6 map scripts and the
  modified Lua parsed. The existing solo Resume suite passed. Package archive
  has 20 entries, including all six map scripts and IWD, with no saves or
  caches: 99,795 bytes, SHA-256
  `AFC80F4BC4A6507CC449147608F4EE0C37D41C736E4949F871B14EBFADF8BF35`.
  GitHub confirms the same size and digest. Installed 0.4.15-alpha and all
  four task-start checkpoint hashes remain unchanged.
- In-game result: Not yet tested. The owner screenshot confirms the previous
  0.4.15 slot screen displayed only round/settings and a wrapping hint.
- Remaining risk/next step: install with the in-game updater, unload/reload,
  then check slot focus, points, weapon images/names, and perk icons in both
  solo pages. Existing saves may need their map loaded once for preview dvars
  to be republished. Co-op checkpoints are unchanged.
- Publication: source commit `1bf6a22` was pushed before
  [GitHub release 0.4.16-alpha](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.16-alpha)
  with the matching ZIP asset. No local install was performed.

## 0.4.15-alpha — 2026-10-28

### 2026-10-28 — Wait for the current update check and contain notes hints

- Request: remove the note page hover description overlapping the menu and
  stop showing a stale no-update result before a new GitHub check completes.
- Change or investigation: the owner screenshot shows `Read the previous
  release-note page.` below the notes box, overlapping the surrounding menu.
  The note page buttons were given stock hint text that the game drew outside
  their panel; those hints are removed. The installed 0.4.14 status CFG still
  contained the last `installed / 0.4.14-alpha` result. On each page poll,
  `exec zmcp_update_status.cfg` could replay that old result before the watcher
  finished a fresh check. New check and install commands carry a unique
  request ID through the watcher, worker and status CFG. The Lua page accepts
  a result only when its ID matches; otherwise it stays in Checking or
  Starting Update and eventually shows a retry error after about three
  minutes. The worker can recover the ID from the log when an older bridge
  process launches it without the new argument. An archived sequence keeps
  request IDs distinct across game restarts. GitHub release checks use a
  fresh query and no-cache header to reduce cached results.
- Files affected: updater Lua; watcher, worker, updater and status PowerShell;
  mod.json, README.md, PROJECT_HANDOFF.md, CHANGELOG.md and release package.
- Validation: modified Lua and PowerShell parsed. An isolated status write
  produced the expected request ID in both status CFG locations. A direct
  fresh GitHub check succeeded and reported 0.4.14 current before publication.
  Build.ps1, six T6 GSC parses and the prior solo/co-op Lua suites passed.
  Full package ZIP contains 20 entries, all six map scripts and the updater
  IWD, with no saves/caches (96,557 bytes, SHA-256
  `03899F787ACE016FB83C1216E9C179108D0C6756F3FA7A8EAFA2F977B02E9EEA`).
  No local install or save changes.
- In-game result: **Verified in-game (owner):** overlapping note hint and
  repeated stale no-update message on 0.4.14. The 0.4.15 fix is not yet
  tested in-game.
- Remaining risk/next step: test a fresh check immediately after publishing a
  later update; if the companion is unavailable the page should show a retry
  error rather than a false up-to-date result. The currently running older
  bridge uses the worker's log fallback until its scheduled task restarts.
- Publication: source commit `b0037f2` was pushed before GitHub release
  `0.4.15-alpha`; GitHub confirms the 96,557-byte ZIP and SHA-256 above. The
  installed 0.4.14 checker returns
  `UPDATE_AVAILABLE|0.4.14-alpha|0.4.15-alpha`. Local installed metadata and
  all four task-start checkpoint hashes are unchanged.

## 0.4.14-alpha — 2026-10-28

### 2026-10-28 — Clear countdown and restore Nuketown perk sites

- Request: move the match-start countdown off the Custom Games settings and
  restore perk machines to their saved Nuketown drop locations.
- Change or investigation: the stock `GameLobby.AddStatusText` placed `Game
  starting in 4` in the left column, where new Resume rows and their hints now
  live. The private lobby keeps that text above the right-hand map preview,
  including after stock lobby status updates. Nuketown's stock
  `init_nuked_perks` randomly assigns perk identities to physical drop sites
  each match. Earlier checkpoints recorded only which machines had landed,
  so their old locations are unrecoverable. New solo and co-op checkpoints
  write five `MACHINELOC` site IDs; readers validate a complete, unique set
  while continuing to accept older files without those records. Resume
  reassigns machine, trigger, collision, bump and blocker references to the
  saved sites before the existing arrival flow. If the saved sites are not
  available, it leaves the new match's placement alone and logs that fallback.
- Files affected: privateonlinegamelobby.lua, shared Nuketown GSC source and
  co-op checkpoint reader, mod.json, README.md, PROJECT_HANDOFF.md,
  CHANGELOG.md and generated release package.
- Validation: Build.ps1 and all six T6 GSC parser checks passed during the
  implementation; modified Lua parsed. The prior solo and 23-case co-op Lua
  suites passed. Full mod ZIP has six map scripts and the updated IWD, with no
  scriptdata or build caches (95,440 bytes, SHA-256
  `457A190CD60BCBA4B2C3C8F60E7A7705417F0C6D2FB582E67A1FA40AD049264A`).
  Installed game and checkpoint files were not written by this session.
- In-game result: **Verified in-game (owner):** a 0.4.13 Nuketown Resume
  restored the match but perk machines arrived at different sites; screenshot
  shows the stock launch countdown overlapping CHEATS and the focused hint.
  The 0.4.14 fixes are not yet tested in-game.
- Remaining risk/next step: publish without installing locally. Test a new
  Nuketown save created on 0.4.14, then Resume it and compare every perk site.
  Existing 0.4.13 saves have no site IDs and retain the old placement behavior.
- Publication: source commit `35fba8d` was pushed before GitHub release
  `0.4.14-alpha`; GitHub reports the matching 95,440-byte ZIP and SHA-256
  above. The installed 0.4.13 updater reports
  `UPDATE_AVAILABLE|0.4.13-alpha|0.4.14-alpha`. Installed metadata remains
  0.4.13-alpha and the four task-start checkpoint hashes are unchanged.

## 0.4.13-alpha — 2026-10-28

### 2026-10-28 — Four solo slots, saved lobby settings, and updater progress

- Request: allow multiple solo checkpoints on the same map, restore the five
  Custom Games settings on Resume, and make a slow updater install visible.
- Change or investigation: SAVE & EXIT now opens a four-slot solo page with a
  second selection to replace an occupied slot. SOLO RESUME opens a matching
  selection page. Slot 1 keeps the old per-map filename and accepts legacy
  format-3 saves; slots 2–4 use separate files. New saves add a validated
  SETTINGS record for difficulty, Magic, Headshots Only, Target Assist, Cheats,
  mode, group and start location. Resume applies the five settings before
  `xpartygo`, then the map checks the loaded settings before restoring. A
  mismatch cancels Resume and retains the checkpoint. Only the resumed slot is
  consumed. The updater now performs one GitHub release lookup during Install
  and reports download, unpacking and copy stages in-game. Prior 0.4.12
  screenshots showed an Installing page for roughly a minute before success;
  the precise delay source was not measured, so network time remains possible.
- Files affected: GSC solo source and shared slot helpers, solo/lobby/updater
  Lua, updater and status PowerShell, Build.ps1, test harness, mod.json,
  README.md, PROJECT_HANDOFF.md, CHANGELOG.md, and generated release package.
- Validation: Build.ps1 completed; all six generated GSC map scripts parsed
  with T6 gsc-tool. All modified Lua and PowerShell files parsed. Solo Resume
  tests cover slot selection, five settings, legacy checkpoint, and launch
  guards; existing 23-case co-op lobby suite passes. The ZIP has the complete
  mod folder, six map scripts and the updated IWD, with no saves or build
  caches (93,506 bytes, SHA-256
  `549428788CA3EF9DFCEC86FB3340A49039288DB373E4D3D4BC2B1FAAE67AE04F`).
  Installed metadata stays 0.4.12-alpha; Buried, Nuketown and TranZit saves
  retain their baseline hashes. No local installation.
- In-game result: Not yet tested. The owner will update from 0.4.12-alpha,
  unload/reload the mod, then test solo slots/settings and updater progress.
- Remaining risk/next step: verify actual BO2 lobby settings transfer and
  server-side comparison in-game; capture update stage timing if a download
  still seems stalled. Co-op Save & Exit remains unverified with two players.
- Publication: source commit `3709c5c` was pushed to main before release
  `0.4.13-alpha`. GitHub reports the matching 93,506-byte ZIP asset with the
  SHA-256 above. The installed 0.4.12 checker reports
  `UPDATE_AVAILABLE|0.4.12-alpha|0.4.13-alpha`. Installed metadata remains
  0.4.12-alpha and all three existing checkpoint hashes match task start.

## 0.4.12-alpha — 2026-10-28

### 2026-10-28 — Paginated release notes and reliable updater results

- Request: fix repeated in-game install attempts that returned to the menu
  without an explanation, delayed release notes, and a dense changelog that
  was cut off with no way to read the rest.
- Change or investigation: owner screenshots of standalone
  `mods/zm_checkpoint` show 0.4.11 available, an installing state, a completed
  0.4.11 install with `No release notes provided`, then release notes appearing
  after a later check as one truncated paragraph. The 0.4.11 formatter removed
  all paragraph breaks and limited notes to 11 lines. The watcher could also
  launch overlapping check/install processes, while the window companion hid
  exceptions, so failed or racing results were opaque. Version 0.4.12 splits
  authored lines and sentences into bullet entries, highlights each bullet,
  and supplies Previous/Next page controls in the notes panel. It carries up
  to 64 lines and displays a page number. Update workers are serialized by a
  named mutex; the watcher queues requests, and errors appear in-game as
  sanitized short text. If Install is clicked after the package is already
  current, the updater now resolves that request instead of leaving it pending.
- Files affected: updater Lua, updater status/window/watcher PowerShell,
  mod.json, README.md, PROJECT_HANDOFF.md, CHANGELOG.md, generated package.
- Validation: modified PowerShell and updater Lua parsed. An isolated status
  test rendered the 0.4.11 release body into 19 formatted/padded lines across
  three pages, created 64 bounded dvar slots, and stripped command punctuation
  and URLs from error text. Build.ps1 and all six GSC parses passed; IWD
  contains page controls, count and error display. Full mod-folder ZIP has 20
  entries, excludes scriptdata and caches, and has SHA-256
  `F2BBE38C86B1BE88491D128AEE532B957C841AD5724087C5616959AA88DE82E4`
  (84,729 bytes). Installed metadata stays 0.4.11-alpha; no local install.
  Buried and TranZit saves retain their prior hashes. Nuketown is now
  `C0376DCF00151DA429F7A5545D010FB8F4052439CE07404201A8D0C8FD7AB404`,
  last written by gameplay at 19:51:40, after the previous session baseline;
  neither Build.ps1 nor this agent wrote scriptdata.
  Source was pushed before GitHub release 0.4.12-alpha was published with
  the matching ZIP digest. The installed 0.4.11 updater reports
  `UPDATE_AVAILABLE|0.4.11-alpha|0.4.12-alpha`; all three saves retain the
  hashes recorded above and no local installation occurred.
- In-game result: **Verified in-game:** 0.4.11 installed, delayed and truncated
  notes, and the reported retry sequence. The 0.4.12 fixes are not yet tested.
- Remaining risk/next step: publish without local install. The currently
  running 0.4.11 bridge remains in memory until restarted; the new window
  companion mutex still serializes update workers after 0.4.12 is installed.
  Owner should test pages, focus, clear errors and a future update through the
  game. A failed check's exact prior exception was not retained by 0.4.11.

## 0.4.11-alpha — 2026-10-28

### 2026-10-28 — Update detection timing check

- Request: investigate why the in-game updater still displayed 0.4.10 as the
  latest version after 0.4.11 had been published.
- Change or investigation: inspected the live Plutonium console log, update
  status CFG, installed metadata, bridge task state, and a direct GitHub check.
  The request marker reached the console. The status CFG now reports
  `update_available` and `0.4.11-alpha`; the direct check also returns
  `UPDATE_AVAILABLE|0.4.10-alpha|0.4.11-alpha`. The user then confirmed the
  update appeared. The earlier screenshot likely captured the previous status
  before the background check completed; exact timing was not captured.
- Files affected: CHANGELOG.md and PROJECT_HANDOFF.md only.
- Validation: live status and direct check agreed; installed version remained
  0.4.10-alpha. No game files or saves were changed by this investigation.
- In-game result: **Verified in-game:** user reports that 0.4.11 is now shown.
- Remaining risk/next step: no updater code change needed for this observation;
  continue with the 0.4.11 download and two-PC Nuketown tests.

### 2026-10-28 — Latest changes panel and first co-op test fixes

- Request: show the latest release changes in a BO2-style right-side updater
  panel; fix the two-player Nuketown Save & Exit readiness rejection and the
  Custom Games map card covering the selected option's description.
- Change or investigation: the Windows companion now passes the newest GitHub
  release notes to the in-game status file as bounded, sanitized plain text.
  The updater shows up to 11 short lines in a dark framed right-side panel.
  The co-op save/restore guards no longer require the unverified pause-menu
  `hello_040` signal. Valid unique account IDs, exact roster, original host,
  alive players and map context remain required. Specific save errors now
  identify an invalid ID, duplicate ID or non-playing player. The stock map
  card is moved and slightly reduced to keep left-side descriptions visible.
- Files affected: updater scripts and Lua, co-op GSC/Lua, private lobby Lua,
  mod.json, README.md, COOP_TEST_PLAN.md, PROJECT_HANDOFF.md, CHANGELOG.md.
- Validation: modified PowerShell and Lua parsed; all six built GSC outputs
  parsed; Build.ps1 passed. Isolated status-file check produced 11 bounded
  release-note lines and stripped unsafe command punctuation. Complete mod
  folder ZIP has 20 entries and excludes saves/caches; SHA-256
  `14692685B0DFFDCB121F4BDCBA95E5C6206F7017C04BF42B949455C835F86FFA`.
  Installed metadata remains 0.4.10-alpha; Buried, Nuketown, and TranZit
  checkpoint hashes match their pre-work baselines. No local install was run.
  Source was pushed before GitHub release 0.4.11-alpha was published with the
  83,057-byte ZIP and matching digest. The local 0.4.10 updater returns
  `UPDATE_AVAILABLE|0.4.10-alpha|0.4.11-alpha`.
- In-game result: **Verified in-game:** previous co-op readiness error and map
  card overlap on Nuketown from owner screenshots. New behavior not yet tested.
- Remaining risk/next step: publish 0.4.11 without local install; both PCs
  load it and retry Nuketown co-op save/resume. Confirm map layout and notes.
  A client mod cannot be attested through the optional pause-menu signal.

## 0.4.10-alpha — 2026-10-28

### 2026-10-28 — Offer Unload after an in-game update

- Request: show a Mods-style U Unload shortcut and an UNLOAD row between NOT NOW
  and BACK, only after this updater page installs an update.
- Change or investigation: copied the stock Mods menu's `alt1` U Unload and
  `alt2` R Refresh prompt bindings. A successful install from this page reveals
  the UNLOAD row and U prompt and focuses Unload. Both invoke the stock
  `loadmod ""` command. They stay hidden on open, during checks, when already
  current, and during installation. Refresh preserves the post-install option
  after the new result arrives.
- Files affected: updater Lua, mod.json, README.md, PROJECT_HANDOFF.md,
  CHANGELOG.md, generated release package.
- Validation: updater Lua and all six built GSC scripts parsed; Build.ps1
  succeeded; IWD contains both prompts, both Unload events, and the stock
  unload command. Complete mod-folder ZIP has 20 entries (80,656 bytes), no
  `scriptdata`, saves, or development caches. Installed metadata remains
  0.4.9-alpha and all three existing checkpoint hashes match their baseline.
  GitHub release 0.4.10-alpha published with the ZIP and matching SHA-256;
  installed updater returned `UPDATE_AVAILABLE|0.4.9-alpha|0.4.10-alpha`.
- In-game result: Not yet tested. The user screenshot shows the previous panel
  with Install Update, Not Now and Back; no post-install Unload is present.
- Remaining risk/next step: owner installs 0.4.10 through the updater, tests
  that both Unload controls appear only after success, and reloads the mod.
  No local 0.4.10 install was performed by this work session.

## 0.4.9-alpha — 2026-10-28

### 2026-10-28 — Add native R Refresh to the updater page

- Request: add the Mods-menu-style R Refresh prompt to the update page so it
  checks GitHub again; keep the full project history current.
- Change or investigation: reused the stock T6 `alt1` ButtonPrompt with the R
  key hint and wired it to the updater's existing request marker. The panel
  returns to Checking, then reads the new result. Refresh is ignored during
  installation. README and handoff now describe this behavior and the ongoing
  GitHub-only release workflow.
- Files affected: updater Lua, mod.json, README.md, PROJECT_HANDOFF.md,
  CHANGELOG.md, generated release package.
- Validation: updater Lua parsed; all six generated GSC files parsed;
  Build.ps1 succeeded. IWD contains the Refresh prompt, event handler, and
  request call. The complete mod-folder ZIP has 20 entries (80,224 bytes) and
  excludes `scriptdata`, `.sav`, `.cache`, and `.tools`. All three existing
  checkpoint hashes matched their baseline. Installed metadata was 0.4.7-alpha
  at task start and 0.4.8-alpha at final check; the agent did not install it.
  GitHub release 0.4.9-alpha published with the ZIP and matching SHA-256;
  installed updater returned `UPDATE_AVAILABLE|0.4.8-alpha|0.4.9-alpha`.
- In-game result: Not yet tested. The user supplied a screenshot of the native
  Mods menu's R Refresh prompt as the visual reference.
- Remaining risk/next step: owner installs 0.4.9 via the updater, unloads and
  reloads the mod, then tests R from the updater page and verifies a fresh
  result appears. No local 0.4.9 install was performed.

## 0.4.8-alpha — 2026-10-28

### 2026-10-28 — Focus Back when the updater is current

- Request: stop the disabled NOT NOW button blinking when no update exists;
  show a selected BACK choice and publish without installing locally.
- Change or investigation: the 0.4.7 panel disabled update choices while
  leaving NOT NOW focused. Added a BACK row that appears and gains focus for
  up-to-date, installed, and error results. The update choices remain greyed
  out when already current. Recorded the owner's remote-release-only workflow.
- Files affected: updater Lua, mod.json, AGENTS.md, README.md, PROJECT_HANDOFF.md,
  CHANGELOG.md, built release package.
- Validation: updater Lua parsed; all six generated GSC files parsed; Build.ps1
  succeeded; IWD contains the new Back/focus code. Release ZIP has 20 entries,
  including the complete mod folder, and no `scriptdata`, `.sav`, `.cache` or
  `.tools`. The installed mod remained 0.4.7-alpha, and all three existing
  checkpoint hashes matched the pre-build baseline. GitHub release
  `0.4.8-alpha` contains the 79,999-byte ZIP with a matching SHA-256 digest;
  installed updater check returned `UPDATE_AVAILABLE|0.4.7-alpha|0.4.8-alpha`.
- In-game result: **Verified in-game:** 0.4.7 update installed and smaller text
  appears clearly in the supplied screenshot; the disabled NOT NOW row blinks.
  0.4.8 focus behavior: Not yet tested.
- Remaining risk/next step: use the installed updater to download 0.4.8, unload
  and reload the mod, then verify the up-to-date Back row in-game. No local
  install was performed by this work session.

## 0.4.3-alpha — 2026-10-28

### 2026-10-28 — In-game update request bridge

- Request: find a way to launch update checks from the in-game button, using
  the Plutonium shell or REA if needed.
- Change or investigation: the button now emits a unique console-log marker.
  A per-user Windows scheduled task watches the log and launches the updater
  window when it sees the marker. Fixed the updater to include GitHub
  prereleases, compare version numbers, and copy package-owned files without
  moving/deleting `scriptdata`. The local 0.4.3 package includes the watcher.
  A prior manual handoff popup was replaced with a brief checking message.
- Files affected: updater Lua, Windows updater scripts, new watcher and bridge
  installer, Build.ps1, mod.json, README.md, PROJECT_HANDOFF.md, CHANGELOG.md.
- Validation: built and installed 0.4.3 locally; six GSC and all Lua parsed;
  modified PowerShell scripts parsed; installed IWD contains the marker; the
  bridge task reports Running; updater check returns UP_TO_DATE for local
  0.4.3 against published 0.4.2; save hashes matched before and after install.
  REA opened shipped t6zm.exe but native analysis was unavailable because no
  provider is configured. `openurl` string/ShellExecute import alone cannot
  prove a launch command.
- In-game result: Not yet tested. Previous screenshot verified the button and
  manual popup; new click-to-Windows handoff awaits test after mod reload.
- Remaining risk/next step: click CHECK FOR UPDATES after reload and confirm
  the companion window opens. If absent, inspect console_zm.log for marker and
  scheduled task status. GitHub release still 0.4.2-alpha; local 0.4.3-alpha
  is not published.

## 0.4.2-alpha — 2026-10-28

### 2026-10-28 — Red upper-left zombie counter

- Request: move the counter to the top-left, slightly higher, and make it red.
- Change or investigation: left safe-area anchor, x=12/y=10 instead of centered
  y=24; red RGB (0.85, 0.08, 0.05). Size and toggle unchanged.
- Files affected: shared zm_checkpoint.gsc, mod.json, README.md,
  PROJECT_HANDOFF.md, CHANGELOG.md, generated packages and installed copies.
- Validation: all six generated GSC files parsed; Build.ps1 and Install.ps1
  passed. Six-map hashes match in raw, standalone and three companion mods;
  IWD entries inspected; ZIP contains no checkpoint/scriptdata files.
  Buried/TranZit saves matched baseline. Nuketown hash check detected a newer
  valid round-2 checkpoint with END; likely runtime activity (not confirmed).
  Installer does not write saves; retained the current file without rollback.
- In-game result: screenshot verifies the prior top-center counter is visible;
  exact loaded map/mod unconfirmed. New styling: Not yet tested.
- Remaining risk/next step: start a new match and check position/color;
  no full restart needed from 0.4.1. Toggle/count accuracy and co-op still need
  testing. Package: dist/zm_checkpoint-0.4.2-alpha.zip.

## 0.4.1-alpha — 2026-10-27

### 2026-10-27 — Small toggleable remaining-zombies counter

- Request: add a compact BO2-style top-center round counter, toggled with 0;
  keep work brief. User deferred co-op testing to 2026-10-28.
- Change or investigation: native per-client numeric HUD, default font at 1.6,
  warm white with subtle red glow, top offset 24; refresh every 0.2 seconds.
  Uses stock round_wait's alive plus unspawned count, clamps at zero, hides
  while dead/spectating or co-op restoration is pending. Individual visibility
  resets each match. Lua binds 0 and KP_INS to a notifyonplayercommand toggle;
  diagnostic cfg contains the same bindings. No save format or co-op changes.
- Files affected: shared GSC, zmcheckpointingame.lua, cfg/zm_checkpoint.cfg,
  mod.json, README.md, PROJECT_HANDOFF.md and CHANGELOG.md.
- Validation (completed 2026-10-28): all six generated GSC files and modified
  Lua passed parsing; Build.ps1 and Install.ps1 completed. Installed map-script
  coverage and IWD toggle bindings were inspected. All three existing saves
  retained their SHA-256 hashes. Standalone and three companion mods updated;
  shareable package: `dist/zm_checkpoint-0.4.1-alpha.zip`.
- In-game result: Not yet tested.
- Remaining risk/next step: reload mod, start a new match, check position,
  count decreasing to zero and both toggle keys. Special rounds/custom enemy
  controllers require gameplay confirmation. Co-op test remains deferred.

## 0.4.0-alpha — 2026-10-27

### 2026-10-27 — Host-stored exact-team co-op checkpoint test build

- Request: implement the approved host-stored complete checkpoint approach.
- Change or investigation: added an independent 2–4-player Classic/Survival
  path, original-host authorization, normalized string XUID roster, per-player
  records, shared world restore, context/settings checks and co-op Resume page.
  Two generation slots protect the previous complete write; a consumption
  receipt prevents replay of older consumed generations. Invalid identity/API
  data, roster mismatch and readiness timeouts fail closed. Stock round_think
  is held until restore completes; a watchdog handles stalled restoration.
  Each player opens pause once per match to send the versioned UI handshake.
  Co-op sessions cannot write solo slots after guests leave. Co-op quests and
  character reconstruction are explicitly outside this version's guarantee.
- Files affected: shared GSC, new `zm_checkpoint_coop.gsc`, menu/in-game Lua,
  new `zmcheckpointcoop.lua`, Build.ps1, mod.json, README.md, COOP_TEST_PLAN.md,
  tools/Test-CoopLobby.lua, PROJECT_HANDOFF.md and CHANGELOG.md.
- Validation: all six generated GSCs and three UI Lua files parse; Build/Install
  PowerShell parsers pass; 23 engine-mocked tests of the actual Lua lobby/action
  pass (including 2/3/4 players, order/name changes, replacement/missing/extra
  players, host/context mismatch, numeric IDs and unavailable API). Built IWD
  contains six Lua files. Installed standalone, six shared raw scripts and three
  companions; installed script/IWD hashes match. All three existing checkpoint
  hashes are unchanged. Package has no scriptdata or saves. Shareable standalone
  ZIP: `dist/zm_checkpoint-0.4.0-alpha.zip`.
- In-game result: Not yet tested. No multiplayer runtime or visual UI result is
  claimed. Static references establish candidate APIs, not their current runtime
  ID equivalence or synchronization behavior.
- Remaining risk/next step: reload the mod on all PCs, start with two-player
  Nuketown and follow COOP_TEST_PLAN.md. Verify lobby/GSC XUID equivalence,
  round startup, separate player inventory, disconnect recovery and repeat saves.
  LAN identities, custom round controllers, map-exclusive systems and damaged
  consumption receipts retain documented limitations. No automatic restart.

## 0.3.4-alpha — 2026-10-25

### 2026-10-27 — Assess same-host, exact-roster co-op checkpoints

- Request: assess host-only Save & Exit and a separate co-op Resume tab gated
  by the original host, exact players/count and map, with each player's save
  stored locally and identity bound to Plutonium accounts.
- Change or investigation: inspected current GSC/Lua and installed standalone
  metadata/six scripts. Confirmed single-player records/guards and no client
  storage protocol. Documented an expected roster-bound design, host-authoritative
  storage alternative, distributed-save acknowledgement requirement, and the
  official LAN username-derived GUID limitation. Online identity APIs and lobby
  equivalence remain unverified; no implementation was attempted.
- Files affected: PROJECT_HANDOFF.md and CHANGELOG.md only.
- Validation: source and installed-state inspection; read-only checkpoint hash
  inventory found three standalone saves. No checkpoint or installed files were
  written. Parsers/build/install not applicable to documentation-only changes.
- In-game result: Not yet tested.
- Remaining risk/next step: isolated two-PC identity, host detection, lobby
  roster and client-local persistence probe before promising the complete design.
  Keep solo behavior unchanged; no restart required for this investigation.

### 2026-10-25 — Add the first Buried quest milestone adapter

- Request: implement Phase 1/Buried only, preserve stable quest progress safely,
  retain format-3 compatibility, document the stock milestone evidence before
  coding, build and install a ready-to-test package, and preserve every current
  checkpoint file.
- Change or investigation:
  - inspected the installed 0.3.3 baseline and all three standalone checkpoint
    files; confirmed the Buried round-9 save has no quest record;
  - audited both Buried branches and the ordered sidequest stages against the
    pinned stock reconstruction and added the milestone/side-effect/reset table
    to `MAP_STATE_AUDIT.md` before source edits;
  - added optional `QUEST,1,zm_buried,<branch>,tower` serialization and strict
    duplicate/schema/map/branch/milestone validation without changing overall
    checkpoint format version 3;
  - skipped Buried `sq_*` and `ftl_*` flags in generic flag save/replay so
    incomplete quest flags do not bypass stock side effects;
  - added an early Buried-only restore phase that rebuilds the selected stock
    tower effects and removes consumed tower parts before setting the branch
    flag. A failed early setup leaves the checkpoint unconsumed;
  - added a Build.ps1 guard against Buried stock externals leaking into other
    generated map scripts. No Die Rise, TranZit, Mob, or Origins quest adapter
    was added.
- Files affected: `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`,
  `tools/Build.ps1`, `src/ui/ui/t6/menus/zmcheckpointmenu.lua`, `mod.json`,
  `README.md`, `MAP_STATE_AUDIT.md`, `PROJECT_HANDOFF.md`, and `CHANGELOG.md`.
- Validation: all six generated GSC files passed bundled T6 PC parsing; the
  modified Lua menu and both PowerShell scripts passed their parsers; package
  inspection confirmed map-exclusive externals are confined to matching outputs
  and the IWD contains the expected UI files. Version 0.3.4 was installed to
  standalone, six shared raw map folders, and all three companion mods. All
  three existing standalone checkpoint hashes matched before and after install;
  the package contains no checkpoint files or `scriptdata` directory.
- In-game result: Not yet tested.
- Remaining risk/next step: test the Maxis and Richtofen tower milestones in
  separate Buried matches, saving immediately after tower construction and
  before amplifier progress. Use a separate active-mod save slot so the existing
  standalone Buried round-9 checkpoint is not replaced. Reload Plutonium or the
  selected mod for the updated UI, then start a new match for the GSC changes.

## 0.3.3-alpha — 2026-10-25

### 2026-10-25 — Add staged Easter-egg persistence plan

- Request: create a durable plan file and a safe continuation prompt so a new
  chat can continue Easter-egg support without damaging known-good behavior.
- Change or investigation:
  - added `EASTER_EGG_PERSISTENCE_PLAN.md` with the approved optional typed
    record design, phased restore order, common framework, map-by-map roadmap,
    required test matrix, validation gates, and rollback rules;
  - constrained the immediate coding scope to Buried and required a stock-script
    milestone/side-effect table before implementation;
  - linked the plan from the handoff, README, and map-state audit;
  - updated the handoff continuation prompt to require the plan and Phase 1
    scope.
- Files affected: `EASTER_EGG_PERSISTENCE_PLAN.md`, `PROJECT_HANDOFF.md`,
  `README.md`, `MAP_STATE_AUDIT.md`, and `CHANGELOG.md`.
- Validation: documentation-only review; links, required headings, current
  version, pinned reference commit, and Phase 1 scope checked.
- In-game result: Not applicable; no source, build, package, installed file, or
  checkpoint changed.
- Remaining risk/next step: a new chat should implement Phase 1/Buried only,
  stop after static validation and installation, and wait for milestone-by-
  milestone in-game evidence before expanding the guarantee.

### 2026-10-25 — Define safe Easter-egg checkpoint architecture

- Request: explain why complete Easter-egg progress is not yet guaranteed and
  determine whether it can be supported safely.
- Change or investigation:
  - inspected the reconstructed quest entry points for TranZit, Die Rise, Mob
    of the Dead, Buried, and Origins;
  - bounded literal-flag inventory found 2 quest-related names in TranZit, 34 in
    Die Rise, 54 in Mob, 34 in Buried, and 56 in Origins, excluding dynamically
    generated names and non-flag state;
  - confirmed TranZit's active route uses nested `level.sq_progress` arrays,
    entity references, and counters rather than a single quest flag;
  - confirmed the other maps combine flags with physical models/triggers,
    carried pieces, player or afterlife state, moving systems, arrays, and live
    waiter threads;
  - defined a versioned per-map `QUEST` record design: save stable completed
    milestones and typed durable items, replay stock side effects, and restart
    only the unfinished step rather than restoring live threads;
  - retained the existing limitation instead of implementing unsafe blanket
    flag replay.
- Files affected: `MAP_STATE_AUDIT.md`, `PROJECT_HANDOFF.md`, `CHANGELOG.md`,
  and `README.md`.
- Validation: source search and control-flow inspection against the pinned
  reconstructed stock-script checkout; documentation links and counts checked.
- In-game result: Not yet tested; investigation/design only, with no runtime or
  installed-file change.
- Remaining risk/next step: implement and test the first versioned quest adapter
  on Buried, preserving completed milestones while restarting the active
  incomplete step. Expand to Die Rise, TranZit, Mob, and Origins only after each
  map's stock side effects are reconstructed and tested.

### 2026-10-25 — Preserve released Arthur/Leroy state on Buried

- Request: after a Buried Resume restored doors, debris, inventory, and other
  world progress correctly, keep Arthur outside his cell near the location and
  state where Save & Exit occurred; also investigate equivalent special actors
  and Easter-egg/secret progression on every stock map.
- Change or investigation:
  - inspected the installed round-9 Buried checkpoint and confirmed it contained
    `jail_door1` and the other opened paths but no actor state;
  - traced the stock `_zm_ai_sloth.gsc` spawn/state machine: every new match
    creates Arthur at `sloth_idle_pos` in `jail_idle`, independently of the
    physical jail-door flag;
  - added an optional Buried `SLOTH` record containing released status, origin,
    angles, prior state name, and booze/release context;
  - added a Buried-only restore adapter that waits for the stock actor, restores
    the open-cell context, teleports him to the saved transform, and calls the
    stock stable `roam` state rather than resuming unsafe mid-animation states;
  - audited all six reconstructed stock-map script sets for allied map actors;
    Arthur was the only persistent map-specific AI assigned to the allied team.
    Bus/driver, hostile bosses, robots, elevators, and afterlife actors require
    different state models and are not treated as Arthur equivalents;
  - audited quest scripts and confirmed that complete Easter-egg continuation
    spans flags, mutable `level` fields, arrays, models, carried parts, character
    identity, and active waiter threads. Existing entity-backed flags remain
    covered, but full quest continuity is retained as an explicit limitation
    rather than being falsely claimed;
  - kept checkpoint format version 3. The new record is optional, so old saves
    remain readable, although a pre-0.3.3 save has no Arthur position to restore.
- Files affected: `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`,
  `tools/Build.ps1`, `src/ui/ui/t6/menus/zmcheckpointmenu.lua`, `mod.json`,
  `README.md`, `MAP_STATE_AUDIT.md`, `PROJECT_HANDOFF.md`, and `CHANGELOG.md`.
- Validation:
  - all six generated map GSC files passed bundled `gsc-tool` T6 PC parsing;
  - modified Lua and both PowerShell scripts passed their parsers;
  - package inspection confirmed the Arthur external/restore functions exist
    only in `zm_buried`, while all readers accept the optional record;
  - the first package guard also rejected the harmless generic `SLOTH` reader.
    That attempt was replaced with a guard against actual Buried externals and
    functions, after which all six builds passed;
  - version `0.3.3-alpha` was built and installed to standalone, six shared raw
    map folders, and all three current companion mods;
  - the installed IWD contains UI version `0.3.3`;
  - Buried and Nuketown checkpoint hashes remained unchanged. The TranZit slot
    advanced during this work from a valid round-5 file to a valid round-7 file;
    the package contains no `scriptdata` and the installer has no checkpoint
    write/delete operation, so the newer runtime save was preserved rather than
    rolled back. A final reinstall then preserved all three current checkpoint
    hashes exactly.
- In-game result: **Verified in-game:** 0.3.2 Buried restored common doors,
  debris, and world unlocks, but Arthur returned to his cell. **Not yet tested:**
  the 0.3.3 Arthur record and restore path.
- Remaining risk/next step: fully reload the mod, create a new 0.3.3 Buried
  checkpoint after releasing Arthur, then Resume it and confirm he appears near
  the saved location and continues roaming. Do not use the existing round-9
  checkpoint as proof because it predates the `SLOTH` record. Full Easter-egg
  progression still requires separate map-specific milestone adapters and
  in-game tests.

## 0.3.2-alpha — 2026-10-25

### 2026-10-25 — Preserve scripted map unlocks and TranZit vault state

- Request: preserve the TranZit bank vault after Resume and find a systematic
  way to retain opened doors/unlocks across the six stock maps without requiring
  the user to discover every mismatch manually.
- Change or investigation:
  - confirmed from the stock TranZit script reconstruction that
    `town_bunker_door` is an explosive-damage-driven scripted mover, not a
    common `zombie_door`/`zombie_debris` blocker;
  - changed the shared collector to enumerate every live map entity and capture
    its set `script_flag`, instead of inspecting only normal door/debris arrays;
    the inventory is refreshed immediately before writing so later-spawned map
    entities are included;
  - added a TranZit-only restore block that replays the vault door's stock
    explosive-damage event, including rotation, map flag, and path connection;
  - audited the other stock map scripts for the same geometry-first pattern and
    added Buried-only physical replay for collapsing passages,
    Arthur-opened barricades, and the courtyard/maze fountains;
  - generalized `Build.ps1` map-only block stripping for Nuketown, TranZit, and
    Buried so no map-specific references leak into another map's linker input;
  - added `MAP_STATE_AUDIT.md` with the evidence base, coverage matrix, known
    limits, and required workflow for future map-state mismatches;
  - kept checkpoint format version 3, so existing valid saves remain readable.
- Files affected: `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`,
  `tools/Build.ps1`, `mod.json`, `README.md`, `MAP_STATE_AUDIT.md`,
  `PROJECT_HANDOFF.md`, and `CHANGELOG.md`.
- Validation:
  - all six generated map GSC files passed bundled `gsc-tool` T6 PC parsing;
  - `Build.ps1` and `Install.ps1` passed PowerShell parser validation;
  - package inspection confirmed all six outputs contain the shared entity
    collector, only `zm_transit` contains `town_bunker_door`, only `zm_buried`
    contains its three special-state target names, and only `zm_nuked` contains
    `zm_nuked_perks` references;
  - version `0.3.2-alpha` was built and installed to standalone, shared raw map
    scripts, and all three existing companion mods;
  - the existing Nuketown and TranZit checkpoint files retained identical SHA-256
    hashes across installation.
- In-game result: **Verified in-game** before the fix: TranZit 0.3.1 restored
  round, weapons, score, and player position correctly, but an opened bank vault
  returned closed. **Not yet tested:** the 0.3.2 vault and Buried physical replay
  paths.
- Remaining risk/next step: create a new 0.3.2 TranZit checkpoint after opening
  the vault, Resume it, and confirm the vault is open. The checkpoint created
  under 0.3.1 cannot contain the newly collected vault flag. Complex dynamic
  systems listed in `MAP_STATE_AUDIT.md` remain intentionally unclaimed until
  dedicated adapters and in-game evidence exist.

## 0.3.1-alpha — 2026-10-24

### 2026-10-24 — Consume resumed checkpoints and isolate map externals

- Request: prevent a dead resumed run from leaving an infinite Resume loop, and
  fix TranZit failing before start with unresolved Nuketown perk functions.
- Change or investigation:
  - successful restoration now overwrites the checkpoint with `CONSUMED` and
    clears its map-specific Resume dvars;
  - a defensive watcher performs the same invalidation at stock
    `pre_end_game`/`end_game`;
  - restoration/perk-schedule threads terminate on `end_game`;
  - `Build.ps1` strips marked Nuketown-only blocks from every non-Nuketown map
    output while preserving the full adapter for `zm_nuked`;
  - reviewed stock `_zm.gsc` evidence confirming solo death notifies
    `pre_end_game` immediately before `end_game`.
  - the first strip-regex used `\s` around marker lines and also consumed the
    following line's indentation. Package inspection caught this before handoff;
    it was replaced with horizontal-space-only matching and the generated output
    was rebuilt, reparsed, and reinstalled.
- Files affected: `src/scripts/zm/zm_nuked/zm_checkpoint.gsc`,
  `tools/Build.ps1`, `src/ui/ui/t6/menus/zmcheckpointmenu.lua`, `mod.json`,
  `AGENTS.md`, `README.md`, `PROJECT_HANDOFF.md`, and `CHANGELOG.md`.
- Validation:
  - Nuketown and generated TranZit GSC both passed the bundled T6 parser;
  - the modified Lua menu passed `luaparse`;
  - modified PowerShell scripts passed parser validation;
  - generated TranZit contains no Nuketown perk external references;
  - version `0.3.1-alpha` was built and installed to the standalone and three
    companion mods;
  - all five installed generic map scripts have the same hash and zero
    `zm_nuked_perks` references; the installed Nuketown script has its separate
    adapter-bearing hash;
  - the pre-existing round-4 Nuketown file was preserved by installation.
- In-game result: not yet tested. The original stale Resume remains until it is
  resumed once with 0.3.1 (then consumed) or manually cleared in-game.
- Remaining risk/next step: fully reload Plutonium/mod, retest the existing
  Nuketown Resume followed by death, and separately launch TranZit. Record
  whether the process-close symptom recurs; no matching Plutonium application
  fault or usable `console_zm.log` was retained for the earlier close.

## 0.3.0-alpha — 2026-10-24

### 2026-10-24 — Persistent project memory

- Request: create complete continuation documentation and ensure future agents
  keep it current after every fix, failure, change, installation, and test.
- Change: added `PROJECT_HANDOFF.md`, this changelog, and project-level
  `AGENTS.md` rules with a required documentation workflow and end-of-task
  checklist.
- Files affected: `AGENTS.md`, `PROJECT_HANDOFF.md`, `CHANGELOG.md`, `README.md`.
- Validation: documentation links and required sections were inspected locally.
- In-game result: not applicable; documentation-only change.
- Remaining risk/next step: future agents must obey `AGENTS.md` and continue
  recording the five pending multi-map in-game tests.

### Added

- Shared checkpoint support for all six stock physical Zombies maps:
  TranZit, Nuketown, Die Rise, Mob of the Dead, Buried, and Origins.
- A separate checkpoint filename and archived Resume metadata for each map.
- Map-aware Resume labels in the private lobby.
- Six-map deployment in both the build and installation scripts.
- Multi-map documentation, limitations, test plan, and project handoff.

### Changed

- The GSC adapter now derives its current map from `mapname`.
- The save header validates against the current map dynamically.
- Nuketown perk-machine serialization and restoration run only on Nuketown.
- Pause-menu support checks the shared supported-map registry.
- User-facing messages and diagnostic controls are map-neutral.

### Verified

- GSC parsing, Lua parsing, and PowerShell parsing succeeded.
- All six build outputs and raw install targets were present.
- Standalone and companion mods contained the six scripts and checkpoint IWD.
- Existing Nuketown round-4 checkpoint remained intact.

### Known limitations

- The five newly added maps still require systematic in-game validation.
- Map-exclusive systems are not fully serialized.
- TranZit, Town, Farm, and Bus Depot currently share one `zm_transit` slot.

## 0.2.6 — 2026-10-24

- Reinserted the native Resume button at the top of the lobby's own vertical
  list, directly above **START MATCH**.
- Kept normal mouse, keyboard, controller, focus, and hint behavior.
- Made the button conditional on a valid archived checkpoint flag.
- In-game result: the native lobby Resume button worked successfully.

## 0.2.5 — 2026-10-24

- Changed Resume to use the private lobby's `xpartygo` launch path.
- Removed the raw `map zm_nuked` launch behavior.
- Fixed the loaded map having no round HUD, no round controller, and no zombies.
- In-game result: Nuketown restored into a live saved round successfully.

## 0.2.4 — 2026-10-24

- Attached Resume after private-lobby construction to avoid stock/custom menu
  scripts that cache or replace `PopulateButtons_Project_Zombie`.
- Added compatibility behavior for installed custom pause-menu variants.

## 0.2.3 — 2026-10-24

- Improved Resume visibility by using persisted checkpoint metadata instead of
  relying only on inconsistent frontend `ui_mapname` state.
- Continued iterative work on positioning Resume in the stock lobby.

## 0.2.2 — 2026-10-24

- Replaced the rejected legacy file API with Plutonium's supported `fs_*` API:
  `fs_fopen`, `fs_writeline`, `fs_readline`, `fs_fclose`, and `fs_testfile`.
- Fixed the in-game **Checkpoint file could not be opened** failure.
- In-game result: checkpoint save completed and exited to the lobby.

## 0.2.1 and earlier — prototype

- Created the initial solo Nuketown checkpoint serializer.
- Added legacy F5/F6/F8/F9 diagnostics.
- Added player, inventory, perk, common persistent-flag, and Nuketown
  perk-machine state.
- Added early pause-menu **SAVE & EXIT** and lobby Resume experiments.
- Used a legacy file API that was later found incompatible with current
  Plutonium builds.

### 2026-10-28 — Publish source repository and shareable release

- Request: create a GitHub repository, upload the project and final distributable,
  and record the rule for updating future releases on request.
- Change or investigation: created public `PourquoiPasMoi/zm-checkpoint`, pushed
  the source and project docs to `main`, added a no-license notice (no general
  reuse license selected), and documented the owner-requested release update
  workflow in `AGENTS.md`. Published `0.4.2-alpha` with the complete standalone
  mod-folder ZIP as the release asset.
- Files affected: repository initialization; README.md, AGENTS.md,
  LICENSE-NOTICE.md; release ZIP `dist/zm_checkpoint-0.4.2-alpha.zip`.
- Validation: confirmed release/tag and downloadable asset via GitHub CLI;
  local ZIP generated from the complete `dist/zm_checkpoint` contents, which
  excludes `.sav` files and `scriptdata`.
- In-game result: Not applicable; publication only.
- Remaining risk/next step: source is public; ask before applying a different
  reuse license because none has been chosen. Future release updates are
  documented and will be made when requested.
### 2026-10-28 — Fix updater menu package installation

- Request: investigate why the user could not see the update entry in-game.
- Change or investigation: confirmed installed `zz_zm_checkpoint.iwd` lacked the
  new main-lobby hook. `Build.ps1` staged sources but incorrectly moved the
  temporary ZIP onto the `.iwd` path only when the target already existed; the
  packaging sequence did not ensure the correct archive reached the standalone
  install. Fixed the build to copy and replace the IWD explicitly, and included
  the mainlobby hook in the archive. Rebuilt and reinstalled 0.4.3-alpha.
- Files affected: `tools/Build.ps1`, `src/ui/ui/t6/menus/mainlobby.lua`,
  `src/ui/ui/t6/menus/zmcheckpointmenu.lua`,
  `src/ui/ui/t6/menus/zmcheckpointupdater.lua`, companion updater scripts,
  generated and installed package.
- Validation: PowerShell parser checks passed. Inspected built and installed
  IWD entries; both include `ui/t6/mainlobby.lua` with the CHECK FOR UPDATES
  action. Build/install completed. The user had observed no menu entry before
  this correction. Existing save files were not modified by the installer.
- In-game result: Awaiting user confirmation after unload/reload of the mod.
- Remaining risk/next step: fully unload/reload the selected mod to clear LUI
  cache, then inspect Zombies main menu. The entry only appears when `fs_game`
  equals `mods/zm_checkpoint`; companion-loaded total conversion mods will not
  show it yet. The T6 UI opens an updater information popup; Windows updater
  still must be started manually because the game offers no supported process
  launch API. Latest local package: `dist/zm_checkpoint-0.4.3-alpha.zip`.
### 2026-10-28 — Fit updater popup text to its panel

- Request: inspect screenshots showing the update entry and its popup after click.
- Change or investigation: screenshot 2 confirms the entry appears below Mods;
  screenshot 1 shows the long default-font message spilling below the small
  popup. Replaced it with a normal large popup and a separate condensed-font
  status/body layout sized to stay inside the panel.
- Files affected: `src/ui/ui/t6/menus/zmcheckpointupdater.lua`, rebuilt and
  installed `zz_zm_checkpoint.iwd`, and `dist/zm_checkpoint-0.4.3-alpha.zip`.
- Validation: all Lua sources parsed; inspected the rebuilt popup source in the
  IWD; installer completed; pre/post standalone save hashes matched.
- In-game result: Not yet tested; screenshots verified the old overflow and the
  main-menu entry's visibility.
- Remaining risk/next step: unload/reload ZM Checkpoint and verify the popup
  layout in-game. The updater must still be launched manually from Windows.
- Additional validation: isolated synthetic console-log marker launched a
  harmless companion through the watcher. This does not prove the T6 button
  writes the marker in-game.
- Corrected the post-install prompt to ask for manual unload/reload; the prior
  Yes/No wording implied an action the Windows companion could not perform
  safely. Rebuilt and reinstalled the package after this correction.
### 2026-10-28 — Fix blank updater terminal and missing result

- Request: the in-game update button opened a blank PowerShell terminal that
  stayed running, with no "up to date" message.
- Change or investigation: user screenshots show the standalone
  `mods/zm_checkpoint` main menu; `storage/t6/main/console_zm.log` contained
  `Unknown command "echo"`. The old menu sent `echo`, so the watcher never saw
  its marker, and the scheduled watcher itself had a visible console. Switched
  to a unique intentionally unknown command that T6 logs, made the scheduled
  watcher start through a hidden WScript wrapper, changed the check-only script
  from `exit` to `return`, and made the window show an error dialog on failure.
- Files affected: updater Lua; watcher, updater and bridge installer scripts;
  new `Launch-UpdateBridge.vbs`; Build.ps1; installed IWD and companion files.
- Validation: modified Lua and PowerShell parsed; Build/Install completed;
  before/after checkpoint hashes matched. The Windows PowerShell 5.1 script
  returned `UP_TO_DATE|0.4.3-alpha` and control returned to its caller. An
  isolated synthetic `Unknown command "zmcp_update_request_20261028"` log line
  launched the companion successfully. Updated bridge task is running.
- In-game result: **Verified in-game failure:** old button produced no result
  and left a blank terminal; exact loaded mod `mods/zm_checkpoint`, main menu.
  Corrected button-to-dialog behavior: Not yet tested in-game.
- Remaining risk/next step: unload/reload the mod to refresh LUI, click CHECK
  FOR UPDATES and confirm the small Windows "up to date" dialog appears and
  dismisses cleanly. The old blank terminal can be closed; the new watcher
  should remain hidden. Local 0.4.3 build remains unpublished.
## 0.4.7-alpha — 2026-10-28

### 2026-10-28 — Smaller, clearer updater text for download test

- Request: improve the oversized, soft-looking updater text and publish a new
  GitHub release without changing the locally installed mod.
- Change or investigation: T6 scales UIText by its layout height; the body
  occupied 74 UI units. Reduced body/status heights to 28, switched the body
  to the normal font, shortened checking/install text, and bumped the version.
- Files affected: updater Lua, mod.json, README.md, PROJECT_HANDOFF.md,
  CHANGELOG.md, built release package.
- Validation: modified Lua and all six generated GSC scripts parsed; Build.ps1
  completed; release ZIP contains mod.json and IWD with no scriptdata or saves.
  Every installed 0.4.6 file matched its baseline hash after packaging.
  GitHub release 0.4.7-alpha published with the ZIP asset. The installed
  0.4.6 updater returned `UPDATE_AVAILABLE|0.4.6-alpha|0.4.7-alpha`; every
  installed file still matched its pre-publication hash.
- In-game result: **Verified in-game:** 0.4.6 body text was oversized and
  nearly overlapped disabled buttons. 0.4.7 appearance: Not yet tested.
- Remaining risk/next step: test the in-game download/install from local
  0.4.6-alpha to published 0.4.7-alpha. No local install was performed.

## 0.4.6-alpha — 2026-10-28

### 2026-10-28 — Move update confirmation into the game

- Request: replace the external Windows Yes/No update prompt with an in-game
  choice, as the status result already appears in the panel.
- Change or investigation: added INSTALL UPDATE and NOT NOW buttons to the
  updater panel. The Install action emits a second console-log marker; the
  background companion downloads and installs without opening a Windows
  prompt, and status moves through installing to installed in the game.
- Files affected: updater Lua, watcher/status/window scripts, mod.json,
  README.md, PROJECT_HANDOFF.md, CHANGELOG.md, generated/local install.
- Validation: modified Lua and PowerShell parsed; Build/Install completed;
  installed companion reported `up_to_date|0.4.6-alpha`; save hashes matched
  before/after. Full button-to-install path awaits a newer published release.
- In-game result: **Verified in-game:** prior 0.4.5 update-available panel and
  external prompt appeared in the user screenshot. New in-game buttons:
  Not yet tested.
- Remaining risk/next step: unload/reload the mod and inspect the updated
  panel. Publish a later version separately to test Install and Not Now.
  Current GitHub release is 0.4.5-alpha.

## 0.4.5-alpha — 2026-10-28

### 2026-10-28 — Publish a small updater test release

- Request: make a small visible change and publish it to GitHub without
  installing it on the current PC, so the in-game update flow can be tested.
- Change or investigation: shorten the up-to-date panel text to "Latest
  version installed" and "Installed: <version>"; bump package version.
- Files affected: updater Lua, mod.json, README.md, PROJECT_HANDOFF.md,
  CHANGELOG.md, built package and GitHub release.
- Validation: modified Lua and all six generated GSC scripts parsed; Build.ps1
  completed; release ZIP contains mod.json and IWD, with no scriptdata or
  checkpoint files. Every installed 0.4.4 file matched its baseline hash after
  packaging. GitHub release 0.4.5-alpha published with the ZIP asset. The installed
  0.4.4 updater returned `UPDATE_AVAILABLE|0.4.4-alpha|0.4.5-alpha`; every
  installed file still matched its pre-publication hash.
- In-game result: **Verified in-game:** 0.4.4-alpha displayed the up-to-date
  status. 0.4.5 download/install path: Not yet tested.
- Remaining risk/next step: test the in-game download/install from local
  0.4.4-alpha to published 0.4.5-alpha. No local install was performed.

## 0.4.4-alpha — 2026-10-28

### 2026-10-28 — Show update result inside the game

- Request: replace the Windows "up to date" popup with a result in the existing
  ZM Checkpoint updater panel.
- Change or investigation: the Windows companion writes `zmcp_update_status.cfg`
  to both T6 `main` and the standalone mod folder. The game panel polls it with
  the normal `exec` command and updates its status to latest version, update
  available, installed, or error. The Windows check no longer shows a dialog
  when already up to date; the Yes/No install prompt remains for an available
  update. The watcher sets checking before starting the check.
- Files affected: updater Lua, status/window/watcher scripts, Build.ps1,
  mod.json, README.md, PROJECT_HANDOFF.md, CHANGELOG.md; local package/install.
- Validation: modified Lua and PowerShell parsed; Build/Install completed;
  direct installed Windows companion wrote `up_to_date` and `0.4.4-alpha` to the
  status CFG; existing save hashes matched before/after. Scheduled bridge
  restarted. The game-side `exec` status refresh still needs an in-game check.
- In-game result: Not yet tested for the new panel status. The previous
  click-to-Windows dialog was verified by the user.
- Remaining risk/next step: unload/reload mod, click CHECK FOR UPDATES, verify
  the panel changes from Checking to latest-version text and no Windows dialog
  appears. Local 0.4.4-alpha is newer than the published 0.4.2-alpha release.

