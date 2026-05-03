#!/bin/bash
# Workaround for input being stuck after entering KDE Desktop Mode from Playtron GameMode.
# InputPlumber's virtual devices don't re-bind cleanly across session changes;
# restarting the service forces fresh device creation that KWin picks up.
#
# Installed on the device at: ~/.config/autostart-scripts/fix-inputplumber.sh
# Triggered by: ~/.config/autostart/fix-inputplumber.desktop on KDE login.
sleep 2
sudo systemctl restart inputplumber
