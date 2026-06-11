#!/usr/bin/env bash
# harden-server.sh — Apply a secure sshd_config to the server.
#
# ⚠️  WARNING: This script disables password authentication.
#     You MUST have SSH key authentication working BEFORE running this.
#     Keep a second terminal session open as a safety net.
#
# Usage (run on the server as root or with sudo):
#   sudo ./harden-server.sh
#   sudo ./harden-server.sh --dry-run
#
# What this script does:
#   1. Backs up the existing sshd_config with a timestamp
#   2. Warns loudly about the risks
#   3. Applies hardened settings (or shows what would change in dry-run mode)
#   4. Validates the new config with sshd -t
#   5. Restarts sshd only if the config is valid
#   6. Runs a verification check

set -euo pipefail

# ---------- config ----------
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_DIR="/etc/ssh/backups"
DRY_RUN=false

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

# ---------- parse arguments ----------
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: sudo $0 [--dry-run]"
            echo ""
            echo "  --dry-run   Show what would be changed without applying"
            exit 0
            ;;
    esac
done

# ---------- root check ----------
if [[ "$(id -u)" -ne 0 ]]; then
    die "This script must be run as root (use sudo)."
fi

# ---------- check current password access ----------
info "Checking current SSH configuration..."
if ! systemctl is-active --quiet sshd 2>/dev/null && ! systemctl is-active --quiet ssh 2>/dev/null; then
    die "sshd is not running. Start it first before hardening."
fi

# ---------- BIG WARNING ----------
echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║                     ⚠️  CRITICAL WARNING                  ║"
echo "  ║                                                          ║"
echo "  ║  This script will DISABLE PASSWORD AUTHENTICATION.       ║"
echo "  ║  Ensure SSH key authentication is WORKING before         ║"
echo "  ║  proceeding, or you will be LOCKED OUT of this server.   ║"
echo "  ║                                                          ║"
echo "  ║  KEEP A SECOND TERMINAL SESSION OPEN as a fallback.      ║"
echo "  ║                                                          ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""

read -r -p "Have you verified SSH key auth works? (yes/no): " answer
if [[ "$answer" != "yes" ]]; then
    echo "Aborted. Set up key authentication first — see docs/04-copy-key-to-server.md"
    exit 1
fi

# ---------- backup ----------
info "Backing up current sshd_config..."
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/sshd_config.backup.$(date +%Y%m%d-%H%M%S)"
cp "$SSHD_CONFIG" "$BACKUP_FILE"
info "Backup saved to: $BACKUP_FILE"

# ---------- define hardened settings ----------
# Each entry is "setting|value|description"
SETTINGS=(
    "PermitRootLogin|no|Disable root login via SSH"
    "PasswordAuthentication|no|Disable password authentication"
    "ChallengeResponseAuthentication|no|Disable keyboard-interactive auth"
    "PubkeyAuthentication|yes|Enable public key authentication"
    "PermitEmptyPasswords|no|Reject accounts with empty passwords"
    "MaxAuthTries|3|Limit authentication attempts per connection"
    "MaxSessions|10|Limit concurrent sessions per connection"
    "ClientAliveInterval|300|Send keepalive every 5 minutes"
    "ClientAliveCountMax|2|Drop connection after 2 missed keepalives"
    "LoginGraceTime|30|30-second grace period for authentication"
    "X11Forwarding|no|Disable X11 forwarding"
    "AllowAgentForwarding|no|Disable SSH agent forwarding"
    "AllowTcpForwarding|no|Disable TCP forwarding"
    "PermitTunnel|no|Disable SSH tunneling"
    "LogLevel|VERBOSE|Increase log detail for auditing"
    "SyslogFacility|AUTH|Log to AUTH facility"
    "KexAlgorithms|curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512|Strong key exchange algorithms"
    "Ciphers|chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com|Strong ciphers"
    "MACs|hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com|Strong MACs"
    "HostKeyAlgorithms|ssh-ed25519,ssh-ed25519-cert-v01@openssh.com|Strong host key algorithms"
)

# ---------- apply or preview ----------
if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo "===== DRY RUN — The following changes would be applied: ====="
    echo ""
    for entry in "${SETTINGS[@]}"; do
        IFS='|' read -r setting value description <<< "$entry"
        current_val=$(grep -E "^#?${setting} " "$SSHD_CONFIG" 2>/dev/null || echo "[Not set]")
        echo "  $setting  →  $value"
        echo "      Description: $description"
        echo "      Current:     $current_val"
        echo ""
    done
    echo "===== Dry run complete. Run without --dry-run to apply. ====="
    exit 0
fi

# ---------- apply settings ----------
info "Applying hardened sshd_config settings..."

# Create a temporary config
TMP_CONFIG=$(mktemp)
cp "$SSHD_CONFIG" "$TMP_CONFIG"

for entry in "${SETTINGS[@]}"; do
    IFS='|' read -r setting value description <<< "$entry"
    if grep -qE "^#?${setting} " "$TMP_CONFIG"; then
        # Replace existing line (commented or not)
        sed -i "s/^#*${setting} .*/${setting} ${value}/" "$TMP_CONFIG"
    else
        # Append new setting
        echo "${setting} ${value}" >> "$TMP_CONFIG"
    fi
    echo "    ✓ $setting $value  ($description)"
done

# ---------- validate ----------
info "Validating new sshd_config syntax..."
if sshd -t -f "$TMP_CONFIG" 2>&1; then
    info "Configuration syntax is valid."
else
    die "Configuration syntax check FAILED. Restoring backup."
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    exit 1
fi

# ---------- apply and restart ----------
info "Installing new sshd_config and restarting sshd..."
cp "$TMP_CONFIG" "$SSHD_CONFIG"
rm -f "$TMP_CONFIG"

# Determine service name (sshd or ssh depending on distro)
if systemctl is-active --quiet sshd 2>/dev/null; then
    SSH_SERVICE="sshd"
elif systemctl is-active --quiet ssh 2>/dev/null; then
    SSH_SERVICE="ssh"
else
    die "Could not determine SSH service name."
fi

systemctl restart "$SSH_SERVICE" || {
    warn "Failed to restart $SSH_SERVICE. Restoring backup..."
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    systemctl restart "$SSH_SERVICE" 2>/dev/null || true
    die "sshd restart failed. Backup has been restored. Check backup config at $BACKUP_FILE"
}

info "sshd restarted successfully with hardened configuration."

# ---------- verify ----------
echo ""
echo "===== VERIFICATION ====="
echo ""

# Check service is running
if systemctl is-active --quiet "$SSH_SERVICE"; then
    echo "  ✓ $SSH_SERVICE is running"
else
    warn "$SSH_SERVICE is NOT running — check journalctl -u $SSH_SERVICE"
fi

# Check key settings
echo ""
echo "  Key settings applied:"
for setting_value in "PasswordAuthentication no" "ChallengeResponseAuthentication no" "PermitRootLogin no" "PubkeyAuthentication yes"; do
    setting_name="${setting_value% *}"
    if grep -q "^${setting_value}" "$SSHD_CONFIG"; then
        echo "    ✓ $setting_value"
    else
        warn "    ✗ $setting_name — NOT SET or commented out"
    fi
done

# Check listening port
echo ""
echo "  Listening on:"
ss -tlnp 2>/dev/null | grep sshd | awk '{print "    " $4}' || echo "    (could not determine)"

echo ""
info "Hardening complete."
echo ""
echo "  NEXT STEPS:"
echo "  1. Open a NEW terminal and verify you can SSH in with your key"
echo "  2. Try: ssh -o PreferredAuthentications=password user@YOUR_SERVER"
echo "     (This should fail — that means passwords are truly disabled)"
echo ""
echo "  BACKUP LOCATION: $BACKUP_FILE"
echo "  To restore: sudo cp $BACKUP_FILE /etc/ssh/sshd_config && sudo systemctl restart $SSH_SERVICE"