# Example: Single Server SSH Key Setup

**Scenario:** You have one Ubuntu server at `203.0.113.10` and you want to secure it with SSH key authentication. You're the only person who accesses this server.

---

## Walkthrough

### 1. Generate a keypair on your laptop

```bash
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519
# Set a passphrase when prompted
```

### 2. Copy the public key to the server

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@203.0.113.10
# Enter your current password — this is the last time you'll use it
```

### 3. Verify key auth works (in a new terminal)

```bash
ssh -o PreferredAuthentications=publickey -o PasswordAuthentication=no user@203.0.113.10
# Should connect without asking for the server password
```

### 4. Harden the SSH daemon

On the server:
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo nano /etc/ssh/sshd_config
```

Set these values:
```
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
AllowUsers user
MaxAuthTries 3
```

Validate and restart:
```bash
sudo sshd -t
sudo systemctl restart sshd
```

### 5. Final verification

Open a **third terminal** and test:
```bash
ssh user@203.0.113.10          # Should work with key auth
ssh -o PreferredAuthentications=password user@203.0.113.10   # Should FAIL
```

---

## Result

| Before | After |
|--------|-------|
| Anyone with the password could log in | Only your private key can authenticate |
| Root could SSH directly | Root login disabled — use `sudo` |
| Brute-force attempts possible | Password auth disabled — brute-force impossible |
| Default crypto (potentially weak) | Only strong, modern ciphers allowed |

---

## Files Used

- [docs/03-generate-ssh-keypair.md](../../docs/03-generate-ssh-keypair.md)
- [docs/04-copy-key-to-server.md](../../docs/04-copy-key-to-server.md)
- [docs/05-configure-sshd.md](../../docs/05-configure-sshd.md)
- [docs/06-test-and-verify.md](../../docs/06-test-and-verify.md)
- [templates/sshd_config.template](../../templates/sshd_config.template)