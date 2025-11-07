#!/usr/bin/env bash

# Load the functions library
FUNCTIONS_LIB_PATH="/tmp/functions.sh"
FUNCTIONS_LIB_URL="https://raw.githubusercontent.com/Sonicverse-EU/bash-functions/main/common-functions.sh"

# Download the latest version of the functions library
rm -f "${FUNCTIONS_LIB_PATH}"
if ! curl -sLo "${FUNCTIONS_LIB_PATH}" "${FUNCTIONS_LIB_URL}"; then
  echo -e "*** Failed to download the functions library. Please check your network connection! ***"
  exit 1
fi

# Source the functions library
# shellcheck source=/tmp/functions.sh
source "${FUNCTIONS_LIB_PATH}"

# Define base variables
INSTALL_DIR="/opt/liquidsoap"
GITHUB_BASE="https://raw.githubusercontent.com/Sonicverse-EU/liquidsoap-audiostack/main"

# Docker files
DOCKER_COMPOSE_URL="${GITHUB_BASE}/docker-compose.yml"
DOCKER_COMPOSE_PATH="${INSTALL_DIR}/docker-compose.yml"

# Liquidsoap configuration
LIQUIDSOAP_CONFIG_URL_BREEZE="${GITHUB_BASE}/conf/breeze.liq"

LIQUIDSOAP_CONFIG_PATH="${INSTALL_DIR}/scripts/radio.liq"

# Liquidsoap library files
LIQUIDSOAP_LIB_DIR="${INSTALL_DIR}/scripts/lib"
LIQUIDSOAP_LIB_DEFAULTS_URL="${GITHUB_BASE}/conf/lib/defaults.liq"
LIQUIDSOAP_LIB_STUDIO_INPUTS_URL="${GITHUB_BASE}/conf/lib/studio_inputs.liq"
LIQUIDSOAP_LIB_ICECAST_OUTPUTS_URL="${GITHUB_BASE}/conf/lib/icecast_outputs.liq"

LIQUIDSOAP_ENV_URL_BREEZE="${GITHUB_BASE}/.env.breeze.example"
LIQUIDSOAP_ENV_PATH="${INSTALL_DIR}/.env"

# Liquidsoap library files
LIQUIDSOAP_LIB_DIR="${INSTALL_DIR}/scripts/lib"
LIQUIDSOAP_LIB_DEFAULTS_URL="${GITHUB_BASE}/conf/lib/defaults.liq"
LIQUIDSOAP_LIB_STUDIO_INPUTS_URL="${GITHUB_BASE}/conf/lib/studio_inputs.liq"
LIQUIDSOAP_LIB_ICECAST_OUTPUTS_URL="${GITHUB_BASE}/conf/lib/icecast_outputs.liq"

AUDIO_FALLBACK_URL="https://audiofiles.breezeradio.nl/nood/noodband.wav"
AUDIO_FALLBACK_PATH="${INSTALL_DIR}/audio/noodband.wav"

SILENCE_DETECTION_PATH="${INSTALL_DIR}/silence_detection.txt"



# General configuration
TIMEZONE="Europe/Amsterdam"
DIRECTORIES=(
  "${INSTALL_DIR}/scripts"
  "${INSTALL_DIR}/scripts/lib"
  "${INSTALL_DIR}/audio"
)
OS_ARCH=$(dpkg --print-architecture)

# Environment setup
set_colors
check_user_privileges privileged
is_this_linux
is_this_os_64bit
set_timezone "${TIMEZONE}"

# Ensure Docker is installed
require_tool "docker"

# Display a welcome banner
clear
cat << "EOF"
==================================================
        Sonicverse Audiostack Installer
==================================================
EOF
echo -e "${GREEN}⎎ Liquidsoap Installation${NC}\n"

# Prompt user for input
ask_user "STATION_CONFIG" "breeze" "Which station configuration would you like to use? (breeze)" "str"

# Validate station configuration
if [[ ! "$STATION_CONFIG" =~ ^(breeze)$ ]]; then
  echo -e "${RED}Error: Invalid station configuration. Must be 'breeze'.${NC}"
  exit 1
fi
ask_user "DO_UPDATES" "y" "Would you like to perform all OS updates? (y/n)" "y/n"

if [ "${DO_UPDATES}" == "y" ]; then
  update_os silent
fi

# Create required directories
echo -e "${BLUE}►► Creating directories...${NC}"
for dir in "${DIRECTORIES[@]}"; do
  mkdir -p "${dir}"
done

# Backup and download configuration files
echo -e "${BLUE}►► Downloading configuration files...${NC}"

# Set configuration URL based on user choice
if [ "${STATION_CONFIG}" == "breeze" ]; then
  LIQUIDSOAP_CONFIG_URL="${LIQUIDSOAP_CONFIG_URL_BREEZE}"
  LIQUIDSOAP_ENV_URL="${LIQUIDSOAP_ENV_URL_BREEZE}"
fi

if ! download_file "${LIQUIDSOAP_CONFIG_URL}" "${LIQUIDSOAP_CONFIG_PATH}" "Liquidsoap configuration for ${STATION_CONFIG}" backup; then
  exit 1
fi

# Download library files
echo -e "${BLUE}►► Downloading Liquidsoap library files...${NC}"
if ! download_file -m "${LIQUIDSOAP_LIB_DIR}" "Liquidsoap library files" \
  "${LIQUIDSOAP_LIB_DEFAULTS_URL}:defaults.liq" \
  "${LIQUIDSOAP_LIB_STUDIO_INPUTS_URL}:studio_inputs.liq" \
  "${LIQUIDSOAP_LIB_ICECAST_OUTPUTS_URL}:icecast_outputs.liq"; then
  exit 1
fi

if ! download_file "${LIQUIDSOAP_ENV_URL}" "${LIQUIDSOAP_ENV_PATH}" "Liquidsoap env for ${STATION_CONFIG}" backup; then
  exit 1
fi

if ! download_file "${DOCKER_COMPOSE_URL}" "${DOCKER_COMPOSE_PATH}" "docker-compose.yml" backup; then
  exit 1
fi

if ! download_file "${AUDIO_FALLBACK_URL}" "${AUDIO_FALLBACK_PATH}" "audio fallback file" backup; then
  exit 1
fi

echo "1" > $SILENCE_DETECTION_PATH


# Display usage instructions
echo -e "\n${BLUE}►► How to run Liquidsoap:${NC}"
echo -e "${YELLOW}Important: Before starting, make sure to edit the .env file with your configuration:${NC}"
echo -e "  ${CYAN}nano ${LIQUIDSOAP_ENV_PATH}${NC}"
echo -e ""
echo -e "${YELLOW}To start Liquidsoap:${NC}"
echo -e "  ${CYAN}cd ${INSTALL_DIR}${NC}"
echo -e "  ${CYAN}docker compose up -d${NC}"
echo -e ""
echo -e "${YELLOW}To view logs:${NC}"
echo -e "  ${CYAN}docker compose logs -f${NC}"
echo -e ""
echo -e "${YELLOW}To stop Liquidsoap:${NC}"
echo -e "  ${CYAN}docker compose down${NC}"
echo -e ""
echo -e "${YELLOW}To control silence detection and fallback:${NC}"
echo -e "  Enable:  ${CYAN}echo '1' > ${SILENCE_DETECTION_PATH}${NC}"
echo -e "  Disable: ${CYAN}echo '0' > ${SILENCE_DETECTION_PATH}${NC}"
echo -e ""
echo -e "${YELLOW}When silence detection is disabled:${NC}"
echo -e "  - Studio inputs will not switch on silence"
echo -e "  - Emergency fallback file will not be used"
echo -e "  - Silent studio streams will continue playing"
