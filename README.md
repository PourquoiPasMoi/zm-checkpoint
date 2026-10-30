# ZM Checkpoint

Experimental save and resume checkpoints for Call of Duty: Black Ops II Zombies on Plutonium T6.

The current shareable build is available from the [Releases page](https://github.com/PourquoiPasMoi/zm-checkpoint/releases/tag/0.4.21-alpha). Download `zm_checkpoint-0.4.21-alpha.zip` and extract its contents into a `zm_checkpoint` folder in your Plutonium T6 `mods` directory. The package is experimental; check the release notes for supported behavior and known limits.

The source, build scripts, test guidance, and project history are in this repository. The user-facing setup and feature details live in [README.md](README.md); contributors should read [AGENTS.md](AGENTS.md) and [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md) first.

## Solo save slots

In a solo match, choose **SAVE & EXIT**, then select one of four slots. An
occupied slot needs a second selection before it is replaced. Slot 1 is the
original per-map checkpoint, so existing solo saves remain available. Slots
2–4 are separate checkpoints for the same map. In the Custom Games lobby,
choose **SOLO RESUME** to select a saved slot. A successful resume consumes
only that slot; the other slots remain available.

The Solo Save and Solo Resume pages show a selected slot's points, weapons,
perks, and match settings. The slot preview now uses real perk artwork bundled
in `mod.ff` and weapon artwork already present in the Zombies front-end. A
weapon without front-end artwork is shown by name. Older saves gain this preview after the new version
loads their map once and reads the checkpoint; the checkpoint file is not
changed by that read. The new slot preview is **validated statically** and
still needs an in-game test.

New solo checkpoints store the lobby's difficulty, Magic, Headshots Only,
Target Assist, and Cheats settings. Resume applies those settings before
launching and checks them again when the map loads. Select the same mode and
start location as the saved match. Older checkpoints without stored settings
remain usable with the lobby's current settings. These new slot and settings
behaviors are **validated statically** and still need an in-game test.

On Nuketown, new checkpoints also record which physical drop site belongs to
each perk machine. Resume restores those assignments before replaying the
arrivals. Checkpoints made before 0.4.14-alpha did not record the assignments,
so their original perk locations cannot be reconstructed. The new placement
restore is **validated statically** and still needs an in-game test.

## In-game updates

On Windows, **CHECK FOR UPDATES** sends a request to a background companion. It
checks GitHub and reports the result in the game. When an update is available,
choose **INSTALL UPDATE** or **NOT NOW**. The companion downloads and installs
package files into `mods/zm_checkpoint` and leaves `scriptdata` saves intact.
Pressing **Esc** on the updater page now asks before leaving. **NO, STAY** is
selected by default. If a download or installation is already running, leaving
the page does not stop it; let it finish, then unload and reload the mod.
When already current, **INSTALL UPDATE** and **NOT NOW** are greyed out and
**BACK** is selected. After an update finishes installing from this page, an
**UNLOAD** row appears between NOT NOW and BACK, and the bottom-right **U Unload**
shortcut appears. Both use the game's normal mod-unload action. They remain
hidden until this updater page completes an installation.
Press **R** on the updater page to run a fresh check. Its **R Refresh** prompt
uses the same bottom-right style as the game's Mods menu.
The right-hand **LATEST CHANGES** panel shows the newest GitHub release's
version and notes. Use **PREV PAGE** and **NEXT PAGE** at the bottom of the
panel to read longer notes. Headings and changes are separated into readable
entries. This panel also appears when the installed version is already current.
The page buttons no longer show descriptions outside the notes panel.
Very long release notes are capped; the GitHub release page has the full text.
If an update check or installation fails, the updater shows a short error reason
so you can retry with **R Refresh**. An installation already in progress is
allowed to finish before another check or install starts.
Each update check has a request ID. The page stays on **Checking for updates**
until the background companion replies to that exact request. An old status
file cannot report **Latest version installed** for a new request. If the
companion is slow, the page continues waiting for that request instead of
showing a premature failure. **R Refresh** can retry a check. Release checks request fresh
GitHub data to reduce stale responses.
Version 0.4.17-alpha fixes request IDs that T6 printed in scientific notation,
which prevented the companion from matching them and left the page waiting.
During installation, the page now identifies the download, unpacking, and
file-copy stages. The companion uses one GitHub release lookup for an install
instead of repeating the check. Network download time can still vary.

For co-op checkpoints, the original host and the same two to four player
account IDs must be present and alive. Opening the pause menu on every PC is
no longer required for the readiness check. Both players should still load
the same mod version. The exact team must reconnect before the host can resume.
The complete team checkpoint exists only on the PC that hosted Save & Exit.
Guests will see no team checkpoint on their own PC; the original host must
open CO-OP RESUME. Lobby account IDs may appear in decimal while saved IDs
appear in hexadecimal; the menu compares both without rounding the 64-bit ID.
This comparison still needs a two-PC in-game test.
If the original host and exact team are shown but Resume remains locked by
game settings, choose **RESTORE SAVED SETTINGS** on CO-OP RESUME. It applies
the saved difficulty, Magic, and Headshots Only values before rechecking the
lobby. A different mode, start location, or loaded mod is identified by name.
The expanded Custom Games menu places the map preview on the lower right so
the selected option's description remains visible.
The stock match-start countdown now appears above that preview, clear of the
expanded settings and Resume rows.

After installation, choose UNLOAD or press U, then load ZM Checkpoint again from
the Mods menu to use the new UI. The updater does not restart Plutonium. If
checks do not complete, confirm that `ZM Checkpoint Update Bridge` is running
in Windows Task Scheduler and inspect `storage/t6/main/console_zm.log` for the
request marker.

The test PC is normally left on its currently installed version when new
releases are published. The owner runs the updater to install each release.
The owner explicitly requested a local 0.4.19-alpha install for the 2026-10-30 investigation.
After installation, unload and reload the mod to apply the updated menu.
