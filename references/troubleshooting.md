# Troubleshooting — SuiPlay0x1 Unlock

Every issue we've seen during the unlock and after, with cause + fix. Bookmark this — most installs hit at least one of these.

---

## Input issues

### Touch doesn't work in KDE on first boot

**Cause:** InputPlumber initialization race. KDE Wayland reads from InputPlumber's virtual touchscreen, not raw hardware. KWin sometimes binds to a stale handle on first boot.

**Fix (manual, immediate):**
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo systemctl restart inputplumber
```

About 3 seconds later, touch starts working.

**Fix (permanent, recommended):** Run the autostart installer from the repo:
```bash
GAMEOS_IP_ADDRESS=192.168.x.x ./scripts/install-fix-inputplumber.sh
```

This drops [`scripts/fix-inputplumber.sh`](../scripts/fix-inputplumber.sh) into `~/.config/autostart-scripts/` and the [`.desktop`](../scripts/fix-inputplumber.desktop) entry into `~/.config/autostart/` on the device. Every KDE login auto-runs the restart and input is ready ~5 sec after the desktop appears. Uses `sudo` without prompting because of the NOPASSWD rule from the unlock setup.

### All input dies (touch + joystick) after stopping InputPlumber

**Cause:** Someone ran `systemctl stop inputplumber` instead of `restart`. KDE has nothing to read from once InputPlumber is stopped — it doesn't read raw hardware.

**Fix:**
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo systemctl start inputplumber
```

> ⚠️ Never run `stop` or `disable` on InputPlumber. Only `restart`.

### Touch doesn't work in GameMode (Playtron launcher)

**Cause:** Likely by design. Many handheld game launchers expect controller-only input. Joystick + buttons still work in GameMode, so navigation isn't broken — you just can't tap on launcher tiles.

**Fix:** None needed if working as designed. If you want to investigate, start by checking whether stock Playtron GameOS *ever* supported touch in the launcher (Playtron docs / Discord / [@PLAYTR0N](https://x.com/PLAYTR0N) on X). If it did, compare current InputPlumber state vs. expected. If it didn't, this isn't a regression introduced by `gameos-unlock`.

### "Welcome to Fedora Linux" dialog feels stuck on first boot

**Cause:** Touch isn't initialized yet (see above). The dialog isn't stuck — input just isn't responding.

**Fix:** Use the joystick to dismiss it (right stick = mouse, A button = click), then run the InputPlumber restart.

---

## SSH / sudo issues

### "Permission denied" on `ssh-copy-id`

**Cause:** You don't know the playtron user's password. It was set during initial device onboarding.

**Fix:** Reset the password from the device itself with `sudo passwd playtron`. You'll need a terminal app on the device (Konsole if you have desktop mode, or a USB keyboard at a TTY).

### Post-quantum key exchange warning from OpenSSH

**Cause:** Newer OpenSSH clients print this informationally when they negotiate a hybrid post-quantum-safe key exchange.

**Fix:** Ignore it. It's not an error. Connection will succeed.

### `ssh-keygen` overwrote my GitHub/AWS key

**Cause:** `ssh-keygen` defaults to `~/.ssh/id_ed25519` and silently destroys the existing key when you accept defaults during overwrite prompt.

**Fix:** Re-authorize the new public key with whatever services depended on the old one (GitHub, AWS, etc.). For next time, accept a different filename when ssh-keygen prompts, e.g. `~/.ssh/id_ed25519_suiplay`.

### SSH passphrase prompt every time

**Cause:** You set a passphrase on the SSH key.

**Fix (macOS):**
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

**Or** remove the passphrase entirely:
```bash
ssh-keygen -p -f ~/.ssh/id_ed25519
```
(Use empty value for the new passphrase.)

### `sudo` command over SSH hangs forever

**Cause:** You haven't configured passwordless sudo for `playtron` yet, and non-interactive `ssh ... sudo ...` has nowhere to put a password prompt.

**Fix:** SSH in interactively first and set up `/etc/sudoers.d/playtron` with `NOPASSWD:ALL` (see walkthrough Part 2.4).

---

## Build issues

### `tutorial.md` build command fails immediately

**Cause:** The Playtron-bundled `tutorial.md` runs `podman build .` over SSH, where `.` resolves to the device's home directory — and there's no Containerfile there.

**Fix:** Use the [walkthrough.md](walkthrough.md) §4.3 sequence instead, which mirrors the actual `gameos-unlock` README. The fix is to `scp` the Containerfile to the device first and use the explicit path: `podman build /home/playtron/`.

### Build fails partway through

**Cause:** Could be transient (network, package mirror) or persistent (Containerfile syntax error).

**Fix:** Re-run the [walkthrough.md](walkthrough.md) §4.3 chain. `bootc switch` only commits a new image after a successful build, so a failed build leaves your existing system intact. If the same error recurs, pull the latest `gameos-unlock` (`git pull --rebase origin main`) and re-copy `Containerfile.example` → `Containerfile`.

### Build succeeds but device boots to black screen / kernel panic

**Cause:** A bad image. Bootc is supposed to auto-roll-back on a fully failed boot.

**Fix:** Hold the power button for 10 seconds to force off, then power on — should boot the previous slot. Then SSH in and run:
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo bootc rollback
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"
```
Make the rollback permanent.

---

## App / launcher issues

### Chrome installed but doesn't show in GameOS home screen

**Cause:** The Playtron launcher caches its app list and doesn't always pick up new tiles immediately.

**Fix:**
```bash
ssh playtron@$GAMEOS_IP_ADDRESS systemctl --user restart playserve
```

Or just enter Game Mode and back to Desktop Mode — the launcher rebuilds on entry.

### Flatpak install fails with "remote 'flathub' not found"

**Cause:** Flathub remote not yet added on a fresh build. The `install-flatpak.sh` wrapper is supposed to add it idempotently.

**Fix:** Add it manually:
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

Then re-run the install.

### App launches in KDE but not in GameOS

**Cause:** Manifest written but Playserve hasn't picked it up.

**Fix:** Same as above — `systemctl --user restart playserve` on the device.

---

## Quick reference

| Symptom | Most likely cause | First thing to try |
|---|---|---|
| Touch dead, joystick OK (KDE) | InputPlumber init race | `restart inputplumber` |
| All input dead | Someone ran `stop inputplumber` | `start inputplumber` |
| Touch dead in GameMode only | By design | Nothing |
| `podman build .` fails | tutorial.md bug | Use walkthrough.md §4.3 |
| Build halts partway | Transient | Re-run the chain |
| Black screen after reboot | Bad image | Hold power 10s, then `bootc rollback` |
| Flatpak app not in GameOS | Launcher cache stale | `restart playserve` |
| `ssh-copy-id` permission denied | Wrong password | `sudo passwd playtron` on device |
