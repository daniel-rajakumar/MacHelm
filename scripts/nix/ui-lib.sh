#!/usr/bin/env bash

# MacHelm UI Library - Utility functions for a premium TUI

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Icons
CHECK_ICON="✔"
INFO_ICON="ℹ"
WARN_ICON="⚠"
ERROR_ICON="✖"
ROCKET_ICON="🚀"

print_header() {
    local title=$1
    echo -e "${BOLD}${BLUE}========================================${NC}"
    echo -e "${BOLD}${BLUE}  ${ROCKET_ICON}  MacHelm: ${title}${NC}"
    echo -e "${BOLD}${BLUE}========================================${NC}"
}

print_status() {
    local msg=$1
    local type=${2:-info}
    case $type in
        success) echo -e "${GREEN}${CHECK_ICON} ${msg}${NC}" ;;
        warn)    echo -e "${YELLOW}${WARN_ICON} ${msg}${NC}" ;;
        error)   echo -e "${RED}${ERROR_ICON} ${msg}${NC}" ;;
        *)       echo -e "${BLUE}${INFO_ICON} ${msg}${NC}" ;;
    esac
}

print_footer() {
    echo -e "${BOLD}${BLUE}----------------------------------------${NC}"
}
