# ZM Checkpoint

Experimental save and resume checkpoints for Call of Duty: Black Ops II Zombies on Plutonium T6.

The current shareable build is available from the [Releases page](https://github.com/PourquoiPasMoi/zm-checkpoint/releases). Download `zm_checkpoint-0.4.11-alpha.zip` from release **0.4.11-alpha** and extract its contents into a `zm_checkpoint` folder in your Plutonium T6 `mods` directory. The package is experimental; check the release notes for supported behavior and known limits.

The source, build scripts, test guidance, and project history are in this repository. The user-facing setup and feature details live in [README.md](README.md); contributors should read [AGENTS.md](AGENTS.md) and [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md) first.

## In-game updates

On Windows, **CHECK FOR UPDATES** sends a request to a background companion. It
checks GitHub and reports the result in the game. When an update is available,
choose **INSTALL UPDATE** or **NOT NOW**. The companion downloads and installs
package files into `mods/zm_checkpoint` and leaves `scriptdata` saves intact.
When already current, **INSTALL UPDATE** and **NOT NOW** are greyed out and
**BACK** is selected. After an update finishes installing from this page, an
**UNLOAD** row appears between NOT NOW and BACK, and the bottom-right **U Unload**
shortcut appears. Both use the game's normal mod-unload action. They remain
hidden until this updater page completes an installation.
Press **R** on the updater page to run a fresh check. Its **R Refresh** prompt
uses the same bottom-right style as the game's Mods menu.
The right-hand **LATEST CHANGES** panel shows the newest GitHub release's
version and a short summary of its release notes. It also appears when the
installed version is already current. Long notes are shortened to fit the
panel; the GitHub release page has the full text.

For co-op checkpoints, the original host and the same two to four player
account IDs must be present and alive. Opening the pause menu on every PC is
no longer required for the readiness check. Both players should still load
the same mod version. The exact team must reconnect before the host can resume.
The expanded Custom Games menu places the map preview on the lower right so
the selected option's description remains visible.

After installation, choose UNLOAD or press U, then load ZM Checkpoint again from
the Mods menu to use the new UI. The updater does not restart Plutonium. If
checks do not complete, confirm that `ZM Checkpoint Update Bridge` is running
in Windows Task Scheduler and inspect `storage/t6/main/console_zm.log` for the
request marker.

The test PC is intentionally left on its currently installed version when new
releases are published. The owner runs the updater to install each release.
