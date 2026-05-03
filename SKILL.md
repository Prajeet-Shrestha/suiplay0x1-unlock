---
name: suiplay0x1-unlock
description: |
  Walk a user through unlocking their SuiPlay0x1 (Playtron GameOS handheld)
  and turning it into a full KDE Plasma Linux desktop using the gameos-unlock
  toolchain. Covers SSH setup, passwordless sudo, bootc desktop image build,
  InputPlumber touch fix, Flatpak app installs, mode switching, and rollback.
  TRIGGER when the user mentions: SuiPlay0x1, Playtron GameOS, gameos-unlock,
  unlocking a handheld with bootc, "KDE on my handheld", or asks how to
  install Steam/Chrome/RetroArch on a Playtron device.
  SKIP when the user is asking about a Steam Deck, ROG Ally, Legion Go, or
  generic Linux desktop install — this skill is specific to Playtron GameOS.
  Note: InputPlumber issues alone are NOT a trigger (Steam Deck also uses
  InputPlumber); only trigger on InputPlumber + Playtron context together.
user-invocable: true
argument-hint: "[topic — e.g. 'ssh setup', 'flatpak install', 'touch fix']"
allowed-tools:
  - Read
---

# SuiPlay0x1 Unlock — Claude Code entry point

This is the Claude Code wrapper. The full agent-agnostic playbook is in [`AGENTS.md`](AGENTS.md) at the repo root — read that for the complete walkthrough.

When this skill triggers (or when invoked as `/suiplay0x1-unlock <topic>`):

1. **Read [`AGENTS.md`](AGENTS.md)** — it has the orientation, the 5 unlock steps, the InputPlumber touch fix, the guardrails ("things NOT to do"), and topic shortcuts.
2. **Then read the relevant `references/` file** based on what the user is asking:
   - Full walkthrough → [`references/walkthrough.md`](references/walkthrough.md)
   - Daily-ops commands → [`references/commands.md`](references/commands.md)
   - Errors / gotchas → [`references/troubleshooting.md`](references/troubleshooting.md)
   - Flatpak app installs → [`references/flatpak-recipes.md`](references/flatpak-recipes.md)

## Slash invocation

If invoked as `/suiplay0x1-unlock <topic>`, jump straight to the matching section in `AGENTS.md` "Topic shortcuts" — `ssh setup`, `sudo`, `build`, `touch fix`, `flatpak install`, `mode switch`, `rollback`, `troubleshoot`.

## Hard rules (also in AGENTS.md but emphasized here)

This is **guide-only**. Never execute `ssh`, `scp`, `sudo`, `bootc`, or `podman` yourself — instruct the user to run commands on their own laptop.

Never suggest `systemctl stop inputplumber` (kills all input). Never tell the user to overwrite `~/.ssh/id_ed25519` blindly. Never run `podman build .` over SSH from the device's home (the buggy `tutorial.md` advice). Full guardrails in [`AGENTS.md`](AGENTS.md) §"Things NOT to do".
