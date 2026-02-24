#!/usr/bin/env bash

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${REPO_ROOT}/scripts/lib/utils.sh"

# === Welcome ===
clear
cat << 'EOF'
███╗   ██╗██╗██╗  ██╗    ██╗  ██╗    ███╗   ██╗ █████╗  ██████╗ ██╗██╗  ██╗
████╗  ██║██║╚██╗██╔╝    ╚██╗██╔╝    ████╗  ██║██╔══██╗██╔════╝ ██║██║  ██║
██╔██╗ ██║██║ ╚███╔╝       ███╔╝     ██╔██╗ ██║███████║██║  ███╗██║███████║
██║╚██╗██║██║ ██╔██╗      ██╔██╗     ██║╚██╗██║██╔══██║██║   ██║██║██╔══██║
██║ ╚████║██║██╔╝ ██╗    ██╔╝ ██╗    ██║ ╚████║██║  ██║╚██████╔╝██║██║  ██║
╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝    ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═╝
===========================================================================
EOF
printf "${GREEN}" >&2
writer "\nHi there!" 0.01
writer "Welcome to the NixOS configuration by Nagih [https://github.com/nagih7]" 0.01

printf "${YELLOW}" >&2
writer "\nPlease answer the following questions..."
printf "${NC}" >&2

# === Collect configuration ===
. "${REPO_ROOT}/scripts/collect_config.sh" || exit 1

# === Summary & confirmation ===
printf "${GREEN}\nThank you! The setup script will now proceed with your configuration.${NC}\n" >&2
writer ". . . . . . . . . ." 0.1

printf "${BLUE}" >&2
writer "\nYour configuration summary:" 0.01
printf "${GREEN}" >&2
writer "Hostname:           ${HOSTNAME}" 0.01
writer "CPU:                ${CPU}" 0.01
writer "GPU:                ${GPU:-None}" 0.01
writer "Firewall Enabled:   ${ENABLE_FIREWALL} ${FIREWALL_PORTS}" 0.01
writer "User Name:          ${USERNAME}" 0.01
writer "User Description:   ${USER_DESCRIPTION}" 0.01
writer "User Email:         ${USER_EMAIL}" 0.01
writer "Git Name:           ${GIT_NAME}" 0.01
writer "Git Email:          ${GIT_EMAIL}" 0.01
writer "Tailscale Enabled:  ${ENABLE_TAILSCALE}" 0.01
writer "Syncthing Enabled:  ${ENABLE_SYNCTHING}" 0.01

printf "\n\n${NC}" >&2
CONFIRMED=$(ask "Do you confirm the above configuration? (yes/no)" "yes")
if [ "$CONFIRMED" != "yes" ]; then
    printf "${RED}\nConfiguration not confirmed. Exiting setup.${NC}\n" >&2
    exit 1
fi
writer ". . . . . . . . . ." 0.1

# === Cleanup old configs ===
rm -rf hosts/{desktop,laptop,${HOSTNAME}}
rm -rf home/{nagih,${USERNAME}}

# === Generate configuration files ===
"${REPO_ROOT}/scripts/generate_host.sh" || { printf "${RED}Host config generation failed.${NC}\n" >&2; exit 1; }
"${REPO_ROOT}/scripts/generate_home.sh" || { printf "${RED}Home config generation failed.${NC}\n" >&2; exit 1; }

# === Commit changes ===
git add hosts/${HOSTNAME}/*
git add home/$(whoami)/*
git commit -m "Setup configuration for host: ${HOSTNAME}"

printf "${GREEN}\nSetup completed successfully!${NC}\n" >&2

writer "Please review the generated configuration files in the 'hosts/${HOSTNAME}/' and 'home/$(whoami)/' directories."

writer "You can now proceed with deploying your NixOS configuration."
writer "\nRun: ${YELLOW}sudo nixos-rebuild switch --flake .#${HOSTNAME}${NC}"
