# 05 — Configure sshd (Harden the SSH Daemon)

Now that key-based login works, it's time to lock down the SSH daemon. The goal: disable password authentication entirely and apply security best practices.

---

## ⚠️ Critical Safety Rule

> **Open a second SSH session before making sshd changes.** Keep your original session open as a fallback. If you make a mistake and lock yourself out, the original session is still active, and you can fix the config.

This process:
1. Open terminal 1 → SSH into server (your working session)
2. Open terminal 2 → SSH into server (your safety net)
3. **Stay in terminal 1** to make changes
4. Open terminal 3 → Test key-based login after changes
5. Only close terminals 1 and 2 when you're 100% sure

---

## Step 1: Back Up the Current Config

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
```

**Why backup with a date stamp?** If you need to revert, you know exactly which backup was the pre-change config. No guessing.

---

## Step 2: Edit sshd_config

```bash
sudo nano /etc/ssh/sshd_config
# or
sudo vim /etc/ssh/sshd_config
```

---

## Step 3: The Critical Settings (What to Change)

### 3.1 — Disable Password Authentication

```
# CHANGE this:
#PasswordAuthentication yes
PasswordAuthentication no
```

**Why:** This is the whole point. Once this is `no`, only SSH keys work. Passwords are rejected — brute-force attacks become impossible.

> ⚠️ **Do not disable password auth until you've verified your key works** (Step 4). Otherwise you're locked out.

### 3.2 — Disable Challenge-Response (Keyboard-Interactive)

```
# CHANGE this:
ChallengeResponseAuthentication no
```

**Why:** `ChallengeResponseAuthentication` enables PAM-based keyboard-interactive auth, which is a different code path from `PasswordAuthentication`. Attackers can exploit it even if `PasswordAuthentication` is disabled. Set both to `no`.

### 3.3 — Disable Root Login

```
# CHANGE this:
#PermitRootLogin prohibit-password
PermitRootLogin no
```

**Why:** Every attacker targets `root`. If root can't log in via SSH, they need to compromise a regular user first, then `sudo` or `su` to root. This forces two steps instead of one. You'll use `sudo` after logging in as your regular user.

> **Exception:** Some provisioning tools (Ansible, Terraform) need root SSH. If you must keep it, use `PermitRootLogin prohibit-password` which allows root key-based login but blocks root password login.

### 3.4 — Restrict Allowed Users (Optional but Recommended)

```
# ADD this line:
AllowUsers yourusername
```

**Why:** Even if an attacker gets a key for `git`, `www-data`, or another service account, they won't be allowed to SSH. Only the users you explicitly list can connect.

For multiple users:
```
AllowUsers alice bob carol
```

### 3.5 — Use Strong Crypto Only

```
# ADD or uncomment:
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com
```

**Why:** Disables weak algorithms (SHA1, CBC ciphers, DSA, ECDSA with weak curves). This follows Mozilla's OpenSSH hardening guidelines.

### 3.6 — Connection Hardening

```
# ADD or uncomment:
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
```

| Setting | Value | Why |
|---------|-------|-----|
| `MaxAuthTries` | 3 | Limit authentication attempts per connection — slows brute-force |
| `MaxSessions` | 10 | Prevent a single connection from spawning unlimited sessions |
| `ClientAliveInterval` | 300 | Server sends keepalive every 5 min — closes dead connections |
| `ClientAliveCountMax` | 2 | After 2 missed keepalives (10 min), drop the connection |
| `LoginGraceTime` | 30 | If you don't authenticate within 30 seconds, disconnect |

---

## Step 4: The Complete Secure sshd_config (Full Example)

For reference, here's a complete hardened config. See also the [sshd_config template](../templates/sshd_config.template).

```ini
# Port and Address
Port 22
AddressFamily inet

# Authentication
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no

# Allowed Users
AllowUsers yourusername

# Strong Cryptography
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com

# Connection Limits
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30

# Disable Unnecessary Features
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no

# Logging
SyslogFacility AUTH
LogLevel VERBOSE
```

---

## Step 5: Test the Config Before Restarting

```bash
sudo sshd -t
```

**No output = valid config.** If there's an error, it will tell you which line is broken. Fix it before restarting.

```bash
# Example error output:
/etc/ssh/sshd_config: line 42: Bad configuration option: AllowUser
# (Missing 's' — should be AllowUsers)
```

---

## Step 6: Restart sshd

```bash
sudo systemctl restart sshd
# or on older systems:
sudo systemctl restart ssh
```

**Important:** `restart` kills existing connections. Your safety-net session from terminal 2 will disconnect, but terminal 1 (where you ran the restart) should survive.

If the restart fails:
```bash
# Check why
sudo systemctl status sshd
sudo journalctl -u sshd -n 50
```

---

## Step 7: Verify in a New Terminal

**Open a brand new terminal** and try to SSH in:

```bash
ssh user@your-server.com
```

What to expect:
- ✅ Connects using your key — no password prompt
- ✅ If you set a key passphrase, it asks for that (not the server password)
- ❌ If you try password auth: "Permission denied (publickey)" — **this is correct**

---

## Step 8: What If Something Went Wrong?

If you're locked out but still have your original session open:

```bash
# Restore the backup
sudo cp /etc/ssh/sshd_config.backup.20260520 /etc/ssh/sshd_config
sudo systemctl restart sshd
```

If you've been completely locked out, you'll need console access (VPS provider's web console, IPMI, or physical access).

---

## Beyond the Basics (Optional)

- **Change the port:** Change `Port 22` to a non-standard port to reduce noise from automated scanners. This is **security through obscurity** — not real security — but it cuts log noise by 95%+.
- **Use a jump host:** Place an SSH bastion in front of your servers and only allow SSH from that bastion's IP (via firewall).
- **Fail2ban:** Install `fail2ban` to automatically block IPs after failed login attempts — pairs well with key-only auth for defense in depth.

---

**Next:** [06 — Test and Verify](06-test-and-verify.md)