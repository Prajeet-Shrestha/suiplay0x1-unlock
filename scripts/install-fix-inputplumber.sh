#!/bin/bash
# Installs fix-inputplumber autostart on a SuiPlay0x1 device.
# Usage: GAMEOS_IP_ADDRESS=192.168.x.x ./scripts/install-fix-inputplumber.sh
set -euo pipefail

if [ -z "${GAMEOS_IP_ADDRESS:-}" ]; then
  echo "Set GAMEOS_IP_ADDRESS first, e.g.: export GAMEOS_IP_ADDRESS=192.168.x.x"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

scp "$SCRIPT_DIR/fix-inputplumber.sh" "playtron@$GAMEOS_IP_ADDRESS:/tmp/fix-inputplumber.sh"
scp "$SCRIPT_DIR/fix-inputplumber.desktop" "playtron@$GAMEOS_IP_ADDRESS:/tmp/fix-inputplumber.desktop"

ssh "playtron@$GAMEOS_IP_ADDRESS" '
  mkdir -p ~/.config/autostart-scripts ~/.config/autostart
  mv /tmp/fix-inputplumber.sh ~/.config/autostart-scripts/fix-inputplumber.sh
  mv /tmp/fix-inputplumber.desktop ~/.config/autostart/fix-inputplumber.desktop
  chmod +x ~/.config/autostart-scripts/fix-inputplumber.sh
  ls -la ~/.config/autostart-scripts/ ~/.config/autostart/
'

echo
echo "Done. Next time you enter KDE Desktop Mode, input will auto-recover ~5 seconds after login."
