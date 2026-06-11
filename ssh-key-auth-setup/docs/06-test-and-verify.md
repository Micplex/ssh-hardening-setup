# 06 — Test and Verify

This step exists because **the worst time to discover your key doesn't work is after you've disabled password auth.** Testing methodically saves you from console-recovery hell.

---

## The Three-Terminal Testing Protocol

```
Terminal 1  ───►  Original SSH session  (safety net — DO NOT CLOSE)
Terminal 2  ───►  Working SSH session    (where you make config changes)
Terminal 3  ───►  Test session           (verify from a clean state)
```

### Why three terminals?

| Terminal | Role | Why You Need It |
|----------|------|-----------------|
| **T1** | Safety net | If T2 dies during `systemctl restart sshd`, T1 survives. It's your escape hatch. |
| **T2** | Work area | Edit configs, restart services. This may disconnect. |
| **T3** | Verification | Clean test. If T3 works, any new connection will work. |

---

## Before You Make Any sshd Changes

### 1. Confirm key auth works from a separate terminal

```bash
# In Terminal 3 — fresh connection
ssh -o PreferredAuthentications=publickey -o PasswordAuthentication=no user@your-server.com
```

These flags force SSH to **only use key auth** for this test. If this fails, your key isn't properly deployed yet — go back to [Step 4](04-copy-key-to-server.md).

**What success looks like:**
- You get a shell prompt without entering a server password
- You may be prompted for your **key passphrase** — that's fine

**What failure looks like:**
```
Permission denied (publickey).
```
→ Your key isn't in `authorized_keys`, or permissions are wrong. Fix before continuing.

### 2. Check authorized_keys on the server

```bash
# From Terminal 1 (your safety net)
cat ~/.ssh/authorized_keys
ls -la ~/.ssh/
```

Verify:
- [ ] `~/.ssh/` permissions are `700` (`drwx------`)
- [ ] `~/.ssh/authorized_keys` permissions are `600` (`-rw-------`)
- [ ] Your public key appears as a complete line (no wrapping, no truncation)
- [ ] No extra characters, spaces, or blank lines mixed in

### 3. Check sshd_config syntax

```bash
sudo sshd -t
```

No output = valid. Any output = error — fix the listed line.

---

## After Restarting sshd

### 4. Verify sshd is running

```bash
sudo systemctl status sshd
```

Expected:
```
Active: active (running) since ...
```

If it's dead:
```bash
sudo journalctl -u sshd -n 50 --no-pager
```

Look for lines like:
```
error: Bind to port 22 on 0.0.0.0 failed: Address already in use
# or
bad permissions on /etc/ssh/sshd_config
```

### 5. Check which port sshd is listening on

```bash
sudo ss -tlnp | grep sshd
```

Expected:
```
LISTEN  0  128  0.0.0.0:22  0.0.0.0:*  users:(("sshd",pid=...,fd=...))
LISTEN  0  128  [::]:22     [::]:*      users:(("sshd",pid=...,fd=...))
```

If nothing shows, sshd isn't listening — restore the backup config.

### 6. Attempt key-based login (Terminal 3)

```bash
ssh user@your-server.com
```

Success = you get a shell without entering a server password.

### 7. Confirm password auth is rejected

```bash
# In Terminal 3 — try to force password auth
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no user@your-server.com
```

Expected output:
```
Permission denied (publickey).
```

**This is the win condition.** The server refuses passwords, only keys are accepted. If it prompts for a password instead, `PasswordAuthentication` is still `yes` in sshd_config — check your config and restart.

---

## Verification Checklist

- [ ] Terminal 3 can connect with key auth (`-o PreferredAuthentications=publickey`)
- [ ] Terminal 3 is **rejected** when forcing password auth (`-o PreferredAuthentications=password`)
- [ ] `sudo sshd -t` returns no errors
- [ ] `sudo systemctl status sshd` shows `active (running)`
- [ ] `sudo ss -tlnp | grep sshd` shows sshd listening
- [ ] `~/.ssh/` permissions are `700`
- [ ] `~/.ssh/authorized_keys` permissions are `600`
- [ ] `PasswordAuthentication no` appears in `/etc/ssh/sshd_config`
- [ ] `ChallengeResponseAuthentication no` appears in `/etc/ssh/sshd_config`

---

## Automated Verification Script

Run this on the server to check everything at once:

```bash
#!/bin/bash
# Save as check-ssh-hardening.sh and run with: bash check-ssh-hardening.sh

echo "=== SSH Hardening Verification ==="
echo ""

# 1. Check sshd_config syntax
echo "[1] sshd_config syntax:"
if sudo sshd -t 2>&1; then
    echo "    ✓ Syntax valid"
else
    echo "    ✗ Syntax error"
fi

# 2. Check sshd is running
echo "[2] sshd service status:"
if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
    echo "    ✓ sshd is running"
else
    echo "    ✗ sshd is NOT running"
fi

# 3. Check key config directives
echo "[3] Security settings in sshd_config:"
for setting in "PasswordAuthentication no" "ChallengeResponseAuthentication no" "PermitRootLogin no" "PubkeyAuthentication yes"; do
    if sudo grep -q "^${setting}" /etc/ssh/sshd_config; then
        echo "    ✓ ${setting}"
    else
        echo "    ✗ ${setting} — NOT SET or commented out"
    fi
done

# 4. Check listening port
echo "[4] Listening port:"
sudo ss -tlnp | grep sshd | awk '{print "    Listening on:", $4}' || echo "    ✗ Not listening"

# 5. Check home directory permissions
echo "[5] .ssh permissions:"
stat -c "%a %n" ~/.ssh ~/.ssh/authorized_keys 2>/dev/null || echo "    ✗ Cannot read permissions"

echo ""
echo "=== Verification Complete ==="
```

---

## Final Sanity Check

Before you close your safety-net terminals, ask yourself:

1. "If my laptop died right now, could anyone else get in?" → **No** — only you have the private key
2. "Can I log in from a completely different machine?" → **If not**, your key may be bound to a specific host — generate a key on that machine too
3. "Do I have a backup of my private key somewhere secure?" → If not, do that now (encrypted USB, password manager, etc.)

---

**Next:** [07 — Troubleshooting](07-troubleshooting.md)