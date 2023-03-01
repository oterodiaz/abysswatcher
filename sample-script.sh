#!/bin/sh

if [ -n "${DARK_MODE+set}" ]; then
    terminal-notifier -title "AbyssWatcher" -message "Dark mode!"
else
    terminal-notifier -title "AbyssWatcher" -message "Light mode!"
fi
