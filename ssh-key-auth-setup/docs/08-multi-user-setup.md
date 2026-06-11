# 08 — Multi-User Setup

Managing SSH key authentication for teams — onboarding, offboarding, per-user keys, and access control via `authorized_keys` options.

---

## The Model: One Key Per Person, Per Machine

Each team member should have their own keypair. Never share private keys between people.

```
alice@laptop  ──►  alice-laptop.pub  ──►  server authorized_keys (alice)
bob@desktop   ──►  bob-desktop.pub   ──►  server authorized_keys (bob)
carol@laptop  ──►  carol-laptop.pub  ──►  server authorized_keys (carol)
```

### Why one key per person?

| Practice | Risk |
|----------|------|
| Shared private key | Can't tell who logged in; can't revoke one person without affecting everyone |
| One key per person | Audit trail works; offboarding is removing one line from `authorized_keys` |
| One key per machine | If a laptop is stolen, only that key needs revoking — the person's other machine still works |

---

## Adding a New Team Member

### Step 1: The new user generates their keypair

```bash
ssh-keygen -t ed25519 -C "alice@company.com" -f ~/.ssh/id_ed25519
```

### Step 2: They send you their public key

```bash
cat ~/.ssh/id_ed25519.pub
# Output: ssh-ed25519 AAAAC3NzaC1lZ... alice@company.com
```

They can send this via Slack, email, a shared password manager — it's public information.

### Step 3: Add their key to the server

```bash
# On the server, as the target user:
echo "ssh-ed25519 AAAAC3NzaC1lZ... alice@company.com" >> ~/.ssh/authorized_keys
```

Or use the script:
```bash
./scripts/add-user-key.sh alice "ssh-ed25519 AAAAC3NzaC1lZ... alice@company.com"
```

### Step 4: Verify

```bash
# The new user tests their access
ssh user@your-server.com
```

---

## Removing a Team Member (Offboarding)

```bash
# Edit authorized_keys and remove their line
nano ~/.ssh/authorized_keys
# Delete the line containing their comment (e.g., "alice@company.com")
```

Or use the script:
```bash
./scripts/revoke-user-key.sh "alice@company.com"
```

This searches for the comment string in `authorized_keys` and removes that line.

**Why comments matter:** The comment field (`-C "alice@company.com"`) becomes the identifier. Without comments, you'd need to match the actual key string — which is unreadable and error-prone.

---

## Advanced: Restricting What a Key Can Do

The `authorized_keys` file supports powerful options before the key. This lets you grant limited access without creating a separate user account.

### Syntax

```
<options> <key-type> <key> <comment>
```

### Common Options

| Option | What It Does | Use Case |
|--------|-------------|----------|
| `command="/path/to/script"` | Forces a specific command — SSH cannot run anything else | Deploy keys, backup scripts |
| `from="192.168.1.0/24"` | Only allow connections from specific IPs/ ranges | Office-only access |
| `no-port-forwarding` | Disable SSH tunneling | Prevent data exfiltration |
| `no-agent-forwarding` | Disable agent forwarding | Prevent credential relay |
| `no-X11-forwarding` | Disable X11 forwarding | Prevent GUI access |
| `no-pty` | Disable pseudo-terminal allocation | For keys that only run a single command |
| `restrict` | Apply all restrictions above at once | Maximum lockdown |
| `environment="VAR=value"` | Set environment variables for the session | Custom paths, app config |

### Example: Deploy-Only Key

This key can only run a deploy script — no shell access, no tunneling:

```
command="/home/deploy/deploy.sh",no-port-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3N... deploy-bot@ci
```

When someone connects with this key:
```bash
ssh deploy@server
# deploy.sh runs automatically
# When deploy.sh exits, the SSH connection closes
# Can't get a shell, can't port-forward, can't run anything else
```

### Example: Office-Only Admin Key

This admin can get a full shell, but only from the office IP range:

```
from="10.0.0.0/8,172.16.0.0/12" ssh-ed25519 AAAAC3N... admin@work-laptop
```

### Example: Read-Only Backup Key

For a backup script that needs to read files but should never modify anything:

```
command="rsync --server --sender -vlogDtprze.iLsfx . /",no-agent-forwarding,no-port-forwarding,no-pty,no-X11-forwarding ssh-ed25519 AAAAC3N... backup@nas
```

---

## User Accounts vs. Shared Accounts

### Option A: Individual Unix Users (Recommended)

Each team member gets their own Linux user account:
```bash
sudo adduser alice
sudo adduser bob
```

Pros:
- Proper audit trails (`/var/log/auth.log` shows who logged in)
- File ownership is clear
- `sudo` can be granted or revoked per-user
- Each user can have their own `authorized_keys`

Cons:
- More setup work

### Option B: Shared Account with Key Comments

Everyone logs in as the same user (e.g., `deploy`), differentiated by key comments:

```
# ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC... alice@company.com
ssh-ed25519 AAAAC3NzaC... bob@company.com
```

Pros:
- Simpler initial setup

Cons:
- `last` and `who` only show `deploy` — no per-person audit trail
- Harder to control per-person `sudo` access
- If one person's key is compromised, everyone's access is suspect

**Recommendation:** Individual accounts for humans. Shared accounts only for automation/CI.

---

## Managing authorized_keys at Scale

### Using a Configuration Management Tool

If you manage many servers, don't edit `authorized_keys` manually. Use:

**Ansible:**
```yaml
- name: Deploy SSH keys for alice
  ansible.posix.authorized_key:
    user: alice
    state: present
    key: "{{ lookup('file', 'keys/alice.pub') }}"
    key_options: 'from="10.0.0.0/8"'
```

**Puppet:**
```puppet
ssh_authorized_key { 'alice@company.com':
  ensure => present,
  user   => 'alice',
  type   => 'ssh-ed25519',
  key    => 'AAAAC3NzaC1lZ...',
  options => ['from="10.0.0.0/8"'],
}
```

### Using a Central authorized_keys File

Point sshd at a single managed file for all users:

```bash
# /etc/ssh/sshd_config
AuthorizedKeysFile /etc/ssh/authorized_keys/%u
```

Then manage `/etc/ssh/authorized_keys/alice`, `/etc/ssh/authorized_keys/bob`, etc. with your config management tool. This keeps keys out of home directories and under centralized control.

---

## Quick Reference: add-user-key.sh Script

```bash
#!/bin/bash
# Usage: ./add-user-key.sh <username> "<public-key>"

USERNAME="$1"
PUBKEY="$2"

if [ -z "$USERNAME" ] || [ -z "$PUBKEY" ]; then
    echo "Usage: $0 <username> \"ssh-ed25519 AAAAC3NzaC... comment\""
    exit 1
fi

# Create user if they don't exist
if ! id "$USERNAME" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$USERNAME"
    echo "Created user: $USERNAME"
fi

# Deploy their key
sudo -u "$USERNAME" mkdir -p /home/"$USERNAME"/.ssh
sudo -u "$USERNAME" chmod 700 /home/"$USERNAME"/.ssh
echo "$PUBKEY" | sudo -u "$USERNAME" tee -a /home/"$USERNAME"/.ssh/authorized_keys > /dev/null
sudo -u "$USERNAME" chmod 600 /home/"$USERNAME"/.ssh/authorized_keys

echo "Key added for $USERNAME"
```

---

**Next:** [09 — Key Rotation](09-key-rotation.md)