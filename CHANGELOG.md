# Changelog

All notable ZM Checkpoint changes and important test results are recorded here.
The package is experimental, so versions before a stable release use alpha
semantics.

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

