#!/usr/bin/env bash
# revoke-user-key.sh — Remove an SSH public key from authorized_keys by comment string.
#
# Usage:
#   sudo ./revoke-user-key.sh <username> "<comment-to-match>"
#   sudo ./revoke-user-key.sh alice "alice@company.com"
#   sudo ./revoke-user-key.sh bob "bob-old-key-2024"
#   sudo ./revoke-user-key.sh alice "alice@company.com" --remove-user
#
# What this script does:
#   1. Finds the key line(s) in authorized_keys matching the comment
#   2. Shows which key(s) will be removed and asks for confirmation
#   3. Removes the matching line(s) from authorized_keys
#   4. Optionally removes the user account (--remove-user flag)
#   5. Saves a backup of authorized_keys before modification

set -euo pipefail

# ---------- helpers ----------
die() {
    echo "ERROR: $*" >&2
    exit 1
}

warn() {
    echo "⚠️  $*"
}

info() {
    echo "==> $*"
}

usage() {
    cat <<EOF
Usage: sudo $0 <username> "<comment>" [--remove-user]

Revoke SSH access by removing a key from authorized_keys matching the comment.

Arguments:
  username       The Unix username whose key to revoke
  comment        The comment string to match (from the -C flag during keygen)
  --remove-user  Also delete the Unix user account and home directory

Examples:
  sudo $0 alice "alice@company.com"
  sudo $0 bob "bob-old-laptop" --remove-user
EOF
    exit 1
}

# ---------- root check ----------
if [[ "$(id -u)" -ne 0 ]]; then
    die "This script must be run as root (use sudo)."
fi

# ---------- parse arguments ----------
USERNAME="${1:-}"
COMMENT="${2:-}"
REMOVE_USER=false

if [[ -z "$USERNAME" || -z "$COMMENT" ]]; then
    usage
fi

shift 2
for arg in "$@"; do
    case "$arg" in
        --remove-user) REMOVE_USER=true ;;
        *) usage ;;
    esac
done

# ---------- verify user exists ----------
if ! id "$USERNAME" &>/dev/null; then
    die "User '$USERNAME' does not exist on this system."
fi

# ---------- get user's home and authorized_keys ----------
USER_HOME=$(eval echo "~$USERNAME")
AUTH_KEYS="$USER_HOME/.ssh/authorized_keys"

if [[ ! -f "$AUTH_KEYS" ]]; then
    die "No authorized_keys file found for $USERNAME at $AUTH_KEYS"
fi

# ---------- find matching keys ----------
info "Searching for keys matching comment: '$COMMENT'..."

MATCHING_LINES=$(grep -n "$COMMENT" "$AUTH_KEYS" 2>/dev/null || true)

if [[ -z "$MATCHING_LINES" ]]; then
    info "No keys found matching '$COMMENT' for user $USERNAME."
    echo ""
    echo "  All keys for $USERNAME:"
    grep -n "" "$AUTH_KEYS" | while IFS= read -r line; do
        echo "    $line"
    done
    exit 0
fi

# ---------- show what will be removed ----------
echo ""
echo "  The following key(s) will be REMOVED from $AUTH_KEYS:"
echo ""
echo "$MATCHING_LINES" | while IFS= read -r line; do
    echo "    Line $line"
done
echo ""

# ---------- confirm ----------
read -r -p "Remove these key(s)? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborted. No keys were removed."
    exit 0
fi

# ---------- backup ----------
BACKUP_FILE="$USER_HOME/.ssh/authorized_keys.backup.$(date +%Y%m%d-%H%M%S)"
cp "$AUTH_KEYS" "$BACKUP_FILE"
info "Backup saved to: $BACKUP_FILE"

# ---------- remove matching lines ----------
info "Removing matching key(s)..."

# Create temp file without matching lines
grep -v "$COMMENT" "$AUTH_KEYS" > "$AUTH_KEYS.tmp"
mv "$AUTH_KEYS.tmp" "$AUTH_KEYS"

# Fix permissions in case they got reset
chown "$USERNAME":"$USERNAME" "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"

# ---------- verify removal ----------
if grep -q "$COMMENT" "$AUTH_KEYS" 2>/dev/null; then
    warn "Some matching lines may still exist. Please check manually:"
    grep "$COMMENT" "$AUTH_KEYS"
else
    info "Key(s) matching '$COMMENT' successfully removed."
fi

# ---------- show remaining keys ----------
REMAINING=$(wc -l < "$AUTH_KEYS")
echo ""
echo "  Remaining keys for $USERNAME ($REMAINING total):"
if [[ "$REMAINING" -eq 0 ]]; then
    echo "    (none)"
else
    cat "$AUTH_KEYS" | while IFS= read -r line; do
        comment=$(echo "$line" | awk '{print $NF}')
        keytype=$(echo "$line" | awk '{print $1}')
        echo "    - [$keytype] $comment"
    done
fi

# ---------- optionally remove user ----------
if [[ "$REMOVE_USER" == true ]]; then
    echo ""
    read -r -p "Also DELETE user account '$USERNAME' and their home directory? (yes/no): " confirm_user
    if [[ "$confirm_user" == "yes" ]]; then
        info "Removing user account: $USERNAME"
        userdel -r "$USERNAME" 2>/dev/null || {
            warn "userdel -r may have partially failed. Check if $USERNAME still exists."
        }
        info "User '$USERNAME' has been removed."
    else
        echo "User account kept. Only SSH keys were revoked."
    fi
else
    echo ""
    echo "  User account '$USERNAME' was NOT removed."
    echo "  To remove the user: sudo userdel -r $USERNAME"
    echo "  Or re-run this script with --remove-user"
fi

echo ""
info "Revocation complete."
echo "  Backup: $BACKUP_FILE"
echo "  To restore: sudo cp $BACKUP_FILE $AUTH_KEYS"