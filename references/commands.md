# SuiPlay0x1: Common Commands

Quick reference for managing the device after Method A unlock. All commands run from your **Mac terminal** unless noted.

## Setup (every new terminal session)

```bash
export GAMEOS_IP_ADDRESS=192.168.x.x
```

> Device IP is DHCP, verify in **Settings → Network** on the device if it changes.

---

## SSH

### Connect to the device
```bash
ssh playtron@$GAMEOS_IP_ADDRESS
```

### Run a single command remotely
```bash
ssh playtron@$GAMEOS_IP_ADDRESS '<command>'
```

### Copy a file from Mac → device
```bash
scp ./localfile.txt playtron@$GAMEOS_IP_ADDRESS:/home/playtron/
```

### Copy a file from device → Mac
```bash
scp playtron@$GAMEOS_IP_ADDRESS:/home/playtron/file.txt ./
```

### Stop seeing passphrase prompts (one-time)
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

---

## Reboot / shutdown

### Reboot
```bash
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"
```

### Shutdown
```bash
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo poweroff"
```

---

## Input fix (manual, if autostart fails)

If input is stuck in KDE Desktop Mode:
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo systemctl restart inputplumber
```

> The autostart script ([scripts/fix-inputplumber.sh](../scripts/fix-inputplumber.sh)) does this automatically on KDE login. Use this manual command only if the autostart fails for some reason.

---

## Switch between Desktop Mode and Game Mode

### From Mac → force device into Desktop Mode (KDE)
```bash
ssh playtron@$GAMEOS_IP_ADDRESS bash ~/.local/share/playtron/apps/local/desktop/switch-to-desktop-mode.sh
```

### From Mac → force device into Game Mode (Playtron launcher)
```bash
ssh playtron@$GAMEOS_IP_ADDRESS bash ~/.local/share/playtron/apps/local/desktop/switch-to-game-mode.sh
```

### Force Game Mode (nuclear option, if launcher is broken)
```bash
ssh playtron@$GAMEOS_IP_ADDRESS "sudo rm -f /etc/sddm.conf.d/60-playtron-session-override.conf && sudo systemctl restart sddm; sync; sudo reboot"
```

### Reload GameOS launcher (refresh app list)
```bash
ssh playtron@$GAMEOS_IP_ADDRESS systemctl --user restart playserve
```

---

## Install a Flatpak app

Template, replace `<NAME>`, `<PACKAGE_ID>`, `<IMAGE_URL>`:
```bash
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"<NAME>\" \"<PACKAGE_ID>\" \"<IMAGE_URL>\""
```

### Examples
```bash
# Firefox
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"Firefox\" \"org.mozilla.firefox\" \"https://img.goodfon.com/original/1920x1080/0/83/mozilla-firefox-brauzer-5087.jpg\""

# RetroArch (NES, SNES, GB, GBA, N64, DS via cores)
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"RetroArch\" \"org.libretro.RetroArch\" \"https://gbatemp.net/attachments/1804196-1684057088-png.437393/\""

# Discord
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"Discord\" \"com.discordapp.Discord\" \"https://www.pixground.com/wp-content/uploads/2023/11/Discord-Logo-Animation-4K-Wallpaper-1024x576.jpg\""

# Heroic Games Launcher (Epic / GOG / Amazon)
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"Heroic\" \"com.heroicgameslauncher.hgl\" \"https://heroicgameslauncher.com/_app/immutable/assets/heroic_logo.D-r9pBIj.png\""
```

Browse Flathub for more: https://flathub.org/

### Uninstall a Flatpak
```bash
ssh playtron@$GAMEOS_IP_ADDRESS "sudo flatpak uninstall -y <PACKAGE_ID>"
ssh playtron@$GAMEOS_IP_ADDRESS "rm -rf ~/.local/share/playtron/apps/local/<NAME>"
```

---

## System status

### bootc image slots (current + rollback)
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo bootc status
```

### Disk usage
```bash
ssh playtron@$GAMEOS_IP_ADDRESS df -h /
```

### Memory / CPU
```bash
ssh playtron@$GAMEOS_IP_ADDRESS "free -h && uptime"
```

### Input devices currently visible to kernel
```bash
ssh playtron@$GAMEOS_IP_ADDRESS 'cat /proc/bus/input/devices | grep -E "^N|^H"'
```

### InputPlumber status
```bash
ssh playtron@$GAMEOS_IP_ADDRESS 'systemctl status inputplumber --no-pager -n 10'
```

---

## Rebuild the desktop image (after Playtron base updates)

In `gameos-unlock/`:
```bash
cd ~/path/to/gameos-unlock
git pull --rebase origin main

scp bootc/desktop/Containerfile playtron@$GAMEOS_IP_ADDRESS:/home/playtron/
export CONTAINER_TAG="$(date +"%Y-%m-%dT%H_%M_%S%z" | sed 's/+/-/g')"
ssh playtron@$GAMEOS_IP_ADDRESS sudo bootc image copy-to-storage
ssh playtron@$GAMEOS_IP_ADDRESS sudo LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" podman build --no-cache --pull=always --tag desktop:${CONTAINER_TAG} /home/playtron/
ssh playtron@$GAMEOS_IP_ADDRESS sudo LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8" bootc switch --transport containers-storage localhost/desktop:${CONTAINER_TAG}
scp bootc/desktop/install-desktop-mode.sh playtron@$GAMEOS_IP_ADDRESS:/home/playtron/
ssh playtron@$GAMEOS_IP_ADDRESS /bin/bash /home/playtron/install-desktop-mode.sh
ssh playtron@$GAMEOS_IP_ADDRESS rm -f /home/playtron/install-desktop-mode.sh
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"
```

> ⚠️ Keep the device plugged in: full rebuild takes 30–60 min and will fail if SSH disconnects.

### Rollback to previous image (if a rebuild breaks things)
```bash
ssh playtron@$GAMEOS_IP_ADDRESS sudo bootc rollback
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"
```

---

## Uninstall everything (return device to stock)

Reverts all gameos-unlock changes and re-enables stock auto-updates:
```bash
cd ~/path/to/gameos-unlock
ssh playtron@$GAMEOS_IP_ADDRESS bash < gameos-unlock-uninstall.sh
ssh playtron@$GAMEOS_IP_ADDRESS "sync && sudo reboot"
```
