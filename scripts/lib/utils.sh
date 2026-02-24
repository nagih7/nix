#!/usr/bin/env bash

# Load guard: prevent re-sourcing
[[ -n "${_UTILS_LOADED:-}" ]] && return 0
_UTILS_LOADED=1

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

writer() {
    local text="$1"
    local delay="${2:-0.00}"
    local no_newline="$3"

    [[ -z "$text" ]] && return

    local decoded_text
    decoded_text=$(printf "%b" "$text")

    for (( i=0; i<${#decoded_text}; i++ )); do
        local char="${decoded_text:$i:1}"

        if [[ "$char" == $'\n' ]]; then
            printf "\n" >&2
        else
            printf "%s" "$char" >&2
        fi

        sleep "$delay"
    done

    [[ -z "$no_newline" ]] && printf "\n" >&2
}

ask() {
    local prompt_text="$1"
    local default_value="$2"
    local user_input

    printf "${CYAN}?? ${NC}" >&2
    writer "${prompt_text} ${YELLOW}[Default: ${default_value}]${NC}: " 0.01 "true"

    read user_input < /dev/tty
    echo "${user_input:-$default_value}"
}
