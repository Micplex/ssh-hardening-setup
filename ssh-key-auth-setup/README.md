# SSH Key Authentication Setup

> A professional, step-by-step guide to configuring SSH key-based authentication — the service I provide to secure your servers by eliminating password-based SSH access.

---

## What This Service Covers

SSH keys replace passwords with cryptographic key pairs, making brute-force attacks practically impossible. This guide walks through the complete process: generating keys, deploying them to servers, hardening the SSH daemon, and verifying everything works before locking out password access.

**Who this is for:**
- DevOps teams securing cloud infrastructure
- Developers setting up secure access to VPS / bare-metal servers
- Anyone tired of seeing thousands of failed root login attempts in `/var/log/auth.log`

---

## Quick Navigation

| Step | Document | What You'll Do |
|------|----------|-----------------|
| 1 | [What Is SSH Key Auth?](docs/01-what-is-ssh-key-auth.md) | Understand the concept |
| 2 | [Prerequisites](docs/02-prerequisites.md) | What you need before starting |
| 3 | [Generate SSH Keypair](docs/03-generate-ssh-keypair.md) | Create your key on your local machine |
| 4 | [Copy Key to Server](docs/04-copy-key-to-server.md) | Deploy the public key |
| 5 | [Configure sshd](docs/05-configure-sshd.md) | Harden the SSH daemon |
| 6 | [Test & Verify](docs/06-test-and-verify.md) | Confirm everything works |
| 7 | [Troubleshooting](docs/07-troubleshooting.md) | Fix common issues |
| 8 | [Multi-User Setup](docs/08-multi-user-setup.md) | Manage keys for teams |
| 9 | [Key Rotation](docs/09-key-rotation.md) | Rotate keys on a schedule |

---

## One-Liner Setup

If you're comfortable on the command line and just want the script:

```bash
# On your local machine (generates key + copies to server)
./scripts/setup-client.sh user@your-server.com

# On the server (hardens SSH configuration)
sudo ./scripts/harden-server.sh
```

**Important:** Read the [Test & Verify guide](docs/06-test-and-verify.md) before running `harden-server.sh` — it disables password authentication and you don't want to lock yourself out.

---

## Repository Structure

```
├── docs/                   # Step-by-step guides (numbered)
├── scripts/                # Automation scripts for repeated client work
├── templates/              # Pre-hardened config files
├── examples/               # Real-world scenarios
└── assets/                 # Diagrams and visuals
```

---

## Why Trust This Guide?

- Every step explains **why**, not just **what**
- Scripts are commented and tested on Ubuntu 20.04/22.04, Debian 11/12, and CentOS/RHEL 8/9
- Config templates follow [Mozilla's OpenSSH guidelines](https://infosec.mozilla.org/guidelines/openssh) and CIS benchmarks
- Covers the edge cases: multiple keys per user, forced commands, jump hosts

---

## License

MIT — use freely, modify freely, attribution appreciated.