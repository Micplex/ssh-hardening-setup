# 07 — Troubleshooting

Common failures, their causes, and how to fix them — sorted by when you'll encounter them during setup.

---

## Permission Denied (publickey)

### Symptom

```
user@server: Permission denied (publickey).
```

This is the most common error. It means the server tried key-based auth, but your key wasn't accepted. Password auth is either disabled or not available.

### Diagnosis by Verbose Mode

```bash
ssh -vvv user@your-server.com
```

Search the verbose output for these lines:

| Line in verbose output | Meaning |
|------------------------|---------|
| `debug1: Trying private key: /home/user/.ssh/id_ed25519` | SSH found your key file |
| `debug1: Will attempt key: ...` | SSH is going to try this key |
| `debug1: Server accepts key: ...` | Server received the key but will check it |
| `debug1: Authentication succeeded (publickey)` | You're in — this is the good one |
| `debug3: authmethod_lookup publickey` → `debug1: No more authentication methods` | Server isn't offering publickey — sshd_config issue |

### Cause 1: Wrong Permissions on Server

```bash
# On the server — check:
ls -la ~/.ssh/
```

| Must be | Path | Command to fix |
|---------|------|----------------|
| `700` | `~/.ssh/` | `chmod 700 ~/.ssh` |
| `600` | `~/.ssh/authorized_keys` | `chmod 600 ~/.ssh/authorized_keys` |
| User-owned (not root) | Both | `chown $USER:$USER ~/.ssh ~/.ssh/authorized_keys` |

Also check the **home directory** itself — it must not be group-writable:
```bash
chmod 750 ~  # or 700
```

### Cause 2: Public Key Not in authorized_keys

```bash
cat ~/.ssh/authorized_keys
```

Is your key there? Is it on a **single line**? Common mistakes:
- Key wrapped across multiple lines (copy-paste from a terminal that word-wrapped)
- Missing the `ssh-ed25519` prefix
- Extra spaces, newlines, or invisible characters

Fix: Remove the broken line and re-add the key using `ssh-copy-id` or the manual method.

### Cause 3: Wrong Key Being Offered

You might have multiple keys and SSH is offering the wrong one:

```bash
# Force a specific key
ssh -i ~/.ssh/id_ed25519 user@your-server.com

# See which keys SSH tries
ssh -vvv user@your-server.com 2>&1 | grep "Offering"
```

### Cause 4: SELinux Blocking (CentOS/RHEL/Fedora)

```bash
# Check SELinux status
getenforce

# If Enforcing, restore the correct context
restorecon -R -v ~/.ssh
```

### Cause 5: authorized_keys File Not Processed

In `/etc/ssh/sshd_config`, check:
```
AuthorizedKeysFile .ssh/authorized_keys
PubkeyAuthentication yes
```

Run `sudo sshd -t` and `sudo systemctl restart sshd` after any change.

---

## Connection Closed / Refused

### Symptom

```
ssh: connect to host server.com port 22: Connection refused
```

### Causes and Fixes

| Cause | Fix |
|-------|-----|
| sshd crashed after bad config | Use console access → `sudo sshd -t` → fix config → `sudo systemctl restart sshd` |
| sshd not running | `sudo systemctl start sshd` |
| Firewall blocking port 22 | `sudo ufw allow 22` or check cloud provider security group |
| Wrong port | `ssh -p 2222 user@server.com` |
| sshd failed to bind | `sudo journalctl -u sshd -n 50` → check for "Address already in use" |

---

## sshd Won't Start After Config Change

### Symptom

```
Job for sshd.service failed because the control process exited with error code.
```

### Diagnostic

```bash
sudo sshd -t
```

This will print the exact line with the syntax error. Common mistakes:
- `AllowUser` instead of `AllowUsers`
- Missing commas between algorithm names
- Duplicate directives

### Recovery

```bash
# Restore from backup
sudo cp /etc/ssh/sshd_config.backup.YYYYMMDD /etc/ssh/sshd_config
sudo systemctl start sshd
```

Then re-apply changes one at a time, testing with `sudo sshd -t` after each change.

---

## Key Passphrase Prompted Every Time

You set a passphrase but didn't add the key to the SSH agent:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

Add this to your `~/.bashrc` or `~/.zshrc` to auto-start the agent:

```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
```

---

## "Too Many Authentication Failures"

### Symptom

```
Received disconnect from X.X.X.X port 22:2: Too many authentication failures
```

### Cause

You have many SSH keys in `~/.ssh/` and the server rejects you after SSH tries them all (even unrelated ones).

### Fix

```bash
# Option A: Specify the exact key
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes user@server.com

# Option B: Use SSH config to specify keys per host
# ~/.ssh/config:
Host your-server.com
    HostName your-server.com
    User yourusername
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

---

## "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"

### Symptom

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
```

### Cause

The server's host key changed. This happens legitimately when:
- The server was rebuilt/reimaged
- OpenSSH was reinstalled, generating new host keys
- You're connecting to a different server at the same IP

It **can** indicate a man-in-the-middle attack, but that's far less common.

### Fix (if you know the change is legitimate)

```bash
# Remove the old host key for this server
ssh-keygen -R your-server.com
ssh-keygen -R <server-ip>

# Reconnect — you'll be prompted to accept the new host key
ssh user@your-server.com
```

**Always verify.** If you didn't rebuild anything and this warning appears, investigate.

---

## "Connection Timed Out" with Key Auth Working Before

Common causes:
- Server firewall rules changed (cloud security group, UFW, iptables)
- Your IP changed and an `AllowUsers` or firewall rule restricts by source IP
- The server crashed or was terminated
- DNS resolves to the wrong IP

---

## Still Stuck?

Run the verbose debug on both sides:

**Client side:**
```bash
ssh -vvv user@your-server.com 2>&1 | tee ssh-debug-client.log
```

**Server side (as root):**
```bash
# Check auth logs
sudo tail -f /var/log/auth.log        # Debian/Ubuntu
sudo tail -f /var/log/secure           # CentOS/RHEL

# Check sshd logs for a specific connection
sudo journalctl -u sshd -f
```

The auth log will show **exactly** why a connection was rejected:
```
sshd[12345]: Authentication refused: bad ownership or modes for directory /home/user
sshd[12345]: Failed publickey for user from X.X.X.X port 45678 ssh2: RSA SHA256:...
```

---

**Next:** [08 — Multi-User Setup](08-multi-user-setup.md)