# 01 — What Is SSH Key Authentication?

## The Problem with Passwords

Every Linux server exposed to the internet gets hammered by brute-force SSH attempts. Bots scan port 22 and try common username/password combinations — `root/admin123`, `ubuntu/password`, and thousands more per minute.

Passwords fail because:
- Users pick weak passwords or reuse them across services
- Automated attacks can try millions of combinations per day
- Password leaks from one service compromise all others where the same password was used
- Even strong passwords travel over the network during authentication (inside an encrypted tunnel, but still)

## How SSH Keys Solve This

SSH key authentication is **asymmetric cryptography** — the same math underpinning TLS/SSL, Bitcoin, and PGP.

```
┌─────────────────────┐                    ┌─────────────────────┐
│   YOUR LAPTOP       │                    │   YOUR SERVER       │
│                     │                    │                     │
│  ~/.ssh/id_ed25519  │                    │  ~/.ssh/authorized_ │
│  (PRIVATE KEY)      │──── NEVER LEAVES ──│  keys               │
│                     │    YOUR MACHINE    │  (PUBLIC KEY)       │
│                     │                    │                     │
└─────────────────────┘                    └─────────────────────┘
```

### The Private Key

- Stays on **your machine only** — never shared, never uploaded
- Protected by a passphrase (optional but strongly recommended)
- Used to **sign** a challenge from the server, proving you hold the key
- If someone steals your private key, they can impersonate you

### The Public Key

- Goes on every **server** you want to access
- Stored in `~/.ssh/authorized_keys` on each server
- Safe to share — it can only verify signatures, not create them
- Think of it like a padlock: anyone can have one, but only the key holder can open it

## The Handshake (What Happens When You SSH)

1. You run `ssh user@server`
2. The server sends a random challenge (a blob of data)
3. Your SSH client signs that challenge with your **private key**
4. The server verifies the signature using your **public key** stored in `authorized_keys`
5. If it matches → you're in. If not → connection refused

The private key **never leaves your machine**. The server proves you own the key without ever seeing it.

## Why Key Types Matter

| Algorithm | Strength | Recommendation |
|-----------|----------|----------------|
| RSA 2048 | Adequate | Minimum acceptable |
| RSA 4096 | Strong | Good, but slow |
| ECDSA | Strong | Fine, but trust concerns (NIST curves) |
| **Ed25519** | **Strongest** | **Use this** — fast, modern, no known weaknesses |
| DSA | Weak | Never use — deprecated |

This guide uses **Ed25519** throughout. It's faster, shorter, and more secure than RSA.

## Password Auth vs. Key Auth — Side by Side

| Feature | Password Auth | Key Auth |
|---------|--------------|----------|
| Brute-force resistant | ❌ | ✅ |
| Can be shared safely | ❌ | ✅ (public key only) |
| Requires user memory | ✅ (remember password) | ❌ (key file, optionally passphrase) |
| Easily revocable per-user | ❌ | ✅ (remove from authorized_keys) |
| Phishing resistant | ❌ | ✅ (key never leaves machine) |
| Audit trail | Weak (shared passwords) | Strong (one key = one identity) |

## What This Guide Will Teach You

By the end, you'll have a server that:
- Only accepts SSH key authentication — password logins are disabled
- Uses modern, secure key algorithms (Ed25519)
- Has SSH daemon hardened against common attack vectors
- Provides per-user key management for teams

---

**Next:** [02 — Prerequisites](02-prerequisites.md)