# suiplay0x1-unlock

A cross-tool **AI agent playbook** that walks **SuiPlay0x1** owners through unlocking their device — turning the stock Playtron GameOS handheld into a full KDE Plasma Linux desktop.

Works with any AI coding agent that reads project instruction files: **Claude Code**, **OpenAI Codex**, **Cursor**, **Aider**, **GitHub Copilot**, **Antigravity**, and any [`AGENTS.md`](https://agents.md/)-aware tool.

> ⚡ **One-liner install** (any supported agent): `npx skills add Prajeet-Shrestha/suiplay0x1-unlock-skill` — via [skills.sh](https://skills.sh), supports Claude Code, Codex, Cursor, OpenCode, Copilot, and 50+ more.

The agent guides you step-by-step through the 5-phase unlock (SSH → sudo → image build → switch → desktop launcher), including the gotchas the official `tutorial.md` leaves out.

## What it covers

- SSH key setup from your laptop to the device
- Passwordless sudo for the `playtron` user
- Building a custom bootc desktop image with KDE Plasma
- The `tutorial.md` build-command bug (and the right sequence)
- The InputPlumber touch-input race fix (one-time + permanent autostart)
- Flatpak app installs (Steam, Chrome, RetroArch, Heroic, Discord, …)
- Mode switching (Game Mode ↔ Desktop Mode)
- Bootc rollback if anything breaks
- Daily-ops command reference

It's **guide-only** — the agent tells you what to run; you run the commands on your own laptop and device. The agent never executes `ssh`, `scp`, `sudo`, or `podman` itself.

## Install

The canonical playbook is [`AGENTS.md`](AGENTS.md) at the repo root. Two install paths — pick whichever fits your setup.

### Path 1 (recommended) — one-liner via [skills.sh](https://skills.sh)

`skills.sh` is a community CLI that installs skills into the right directory for **whatever agent you're using** — no account, no auth, no manual file shuffling.

**Auto-detect your agent:**
```bash
npx skills add Prajeet-Shrestha/suiplay0x1-unlock-skill
```

**Or target specific agents** (see [supported agents](https://skills.sh/agents)):
```bash
# Claude Code
npx skills add Prajeet-Shrestha/suiplay0x1-unlock-skill -a claude-code

# OpenAI Codex
npx skills add Prajeet-Shrestha/suiplay0x1-unlock-skill -a codex

# Cursor
npx skills add Prajeet-Shrestha/suiplay0x1-unlock-skill -a cursor

# OpenCode
npx skills add Prajeet-Shrestha/suiplay0x1-unlock-skill -a opencode

# GitHub Copilot
npx skills add Prajeet-Shrestha/suiplay0x1-unlock-skill -a copilot

# Multiple at once
npx skills add Prajeet-Shrestha/suiplay0x1-unlock-skill -a claude-code -a codex -a cursor
```

By default `npx skills add` symlinks files into the agent's skills directory (`~/.claude/skills/`, `~/.codex/skills/`, `~/.cursor/skills/`, etc.). Pass `--copy` to copy instead, or omit `-a` and pass a project path to install at project scope (`./.agents/skills/`).

After install, restart your agent / IDE so it picks up the new skill.

### Path 2 — manual (no Node required)

If you don't want to use `npx`, clone the repo and wire it up directly for your tool:

#### Claude Code
```bash
mkdir -p ~/.claude/skills
git clone https://github.com/Prajeet-Shrestha/suiplay0x1-unlock-skill ~/.claude/skills/suiplay0x1-unlock
```

#### Codex / Aider / any AGENTS.md-aware tool
```bash
git clone https://github.com/Prajeet-Shrestha/suiplay0x1-unlock-skill
cd suiplay0x1-unlock-skill
codex   # or: aider --read AGENTS.md --read references/walkthrough.md
```

Most agentic tools (Codex, Aider, Antigravity, etc.) auto-detect `AGENTS.md` when you open the repo as a workspace.

#### Cursor (project rule)
```bash
git clone https://github.com/Prajeet-Shrestha/suiplay0x1-unlock-skill /tmp/skill
mkdir -p .cursor/rules
ln -s /tmp/skill/AGENTS.md .cursor/rules/suiplay0x1-unlock.mdc
```

#### GitHub Copilot (project instructions)
```bash
git clone https://github.com/Prajeet-Shrestha/suiplay0x1-unlock-skill /tmp/skill
mkdir -p .github
cp /tmp/skill/AGENTS.md .github/copilot-instructions.md
```

#### Plain fallback — paste into chat
If your AI tool doesn't read `AGENTS.md` automatically, paste [`AGENTS.md`](AGENTS.md) into the chat or attach the repo. Any model with a long-enough context window can follow the playbook.

After any of these, restart Claude Code / your agent so it loads the playbook.

## Use it

Once your tool has loaded the playbook, type something like:

- *"I just got a SuiPlay0x1 — how do I unlock it?"*
- *"My SuiPlay0x1 touchscreen stopped working in KDE"*
- *"How do I install Steam on my Playtron handheld?"*

The agent reads `AGENTS.md` and the relevant `references/*.md` and walks you through.

In **Claude Code** (or any agent that supports slash-invocable skills), you can also invoke it explicitly:

```
/suiplay0x1-unlock ssh setup
/suiplay0x1-unlock flatpak install
/suiplay0x1-unlock touch fix
```

## Repo contents

| File | Purpose |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Canonical agent-agnostic playbook — the source of truth |
| [`SKILL.md`](SKILL.md) | Claude Code wrapper — frontmatter + delegation to AGENTS.md |
| [`references/walkthrough.md`](references/walkthrough.md) | Full 9-part walkthrough of the unlock |
| [`references/commands.md`](references/commands.md) | Daily-ops cheat sheet (reboot, rollback, mode-switch, etc.) |
| [`references/troubleshooting.md`](references/troubleshooting.md) | Every issue we've seen, with cause + fix |
| [`references/flatpak-recipes.md`](references/flatpak-recipes.md) | Common app install one-liners |
| [`scripts/install-fix-inputplumber.sh`](scripts/install-fix-inputplumber.sh) | One-shot installer for the KDE autostart input fix |
| [`scripts/fix-inputplumber.sh`](scripts/fix-inputplumber.sh) | The autostart script body |
| [`scripts/fix-inputplumber.desktop`](scripts/fix-inputplumber.desktop) | KDE autostart entry |

## Credits

This playbook is a wrapper around the work of **[Luke Short](https://github.com/LukeShortCloud)** ([@LukeShortCloud](https://github.com/LukeShortCloud)), VP of Linux Engineering at Playtron. His [`gameos-unlock`](https://github.com/LukeShortCloud/gameos-unlock) script does the actual heavy lifting — the bootc image build, the desktop-mode installer, the Flatpak wrapper. **None of this would exist without his work.** This repo simply teaches AI agents how to walk a user through running it cleanly.

Also credits the broader **Playtron team** who built GameOS itself:

- Alesh Slovak ([@alkazar](https://github.com/alkazar))
- William Edwards ([@ShadowApex](https://github.com/ShadowApex))
- Mathieu Comandon ([@strycore](https://github.com/strycore))
- Paweł Lidwin ([@imLinguin](https://github.com/imLinguin))
- ptitSeb ([@ptitSeb](https://github.com/ptitSeb))
- Brian Budge ([@codename-irvin](https://github.com/codename-irvin))

And the **bootc** project, the immutable-image OS framework that makes the whole approach possible.

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE). Matches the upstream `gameos-unlock` license.

## Disclaimer

This is a community playbook, not an official Playtron product. Unlocking your device is supported by Playtron (the Containerfile and tooling come from a Playtron VP), but mistakes are yours to undo. Bootc's rollback slot is your safety net — see [`references/troubleshooting.md`](references/troubleshooting.md) for recovery if anything goes sideways.
