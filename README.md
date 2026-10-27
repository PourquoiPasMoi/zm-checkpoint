# ZM Checkpoint

Experimental save and resume checkpoints for Call of Duty: Black Ops II Zombies on Plutonium T6.

The current shareable build is available from the [Releases page](https://github.com/PourquoiPasMoi/zm-checkpoint/releases). Download `zm_checkpoint-0.4.7-alpha.zip` from release **0.4.7-alpha** and extract its contents into a `zm_checkpoint` folder in your Plutonium T6 `mods` directory. The package is experimental; check the release notes and [README](README.md) for supported behavior and known limits.

The source, build scripts, test guidance, and project history are in this repository. The user-facing setup and feature details live in [README.md](README.md); contributors should read [AGENTS.md](AGENTS.md) and [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md) first.

## In-game update bridge (local 0.4.3-alpha)

On Windows, the installed **CHECK FOR UPDATES** button now sends a request to a
small background companion. The project installer registers the companion for
this Windows user at sign-in and starts it immediately. It watches the Plutonium
Zombies console log; pressing the button opens the Windows updater prompt. The
updater compares the installed version with the newest published GitHub release,
verifies the downloaded ZIP's published SHA-256 when available, and copies only
package files into `mods/zm_checkpoint`. It does not touch `scriptdata` saves.

The menu bridge is installed and statically validated; the complete button-to-
Windows flow still needs an in-game click test. If no window appears, check that
`ZM Checkpoint Update Bridge` is running in Windows Task Scheduler and that
`console_zm.log` under Plutonium `storage/t6/main` contains the request marker.
The release page currently holds 0.4.2-alpha; this local 0.4.3-alpha build has
not been published yet. Unload and reload the mod after an IWD update.
The first in-game update check revealed a Plutonium T6 limitation: `echo` is an
unknown command, so the old console-log signal failed and left a visible watcher
terminal. The installed bridge now emits `zmcp_update_request_20261028`, which
is intentionally logged as an unknown command, and runs the watcher hidden.
After reloading the mod, pressing **CHECK FOR UPDATES** should show a small
Windows status dialog. The corrected in-game flow still needs confirmation.
With local **0.4.4-alpha**, CHECK FOR UPDATES shows the result in the in-game
updater panel. For an up-to-date check, the Windows companion no longer opens a
dialog. It writes a small status config that the game panel reads. When an update
is available, the Windows Yes/No download prompt still appears. Reload the mod
to load the new menu; the in-game status display awaits confirmation.

Version **0.4.5-alpha** shortens the in-game "latest version" message. It is a
small visible update for checking that the in-game updater can download and
install a newer release. The original test PC deliberately remains on
0.4.4-alpha until the in-game update is run; the new release still needs that
end-to-end test.

Local **0.4.6-alpha** moves the update decision into the in-game updater panel.
When a newer GitHub release is found, choose **INSTALL UPDATE** or **NOT NOW**
there. Installation progress and the reload instruction appear in the same
panel. The Windows companion still performs the download and file copy in the
background; no Windows confirmation dialog is used. This panel flow is built
and installed locally but needs an in-game test with a newer release.

Version **0.4.7-alpha** uses smaller normal-sized updater text, with shorter
messages so the words stay clear and do not overlap the in-game action buttons.
The original test PC remains on 0.4.6-alpha until the user downloads this
release through CHECK FOR UPDATES; this change has not yet been tested in-game.
