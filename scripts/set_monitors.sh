#!/usr/bin/env bash

PORT_NAME=$(hyprctl monitors -j | jq -r '.[0].name')
MONITOR_INFO=$(hyprctl monitors -j | jq -r '.[0].availableModes | .[0]')

hyprctl keyword monitor "$PORT_NAME, $MONITOR_INFO, 0x0, 1, bitdepth, 8"