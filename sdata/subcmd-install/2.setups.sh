# This script is meant to be sourced.
# It's not for directly running.
printf "${STY_CYAN}[$0]: 2. Setup for permissions/services etc\n${STY_RST}"

#####################################################################################

v sudo usermod -aG video,input "$(whoami)"
v sudo chsh --shell "$(command -v zsh)" "$(whoami)"
