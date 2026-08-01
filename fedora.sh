#!/usr/bin/env bash
# Fedora dotfiles installer — minimal: configure dnf, install packages, stow configs.
# Run from anywhere:  bash fedora.sh
# Assumes this script sits inside the dotfiles repo (no git clone).

set -euo pipefail

# ---------- pretty output ----------
if [ -t 1 ]; then
  red=$(tput setaf 1); green=$(tput setaf 2); blue=$(tput setaf 4); reset=$(tput sgr0); bold=$(tput bold)
else
  red=''; green=''; blue=''; reset=''; bold=''
fi
info()  { printf '%s[+]%s %s%s%s\n' "$green" "$reset" "$blue" "$*" "$reset"; }
warn()  { printf '%s[!]%s %s\n'            "$red"   "$reset" "$*"; }
die()   { warn "$*"; exit 1; }

# ---------- identity ----------
# Detect Fedora
. /etc/os-release 2>/dev/null || die "Could not read /etc/os-release — not Fedora?"
[ "${ID:-}" = "fedora" ] || die "This script targets Fedora (detected: ${ID:-unknown})."

# Resolve target user (whoever invoked sudo, or current user)
if [ "$(id -u)" -eq 0 ]; then
  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    target_user="$SUDO_USER"
    target_home=$(getent passwd "$target_user" | cut -d: -f6)
  else
    target_user="root"
    target_home="$HOME"
  fi
else
  target_user="$USER"
  target_home="$HOME"
fi

[ -n "$target_home" ] && [ -d "$target_home" ] || die "Could not determine target home directory."
export HOME="$target_home"

info "Target user:    $target_user"
info "Target home:    $target_home"

# ---------- preflight ----------
command -v sudo >/dev/null 2>&1 || die "'sudo' is required."
[ "$(id -u)" -ne 0 ] && SUDO="sudo -E" || SUDO=""
stow --version >/dev/null 2>&1 || $SUDO dnf install -y stow

# ---------- locate the dotfiles repo (this script's directory) ----------
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -d "$script_dir/alacritty" ] || die "Dotfiles repo not found at $script_dir (expected alacritty/, kitty/, etc. siblings of this script)."
info "Dotfiles repo:  $script_dir"

# ---------- 1. configure dnf ----------
info "Configuring DNF…"
$SUDO tee /etc/dnf/dnf.conf >/dev/null <<'EOF'
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
EOF

info "Updating system packages…"
$SUDO dnf -y upgrade || warn "dnf upgrade failed; continuing (network/repo issues?)"

info "Enabling RPM Fusion (free + nonfree)…"
fedora_ver="$(rpm -E %fedora)"
$SUDO dnf -y install \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm" || \
  warn "RPM Fusion install failed (may already be enabled)."

info "Removing 'powerline' to avoid a Neovim plugin conflict…"
$SUDO dnf -y remove powerline || true

# ---------- 2. install packages ----------
info "Installing packages…"
$SUDO dnf -y install \
  bpytop fd neofetch nodejs npm fzf kitty alacritty zsh stow \
  git tmux ripgrep xclip fastfetch

# exa has been renamed to eza on Fedora; install via cargo isn't desired, so skip silently.
# If you want exa back, swap the stow config or install eza:  sudo dnf install -y eza

# ---------- 3. stow configs ----------
info "Stowing dotfiles into $target_home…"
cd "$script_dir"

# Back up any existing conflicting files in $HOME so stow doesn't choke.
backup_dir="$target_home/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
for pkg in alacritty kitty nvim bash tmux zsh .scripts; do
  [ -d "$pkg" ] || continue
  # stow finds all top-level files/dirs under $pkg; only the ones that map to $HOME matter.
  while IFS= read -r -d '' item; do
    rel="${item#./}"
    rel="${rel#${pkg}/}"
    [ -n "$rel" ] || continue
    target="$target_home/$rel"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mkdir -p "$backup_dir/$(dirname "$rel")"
      mv "$target" "$backup_dir/$rel"
      warn "Backed up $target -> $backup_dir/$rel"
    fi
  done < <(find "./$pkg" -mindepth 1 -maxdepth 1 -print0)
done

stow -v -t "$target_home" -d "$script_dir" \
  alacritty kitty nvim bash tmux zsh .scripts

# ---------- done ----------
info "All set. Restart your terminal (or 'exec zsh') to pick up the new config."
if command -v fastfetch >/dev/null 2>&1; then
  fastfetch || true
elif command -v neofetch >/dev/null 2>&1; then
  neofetch || true
fi
