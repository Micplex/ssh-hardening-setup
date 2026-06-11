#!/usr/bin/env bash
# add-user-key.sh — Add a new SSH public key for a user on the server.
#
# Usage:
#   sudo ./add-user-key.sh <username> "<full-public-key-line>"
#   sudo ./add-user-key.sh alice "ssh-ed25519 AAAAC3NzaC... alice@company.com"
#   sudo ./add-user-key.sh bob "$(cat ~/bob-key.pub)"
#
# What this script does:
#   1. Creates the Unix user account if it doesn't exist
#   2. Creates ~/.ssh/ with correct permissions (700)
#   3. Appends the public key to ~/.ssh/authorized_keys
#   4. Sets authorized_keys permissions to 600
#   5. Verifies the key was added correctly

set -euo pipefail

# ---------- helpers ----------
die() {
    echo "ERROR: $*" >&2
    exit 1
}

info() {
    echo "==> $*"
}

usage() {
    cat <<EOF
Usage: sudo $0 <username> "<public-key>"

Add a user's SSH public key to the server. Creates the Unix account
if it doesn't already exist.

Arguments:
  username      The Unix username to add the key for
  public-key    The full public key line (including ssh-ed25519 prefix and comment)

Examples:
  sudo $0 alice "ssh-ed25519 AAAAC3NzaC... alice@company.com"
  sudo $0 bob "\$(cat ~/bob-key.pub)"
EOF
    exit 1
}

# ---------- root check ----------
if [[ "$(id -u)" -ne 0 ]]; then
    die "This script must be run as root (use sudo)."
fi

# ---------- parse arguments ----------
USERNAME="${1:-}"
PUBKEY="${2:-}"

if [[ -z "$USERNAME" || -z "$PUBKEY" ]]; then
    usage
fi

# ---------- validate the key format ----------
if ! echo "$PUBKEY" | grep -qE '^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-dss) '; then
    die "The provided key doesn't look like a valid SSH public key."
    echo "    Expected format: ssh-ed25519 AAAAC3NzaC... comment"
    echo "    Got: $PUBKEY"
fi

# ---------- create user if needed ----------
if id "$USERNAME" &>/dev/null; then
    info "User '$USERNAME' already exists."
else
    info "Creating user: $USERNAME"
    useradd -m -s /bin/bash "$USERNAME" || die "Failed to create user $USERNAME"
    info "User '$USERNAME' created."
fi

# ---------- get user's home directory ----------
USER_HOME=$(eval echo "~$USERNAME")
if [[ ! -d "$USER_HOME" ]]; then
    die "Home directory for $USERNAME not found at $USER_HOME"
fi

# ---------- deploy the key ----------
info "Deploying SSH key for $USERNAME..."

# Create .ssh directory
mkdir -p "$USER_HOME/.ssh"

# Append the key (using >> to never overwrite existing keys)
echo "$PUBKEY" >> "$USER_HOME/.ssh/authorized_keys"

# Fix ownership
chown -R "$USERNAME":"$USERNAME" "$USER_HOME/.ssh"

# Fix permissions
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"

# ---------- verify ----------
info "Verifying key deployment..."

# Check the key is actually in the file
if grep -qF "$PUBKEY" "$USER_HOME/.ssh/authorized_keys"; then
    info "Key successfully added."
else
    die "Key was not found in authorized_keys after writing. Something went wrong."
fi

# Check permissions
SSH_DIR_PERMS=$(stat -c "%a" "$USER_HOME/.ssh")
AUTH_KEYS_PERMS=$(stat -c "%a" "$USER_HOME/.ssh/authorized_keys")

if [[ "$SSH_DIR_PERMS" != "700" ]]; then
    warn "~/.ssh permissions are $SSH_DIR_PERMS (expected 700)"
fi
if [[ "$AUTH_KEYS_PERMS" != "600" ]]; then
    warn "authorized_keys permissions are $AUTH_KEYS_PERMS (expected 600)"
fi

# ---------- summary ----------
echo ""
echo "===== KEY ADDED SUCCESSFULLY ====="
echo "  User:       $USERNAME"
echo "  Home:       $USER_HOME"
echo "  Key file:   $USER_HOME/.ssh/authorized_keys"
echo "  .ssh perms: $SSH_DIR_PERMS"
echo "  auth perms: $AUTH_KEYS_PERMS"
echo ""
echo "  The user can now connect with: ssh $USERNAME@$(hostname)"
echo ""

# Show all keys for this user
echo "  Current keys for $USERNAME:"
cat "$USER_HOME/.ssh/authorized_keys" | while IFS= read -r line; do
    # Show just the key type and comment for readability
    comment=$(echo "$line" | awk '{print $NF}')
    keytype=$(echo "$line" | awk '{print $1}')
    echo "    - [$keytype] $comment"
done