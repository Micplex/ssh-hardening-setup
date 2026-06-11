#!/usr/bin/env bash
# setup-client.sh — Generate an Ed25519 keypair and copy the public key to a server.
#
# Usage:
#   ./setup-client.sh user@your-server.com
#   ./setup-client.sh -p 2222 user@your-server.com
#   ./setup-client.sh -k ~/.ssh/id_ed25519_work user@your-server.com
#
# What this script does:
#   1. Creates ~/.ssh/ with correct permissions if it doesn't exist
#   2. Generates a new Ed25519 keypair (skips if a key with that name already exists)
#   3. Copies the public key to the target server using ssh-copy-id
#   4. Adds the private key to ssh-agent
#   5. Tests the connection with key-only auth

set -euo pipefail

# ---------- defaults ----------
KEY_PATH="$HOME/.ssh/id_ed25519"
KEY_COMMENT=""
PORT="22"
SERVER=""

# ---------- helpers ----------
die() {
    echo "ERROR: $*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] user@server

Options:
  -k PATH     Path for the keypair (default: ~/.ssh/id_ed25519)
  -c COMMENT  Comment for the key (default: user@hostname-YYYYMMDD)
  -p PORT     SSH port on the target server (default: 22)
  -h          Show this help message

Examples:
  $(basename "$0") user@example.com
  $(basename "$0") -p 2222 user@example.com
  $(basename "$0") -k ~/.ssh/id_ed25519_work -c "me@company.com" user@host.com
EOF
    exit 0
}

# ---------- parse arguments ----------
while getopts "k:c:p:h" opt; do
    case "$opt" in
        k) KEY_PATH="$OPTARG" ;;
        c) KEY_COMMENT="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

SERVER="${1:-}"

if [[ -z "$SERVER" ]]; then
    die "Missing server argument. Usage: $0 user@server"
fi

# Auto-generate comment if not provided
if [[ -z "$KEY_COMMENT" ]]; then
    KEY_COMMENT="${USER:-anonymous}@$(hostname)-$(date +%Y%m%d)"
fi

# ---------- ensure ~/.ssh exists ----------
echo "==> Ensuring ~/.ssh/ directory exists with correct permissions..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ---------- generate keypair ----------
if [[ -f "$KEY_PATH" ]]; then
    echo "==> WARNING: $KEY_PATH already exists."
    read -r -p "Overwrite? (y/N) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -f "$KEY_PATH" "$KEY_PATH.pub"
    else
        die "Key already exists. Use -k to specify a different path, or remove the existing key first."
    fi
fi

echo "==> Generating Ed25519 keypair: $KEY_PATH"
echo "    Comment: $KEY_COMMENT"

ssh-keygen -t ed25519 -C "$KEY_COMMENT" -f "$KEY_PATH" || die "ssh-keygen failed"

chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"
echo "    Keypair created successfully."

# ---------- display public key ----------
echo ""
echo "===== YOUR PUBLIC KEY (safe to share) ====="
cat "${KEY_PATH}.pub"
echo "==========================================="
echo ""

# ---------- copy key to server ----------
echo "==> Copying public key to $SERVER (port $PORT)..."
echo "    You will be prompted for the server password."

if [[ "$PORT" == "22" ]]; then
    ssh-copy-id -i "${KEY_PATH}.pub" "$SERVER" || die "ssh-copy-id failed. Check your password and server reachability."
else
    ssh-copy-id -i "${KEY_PATH}.pub" -p "$PORT" "$SERVER" || die "ssh-copy-id failed. Check your password, port, and server reachability."
fi
echo "    Public key copied successfully."

# ---------- add to ssh-agent ----------
echo "==> Adding private key to ssh-agent..."
if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    eval "$(ssh-agent -s)" > /dev/null
fi
ssh-add "$KEY_PATH" || echo "    WARNING: Could not add key to agent (you can do this manually later)."

# ---------- test connection ----------
echo "==> Testing key-based authentication..."
echo "    (You may be prompted for the key passphrase if you set one)"

SSH_CMD="ssh -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o ConnectTimeout=10"
if [[ "$PORT" != "22" ]]; then
    SSH_CMD="$SSH_CMD -p $PORT"
fi

if $SSH_CMD -i "$KEY_PATH" "$SERVER" "echo '    Connection successful — key authentication works!'"; then
    echo "==> Setup complete! Your key is now deployed to $SERVER."
    echo ""
    echo "    Next steps:"
    echo "    1. Read the hardening guide: docs/05-configure-sshd.md"
    echo "    2. Run: ./scripts/harden-server.sh (ONLY after verifying key auth)"
    echo ""
    echo "    IMPORTANT: Keep your private key ($KEY_PATH) safe and never share it."
else
    echo ""
    echo "    WARNING: Key authentication test failed."
    echo "    The key was copied to the server, but something prevented a successful login."
    echo "    Troubleshoot with: ssh -vvv -i $KEY_PATH $SERVER"
    echo "    See docs/07-troubleshooting.md for common fixes."
fi