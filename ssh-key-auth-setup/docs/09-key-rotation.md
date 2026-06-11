# 09 — Key Rotation

SSH keys don't expire on their own. Rotating them on a schedule limits the damage window if a key is ever compromised without your knowledge.

---

## Why Rotate Keys?

| Scenario | Without Rotation | With Rotation |
|----------|-----------------|---------------|
| Laptop stolen 6 months ago | Attacker still has access | Key was rotated — old key is useless |
| Ex-employee's key left active | Permanent backdoor | Rotation policy forces cleanup |
| Private key leaked via backup | Leaked key works forever | Rotated before leak matters |
| Compliance (SOC2, HIPAA, PCI-DSS) | Audit finding | Rotation policy satisfies checkboxes |

---

## Rotation Policy (Recommended)

| Key Type | Rotation Cadence |
|----------|-----------------|
| **Personal keys** (laptop, desktop) | Every 6–12 months |
| **Deploy/CI keys** | Every 90 days |
| **Emergency/break-glass keys** | Every 30 days (and store securely offline) |
| **After a security incident** | Immediately |

---

## Step-by-Step Key Rotation Process

### Step 1: Generate a New Keypair

```bash
# Keep the old key for now — don't delete it yet
ssh-keygen -t ed25519 -C "your-email@example.com-$(date +%Y%m)" -f ~/.ssh/id_ed25519_new
```

**Why include the date?** The comment (`-C`) now shows when the key was generated. At a glance, you or an auditor can see how recent each key is.

### Step 2: Add the New Public Key to the Server

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_new.pub user@your-server.com
```

Now `authorized_keys` has **both** keys:
```
ssh-ed25519 AAA...OLD... your-email@example.com
ssh-ed25519 AAA...NEW... your-email@example.com-202605
```

### Step 3: Test the New Key

```bash
ssh -i ~/.ssh/id_ed25519_new user@your-server.com
```

If this works, the new key is functional.

### Step 4: Remove the Old Key

```bash
# Manual: edit authorized_keys and delete the old key's line
nano ~/.ssh/authorized_keys

# Or use the script:
./scripts/revoke-user-key.sh "your-email@example.com"
```

> ⚠️ Make sure you remove the **right** key. Check the comment fields. If you accidentally delete both, re-add the new one.

### Step 5: Replace the Old Private Key Locally

```bash
# Back up the old key (just in case)
mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.old.$(date +%Y%m%d)
mv ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519.pub.old.$(date +%Y%m%d)

# Move the new key into place
mv ~/.ssh/id_ed25519_new ~/.ssh/id_ed25519
mv ~/.ssh/id_ed25519_new.pub ~/.ssh/id_ed25519.pub

# Fix permissions
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Step 6: Update the SSH Agent

```bash
ssh-add -d ~/.ssh/id_ed25519.old.$(date +%Y%m%d)   # Remove old key from agent
ssh-add ~/.ssh/id_ed25519                            # Add the new key
```

### Step 7: Final Verification

```bash
# Standard connection — should use the new key automatically
ssh user@your-server.com
```

---

## Automating Rotation with a Script

The `scripts/` directory includes a `rotate-key.sh` for consistent rotation. Usage:

```bash
./scripts/rotate-key.sh user@your-server.com
```

What it does:
1. Generates a new Ed25519 key with a timestamped comment
2. Copies it to the server via `ssh-copy-id`
3. Tests the new key before removing the old one
4. Removes old key from server's `authorized_keys`
5. Archives the old key locally
6. Updates the SSH agent

---

## Multi-Server Rotation

Rotating a key across many servers:

```bash
#!/bin/bash
# Rotate a personal key across all servers
SERVERS=(
    "user@web1.example.com"
    "user@web2.example.com"
    "user@db1.example.com"
    "user@admin.example.com"
)

NEW_KEY="$HOME/.ssh/id_ed25519_new"
OLD_COMMENT="your-email@example.com"  # The comment on the key to replace

# Generate new key (only once)
ssh-keygen -t ed25519 -C "your-email@example.com-$(date +%Y%m)" -f "$NEW_KEY"

for SERVER in "${SERVERS[@]}"; do
    echo "=== Rotating key on $SERVER ==="
    ssh-copy-id -i "${NEW_KEY}.pub" "$SERVER"
    ssh "$SERVER" "grep -v '$OLD_COMMENT' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp && mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys"
    echo "Done: $SERVER"
done

echo "All servers updated. Verify, then replace your local key."
```

> Use Ansible, Salt, or Puppet if you have more than a handful of servers.

---

## Emergency Response: Compromised Key

If you suspect a private key has been compromised:

### Priority 1: Cut Access Immediately

```bash
# Remove every instance of the compromised key's comment from all servers
ssh user@server "grep -v 'your-email@example.com' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp && mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys"
```

Or use the revoke script on each server:
```bash
./scripts/revoke-user-key.sh "your-email@example.com"
```

### Priority 2: Generate a Replacement Key

Follow the rotation steps above to create and deploy a new key.

### Priority 3: Audit

```bash
# Check who logged in with the compromised key
sudo grep "your-email@example.com" /var/log/auth.log*  # Debian/Ubuntu
sudo grep "your-email@example.com" /var/log/secure*     # CentOS/RHEL

# Look for suspicious activity during the compromise window
last -f /var/log/wtmp | head -50
sudo journalctl -u sshd --since "2026-05-01" | grep -i "accepted publickey"
```

### Priority 4: Document

Record: what was compromised, when it was discovered, when access was cut, what the audit revealed. This is critical for incident response reports and compliance.

---

## Rotation Checklist

- [ ] New keypair generated with timestamped comment
- [ ] New public key copied to all servers
- [ ] New key tested on each server before old key is removed
- [ ] Old public key removed from all `authorized_keys` files
- [ ] Old private key archived (not deleted immediately)
- [ ] SSH agent updated with new key
- [ ] Rotation date recorded (CHANGELOG, password manager, or internal wiki)
- [ ] Old archives purged after confirmation period (~1 week)

---

**Back to:** [README](../README.md)