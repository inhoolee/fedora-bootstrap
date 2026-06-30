#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf '\n[warn] %s\n' "$*" >&2
}

die() {
  printf '\n[error] %s\n' "$*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

run_sudo() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '[dry-run] sudo'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  sudo "$@"
}

is_fedora() {
  [[ -r /etc/os-release ]] && . /etc/os-release && [[ "${ID:-}" == "fedora" ]]
}

dnf_install() {
  local packages=("$@")

  if ((${#packages[@]} == 0)); then
    return 0
  fi

  log "Installing packages"
  run_sudo dnf install -y "${packages[@]}"
}

enable_rpm_fusion() {
  local fedora_version

  fedora_version="$(rpm -E %fedora)"
  if rpm -q rpmfusion-free-release >/dev/null 2>&1 && rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
    log "RPM Fusion is already enabled"
    return 0
  fi

  log "Enabling RPM Fusion"
  run_sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm"
}

enable_flathub() {
  need_command flatpak

  if flatpak remotes --columns=name | grep -qx flathub; then
    log "Flathub is already enabled"
    return 0
  fi

  log "Enabling Flathub"
  run_sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

configure_dnf() {
  local conf=/etc/dnf/dnf.conf
  local settings=(
    "max_parallel_downloads=10"
    "defaultyes=True"
  )

  log "Configuring DNF"
  for setting in "${settings[@]}"; do
    if grep -qxF "$setting" "$conf"; then
      continue
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      printf '[dry-run] append %q to %s\n' "$setting" "$conf"
    else
      printf '%s\n' "$setting" | sudo tee -a "$conf" >/dev/null
    fi
  done
}

main() {
  local packages=(
    curl
    dnf-plugins-core
    fastfetch
    fd-find
    flatpak
    fzf
    git
    htop
    jq
    make
    neovim
    ripgrep
    ShellCheck
    tmux
    unzip
    vim
    wget
    zsh
  )

  is_fedora || die "$SCRIPT_NAME is intended for Fedora only."
  need_command sudo
  need_command dnf
  need_command rpm

  log "Refreshing package metadata"
  run_sudo dnf makecache --refresh

  configure_dnf
  enable_rpm_fusion
  dnf_install "${packages[@]}"
  enable_flathub

  log "Updating installed packages"
  run_sudo dnf upgrade -y

  log "Done"
}

main "$@"
