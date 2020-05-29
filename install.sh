#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Configuration
#
# Add or remove any hooks you want to install to this list.
#
# Valid hooks must: be valid git hooks, as defined at https://githooks.com/.
# This constraint is not checked in the script.
#
# This script must be located within the working tree of the repo you want to
# install the hooks into. Additionally, all hooks must be located in the same
# directory as this script. We recommend checking both this script and your
# hooks into source control.
HOOKS_TO_INSTALL=(
"commit-msg"
)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Color codes
red='\033[0;31m'
yellow='\033[0;33m'
blue='\033[0;34m'
green='\033[0;32m'
NC='\033[0m'
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Utilities
exit_if_errors(){
  if [ "${errs_found}" -gt 0 ]; then
    print_results
    exit "${errs_found}"
  fi
}

print_results(){
  case ${successes} in
    0)
      echo
      echo -e -n "${red}${successes} hooks successfully installed"
      ;;
    1)
      echo
      echo -e -n "${green}${successes} hook successfully installed"
      ;;
    *)
      echo
      echo -e -n "${green}${successes} hooks successfully installed"
      ;;
  esac

  case ${warnings_found} in
    0)
      ;;
    1)
      echo -e -n ", ${yellow}${warnings_found} warning"
      ;;
    *)
      echo -e -n ", ${yellow}${warnings_found} warnings"
      ;;
  esac

  case ${errs_found} in
    0)
      echo -e ".${NC}"
      ;;
    1)
      echo -e ", ${red}${errs_found} error.${NC}"
      ;;
    *)
      echo -e ", ${red}${errs_found} errors.${NC}"
      ;;
  esac
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Installation
ROOT_DIR=$(git rev-parse --show-toplevel)
HOOKS_DIR="${ROOT_DIR}/.git/hooks"
errs_found=0
warnings_found=0
successes=0
# Ensure we are in a git repository
if ! (git rev-parse --is-inside-work-tree > /dev/null 2> /dev/null) ; then
  echo -e "${red}This script must be run from within a git repo.${NC}"
  ((errs_found++))
fi
exit_if_errors

for HOOK_FILE in "${HOOKS_TO_INSTALL[@]}"; do
  HOOK_FILE_RELATIVE_TO_SCRIPT="$(dirname "${0}")/${HOOK_FILE}"

  if [ -f "${HOOK_FILE_RELATIVE_TO_SCRIPT}" ]; then
    INSTALL_PATH="${HOOKS_DIR}/${HOOK_FILE}"
    if [ -f "${INSTALL_PATH}" ]; then
      echo -e "${yellow}Tried to install ${blue}${HOOK_FILE_RELATIVE_TO_SCRIPT}${yellow}, but a hook called ${HOOK_FILE} already exists. Skipping...${NC}"
      ((warnings_found++))
    else
      ln -s "$(realpath "--relative-to=${HOOKS_DIR}" "${HOOK_FILE_RELATIVE_TO_SCRIPT}")" "${INSTALL_PATH}"
      chmod +ux "${HOOK_FILE_RELATIVE_TO_SCRIPT}"
      echo -e "${green}Installed hook: ${blue}${HOOK_FILE_RELATIVE_TO_SCRIPT}${green}.${NC}"
      ((successes++))
    fi
  else
    echo -e "${yellow}Tried to install ${blue}${HOOK_FILE_RELATIVE_TO_SCRIPT}${yellow}, but no such file exists. Skipping...${NC}"
    ((warnings_found++))
  fi
done

print_results

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
