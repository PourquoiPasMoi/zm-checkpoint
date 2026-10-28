# Host-stored co-op checkpoints — 0.4.0-alpha

Status: first two-PC Nuketown test reached the save button but the team-readiness
guard rejected it. The 0.4.11 candidate removes the unproven pause handshake
as a save/restore blocker; a new two-PC test is required.

## How to try it

1. Both players install the same current package and load ZM Checkpoint. Reload
   the mod or restart Plutonium yourself after installation. Do not replace any
   scriptdata folder. For a friend's standalone installation, extract the
   package contents to `%LOCALAPPDATA%\Plutonium\storage\t6\mods\zm_checkpoint`.
2. The intended host creates a private Nuketown Classic lobby. Join with the
   second account and start normally. Set `developer 1` before launch for logs.
3. Both players should verify that ZM Checkpoint is loaded. Opening pause can
   still send a diagnostic UI signal, but it is not required for saving.
4. At round 2 or 3, record different weapons/ammo, points, perks and positions
   for each player. Keep everyone alive, out of last stand and spectating.
5. Only the host selects SAVE & EXIT. Expect `Team checkpoint saved` and a
   return to the lobby. All player state is on the host PC; guests need no save.
6. Open CO-OP RESUME in the private lobby. Select the same map, mode, start
   location, mod, difficulty, magic and headshots settings. Reconnect the exact
   accounts. The original host must host. The page refreshes every half second.
7. Press RESUME TEAM CHECKPOINT. Loading uses xpartygo. The round is held
   while IDs and readiness are checked.
   There is a 120-second team wait and 150-second overall restoration timeout.
8. Verify all player states, opened paths, active round HUD, zombie spawning,
   and multiplayer zombie counts. Then save again and repeat. Confirm that a
   successfully consumed checkpoint cannot be resumed after death/relaunch.

The page displays connected names and missing account IDs. Names are not keys.
Online account ID stability and Lua/GSC ID equivalence require this real test.
LAN username-derived identities are weaker; this is not proof of account
ownership in LAN mode. IDs are compared as normalized hex strings, never floats.

## Required negative tests

- Guest presses Save & Exit: rejected by host-side authorization.
- Missing player, extra player, same count with a replacement, duplicate ID:
  Resume stays locked. Same players joining in a different order: allowed.
- Another host, another mod, another mode/location or recorded setting: locked.
- Display-name change with the same authenticated ID: should remain eligible.
- Player disconnects during load/restore: return to lobby without consuming.
- Client does not open pause: save and restore still rely on exact valid account
  IDs and all players being alive. Check that a missing mod still gets reported
  as a compatibility limitation rather than an identity mismatch.
- Wrong/stale lobby metadata or manual co-op autoload: server still checks file,
  host, exact roster and context; does not fall back to a fresh playable run.
- Incomplete newest generation: reader retains the earlier complete generation.
- Failed consumption receipt: fail closed; do not claim the run resumed.

Do file-failure tests only on a disposable copy/test mod. Never edit real saves
to test corruption. Preserve exact logs, map/mode/location, package versions,
host/player IDs, party order, and observed before/after inventory for failures.

## Storage and boundaries

- Separate `zm_checkpoint_coop_<map>_a.sav` and `_b.sav` files alternate. Each
  is a full `COOP,1,<map>` snapshot with host, exact roster, settings, generation,
  member-delimited inventory, shared world state, and final END. The older
  complete file remains while the next generation is written and reread.
- `_used.sav` records the consumed generation. Older generations cannot bypass
  this receipt. A damaged receipt deliberately locks Resume and needs manual
  investigation; the full snapshots remain available. This is not an OS-level
  atomic transaction or protection against deliberate editing of local files.
- One active co-op checkpoint per physical map per loaded host mod. A successful
  new save replaces the offered co-op run for that map. Solo format-3 slots are
  untouched and retain their original one-player save/restore path.
- 2–4 players, Classic/Survival, listen host only. Dedicated servers, split-screen
  identity, host migration, competitive modes, and custom round-controller
  replacements are not supported. Every player must have the matching UI.
- Current implementation captures common player/world state, Nuketown machines,
  and Buried Arthur. Co-op quest milestones and character assignments are not
  serialized. All existing map-specific exclusions remain: bus, elevators,
  afterlife, staffs/generators, full Easter eggs, etc. No map is co-op verified.
- Round restarts at its beginning. Normal round-start effects may adjust ammo
  (including stock grenade replenishment); these need observation in testing.
- The server owns state and authorization. The optional UI handshake is only
  diagnostic, not proof of client files. The host cannot establish from this
  signal that a guest has identical mod files. Local host save edits are
  outside the ownership guarantee.

## Static evidence and checks

- Stock GSC reference commit `d02a9efd4382689180aaadcb609452babf5dc4c8`:
  `_globallogic_player.gsc` uses getguid/getxuid/ishost; `_zm.gsc` supplies the
  initial_blackscreen_passed flag and round_think startup path.
- Lua reference `Yallamaztar/T6-Modding-Resources` at
  `f7e3861e0c90e78f9e0b41886a3503f31c58a1b2`: lobbyplayerlists.lua uses
  Engine.GetPlayersInLobby; splitscreengamelobby.lua supplies string XUIDs;
  privategamelobby.lua checks GameHost; codbase.lua implements isPartyHost.
  Static source evidence is not a runtime API guarantee.
- `tools/Test-CoopLobby.lua` executes the shipped Lua gate with engine mocks,
  checking exact roster, order/name changes, 64-bit strings, host/context
  mismatches, missing APIs and the launch action. GSC requires actual game tests.
