# 03 — Generate Your SSH Keypair

This is where the magic starts. You'll create a cryptographic keypair on your local machine — the private key stays here forever, the public key goes to your servers.

---

## Step 1: Decide Where to Store Your Key

The standard location is `~/.ssh/`. If this directory doesn't exist, create it now:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

**Why `chmod 700`?** The `.ssh` directory must only be readable/writable by you. If other users can read it, SSH will refuse to use keys inside it — this is a security feature, not a bug.

---

## Step 2: Generate the Key

```bash
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519
```

### Breaking down each flag:

| Flag | What It Does | Why It Matters |
|------|-------------|----------------|
| `-t ed25519` | Key type: Ed25519 | Fastest, most secure modern algorithm. 256-bit security in a tiny key. |
| `-C "email"` | Comment added to the key | Identifies the key later. Use your email, or `"laptop-personal"`, `"work-desktop"`, etc. |
| `-f ~/.ssh/id_ed25519` | Output filename | Keeps keys organized. Avoids overwriting existing keys. |

### During generation, you'll be prompted:

```
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

**Add a passphrase.** Here's why:

| Scenario | No Passphrase | With Passphrase |
|----------|:---:|:---:|
| Someone steals your laptop | ❌ Instant server access | ✅ They still need the passphrase |
| Key used by automated scripts | ✅ No prompt | ❌ Would hang waiting for passphrase |
| Malware reads `~/.ssh/` | ❌ Keys stolen in plaintext | ✅ Encrypted at rest, unusable without passphrase |

> **For automation/CI/CD keys:** Skip the passphrase, but restrict what commands that key can run using `command=` in `authorized_keys` (covered in [Step 8](08-multi-user-setup.md)).

---

## Step 3: Verify What Was Created

```bash
ls -la ~/.ssh/id_ed25519*
```

You should see two files:

```
-rw------- 1 user user  411 May 20 21:00 /home/user/.ssh/id_ed25519      ← PRIVATE (keep secret!)
-rw-r--r-- 1 user user  101 May 20 21:00 /home/user/.ssh/id_ed25519.pub  ← PUBLIC (share freely)
```

### Permission check:

| File | Permission | Meaning |
|------|-----------|---------|
| `id_ed25519` (private) | `600` (`-rw-------`) | Only you can read/write |
| `id_ed25519.pub` (public) | `644` (`-rw-r--r--`) | You write, others read — it's public |

If your private key permissions are wrong, SSH will reject it:

```bash
# Fix permissions if needed
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

---

## Step 4: Inspect Your Keys

### View the public key (the one you share):

```bash
cat ~/.ssh/id_ed25519.pub
```

Example output:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGx... your-email@example.com
```

Breaking that down:
- `ssh-ed25519` — the algorithm
- `AAAAC3Nza...` — the actual public key (base64-encoded)
- `your-email@example.com` — your comment

### View the private key (NEVER share this):

```bash
cat ~/.ssh/id_ed25519
```

Example:
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
...
-----END OPENSSH PRIVATE KEY-----
```

If you used a passphrase, the private key is encrypted. Without the passphrase, it's useless to an attacker.

---

## Step 5: Add Your Key to the SSH Agent (Recommended)

The SSH agent holds decrypted private keys in memory so you don't type your passphrase every time:

```bash
# Start the agent if not already running
eval "$(ssh-agent -s)"

# Add your key (you'll be prompted for the passphrase once)
ssh-add ~/.ssh/id_ed25519
```

Now you can SSH into servers without retyping the passphrase during this session. The key is held in memory, safely.

---

## Common Questions

**Q: I already have an RSA key. Should I switch to Ed25519?**
A: Yes. Generate a new Ed25519 key and add it alongside your existing RSA key. SSH tries all available keys until one works. Over time, phase out the RSA key.

**Q: Can I use the same key for multiple servers?**
A: Yes — and that's the normal workflow. One private key on your laptop, the matching public key on every server you manage.

**Q: Should I use different keys for work vs. personal?**
A: Yes. Generate separate keys (`id_ed25519_work`, `id_ed25519_personal`) and use `~/.ssh/config` to specify which key connects to which host.

**Q: What if I lose my private key?**
A: Generate a new keypair and add the new public key to your servers. The old public key won't do anything without its matching private key, but you should still remove it.

---

**Next:** [04 — Copy Your Key to the Server](04-copy-key-to-server.md)