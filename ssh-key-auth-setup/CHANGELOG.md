# Changelog

All notable changes to the SSH Key Auth Setup guide and scripts.

---

## [1.0.0] — Initial Release

### Added
- 9-step documented guide covering full SSH key auth lifecycle
- `setup-client.sh` — automate key generation and deployment
- `harden-server.sh` — apply secure sshd_config settings
- `add-user-key.sh` — add keys for new team members
- `revoke-user-key.sh` — remove keys during offboarding
- Pre-hardened config templates (sshd_config, ssh_config, authorized_keys)
- Real-world example scenarios (single server, multi-server, GitHub SSH)
- Troubleshooting guide with common error fixes

---

*Format follows [Keep a Changelog](https://keepachangelog.com/).*