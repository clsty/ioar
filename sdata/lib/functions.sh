# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
# NOTE that you NOT need to `cd ..' because the `$0' is NOT this file, but the script file which will source this file.

# shellcheck shell=bash

function try { "$@" || sleep 0; }
function v(){
  echo -e "####################################################"
  echo -e "${STY_BLUE}[$0]: Next command:${STY_RST}"
  echo -e "${STY_GREEN}$*${STY_RST}"
  local execute=true
  if $ask;then
    while true;do
      echo -e "${STY_BLUE}Execute? ${STY_RST}"
      echo "  y = Yes"
      echo "  e = Exit now"
      echo "  s = Skip this command (NOT recommended - your setup might not work correctly)"
      echo "  yesforall = Yes and don't ask again; NOT recommended unless you really sure"
      local p; read -p "====> " p
      case $p in
        [yY]) echo -e "${STY_BLUE}OK, executing...${STY_RST}" ;break ;;
        [eE]) echo -e "${STY_BLUE}Exiting...${STY_RST}" ;exit ;break ;;
        [sS]) echo -e "${STY_BLUE}Alright, skipping this one...${STY_RST}" ;execute=false ;break ;;
        "yesforall") echo -e "${STY_BLUE}Alright, won't ask again. Executing...${STY_RST}"; ask=false ;break ;;
        *) echo -e "${STY_RED}Please enter [y/e/s/yesforall].${STY_RST}";;
      esac
    done
  fi
  if $execute;then x "$@";else
    echo -e "${STY_YELLOW}[$0]: Skipped \"$*\"${STY_RST}"
  fi
}
# When use v() for a defined function, use x() INSIDE its definition to catch errors.
function x(){
  if "$@";then local cmdstatus=0;else local cmdstatus=1;fi # 0=normal; 1=failed; 2=failed but ignored
  while [ $cmdstatus == 1 ] ;do
    echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$*${STY_RED}\" has failed."
    echo -e "You may need to resolve the problem manually BEFORE repeating this command."
    echo -e "[Tip] If a certain package is failing to install, try installing it separately in another terminal.${STY_RST}"
    echo "  r = Repeat this command (DEFAULT)"
    echo "  e = Exit now"
    echo "  i = Ignore this error and continue (your setup might not work correctly)"
    local p; read -p " [R/e/i]: " p
    case $p in
      [iI]) echo -e "${STY_BLUE}Alright, ignore and continue...${STY_RST}";cmdstatus=2;;
      [eE]) echo -e "${STY_BLUE}Alright, will exit.${STY_RST}";break;;
      *) echo -e "${STY_BLUE}OK, repeating...${STY_RST}"
         if "$@";then cmdstatus=0;else cmdstatus=1;fi
         ;;
    esac
  done
  case $cmdstatus in
    0) echo -e "${STY_BLUE}[$0]: Command \"${STY_GREEN}$*${STY_BLUE}\" finished.${STY_RST}";;
    1) echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$*${STY_RED}\" has failed. Exiting...${STY_RST}";exit 1;;
    2) echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$*${STY_RED}\" has failed but ignored by user.${STY_RST}";;
  esac
}
function showfun(){
  echo -e "${STY_BLUE}[$0]: The definition of function \"$1\" is as follows:${STY_RST}"
  printf "${STY_GREEN}"
  type -a "$1" 2>/dev/null || return 1
  printf "${STY_RST}"
}
function pause(){
  if [ ! "$ask" == "false" ];then
    printf "${STY_FAINT}${STY_SLANT}"
    local p; read -p "(Ctrl-C to abort, others to proceed)" p
    printf "${STY_RST}"
  fi
}
function remove_bashcomments_emptylines(){
  mkdir -p "$(dirname "$2")" && cat "$1" | sed -e 's/#.*//' -e '/^[[:space:]]*$/d' > "$2"
}
function prevent_sudo_or_root(){
  case $(whoami) in
    root) echo -e "${STY_RED}[$0]: This script is NOT to be executed with sudo or as root. Aborting...${STY_RST}";exit 1;;
  esac
}
function auto_update_git_submodule(){
  if git submodule status --recursive | grep -E '^[+-U]';then
    # Note: `git pull --recurse-submodules` cannot substitute `git submodule update --init --recursive` cuz it does not init a submodule when needed.
    x git submodule update --init --recursive
  fi
}
function backup_clashing_targets(){
  # For non-recursive dirs/files under target_dir, only backup those which clashes with the ones under source_dir
  # However, ignore the ones listed in ignored_list

  # Deal with arguments
  local source_dir="$1"
  local target_dir="$2"
  local backup_dir="$3"
  local -a ignored_list=("${@:4}")

  # Find clash dirs/files, save as clash_list
  local clash_list=()
  local source_list=($(ls -A "$source_dir"))
  local target_list=($(ls -A "$target_dir"))
  local -A target_map
  for i in "${target_list[@]}"; do
    target_map["$i"]=1
  done
  for i in "${source_list[@]}"; do
    if [[ -n "${target_map[$i]}" ]]; then
      clash_list+=("$i")
    fi
  done
  local -A delk
  for del in "${ignored_list[@]}" ; do delk[$del]=1 ; done
  for k in "${!clash_list[@]}" ; do
    [ "${delk[${clash_list[$k]}]-}" ] && unset 'clash_list[k]'
  done
  clash_list=("${clash_list[@]}")

  # Construct args_includes for rsync
  local args_includes=()
  for i in "${clash_list[@]}"; do
    if [[ -d "$target_dir/$i" ]]; then
      args_includes+=(--include="/$i/")
      args_includes+=(--include="/$i/**")
    else
      args_includes+=(--include="/$i")
    fi
  done
  args_includes+=(--exclude='*')

  x mkdir -p $backup_dir
  x rsync -av --progress "${args_includes[@]}" "$target_dir/" "$backup_dir/"
}
