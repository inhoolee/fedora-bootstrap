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

run_user() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

is_fedora() {
  [[ -r /etc/os-release ]] && . /etc/os-release && [[ "${ID:-}" == "fedora" ]]
}

set_dark_mode() {
  if ! command -v gsettings >/dev/null 2>&1; then
    warn "gsettings is not available; skipping GNOME dark mode."
    return 0
  fi

  if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    warn "No graphical session detected; skipping GNOME dark mode."
    return 0
  fi

  log "Setting GNOME dark mode"
  run_user gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  run_user gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
}

rename_user_dir() {
  local source_dir="$1"
  local target_dir="$2"

  if [[ ! -d "$source_dir" ]]; then
    return 0
  fi

  if [[ -e "$target_dir" ]]; then
    warn "Cannot rename $source_dir to $target_dir because the target already exists."
    return 0
  fi

  run_user mv "$source_dir" "$target_dir"
}

set_xdg_user_dir() {
  local key="$1"
  local path="$2"

  if [[ ! -d "$path" ]]; then
    return 0
  fi

  if ! command -v xdg-user-dirs-update >/dev/null 2>&1; then
    warn "xdg-user-dirs-update is not available; skipping XDG setting for $key."
    return 0
  fi

  run_user xdg-user-dirs-update --set "$key" "$path"
}

delete_empty_korean_named_dirs() {
  local dir
  local dir_name

  for dir in "$HOME"/*; do
    [[ -d "$dir" ]] || continue

    dir_name="$(basename "$dir")"
    printf '%s\n' "$dir_name" | grep -Pq '\p{Hangul}' || continue

    if find "$dir" -mindepth 1 -print -quit | grep -q .; then
      warn "Skipping non-empty Korean-named directory: $dir"
      continue
    fi

    run_user rmdir "$dir"
  done
}

normalize_user_dirs() {
  log "Normalizing home directory names"
  rename_user_dir "$HOME/바탕화면" "$HOME/Desktop"
  rename_user_dir "$HOME/문서" "$HOME/Documents"
  rename_user_dir "$HOME/다운로드" "$HOME/Downloads"
  delete_empty_korean_named_dirs
  set_xdg_user_dir DESKTOP "$HOME/Desktop"
  set_xdg_user_dir DOCUMENTS "$HOME/Documents"
  set_xdg_user_dir DOWNLOAD "$HOME/Downloads"
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

  set_dark_mode
  normalize_user_dirs

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
