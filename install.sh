#!/usr/bin/env bash
# scripts/install.sh
#
# The ONE thing `syz self-update` genuinely can't do: install syz on a
# machine that has never had it before. That's an unavoidable chicken-and-
# egg problem for any CLI tool — you can't run "syz self-update" if `syz`
# doesn't exist yet. This script is the one-time bootstrap; every update
# after this is `syz self-update` (or the GUI's "Install/Update CLI"
# button, which does the same thing and can also do this very first
# install, given the GUI is already on the machine).
#
# This script is meant to be published at the root of the public
# rautte/syzmaniac-releases repo (NOT the private source repo — that one
# nobody but the maintainer can fetch from) so it works as:
#
#   curl -fsSL https://raw.githubusercontent.com/rautte/syzmaniac-releases/main/install.sh | bash
#
# Downloads the latest release for this machine's OS/arch, verifies it
# against goreleaser's published checksums.txt, and installs it to
# $SYZ_INSTALL_DIR (default: $HOME/.local/bin) — never anywhere requiring
# sudo, since this should never need elevated privileges.
set -euo pipefail

REPO="rautte/syzmaniac-releases"
BINARY="syz"
INSTALL_DIR="${SYZ_INSTALL_DIR:-$HOME/.local/bin}"

# Same two-color convention as `syz`'s own Go commands: yellow for a
# warning (nothing broke, but worth knowing), red for a real failure.
# Disabled automatically when stdout isn't a real terminal, same reasoning
# as NO_COLOR — a piped/redirected/logged run shouldn't fill up with raw
# escape codes.
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
  C_RESET=$'\033[0m'
else
  C_YELLOW=""
  C_RED=""
  C_RESET=""
fi
warn() { echo "${C_YELLOW}$*${C_RESET}"; }
err() { echo "${C_RED}$*${C_RESET}" >&2; }

# section prints a titled, dashed-rule divider — same fixed-width box style
# `syz`'s own Go commands use — so a first-time install has clear,
# skimmable stages instead of one undifferentiated wall of lines. A blank
# line always precedes it, so sections never run into each other.
RULE="------------------------------------------------------------------------------"
section() {
  echo ""
  echo "${RULE}"
  echo " $1"
  echo "${RULE}"
}

echo ""
section "🔎 Detecting platform"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "${os}" in
  darwin|linux) ;;
  *) err "❌ Unsupported OS: ${os} (only darwin/linux are published today)"; exit 1 ;;
esac

arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) err "❌ Unsupported architecture: ${arch}"; exit 1 ;;
esac
echo "  OS/Arch:  ${os}/${arch}"

section "🔍 Finding the latest release"
latest_json="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")"
version="$(printf '%s' "${latest_json}" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
if [[ -z "${version}" ]]; then
  err "❌ Couldn't determine the latest release version."
  exit 1
fi
version_num="${version#v}"
echo "  Latest version:  ${version}"

archive="${BINARY}_${version_num}_${os}_${arch}.tar.gz"
base_url="https://github.com/${REPO}/releases/download/${version}"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

section "⬇️  Downloading"
echo "  ${archive}"
curl -fsSL -o "${tmp}/${archive}" "${base_url}/${archive}"
curl -fsSL -o "${tmp}/${BINARY}_checksums.txt" "${base_url}/${BINARY}_checksums.txt"

section "🔐 Verifying"
echo "  Checking sha256 against the published checksums..."
( cd "${tmp}" && grep " ${archive}\$" "${BINARY}_checksums.txt" | shasum -a 256 -c - )

section "📂 Installing"
echo "  Extracting..."
tar -xzf "${tmp}/${archive}" -C "${tmp}"

mkdir -p "${INSTALL_DIR}"
mv "${tmp}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
chmod +x "${INSTALL_DIR}/${BINARY}"
echo "  ✅ Installed ${version} to ${INSTALL_DIR}/${BINARY}"

section "🎉 Done"
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*)
    echo "  Ready — run 'syz --help' to get started."
    ;;
  *)
    warn "  ⚠️  ${INSTALL_DIR} isn't on your PATH yet. Add this to your shell config"
    warn "     (~/.zshrc, ~/.bashrc, or equivalent), then restart your shell:"
    echo ""
    echo "         export PATH=\"${INSTALL_DIR}:\$PATH\""
    ;;
esac
echo ""
