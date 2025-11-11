# This script is meant to be sourced.
# It's not for directly running.
printf "${STY_CYAN}[$0]: 3. Copying config files\n${STY_RST}"

# shellcheck shell=bash

function warning_rsync_delete(){
  printf "${STY_YELLOW}"
  printf "The command below uses --delete for rsync which overwrites the destination folder.\n"
  printf "${STY_RST}"
}

function warning_rsync_normal(){
  printf "${STY_YELLOW}"
  printf "The command below uses rsync which overwrites the destination.\n"
  printf "${STY_RST}"
}

function backup_configs(){
  backup_clashing_targets dots/.config $XDG_CONFIG_HOME "${BACKUP_DIR}/.config"
  #backup_clashing_targets dots/.local/share $XDG_DATA_HOME "${BACKUP_DIR}/.local/share"
  backup_clashing_targets dots/ $HOME/ "${BACKUP_DIR}" .config .local
  printf "${STY_BLUE}Backup into \"${BACKUP_DIR}\" finished.${STY_RST}\n"
}
function ask_backup_configs(){
  showfun backup_clashing_targets
  printf "${STY_RED}"
  printf "Would you like to backup clashing dirs/files under \"$XDG_CONFIG_HOME\" and \"$XDG_DATA_HOME\" to \"$BACKUP_DIR\"?\n"
  printf "${STY_RST}"
  while true;do
    echo "  y = Yes, backup"
    echo "  n/s = No, skip to next"
    local p; read -p "====> " p
    case $p in
      [yY]) echo -e "${STY_BLUE}OK, doing backup...${STY_RST}" ;local backup=true;break ;;
      [nNsS]) echo -e "${STY_BLUE}Alright, skipping...${STY_RST}" ;local backup=false;break ;;
      *) echo -e "${STY_RED}Please enter [y/n].${STY_RST}";;
     esac
  done
  if $backup;then backup_configs;fi
}
function auto_backup_configs(){
  # Backup when $BACKUP_DIR does not exist
  if [[ ! -d "$BACKUP_DIR" ]]; then backup_configs;fi
}
function copy_file_s_t(){
  local s=$1
  local t=$2
  if [ -f $t ];then
    echo -e "${STY_YELLOW}[$0]: \"$t\" already exists.${STY_RST}"
    if $firstrun;then
      echo -e "${STY_BLUE}[$0]: It seems to be the firstrun.${STY_RST}"
      v mv $t $t.old
      v cp -f $s $t
    else
      echo -e "${STY_BLUE}[$0]: It seems not a firstrun.${STY_RST}"
      v cp -f $s $t.new
    fi
  else
    echo -e "${STY_GREEN}[$0]: \"$t\" does not exist yet.${STY_RST}"
    v cp $s $t
  fi
}
function copy_dir_s_t(){
  local s=$1
  local t=$2
  if [ -d $t ];then
    echo -e "${STY_BLUE}[$0]: \"$t\" already exists, will not do anything.${STY_RST}"
  else
    echo -e "${STY_YELLOW}[$0]: \"$t\" does not exist yet.${STY_RST}"
    v rsync -av --delete $s/ $t/
  fi
}

#####################################################################################
showfun auto_update_git_submodule
v auto_update_git_submodule

# In case some dirs does not exists
v mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME
firstrun_file="${XDG_CACHE_HOME}/.ioar-installed"
if test -f "${firstrun_file}"; then
  firstrun=false
else
  firstrun=true
fi

if [[ ! "${SKIP_BACKUP}" == true ]]; then
  case $ask in
    false) auto_backup_configs ;;
    *) ask_backup_configs ;;
  esac
fi

# For Misc configs (except Hyprland)
for i in $(find dots/.config/ -mindepth 1 -maxdepth 1 ! -name 'hypr' -exec basename {} \;); do
  echo "[$0]: Found target: dots/.config/$i"
  if [ -d "dots/.config/$i" ];then warning_rsync_delete; v rsync -av --delete "dots/.config/$i/" "$XDG_CONFIG_HOME/$i/"
  elif [ -f "dots/.config/$i" ];then warning_rsync_normal; v rsync -av "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
  fi
done
for i in .zshrc .p10k.zsh;do
  warning_rsync_normal; v rsync -av "dots/$i" "$HOME/$i"
done

# For Hyprland
x mkdir -p "$XDG_CONFIG_HOME"/hypr
warning_rsync_delete; v rsync -av --delete dots/.config/hypr/hyprland/ "$XDG_CONFIG_HOME"/hypr/hyprland/
copy_file_s_t \
  "dots/.config/hypr/hyprland.conf" \
  "${XDG_CONFIG_HOME}/hypr/hyprland.conf"
copy_file_s_t \
  "dots/.config/hypr/hypridle.conf" \
  "${XDG_CONFIG_HOME}/hypr/hypridle.conf"

copy_dir_s_t \
  "dots/.config/hypr/custom" \
  "${XDG_CONFIG_HOME}/hypr/custom"

v touch "${firstrun_file}"

# Prevent hyprland from not fully loaded
sleep 1
try hyprctl reload

#####################################################################################
printf "\n"
printf "\n"
printf "\n"
printf "${STY_CYAN}[$0]: Finished${STY_RST}\n"
