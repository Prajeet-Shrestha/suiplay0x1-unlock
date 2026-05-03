# SuiPlay0x1 Unlock — Agent Playbook

A cross-tool playbook for AI coding agents (Claude Code, Codex, Cursor, Aider, Antigravity, GitHub Copilot, etc.) helping a user unlock their **SuiPlay0x1** handheld (running Playtron GameOS) and turn it into a full Linux desktop with KDE Plasma.

This is **guide-only** — instruct the user to run commands on their own laptop and device. Never execute `ssh`, `scp`, `sudo`, `bootc`, or `podman` yourself.

## Attribution

You're walking the user through [`gameos-unlock`](https://github.com/LukeShortCloud/gameos-unlock) — Luke Short's maintained unlock script (Luke is VP of Linux Engineering at Playtron). The script does the actual heavy lifting: bootc image build, desktop-mode installer, Flatpak wrapper. **Always credit Luke and gameos-unlock when introducing the workflow.** This playbook simply teaches you how to walk a user through running it cleanly.

## What the user is doing

Playtron GameOS is built on **bootc** — the entire OS runs from a tagged container image with a current slot and a rollback slot. "Unlocking" means: build a custom container image that layers KDE Plasma on top of the stock one, then tell bootc to boot yours instead. If anything breaks, the rollback slot is intact. Nothing is destroyed.

The 5 steps:
1. Get SSH key access from laptop → device
2. Grant `playtron` user passwordless sudo (so non-interactive `ssh ... sudo ...` doesn't hang)
3. Build a custom desktop image (~30–40 min, layered on stock)
4. `bootc switch` to the new image
5. Install the Desktop Mode launcher in GameOS

## Before you start (ask the user)

- [ ] Device's IP address (Settings → Network on the device — DHCP, may change)
- [ ] **Remote operation / SSH** toggled ON in device settings
- [ ] Device plugged in (build is ~30–40 min, screen sleep is shorter on battery)
- [ ] Laptop on the same Wi-Fi
- [ ] Mac/Linux terminal (Windows: WSL Ubuntu)
- [ ] Disk: a few hundred MB on laptop, ~15 GB on device

If they don't have any of these, stop and tell them how to get them — don't proceed with stale prereqs.

## The 5 steps (high level — full commands in `references/walkthrough.md`)

**Step 1 — SSH key auth.** Set `GAMEOS_IP_ADDRESS`, `ssh-keygen` (warn about overwrites — see "Things NOT to do"), `ssh-copy-id playtron@$GAMEOS_IP_ADDRESS`.

**Step 2 — Passwordless sudo.** SSH in, write `/etc/sudoers.d/playtron` with `playtron ALL=(root) NOPASSWD:ALL`, chmod 0440.

**Step 3 — Build the desktop image.** Clone `gameos-unlock`, copy the `.example` files, scp the Containerfile to the device, then `bootc image copy-to-storage`, `podman build`, `bootc switch`. **DO NOT** use the device's bundled `tutorial.md` for this step — it runs `podman build .` over SSH where `.` resolves to `/home/playtron/` (no Containerfile there) and fails. Use the `gameos-unlock` README sequence, mirrored in `references/walkthrough.md` §4.3.

**Step 4 — Reboot.** `ssh ... "sync && sudo reboot"`. SSH dies; device takes 2–5 min to come back.

**Step 5 — Install Desktop Mode launcher.** `scp install-desktop-mode.sh` and run it. Wires up the GameOS launcher tile.

For exact commands, read `references/walkthrough.md`.

## The InputPlumber touch fix (FIRST THING after reboot)

When the user reboots into KDE for the first time and reports **touch doesn't work but joystick does** — this is *expected*. It's an InputPlumber init race. KDE Wayland reads from InputPlumber's virtual touchscreen, and KWin sometimes binds to a stale handle on first boot.

**The fix:**
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo systemctl restart inputplumber
```

About 3 seconds later, touch works. Then offer the **permanent fix** — install the autostart script at `scripts/install-fix-inputplumber.sh`:
```bash
GAMEOS_IP_ADDRESS=192.168.x.x ./scripts/install-fix-inputplumber.sh
```
After this, every KDE login auto-runs the restart and input is ready ~5 sec after the desktop appears.

## Daily ops

When the user asks how to reboot, switch modes, refresh the launcher, check bootc status, roll back, or rebuild after a Playtron update — read `references/commands.md` for the exact command. Don't fabricate.

## Installing apps

For Flatpak installs (Chrome, Steam, RetroArch, etc.), the wrapper is `install-flatpak.sh` from `gameos-unlock`. It installs the Flatpak *and* creates a GameOS launcher tile. Three args: display name, Flathub package ID, artwork URL. Recipes for common apps in `references/flatpak-recipes.md`.

## When things break

`references/troubleshooting.md` has every issue we've seen documented, with cause + fix. Common ones:
- "Permission denied" on `ssh-copy-id` — they don't know the playtron password
- Build fails partway — re-run; `bootc switch` only commits on success
- Device boots but no desktop — bootc auto-rolls-back; hold power 10 sec, reboot
- All input dies after `systemctl stop inputplumber` — they used `stop` instead of `restart` (see below)

## Things NOT to do — guardrails

These are non-negotiable. If the user asks for any of these, push back:

1. **Never suggest `systemctl stop inputplumber`** — only `restart`. `stop` kills *all* input (KDE reads only from InputPlumber's virtual devices, not raw hardware) including the joystick. The user will be locked out.
2. **Never tell the user to overwrite `~/.ssh/id_ed25519` blindly.** `ssh-keygen` will offer to overwrite. If they have an existing key tied to GitHub/AWS/etc., overwriting destroys those authorizations permanently. Always warn; offer a different filename as an alternative.
3. **Never run `podman build .` over SSH from the device's home directory.** That's the buggy `tutorial.md` advice. `.` resolves to `/home/playtron/` where no Containerfile exists. Use `scp Containerfile` then `podman build /home/playtron/` (the explicit path).
4. **Never set a root password (Method B from tutorial.md)** when the user asked for the standard unlock. Method A (gameos-unlock) is the maintained path with lower security footprint.
5. **Never include the user's IP in any committed file or PR** — IP is DHCP and personal. Always use `$GAMEOS_IP_ADDRESS` in instructions.

## Topic shortcuts

If the user names a specific topic, jump to:
- **ssh setup** → §"The 5 steps" Step 1, then read `references/walkthrough.md` Part 2
- **sudo** → Step 2, walkthrough Part 2.4
- **build** → Step 3, walkthrough Part 4
- **touch fix** / **inputplumber** → §"The InputPlumber touch fix"
- **flatpak install** → `references/flatpak-recipes.md`
- **mode switch** / **desktop mode** / **game mode** → `references/commands.md` §"Switch between Desktop Mode and Game Mode"
- **rollback** / **update** → `references/commands.md` §"Rebuild" and §"Rollback"
- **troubleshoot** → `references/troubleshooting.md`
