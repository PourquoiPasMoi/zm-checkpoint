# Mandatory Project Rules for All Agents

These rules apply to every agent working anywhere in this project tree.

## 1. Read the project memory before changing anything

At the beginning of every new task:

1. Read `PROJECT_HANDOFF.md` completely.
2. Read `CHANGELOG.md` completely.
3. Read the relevant sections of `README.md` and the source files involved.
4. Inspect the current installed state when the task concerns in-game behavior.

Do not repeat an approach already documented as failed unless new evidence shows
why the result should be different. If retrying one, explicitly record the new
evidence and outcome.

## 2. Keep the project memory current

After every meaningful action, update the documentation before declaring the
task complete. A meaningful action includes:

- fixing a problem;
- finding the cause of a problem;
- adding or changing a feature;
- changing save-format, GSC, Lua, menu, build, or installer behavior;
- installing or packaging a new version;
- completing an in-game test;
- discovering a failed approach, regression, compatibility issue, or limitation;
- changing the recommended next step.

Update both files as appropriate:

- `CHANGELOG.md`: concise chronological record of what changed and the result.
- `PROJECT_HANDOFF.md`: current truth—architecture, status, tested behavior,
  limitations, troubleshooting lessons, installed state, and next steps.

Also update `README.md` when user-facing setup, controls, behavior, compatibility,
or limitations change.

Documentation updates are part of the implementation, not optional follow-up
work. Do not say a task is finished until these updates are made.

## 3. Record failures as useful evidence

When an attempt fails, preserve a short entry containing:

- date and version/build;
- exact map and loaded mod;
- what was attempted;
- visible symptom and relevant log/error text;
- root cause, if known;
- files or functions involved;
- whether the attempt was reverted, replaced, or remains unresolved;
- the lesson or rule that should guide future work.

Never erase a useful failure from the history merely because a later solution
works. Condense it if necessary, but keep the lesson.

## 4. Separate facts from assumptions

Use these labels in documentation and reports when relevant:

- **Verified in-game:** personally observed by the user or captured in evidence.
- **Validated statically:** parser/build/package inspection passed, but not yet
  exercised in the game.
- **Expected:** reasoned from source or engine behavior and still needs testing.
- **Known limitation:** intentionally unsupported or confirmed incomplete.

Do not describe a feature as working on a map merely because it compiled or was
installed. The five maps added in 0.3.0 remain unverified in-game until their
test results are recorded.

## 5. Preserve the known-good behavior

- Build/install/maintenance actions must not delete or overwrite checkpoint files
  under any `scriptdata` directory. Runtime GSC may deliberately invalidate a
  successfully resumed checkpoint as part of the documented one-use lifecycle.
- Preserve the proven Nuketown Save & Exit and Resume workflow.
- Preserve Resume through `set zmcp_autoload 1` followed by `xpartygo`.
- Do not launch Resume through raw `map <name>`; that previously caused a loaded
  map with no round controller, round HUD, or zombie spawning.
- Preserve checkpoint validation, format version checks, map checks, and the
  final `END` record.
- Do not remove the solo-player guard until multiplayer state synchronization is
  deliberately designed and tested.
- Keep Nuketown-specific behavior conditional or in a dedicated adapter.
- Do not replace unrelated archives or files belonging to other mods.
- Do not close or restart Plutonium automatically; tell the user when it is
  required.

## 6. Validate every change proportionally

For source changes, perform the applicable checks before handoff:

- Parse GSC with the bundled T6 `gsc-tool`.
- Parse every modified Lua file.
- Parse modified PowerShell scripts.
- Run `tools\Build.ps1` after package-affecting changes.
- Run `tools\Install.ps1` when the user asked to install or when a test build must
  reach Plutonium.
- Inspect the resulting IWD and installed map-script coverage.
- Confirm existing checkpoint files remain intact.
- Clearly distinguish static validation from an actual in-game test.

Record important validation results in `PROJECT_HANDOFF.md` and the current
version entry in `CHANGELOG.md`.

## 7. Maintain a reproducible work log

For each work session, append or update a dated entry in the appropriate version
section of `CHANGELOG.md` using this compact structure:

```text
### YYYY-MM-DD — Short title

- Request:
- Change or investigation:
- Files affected:
- Validation:
- In-game result:
- Remaining risk/next step:
```

Use `In-game result: Not yet tested` when applicable. Never silently treat a
static parser or successful install as proof of correct gameplay.

## 8. End-of-task checklist

Before the final response, confirm:

- [ ] The implementation or investigation is complete for the requested scope.
- [ ] Relevant parsers/build checks passed, or failures are documented.
- [ ] Existing saves were preserved.
- [ ] `CHANGELOG.md` records this session.
- [ ] `PROJECT_HANDOFF.md` reflects the current truth and next step.
- [ ] `README.md` was updated if user-facing behavior changed.
- [ ] The user is told whether a Plutonium/mod restart is required.
- [ ] Claims clearly distinguish installed, statically validated, and verified
      in-game behavior.

## Publishing updates

When the project owner asks to update the GitHub release, build the current
shareable package with `tools/Build.ps1`, inspect that it contains the complete
`dist/zm_checkpoint` folder and no checkpoint saves, and publish the folder
contents as a ZIP release asset. Update the GitHub repository source first,
then create or update the matching version tag/release and attach the ZIP. Keep
the release version aligned with `mod.json`; update the README release link and
record the publication in `CHANGELOG.md` and `PROJECT_HANDOFF.md`. Never include
`.cache`, `.tools`, installed game data, or `scriptdata` checkpoint files.
