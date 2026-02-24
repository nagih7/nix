#!/usr/bin/env bash

# Source utils (load guard prevents double-loading)
_COLLECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_COLLECT_DIR}/lib/utils.sh"

writer "\n--- System Configuration ---\n" 0.01
export HOSTNAME
HOSTNAME=$(ask "Enter your desired hostname" "example-host")
export CPU
CPU=$("${_COLLECT_DIR}/detect_cpu.sh")
export GPU
GPU=$("${_COLLECT_DIR}/detect_gpu.sh")
export ENABLE_FIREWALL
export FIREWALL_PORTS
ENABLE_FIREWALL=$(ask "Do you want to enable the firewall? (yes/no)" "no")
if [ "$ENABLE_FIREWALL" == "yes" ]; then
    ENABLE_FIREWALL="true"
    FIREWALL_PORTS=$(ask "Enter the ports to open (comma-separated)" "80,443")
else
    ENABLE_FIREWALL="false"
    FIREWALL_PORTS=""
fi

writer "\nUser configuration ---\n" 0.01
export USERNAME
USERNAME=$(ask "Enter your name (John)" "none")
export USER_DESCRIPTION
USER_DESCRIPTION=$(ask "Enter a description for you (John Smith)" "$USERNAME")
export USER_EMAIL
USER_EMAIL=$(ask "Enter your email (your_email@example.com)" "your_email@example.com")

writer "\nGit configuration ---\n" 0.01
export GIT_NAME
GIT_NAME=$(ask "Enter your Git name" "$USERNAME")
export GIT_EMAIL
GIT_EMAIL=$(ask "Enter your Git email" "$USER_EMAIL")

writer "\nMore configuration ---\n" 0.01
export ENABLE_TAILSCALE
ENABLE_TAILSCALE=$(ask "Do you want to enable Tailscale? (yes/no)" "no")
if [ "$ENABLE_TAILSCALE" == "yes" ]; then
    ENABLE_TAILSCALE="true"
else
    ENABLE_TAILSCALE="false"
fi
export ENABLE_SYNCTHING
ENABLE_SYNCTHING=$(ask "Do you want to enable Syncthing? (yes/no)" "no")
if [ "$ENABLE_SYNCTHING" == "yes" ]; then
    ENABLE_SYNCTHING="true"
else
    ENABLE_SYNCTHING="false"
fi
