# Unlocking the SuiPlay0x1: A Complete Walkthrough

**Goal:** Turn the SuiPlay0x1 handheld (running Playtron GameOS) into a full Linux device with a KDE Plasma desktop, the ability to install any Flatpak app from Flathub, and a working dual-mode setup that lets you switch between the GameOS launcher and a real desktop.

**Approach used:** Method A — the [`gameos-unlock`](https://github.com/LukeShortCloud/gameos-unlock) script by Luke Short (VP of Linux Engineering at Playtron). This is the maintained, repeatable path; an alternative manual approach (Method B) exists but trades convenience for control.

**Time required:** ~60–90 minutes start to finish, mostly waiting for the container build.

**Prerequisites:**
- A SuiPlay0x1 with stock Playtron GameOS, fully charged or plugged in
- A Mac or Linux laptop (Windows works via WSL Ubuntu)
- A home Wi-Fi network you can put both devices on
- A few hundred MB of free space on your laptop and ~15 GB free on the device

---

## Part 0: What you're actually doing

Before running commands, it helps to understand the architecture you're modifying.

Playtron GameOS is a **bootc-based Linux distro**. That means the entire OS runs from a container image — the system reads a tagged image from `containers-storage` at boot. Updates aren't applied package-by-package; they swap in a whole new image and reboot. There are two image slots (current + rollback), so a bad image can be reverted by holding power and booting the previous slot.

What "unlocking" actually means in this context:
1. **Get SSH key access** so your laptop can run commands on the device.
2. **Grant `playtron` user passwordless sudo** so future automation doesn't get stuck on prompts.
3. **Build a custom container image** that adds KDE Plasma (and anything else you want) on top of the stock image.
4. **Tell `bootc` to switch** to your custom image at the next boot.
5. **Wire up a "Desktop Mode" launcher icon** in GameOS so you can swap between GameMode and KDE without typing commands.

Everything below is a concrete implementation of those five steps, plus a handful of gotchas the official tutorial doesn't mention.

---

## Part 1: Preparation

### 1.1 Get the device's IP address

On the SuiPlay0x1, go to **Settings → Network → (your Wi-Fi) → Network Details** and note the **IP Address** (e.g. `192.168.x.x`).

> ⚠️ This is a DHCP lease. If the device reboots and gets a different IP, redo the `export GAMEOS_IP_ADDRESS=...` step. To make it stable, set a DHCP reservation in your router by MAC address.

### 1.2 Enable SSH on the device

In the device's settings, find and toggle **Remote operation** (or **SSH server**) ON. Without this, every step below fails with `Connection refused`.

### 1.3 Verify network reachability from your laptop

Get on the same Wi-Fi as the device, open a terminal, and confirm SSH is listening:

```bash
nc -zv 192.168.x.x 22
```

Expected: `Connection to 192.168.x.x port 22 [tcp/ssh] succeeded!`

---

## Part 2: SSH key authentication

Goal: stop typing the device's password every time you connect, and let scripted sequences run cleanly.

### 2.1 Set the IP env var

In your laptop terminal:

```bash
export GAMEOS_IP_ADDRESS=192.168.x.x
```

This persists only for the current terminal window. Re-run it whenever you open a fresh terminal.

### 2.2 Generate an SSH keypair

```bash
ssh-keygen
```

Accept all defaults (path: `~/.ssh/id_ed25519`). For the passphrase, you have a real choice:

- **Empty passphrase** — convenient, fine for a personal laptop talking to a LAN-only handheld. The risk is theoretical: an attacker who already has access to your unlocked laptop could copy the key. If your laptop is compromised, that's your problem before SSH keys are.
- **A real passphrase** — slightly more secure, but you'll be prompted on every SSH call unless you load it into `ssh-agent` (`ssh-add --apple-use-keychain ~/.ssh/id_ed25519` on macOS).

> ⚠️ If you already have a key at `~/.ssh/id_ed25519`, ssh-keygen will offer to overwrite it. **Saying yes destroys the old key permanently.** Anything that authorized that old public key (GitHub, AWS, etc.) will need re-authorization with the new one. Either pick a different filename or accept the consequence consciously.

### 2.3 Copy the public key to the device

```bash
ssh-copy-id playtron@$GAMEOS_IP_ADDRESS
```

It'll prompt:
1. `Are you sure you want to continue connecting (yes/no)?` → type `yes` (TOFU host-key trust)
2. `playtron@192.168.x.x's password:` → enter the password set during the device's onboarding wizard

If you don't know the password, you'll need to set or reset it from the device itself before continuing. On stock Playtron GameOS the user account password is established during the first-boot setup flow.

After success: `Number of key(s) added: 1`.

> ⚠️ **Watch out for the "post-quantum key exchange" warning** that newer OpenSSH clients print. It's informational, not an error. Ignore it.

### 2.4 Configure passwordless sudo on the device

SSH in:

```bash
ssh playtron@$GAMEOS_IP_ADDRESS
```

The prompt should change to `[playtron@playtronos ~]$`. From there:

```bash
sudo touch /etc/sudoers.d/playtron
echo "playtron ALL=(root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/playtron
sudo chmod 0440 /etc/sudoers.d/playtron
exit
```

The first `sudo` will prompt for the playtron password (last time, if all goes well). Subsequent commands inherit a 5-minute sudo cache. The `exit` returns you to your laptop.

**Why this matters:** later steps run `sudo` over SSH non-interactively (`ssh user@host sudo command`). Without NOPASSWD, those commands would hang forever waiting for a password prompt that never appears.

---

## Part 3: Clone the unlock repo

```bash
git clone https://github.com/LukeShortCloud/gameos-unlock.git
cd gameos-unlock
```

Choose any directory; the build doesn't care where it lives on your laptop.

---

## Part 4: Build the custom desktop image

This is the slow, important step. You'll build a container image **on the device** (not your laptop) that layers KDE Plasma on top of the stock Playtron image, then tell bootc to use it.

### 4.1 Prepare the build context

```bash
git pull --rebase origin main
cp bootc/desktop/Containerfile.example bootc/desktop/Containerfile
cp bootc/desktop/install-desktop-mode.sh.example bootc/desktop/install-desktop-mode.sh
```

The `.example` files are templates. Copying them into working filenames lets you customize without dirtying the git checkout.

### 4.2 (Optional) Switch from KDE to GNOME

The default Containerfile installs **KDE Plasma**, which is the right call for a handheld (tested on Steam Deck, lighter, scales to small screens). Skip this section to keep KDE.

If you really want GNOME on macOS:
```bash
sed -i '' 's/kde-desktop/gnome-desktop/g' bootc/desktop/Containerfile
sed -i '' 's/Session=plasma/Session=gnome-wayland/g' bootc/desktop/install-desktop-mode.sh
```

(On Linux/WSL, drop the `''` after `-i`.)

### 4.3 Run the build

> ⚠️ **The tutorial.md included with SuiPlay0x1 is wrong on this step.** It runs `podman build .` over SSH, but `.` resolves to the device's home directory where no Containerfile exists. The actual `gameos-unlock` README has the correct sequence: scp the Containerfile to the device first, then build with the device-side path as the context. Use this version below, not the one in tutorial.md.

Make sure the device is plugged in (build can take 30+ min and the screen sleep timeout is shorter on battery). Then:

```bash
scp bootc/desktop/Containerfile playtron@$GAMEOS_IP_ADDRESS:/home/playtron/
export CONTAINER_TAG="$(date +"%Y-%m-%dT%H_%M_%S%z" | sed 's/+/-/g')"
ssh playtron@$GAMEOS_IP_ADDRESS sudo bootc image copy-to-storage
ssh playtron@$GAMEOS_IP_ADDRESS sudo LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" podman build --no-cache --pull=always --tag desktop:${CONTAINER_TAG} /home/playtron/
ssh playtron@$GAMEOS_IP_ADDRESS sudo LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" bootc switch --transport containers-storage localhost/desktop:${CONTAINER_TAG}
scp bootc/desktop/install-desktop-mode.sh playtron@$GAMEOS_IP_ADDRESS:/home/playtron/
ssh playtron@$GAMEOS_IP_ADDRESS /bin/bash /home/playtron/install-desktop-mode.sh
ssh playtron@$GAMEOS_IP_ADDRESS rm -f /home/playtron/install-desktop-mode.sh
```

What each line does:
- `scp Containerfile` — sends the build instructions to the device
- `bootc image copy-to-storage` — copies the running image into podman's storage so the new image can layer on it
- `podman build` — builds your custom image (~25–40 min on first run; pulls 836 MiB of packages, installs ~675, runs scriptlets)
- `bootc switch` — tells the system to boot this image next time
- `scp install-desktop-mode.sh` + run it — wires up the "Desktop Mode" launcher icon in GameOS

### 4.4 What you'll see

Expect output like:
- `Copying local image docker://ghcr.io/playtron-os/playtron-os:latest to containers-storage:localhost/bootc ...`
- `[1/675] Installing kde-frameworks-...` (counters running up to ~716 with installs/upgrades/removes)
- `Lint warning: ...` near the end — cosmetic; checks passed = 10
- `Successfully tagged localhost/desktop:<timestamp>`
- `Queued for next boot: ostree-unverified-image:containers-storage:localhost/desktop:...`
- Eventually your laptop shell prompt returns

If the build fails partway, your device is still safe — bootc only commits the new image after `bootc switch` succeeds. Re-run the chain.

### 4.5 Reboot

```bash
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"
```

The SSH connection dies (this is normal — `sudo reboot` kills the session). The device takes 2–5 minutes to come back up; the first boot on the new image is slower than subsequent ones.

---

## Part 5: First boot into KDE

When the device comes back up, it should auto-login to KDE Plasma. You'll see:

- The Plasma desktop with a panel
- A **Game Mode** shortcut on the desktop (use this to switch back to GameOS)
- A "Welcome to Fedora Linux" dialog (Fedora's first-launch wizard — close or skip through it)

A new **Desktop Mode** icon will also appear in the GameOS home screen the next time you switch to GameMode.

### 5.1 The first input gotcha

On first boot into KDE you may find that **touch doesn't respond, even though the joystick and buttons work**. This isn't broken hardware — it's an InputPlumber initialization race.

#### What's happening

InputPlumber is Playtron's input-translation daemon. It grabs the real Goodix touchscreen at the kernel level (`event5`) and re-emits a virtual touchscreen device for compositors to consume. KDE Wayland reads from these virtual devices, **not the raw hardware** — which is why naively stopping the service kills *all* input, including the joystick.

When KDE starts up, KWin sometimes binds to a stale or partially-initialized virtual touchscreen handle. Touches don't register until the handle is refreshed.

#### The fix (manual)

From your laptop:

```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo systemctl restart inputplumber
```

About 3 seconds later, touch starts working in KDE.

> ⚠️ **Do not `stop` or `disable` InputPlumber.** It kills all input. Always `restart`.

#### The fix (automatic, recommended)

Install a KDE autostart script that runs the restart on every login:

```bash
# Create the fix script on the device
ssh playtron@192.168.x.x 'mkdir -p ~/.config/autostart-scripts && cat > ~/.config/autostart-scripts/fix-inputplumber.sh << "EOF"
#!/bin/bash
sleep 2
sudo systemctl restart inputplumber
EOF
chmod +x ~/.config/autostart-scripts/fix-inputplumber.sh'

# Register it with KDE's autostart system
ssh playtron@192.168.x.x 'mkdir -p ~/.config/autostart && cat > ~/.config/autostart/fix-inputplumber.desktop << "EOF"
[Desktop Entry]
Type=Application
Name=Fix InputPlumber
Exec=/bin/bash /home/playtron/.config/autostart-scripts/fix-inputplumber.sh
X-KDE-AutostartScript=true
OnlyShowIn=KDE;
EOF'
```

Now every time you enter Desktop Mode, KDE auto-runs the script and input is ready ~5 seconds after the desktop appears. The script uses `sudo` without prompting because of the NOPASSWD rule from Part 2.4.

> 💡 We've packaged this as a one-shot installer at [`scripts/install-fix-inputplumber.sh`](../scripts/install-fix-inputplumber.sh) in this repo.

### 5.2 The second input gotcha: GameMode touch

After the unlock, **touch may not work in GameMode** (the Playtron launcher), only in KDE. This is most likely by design — many handheld game launchers expect controller-only input. Joystick and buttons still work in GameMode, so navigation isn't broken; you just can't tap. We didn't fix this because it might not actually be a regression.

---

## Part 6: Install applications

Apps are installed via Flatpak, which is the standard sandboxed-app system on Fedora-based distros. The `gameos-unlock` repo includes a wrapper that not only installs the Flatpak but also creates a launcher entry visible in the **GameOS home screen** (not just KDE's app menu).

### 6.1 The install template

```bash
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"<NAME>\" \"<PACKAGE_ID>\" \"<IMAGE_URL>\""
```

Three values to replace:
- **`<NAME>`** — display name shown in GameOS (e.g. `"Chrome"`)
- **`<PACKAGE_ID>`** — Flathub app ID, reverse-DNS format (e.g. `"com.google.Chrome"`)
- **`<IMAGE_URL>`** — URL to a JPG/PNG/WebP used as the launcher's tile artwork

Find package IDs at https://flathub.org/.

### 6.2 Example: Google Chrome

```bash
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"Chrome\" \"com.google.Chrome\" \"https://wallpapersok.com/images/high/seamless-google-chrome-art-ascghdz14kzmk87u.webp\""
```

The script:
1. Adds Flathub as a remote (idempotent)
2. Installs the Flatpak (~250 MB for Chrome)
3. Applies a `--filesystem=/run/udev:ro` override (lets Chrome detect hardware)
4. Creates `~/.local/share/playtron/apps/local/Chrome/launcher.sh` that runs `flatpak run com.google.Chrome`
5. Writes a manifest with the artwork URL so GameOS picks it up as a tile

After install, Chrome shows up in:
- KDE menu → Internet → Google Chrome
- GameOS home screen (may need `systemctl --user restart playserve` to refresh)

### 6.3 Other useful apps

Same template, different package IDs and artwork URLs:

| App | Package ID | What it's good for |
|---|---|---|
| Firefox | `org.mozilla.firefox` | Default browser if not building Firefox into the Containerfile |
| RetroArch | `org.libretro.RetroArch` | NES, SNES, GB/GBC/GBA, N64, DS via downloadable cores |
| RetroDeck | `net.retrodeck.retrodeck` | Heavier all-in-one emulator suite (Dolphin, etc.) |
| Heroic | `com.heroicgameslauncher.hgl` | Epic Games / GOG / Amazon Prime games |
| Discord | `com.discordapp.Discord` | Voice/text chat |
| Steam | `com.valvesoftware.Steam` | Comes with Proton for Windows games |

> ⚠️ Switch emulation (Yuzu, Ryujinx) was shut down by Nintendo. Forks exist (Suyu, Sudachi) but aren't on Flathub — skip unless you're prepared to manage AppImages manually.

---

## Part 7: Daily operations

A reference card for things you'll do regularly. (Full list with examples in [`commands.md`](commands.md).)

### Connect to the device
```bash
ssh playtron@$GAMEOS_IP_ADDRESS
```

### Reboot
```bash
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"
```

### Check current image / rollback target
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo bootc status
```

### Roll back to the previous image (if a rebuild breaks things)
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo bootc rollback
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"
```

### Rebuild after a Playtron base update

Re-run the same Part 4.3 chain — just `git pull` first to get any updates to the Containerfile, then redo the build/switch/reboot sequence. Your customizations (Chrome, autostart fix) are preserved across rebuilds since they live in `playtron`'s home directory, not in the bootc image.

### Uninstall everything (return to stock)

`gameos-unlock` ships a clean uninstaller:

```bash
ssh playtron@$GAMEOS_IP_ADDRESS bash < gameos-unlock-uninstall.sh
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"
```

This reverts bootc to the stock image and restores Playtron's auto-update flow.

---

## Part 8: Troubleshooting reference

A summary of every problem we hit during the actual install, in the order we hit them. Bookmark this — you'll likely see at least one of these.

### "Permission denied" when running `ssh-copy-id`
You don't know the playtron user's password. It was set during initial device onboarding. If you don't remember it, set it from the device itself with `sudo passwd playtron` (you'll need a terminal app on the device, e.g., Konsole if you have one, or a USB keyboard at a TTY).

### `tutorial.md`'s build command fails
The version in `tutorial.md` (the marketing/onboarding doc) runs `podman build .` over SSH where `.` is the device's home — and there's no Containerfile there. Use Part 4.3 in this walkthrough, which mirrors the actual `gameos-unlock` README.

### Touch doesn't work in KDE on first boot
InputPlumber initialization race. Run `sudo systemctl restart inputplumber` from your laptop. For a permanent fix, install the KDE autostart script (Part 5.1).

### All input dies (touch + joystick) after stopping InputPlumber
You ran `stop` instead of `restart`. KDE reads from InputPlumber's virtual devices; without them, it has nothing to read. Start the service back up: `ssh ... sudo systemctl start inputplumber`.

### "Welcome to Fedora Linux" dialog feels stuck
It's not stuck. Touch isn't initialized yet (see above). Use the joystick (right stick = mouse, A button = click) to dismiss it.

### Chrome installed but doesn't show up in GameOS home
The Playtron launcher caches its app list. Force a refresh:
```bash
ssh playtron@$GAMEOS_IP_ADDRESS systemctl --user restart playserve
```
Or just enter Game Mode and back to Desktop Mode — the launcher rebuilds on entry.

### Build fails partway
Re-run the Part 4.3 chain. `bootc switch` only commits a new image after a successful build, so a failed build leaves your existing system intact.

### Device boots but desktop doesn't appear / kernel panic
Bootc auto-rolls-back on a fully failed boot. Hold the power button for 10 seconds, power on; it should boot the previous slot. Then SSH in and run `sudo bootc rollback` to make it permanent.

### SSH passphrase prompt appears every time
You set a passphrase on your SSH key. Add it to the macOS Keychain once:
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```
Or remove the passphrase entirely with `ssh-keygen -p -f ~/.ssh/id_ed25519` (use empty for the new value).

---

## Part 9: Acknowledgements & references

- **`gameos-unlock` script** — Luke Short ([@LukeShortCloud](https://github.com/LukeShortCloud)), VP of Linux Engineering at Playtron. The script and its README are the source of truth; this walkthrough is an annotated tour of running it cleanly on a SuiPlay0x1.
- **Playtron GameOS** — built by the Playtron team: Alesh Slovak, William Edwards, Mathieu Comandon, Paweł Lidwin, ptitSeb, Brian Budge.
- **bootc** — the immutable-image OS framework that makes this whole approach possible.
- **InputPlumber** — Playtron's input-translation daemon; its profiles live at `/usr/share/inputplumber/profiles/` and device configs at `/usr/share/inputplumber/devices/`.

---

## Appendix: TL;DR for someone repeating the install

If you've done this once and want to redo it on another device or after a reset, the entire process collapses to:

```bash
# 1. Setup
export GAMEOS_IP_ADDRESS=192.168.x.x
ssh-keygen
ssh-copy-id playtron@$GAMEOS_IP_ADDRESS

# 2. Passwordless sudo
ssh playtron@$GAMEOS_IP_ADDRESS << 'EOF'
sudo touch /etc/sudoers.d/playtron
echo "playtron ALL=(root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/playtron
sudo chmod 0440 /etc/sudoers.d/playtron
EOF

# 3. Clone + prep
git clone https://github.com/LukeShortCloud/gameos-unlock.git
cd gameos-unlock
cp bootc/desktop/Containerfile.example bootc/desktop/Containerfile
cp bootc/desktop/install-desktop-mode.sh.example bootc/desktop/install-desktop-mode.sh

# 4. Build + switch (~30 min)
scp bootc/desktop/Containerfile playtron@$GAMEOS_IP_ADDRESS:/home/playtron/
export CONTAINER_TAG="$(date +"%Y-%m-%dT%H_%M_%S%z" | sed 's/+/-/g')"
ssh playtron@$GAMEOS_IP_ADDRESS sudo bootc image copy-to-storage
ssh playtron@$GAMEOS_IP_ADDRESS sudo LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" podman build --no-cache --pull=always --tag desktop:${CONTAINER_TAG} /home/playtron/
ssh playtron@$GAMEOS_IP_ADDRESS sudo LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" bootc switch --transport containers-storage localhost/desktop:${CONTAINER_TAG}
scp bootc/desktop/install-desktop-mode.sh playtron@$GAMEOS_IP_ADDRESS:/home/playtron/
ssh playtron@$GAMEOS_IP_ADDRESS /bin/bash /home/playtron/install-desktop-mode.sh
ssh playtron@$GAMEOS_IP_ADDRESS rm -f /home/playtron/install-desktop-mode.sh
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"

# 5. After reboot — install input fix
./scripts/install-fix-inputplumber.sh   # from this repo
```

Done. ~50 lines, one device, one full Linux desktop.
