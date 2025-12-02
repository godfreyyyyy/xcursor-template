#!/usr/bin/env /bin/bash

# If run as root, it will place cursor themes at "/usr/share/icons" directory.
# Otherwise at "$HOME/.local/share/icons".

. vars.sh

install_for_root() {
  cp -r $builds_dir/* /usr/share/icons
}

install_for_user() {
  cp -r $builds_dir/* $HOME/.local/share/icons
}

if [ "$EUID" -ne 0 ]
then
  install_for_user
else
  install_for_root
fi
