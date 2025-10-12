# !/bin/sh
# Dotfiles installer for Fedora.
# Run with super-user privileges.
#
# Author: guylev38
# Date: 10/10/2025

# ----- Consts ----- #

PACKAGES="git neovim stow kitty npm zsh tmux ripgrep"

# ------ Functions ----- #

configure_dnf() {
  echo "[+] Configuring DNF..."
  echo "fastestmirror=True" >>/etc/dnf/dnf.conf
  echo "max_parallel_downloads=10" >>/etc/dnf/dnf.conf
  echo "defaultyes=True" >>/etc/dnf/dnf.conf
  echo "[+] Configured DNF!"
}

enable_rpm_fusion() {
  echo "Enabling RPM Fusion"
  dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

unpack_dotfiles() {
  # Rebuild dotfiles and return to it.
}

main() {
  if [ $EUID -ne 0 ]; then # Check if root.
    if [-z "$1"]; then
      echo "Usage: ./fedora.sh <user> <github_username>"
      exit 1
    fi
    configure_dnf
    echo "Updating the system"
    enable_rpm_fusion
    dnf update -y

    dnf install $PACKAGES

  fi

  else
  echo "Run with root privileges!"
}

main
