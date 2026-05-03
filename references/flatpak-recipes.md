# Flatpak Recipes — SuiPlay0x1

Common app installs using the [`install-flatpak.sh`](https://github.com/LukeShortCloud/gameos-unlock/blob/main/plugin-local/install-flatpak.sh) wrapper from `gameos-unlock`. Each one installs the Flatpak *and* creates a launcher tile in the GameOS home screen.

## The template

```bash
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"<NAME>\" \"<PACKAGE_ID>\" \"<IMAGE_URL>\""
```

Three values:
- **`<NAME>`** — display name shown in GameOS (e.g. `"Chrome"`)
- **`<PACKAGE_ID>`** — Flathub app ID, reverse-DNS format (e.g. `"com.google.Chrome"`)
- **`<IMAGE_URL>`** — JPG/PNG/WebP for the launcher tile artwork

Browse Flathub for more package IDs: https://flathub.org/

## Common apps

### Browsers

```bash
# Google Chrome
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"Chrome\" \"com.google.Chrome\" \"https://wallpapersok.com/images/high/seamless-google-chrome-art-ascghdz14kzmk87u.webp\""

# Firefox
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"Firefox\" \"org.mozilla.firefox\" \"https://img.goodfon.com/original/1920x1080/0/83/mozilla-firefox-brauzer-5087.jpg\""
```

### Game launchers

```bash
# Steam (with Proton — runs Windows games)
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"Steam\" \"com.valvesoftware.Steam\" \"<steam-artwork-url>\""

# Heroic — Epic Games / GOG / Amazon Prime
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"Heroic\" \"com.heroicgameslauncher.hgl\" \"https://heroicgameslauncher.com/_app/immutable/assets/heroic_logo.D-r9pBIj.png\""
```

### Emulators

```bash
# RetroArch — NES, SNES, GB/GBC/GBA, N64, DS via downloadable cores
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"RetroArch\" \"org.libretro.RetroArch\" \"https://gbatemp.net/attachments/1804196-1684057088-png.437393/\""

# RetroDeck — heavier all-in-one suite (Dolphin, etc.)
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"RetroDeck\" \"net.retrodeck.retrodeck\" \"<retrodeck-artwork-url>\""
```

### Communication

```bash
# Discord
ssh playtron@$GAMEOS_IP_ADDRESS "curl https://raw.githubusercontent.com/LukeShortCloud/gameos-unlock/refs/heads/main/plugin-local/install-flatpak.sh | bash -s -- \"Discord\" \"com.discordapp.Discord\" \"https://www.pixground.com/wp-content/uploads/2023/11/Discord-Logo-Animation-4K-Wallpaper-1024x576.jpg\""
```

## Reference table

| App | Package ID | Notes |
|---|---|---|
| Google Chrome | `com.google.Chrome` | ~250 MB; auto-applies `--filesystem=/run/udev:ro` for hardware detection |
| Firefox | `org.mozilla.firefox` | Default browser if not building into Containerfile |
| Steam | `com.valvesoftware.Steam` | Comes with Proton |
| Heroic | `com.heroicgameslauncher.hgl` | Epic / GOG / Amazon Prime |
| RetroArch | `org.libretro.RetroArch` | Cores downloadable from inside the app |
| RetroDeck | `net.retrodeck.retrodeck` | All-in-one, heavier |
| Discord | `com.discordapp.Discord` | |
| OBS Studio | `com.obsproject.Studio` | Recording / streaming |
| VLC | `org.videolan.VLC` | Video player |

> ⚠️ **Switch emulation** (Yuzu, Ryujinx) was shut down by Nintendo. Forks exist (Suyu, Sudachi) but aren't on Flathub — skip unless you're prepared to manage AppImages manually.

## After install — refresh the launcher

If a new app shows up in KDE's app menu but not in GameOS:

```bash
ssh playtron@$GAMEOS_IP_ADDRESS systemctl --user restart playserve
```

Or just enter Game Mode and back to Desktop Mode — the launcher rebuilds on entry.

## Uninstall

```bash
ssh playtron@$GAMEOS_IP_ADDRESS "sudo flatpak uninstall -y <PACKAGE_ID>"
ssh playtron@$GAMEOS_IP_ADDRESS "rm -rf ~/.local/share/playtron/apps/local/<NAME>"
```

The first command removes the Flatpak. The second removes the GameOS launcher tile.
