# 04 — Copy Your Public Key to the Server

Your public key needs to live on every server you want to access. This step places your public key into the server's `~/.ssh/authorized_keys` file, which is how the server knows to trust your private key.

---

## Method 1: `ssh-copy-id` (Recommended — One Command)

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@your-server.com
```

### What this command does:

1. SSHes into the server using your **password** (you'll be prompted for it)
2. Creates `~/.ssh/` on the server if it doesn't exist
3. Creates `~/.ssh/authorized_keys` if it doesn't exist
4. Appends your public key to `authorized_keys`
5. Sets correct permissions on both `~/.ssh/` (700) and `authorized_keys` (600)

**Why permissions matter:** SSH will **silently ignore** `authorized_keys` if it's writable by anyone other than the owner. This prevents other users from adding their own keys to your account. `ssh-copy-id` handles this automatically.

### Specifying a non-default key:

```bash
# If you generated a key with a custom name
ssh-copy-id -i ~/.ssh/id_ed25519_work.pub user@your-server.com
```

### Specifying a non-default port:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 2222 user@your-server.com
```

---

## Method 2: Manual Copy (When `ssh-copy-id` Isn't Available)

Use this on Windows without Git Bash/WSL, or on any system where `ssh-copy-id` is missing.

### Step 1: Read your public key

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output — it's a single long line starting with `ssh-ed25519`.

### Step 2: SSH into the server

```bash
ssh user@your-server.com
```

### Step 3: Create the `.ssh` directory (if needed)

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

### Step 4: Add your key to `authorized_keys`

```bash
# Paste your public key into authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-email@example.com" >> ~/.ssh/authorized_keys

# Fix permissions
chmod 600 ~/.ssh/authorized_keys
```

### Step 5: Verify the key was added

```bash
cat ~/.ssh/authorized_keys
# Should show your key as the last line (or only line)
```

---

## Method 3: One-Liner Pipe (Advanced)

This pipes your public key directly to the server without `ssh-copy-id` — useful in scripts:

```bash
cat ~/.ssh/id_ed25519.pub | ssh user@your-server.com "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

**Why each part matters:**

| Command | Purpose |
|---------|---------|
| `mkdir -p ~/.ssh` | Create .ssh dir if missing (won't error if it exists) |
| `chmod 700 ~/.ssh` | Lock down directory permissions |
| `cat >>` | **Append** to authorized_keys (never overwrite with `>`) |
| `chmod 600` | Lock down authorized_keys permissions |

> ⚠️ Always use `>>` (append), never `>` (overwrite). Using `>` would delete every other key in the file, locking out other users.

---

## Verify Key-Based Login Works

**Before closing your current session**, open a **new terminal window** and test:

```bash
ssh user@your-server.com
```

If it connects without asking for a password (it may ask for your key's passphrase instead), you've succeeded.

### What you should see:

```
# No password prompt — or if you set a key passphrase:
Enter passphrase for key '/home/user/.ssh/id_ed25519':
# Then you're in
```

### What if it still asks for a password?

See the [Troubleshooting guide](07-troubleshooting.md) — common causes:
- Wrong permissions on `~/.ssh/` or `authorized_keys`
- Typos in the key (did you copy the entire line?)
- SELinux blocking access (CentOS/RHEL)

---

## Security Notes

- **The public key is safe to share.** Anyone with it can verify your signatures but can't create them.
- **Each line in `authorized_keys` is one key.** You can have multiple keys for the same user (laptop key, desktop key, emergency key).
- **Comments after the key are not validated.** The `your-email@example.com` part is purely for identification.
- **Never manually edit `authorized_keys` while rushing.** A typo or extra newline won't break existing keys but might prevent new ones from working. Always test in a new terminal.

---

**Next:** [05 — Configure sshd (Harden the SSH Daemon)](05-configure-sshd.md)