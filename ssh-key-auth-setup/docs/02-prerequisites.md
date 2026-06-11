# 02 — Prerequisites

Before starting the SSH key setup process, both you (the client machine) and the server need a few things in place.

---

## On Your Local Machine (Client)

### 1. SSH Client Installed

| OS | Command to Check | How to Install |
|----|-----------------|----------------|
| **Linux** | `ssh -V` | Already installed on all distributions |
| **macOS** | `ssh -V` | Built-in — nothing to install |
| **Windows 10/11** | `ssh -V` in PowerShell or CMD | Built-in since Windows 10 1809+ |
| **Windows (older)** | N/A | Install [Git for Windows](https://git-scm.com/) (includes OpenSSH) |

Verify with:

```bash
ssh -V
# Expected output: OpenSSH_8.x, OpenSSH_9.x — anything 7.6+ is fine
```

### 2. Terminal Access

You need a terminal emulator. Use whatever you're comfortable with:
- **Linux:** GNOME Terminal, Konsole, Alacritty, tmux
- **macOS:** Terminal.app, iTerm2
- **Windows:** PowerShell, Windows Terminal, CMD, or Git Bash

### 3. `ssh-copy-id` Utility (Recommended)

This tool copies your public key to the server in one command. It's included by default on Linux and macOS. **Windows users** can use it via Git Bash or WSL.

```bash
which ssh-copy-id
# Expected: /usr/bin/ssh-copy-id
```

If missing (rare on Linux/macOS), you can install it:
```bash
# Debian/Ubuntu
sudo apt install openssh-client

# macOS (via Homebrew)
brew install ssh-copy-id
```

> **Note for Windows users without WSL/Git Bash:** You can manually copy the key — the manual method is covered in [Step 4](04-copy-key-to-server.md).

---

## On the Server

### 1. SSH Server Running

```bash
# Check if sshd is running
sudo systemctl status sshd
# or on older systems:
sudo systemctl status ssh
```

If not running:
```bash
# Debian/Ubuntu
sudo apt install openssh-server
sudo systemctl enable --now ssh

# CentOS/RHEL/Fedora
sudo dnf install openssh-server
sudo systemctl enable --now sshd
```

### 2. Password-Based SSH Access Working

You need to be able to SSH into the server **with a password** to set up key authentication. Test it:

```bash
ssh user@your-server.com
# Enter password when prompted — if you get in, you're ready
```

### 3. Sudo Access on the Server

Modifying `/etc/ssh/sshd_config` requires root. You need a user with `sudo` privileges.

```bash
# Verify sudo access
sudo whoami
# Expected: root
```

### 4. Know Your Server's IP or Hostname

You'll need this throughout:
```bash
# On the server, find its IP
ip addr show
# or
hostname -I
```

---

## Before You Begin Checklist

- [ ] SSH client installed and working on your machine
- [ ] Password SSH access to the server works
- [ ] Sudo/root access on the server confirmed
- [ ] Server IP or hostname noted
- [ ] A second terminal window kept open (as a safety net — see [Step 6](06-test-and-verify.md))

---

## One Critical Safety Rule

> **Never close your working SSH session until you've verified key authentication works in a new terminal.**

Step 6 covers this in detail, but the golden rule of SSH hardening is: **always have a fallback session open.** If you disable password authentication and your key doesn't work, that open session is your only way back in.

---

**Next:** [03 — Generate SSH Keypair](03-generate-ssh-keypair.md)