# This script is meant to be sourced.
# It's not for directly running.
function print_os_group_id(){
    printf "${STY_CYAN}"
    printf "===INFO===\n"
    printf "Detected OS_DISTRO_ID: ${OS_DISTRO_ID}\n"
    printf "Detected OS_DISTRO_ID_LIKE: ${OS_DISTRO_ID_LIKE}\n"
    printf "Determined OS_GROUP_ID: ${OS_GROUP_ID}\n"
    printf "==========\n\n"
    printf "${STY_RST}"
}
function print_os_group_id_fallback(){
    printf "${STY_RED}"
    printf "===CAUTION===\n"
    printf "Distro not recognized, determined as fallback.\n"
    printf "=============\n\n"
    printf "${STY_RST}"
}
function print_os_group_id_architecture(){
    printf "${STY_RED}"
    printf "===CAUTION===\n"
    printf "Detected machine architecture: ${MACHINE_ARCH}\n"
    printf "This script only supports x86_64.\n"
    printf "It is very likely to fail when installing dependencies on your machine.\n"
    printf "=============\n\n"
    printf "${STY_RST}"
}
#####################################################################################

####################
# Detect distro
# Helpful link(s):
# http://stackoverflow.com/questions/29581754
# https://github.com/which-distro/os-release
OS_RELEASE_FILE_CUSTOM="${REPO_ROOT}/os-release"
if test -f "${OS_RELEASE_FILE_CUSTOM}"; then
  printf "${STY_YELLOW}Warning: using custom os-release file \"${OS_RELEASE_FILE_CUSTOM}\".${STY_RST}\n"
  OS_RELEASE_FILE="${OS_RELEASE_FILE_CUSTOM}"
elif test -f /etc/os-release; then
  OS_RELEASE_FILE=/etc/os-release
else
  printf "${STY_RED}/etc/os-release does not exist, aborting...${STY_RST}\n" ; exit 1
fi
export OS_DISTRO_ID=$(awk -F'=' '/^ID=/ { gsub("\"","",$2); print tolower($2) }' ${OS_RELEASE_FILE} 2> /dev/null)
export OS_DISTRO_ID_LIKE=$(awk -F'=' '/^ID_LIKE=/ { gsub("\"","",$2); print tolower($2) }' ${OS_RELEASE_FILE} 2> /dev/null)


####################
# Determine distro ID

if [[ "$OS_DISTRO_ID" =~ ^(arch|endeavouros|cachyos)$ ]] || [[ "$OS_DISTRO_ID_LIKE" == "arch" ]]; then
  OS_GROUP_ID="arch"
  print_os_group_id_functions=(print_os_group_id)
elif [[ "$OS_DISTRO_ID" == "gentoo" ]] || [[ "$OS_DISTRO_ID_LIKE" == "gentoo" ]]; then
  OS_GROUP_ID="gentoo"
  print_os_group_id_functions=(print_os_group_id)
elif [[ "$OS_DISTRO_ID" == "fedora" ]] || [[ "$OS_DISTRO_ID_LIKE" == "fedora" ]]; then
  OS_GROUP_ID="fedora"
  print_os_group_id_functions=(print_os_group_id)
elif [[ "$OS_DISTRO_ID" =~ ^(opensuse-leap|opensuse-tumbleweed)$ ]] || [[ "$OS_DISTRO_ID_LIKE" =~ ^(opensuse|suse)(\ (opensuse|suse))?$ ]]; then
  OS_GROUP_ID="suse"
  print_os_group_id_functions=(print_os_group_id)
elif [[ "$OS_DISTRO_ID" == "debian" || "$OS_DISTRO_ID_LIKE" == "debian" ]]; then
  OS_GROUP_ID="debian"
  print_os_group_id_functions=(print_os_group_id)
else
  OS_GROUP_ID="fallback"
  print_os_group_id_functions=(print_os_group_id{,_fallback})
fi

####################
# Detect architecture
# Helpful link(s):
# http://stackoverflow.com/questions/45125516
export MACHINE_ARCH=$(uname -m)
case "${MACHINE_ARCH}" in
  "x86_64") sleep 0;;
  *) print_os_group_id_functions+=(print_os_group_id_architecture);;
esac
