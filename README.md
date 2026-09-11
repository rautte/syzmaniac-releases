# SyzManiac — prebuilt releases

This repo holds SyzManiac's published binaries only. The source code is
private; this is where anyone can get a working copy without needing
access to it.

## Install (one command)

```sh
curl -fsSL https://raw.githubusercontent.com/rautte/syzmaniac-releases/main/install.sh | bash
```

This detects your OS/architecture, downloads the matching release, verifies
it against the published checksum, and installs `syz` to `~/.local/bin`
(no `sudo`, nothing system-wide). If that directory isn't already on your
PATH, the script tells you the exact line to add to your shell config.

Then check it worked:

```sh
syz --version
```

## Get the GUI (macOS)

Once you have `syz`, one more command installs the desktop app:

```sh
syz gui update
```

This downloads the latest GUI build, installs it to
`/Applications/syzmaniac-gui.app`, and automatically clears macOS's
Gatekeeper quarantine flag — the app isn't signed with an Apple Developer
ID or notarized yet (an early-rollout tradeoff, not a sign anything's
wrong), so without this step macOS would otherwise block it on first open.

```sh
open /Applications/syzmaniac-gui.app
```

## Staying up to date

From then on, updating either one is a single command, any time:

```sh
syz self-update   # updates the CLI
syz gui update    # updates the GUI app
```

Or, from inside the GUI itself: the **Account & Sync** tab has a
"Command-line tool (syz)" panel that can install/update the CLI for you
with one click — including the very first time, before `syz` exists on
the machine at all.

## Manual download

Prefer to do it by hand? Every release page has the raw archives:

- **CLI**: `syz_<version>_<os>_<arch>.tar.gz` for your platform, plus `syz_checksums.txt`.
- **GUI (macOS)**: `syzmaniac-gui_<version>_macos.zip` — includes a
  "Read me before opening.md" with the exact Gatekeeper bypass steps.

See the [latest release](https://github.com/rautte/syzmaniac-releases/releases/latest).
