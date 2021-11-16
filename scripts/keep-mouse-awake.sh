#!/bin/bash

# Disable mouse poweroff
echo 2 | sudo tee /sys/bus/usb/devices/*/power/autosuspend >/dev/null
echo on | sudo tee /sys/bus/usb/devices/*/power/level >/dev/null