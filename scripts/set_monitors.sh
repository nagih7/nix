#!/usr/bin/env bash

PORT_NAME_1=$(hyprctl monitors -j | jq -r '.[0].name')
MONITOR_INFO_1=$(hyprctl monitors -j | jq -r '.[0].availableModes | .[0]')

PORT_NAME_2=$(hyprctl monitors -j | jq -r '.[1].name')
MONITOR_INFO_2=$(hyprctl monitors -j | jq -r '.[1].availableModes | .[1]')

hyprctl keyword monitor "$PORT_NAME_1, $MONITOR_INFO_1, 0x0, 1, bitdepth, 8"
hyprctl keyword monitor "$PORT_NAME_2, $MONITOR_INFO_2, -1080x0, 1, transform, 1"