# 🧰 Deployment Guide — How to Use This Toolkit for Paid Client Work

> **This is your operations manual.** It covers how every service works, how to deploy it on a client's server, what can go wrong, what clients typically ask, and how to present yourself professionally throughout the process.

---

## 🧭 What This Toolkit Is

You have five deployment services that secure and set up Linux servers for paying customers. Each one runs a set of proprietary scripts and config templates that you execute on the client's server over SSH. After deployment, **you remove the scripts** — the client keeps the working configuration.

The five services:

| # | Service | Price | What It Sells |
|---|---------|-------|---------------|
| 1 | **SSH Key Auth Setup** | $35+ | Password-less SSH using Ed25519 keys + sshd hardening |
| 2 | **Linux Server Hardening** | $60+ | Full server lockdown: UFW, Fail2ban, unattended upgrades, sysctl |
| 3 | **Automated Backup System** | $60+ | Cron-scheduled backups to remote storage with tested restore |
| 4 | **Server Monitoring Suite** | $60+ | Real-time CPU/memory/disk/service monitoring with alerts |
| 5 | **Docker + Nginx + SSL Stack** | $100+ | Containerized app behind Nginx with Let's Encrypt HTTPS |

**Bundles are available** — see `README_SERVICE.md` for the pricing table. Always pitch the bundle because it saves them money and anchors the value higher.

---

## 🏗️ How Each Service Works

### 🔑 1. SSH Key Authentication Setup

**The scripts involved:**

| Script | Where It Runs | What It Does | Dependencies |
|--------|---------------|--------------|--------------|
| `setup-client.sh` | Client's local machine | Generates Ed25519 keypair, copies public key to server, adds to ssh-agent, tests connection | Needs `ssh-copy-id` (usually installed) |
| `harden-server.sh` | Client's server (sudo) | Backs up sshd_config, applies 19+ hardened settings, validates syntax, restarts sshd | Must be run as root |

**Deployment flow:**

```
1. Client shares their screen or runs commands you dictate
2. Run: ./scripts/setup-client.sh user@server-ip
   → Generates Ed25519 keypair on their machine
   → Copies public key to their server
   → Tests key-only login works
3. On their server (via the key-auth session you just confirmed works):
   sudo ./scripts/harden-server.sh
   → Backs up current config
   → Warns loudly about password auth being disabled
   → Applies hardened settings
   → Validates config with sshd -t
   → Restarts sshd
4. Verification: Open a new terminal, connect with key → works. Try password → fails.
```

**What the client keeps:**
- Their private key on their local machine
- Hardened `/etc/ssh/sshd_config` on the server
- Backup of the original config at `/etc/ssh/backups/sshd_config.backup.TIMESTAMP`

**⚠️ Danger zones:**
- **Never** run `harden-server.sh` before confirming key auth works. If you do, the client is locked out.
- **Always** keep a second SSH session open during hardening. If the restart fails, you can fix it from the backup session.
- If `sshd -t` fails the config validation, the script aborts and restores the backup automatically. Don't bypass this.

---

### 🔒 2. Linux Server Hardening

**The scripts involved:**

This is the heaviest deployment. It runs a suite that touches SSH, UFW, Fail2ban, unattended upgrades, user permissions, sysctl, and login banners.

**Deployment flow:**

```
1. SSH into the client's server (root or sudo user)
2. Run: sudo ./harden.sh --user <admin-username> --port <ssh-port>
   → Updates system packages
   → Hardens SSH config
   → Moves SSH to a custom port
   → Configures UFW (deny-all default, allow only specified ports)
   → Installs and configures Fail2ban
   → Enables unattended security upgrades
   → Applies sysctl kernel hardening
   → Creates admin user with sudo
   → Configures login banner
   → Enables audit logging
3. Post-deployment verification (script does this):
   → Confirms every service is active
   → Shows Lynx hardening score improvement (if available)
   → Outputs summary of what changed
```

**⚠️ Key safety checks:**
- **UFW must allow the SSH port before enabling.** If you lock out SSH, you've bricked the client's access.
- **Note the SSH port change.** The client needs to know the new port to connect after deployment.
- **Verify Fail2ban is actually logging bans** in the hours after deployment. A silent Fail2ban does nothing.
- Check `ufw status` is `active` before you leave.

**Post-deployment monitoring tip:** Log back in after 24 hours and check Fail2ban logs. Show the client how many IPs got banned — it proves value.

---

### 💾 3. Automated Backup System

**Deployment flow:**

```
1. Pre-deployment conversation:
   → What to back up: /var/www, /home, /etc, databases?
   → Where to back up to: another server? Backblaze B2? S3 bucket?
   → Schedule: hourly, daily, weekly?
   → Retention: keep last 7 daily, 4 weekly?
   → Alert method: email? webhook?
2. Deploy scripts onto the server
3. Configure cron jobs for the schedule
4. Run the first backup manually and verify it completes
5. Test restoration: actually recover a single file to prove it works
6. Configure alerting — send a test alert
7. Provide the written recovery runbook
```

**⚠️ Critical things to verify:**
- The remote destination is actually reachable from the server
- Compression is working (verify file sizes in the log)
- Checksum verification is active — a corrupted backup is worse than no backup
- The retention policy is actually pruning old backups
- **Run a real restore test before you leave.** Pick any file, restore it to a temp location, and verify it's intact.

---

### 📊 4. Server Monitoring Suite

**Deployment flow:**

```
1. Identify what matters to the client:
   → Which services must be up? (nginx, docker, postgres, etc.)
   → What are their normal resource usage levels?
   → How do they want alerts? (email, Slack, webhook)
2. Deploy monitoring scripts onto the server
3. Configure thresholds based on their actual usage:
   → CPU: default >85% for 5 minutes
   → Memory: default >90%
   → Disk: default >80%
4. Set up the service watchlist
5. Run the dashboard, confirm all metrics are populating
6. Trigger a test alert — have the client confirm they received it
7. Provide the written guide on how to read the dashboard and alerts
```

**⚠️ Watch out for:**
- Don't set thresholds too tight. If the server normally runs at 60% CPU and you set the alert at 65%, the client gets spammed with false alarms and tunes it out.
- Confirm the alert destination works. Emails get lost in spam. Slack/Teams webhooks are more reliable.
- The dashboard should show "All systems nominal" during normal operation. If it shows warnings immediately after deploy, fix those before leaving.

---

### 🐳 5. Docker + Nginx + SSL Stack

**Deployment flow:**

```
1. Pre-deployment review:
   → What's the app? (Node, Python, PHP, static)
   → Does the client have a domain name? Is DNS pointed correctly?
   → What ports does the app need?
2. Build the Docker Compose file for their stack
3. Configure Nginx as reverse proxy
4. Run: ./deploy.sh --domain yourdomain.com --app ./their-app
   → Pulls base images
   → Builds application container
   → Configures Nginx for the domain
   → Requests Let's Encrypt SSL certificate
   → Sets up HTTP → HTTPS redirect
   → Configures auto-renewal cron job
   → Starts all containers with health checks
5. Verify:
   → https://their-domain.com loads with green padlock
   → HTTP redirects to HTTPS
   → Containers are healthy
   → Auto-renewal cron is registered
```

**⚠️ Pre-flight checklist:**
- **DNS must be pointing at the server.** Let's Encrypt validates domain ownership via HTTP — if DNS isn't resolved, the cert won't issue.
- Port 80 must be open temporarily for the ACME challenge.
- The client's app must be container-ready. If it has hardcoded localhost references or absolute paths, fix those first.
- 30-day support window is included in this service. Set a calendar reminder at day 25 to check in.

---

## 📋 Standard Deployment Protocol (Every Service)

Follow this exact flow for every client engagement. Consistency prevents mistakes.

### Phase 1: Pre-Deployment (Before You SSH)

1. **Collect credentials:** Server IP, SSH port, username, password/key
2. **Confirm compatibility:** Which Ubuntu/Debian version? (Run `lsb_release -a`)
3. **Document the current state:** Take notes on what exists before you touch anything
4. **Inform the client:** "I'm about to start. This should take roughly [estimate]. I'll message you when it's done."

### Phase 2: Deployment (On Their Server)

1. **Backup everything you modify** before making changes
2. **Run each script in order**
3. **Verify each step** before moving to the next — do not batch changes
4. **Keep a fallback session open** for services that touch SSH
5. **Document what you changed** as you go (you'll need this for the handover)

### Phase 3: Post-Deployment (Verification)

1. **Run the verification checks** built into each script
2. **Test from outside their network** if possible (or have them test from a new terminal)
3. **Confirm every component is active:** services running, firewall active, certs valid
4. **Write a quick summary** of changes for the client (even just a few bullet points)

### Phase 4: Cleanup

1. **Delete every script you uploaded** to their server. `rm` the files, check `/tmp`, check `~/.ssh` for anything you left.
2. **Delete any temporary files** or backups you created that aren't the official config backup.
3. **Confirm you have no lingering access.** Delete the SSH key you used for deployment unless they've explicitly asked you to keep it for a retainer.
4. **Remove their password/key from your notes** after handover (unless retainer).

---

## 🧹 Cleanup Checklist (After Every Deployment)

```bash
# Run these on the client's server before you disconnect:

# Remove your deployment scripts
rm -rf /tmp/deploy-* ~/scripts/

# Verify no lingering authorized_keys from you
cat ~/.ssh/authorized_keys   # Confirm only client keys

# Clear your shell history (if you typed sensitive commands)
history -c && history -w

# Remove your SSH key from their authorized_keys (if you added it)
# Do NOT do this if they've hired you for ongoing maintenance
```

**Important:** Always confirm with the client that you're about to revoke your own access. Some clients prefer you keep access for the support window. Get that in writing.

---

## ❓ Common Customer Questions & How to Answer

### "Can you just give me the scripts so I can run them myself?"
**Your answer:** "The scripts are proprietary and stay with me. What you get is a fully configured, working server that belongs entirely to you — configuration files, keys, firewall rules, everything. If you need something adjusted later, I'm available for maintenance work."

*Why this works: It emphasizes what they DO get (everything on their server) and frames the scripts as a tool, not a product.*

---

### "What if something breaks after you leave?"
**Your answer:** "The [Docker SSL Stack / monitoring / backup] service includes a [X-day] support window. After that, maintenance and troubleshooting are available at an hourly rate."

*Set the boundary early. Do not promise indefinite free support.*

---

### "Why should I pay for this when I can find tutorials online?"
**Your answer:** "You absolutely can. The difference is: I do this every day. I know the edge cases, I test everything before I leave, and you're not spending 4 hours troubleshooting a bad sshd_config at 2am. You're paying for speed and certainty."

*This is honest and positions your value correctly — time saved, risk eliminated.*

---

### "Can you also do [thing not in scope]?"
**Your answer:** "I can take a look at that. Let me confirm the scope and I'll give you a price before I start any extra work."

*Never say yes for free. Always scope it and price it before touching it.*

---

### "Do you offer ongoing maintenance?"
**Your answer:** "Yes, I offer a monthly maintenance retainer. That includes [monthly updates, log reviews, monitoring checks, etc.]. The rate depends on the number of servers and services."

*If they ask this, they're a good long-term client. Have a retainer package ready to pitch.*

---

### "How do I know you won't leave a backdoor?"
**Your answer:** "Before I disconnect, I'll show you every file I touched and confirm there are no extra keys in your authorized_keys. You can verify yourself — I want you to check. Your server, your keys, your config. Everything stays with you."

*Transparency builds trust. Offer to let them watch you delete your access.*

---

### "My server is running CentOS / RHEL 9. Does this work?"
**Your answer:** "The tooling is built and tested on Ubuntu 20.04–24.04 and Debian 11–12. For CentOS/RHEL, I'd need to do a manual setup, which takes longer and costs [higher rate]. Would you like me to quote that?"

*Don't try to run Ubuntu-tested scripts on RHEL. The service names are different (sshd vs ssh), package managers differ, config paths vary. Manual = costs more.*

---

### "Can you set up [service] on five servers at once?"
**Your answer:** "Yes. For multiple servers, I offer a bulk rate. Let me know how many and I'll send you a quote."

*Multi-server deals are your best margin. Give a discount that still makes you money.*

---

## ⚡ Things That WILL Go Wrong — Be Ready

### "The SSH connection dropped during hardening"

**What happened:** sshd restart failed or the new config rejected connections.

**Your fix:**
- Use the **second terminal session** you kept open as a safety net
- Restore the backup: `sudo cp /etc/ssh/backups/sshd_config.backup.TIMESTAMP /etc/ssh/sshd_config && sudo systemctl restart sshd`
- If you don't have a second session, the client needs console access (VPS provider's web console)

**Prevention:** Never close your original session until the new config is tested in a separate terminal.

---

### "Fail2ban isn't banning anyone"

**Check:**
- `sudo systemctl status fail2ban` — is it running?
- `sudo fail2ban-client status sshd` — is the jail active?
- Look at the logs: `sudo tail -f /var/log/fail2ban.log`

**Common cause:** The log path in the Fail2ban jail config doesn't match where sshd actually writes logs on that distro.

---

### "Let's Encrypt SSL certificate won't issue"

**Check:**
- `dig yourdomain.com` — does it resolve to the server's IP? (DNS propagation can take hours)
- Is port 80 open? `sudo ufw status` must show `80/tcp ALLOW`
- Is Nginx actually listening? `sudo netstat -tlnp | grep :80`
- Check certbot logs: `sudo journalctl -u certbot`

**Common cause:** DNS isn't propagated yet. Wait 30 minutes, try again.

---

### "The client says 'it was working before you touched it'"

**Prevention steps:**
1. **Document the starting state.** Before you run anything, note what version of Ubuntu, what services are running, what ports are open.
2. **Take screenshots** of things that were wrong before you started (exposed port, failed login attempts in auth.log).
3. **Never say "I don't know what happened."** Say "Let me check the logs and rebuild from the backup."

---

### "sudo doesn't work after deployment"

The user you created or modified may not have sudo access. Check `/etc/sudoers.d/` or run `visudo`. Always test `sudo whoami` as the new user before leaving.

---

## 💰 Pricing & Negotiation Strategy

### Your pricing (from README_SERVICE.md)

| Service | Starting Price |
|---------|---------------|
| SSH Key Auth | $35 |
| Server Hardening | $60 |
| Backup System | $60 |
| Monitoring Suite | $60 |
| Docker SSL Stack | $100 |

### How to handle "that's too expensive"

1. **Don't drop your price immediately.** Explain what they're getting.
2. **Pivot to a bundle.** "I understand. The Essentials bundle — SSH setup + hardening — is $85, which saves you $10 over buying separately. That gives you the two most important pieces."
3. **If they still push back,** offer to remove add-ons (do hardening without the audit report, etc.) but keep the core price.
4. **Last resort:** Offer a discount in exchange for something — a testimonial, a referral, or permission to use their setup as a case study.

### How to upsell

- **After SSH setup:** "Now that your SSH is locked down, the next thing bots will try is brute-forcing your exposed services. Hardening with Fail2ban + UFW stops that completely."
- **After hardening:** "You've got a secure server now. If it goes down, how do you know? Monitoring catches problems before your users report them."
- **After monitoring:** "Now you'll know when something breaks — but what about your data? Backups mean you can recover in minutes, not days."
- **When they mention hosting an app:** "Let me put that behind Nginx with a real SSL certificate. HTTP in 2026 looks unprofessional, and Let's Encrypt gives you HTTPS for free — I just set it up."

### The bundle ladder

```
SSH Key Auth ($35) → "add hardening" → Essentials ($85, save $10)
Hardening ($60) → "add backup + monitoring" → Production Starter ($160, save $20)
Docker Stack ($100) → "add hardening + monitoring" → Full Stack Launch ($200, save $20)
Everything → Complete Platform ($280, save $35)
```

---

## 📝 Client Communication Templates

### Initial response (when someone emails you)

```
Subject: Re: Server setup inquiry

Hi [Name],

Thanks for reaching out. Based on what you described — [their situation] — here's what I'd recommend:

[Service/bundle suggestion with price]

Turnaround is usually [timeframe] from when we start. Here's how it works:

1. You share server access (I'll tell you exactly what I need)
2. I deploy and verify everything
3. I show you the working result
4. You approve, I clean up and hand over

Payment via [Payoneer/Wise/Crypto] before deployment begins.

Would you like to move forward, or do you have questions?

— Micah
```

### Post-deployment handover message

```
Hi [Name],

Deployment is complete. Here's a summary:

✓ [Service 1] — [what was done, config location]
✓ [Service 2] — [what was done, config location]
...
✓ Verification — all checks passed

Your server details:
- SSH: [user]@[ip] port [port] (key only, no password)
- Firewall: UFW active, ports [X, Y, Z] open
- [other relevant details]

Config backups are at: [path]

My deployment scripts have been removed. Your server now runs entirely on its own configuration — no dependencies on me.

If anything comes up, I'm available for maintenance work at my standard rate.

Thanks for your business!

— Micah
```

---

## 🔐 Security Hygiene (For You)

- **Never reuse the same deployment key** across clients. Generate a new temporary key for each job and delete it after.
- **Don't store client credentials** in plain text. If you keep notes, encrypt them.
- **Assume the client's server is already compromised** when you first log in. Check `auth.log`, `last`, running processes.
- **If you find malware or suspicious activity,** stop deployment, inform the client, and quote remediation separately.
- **Don't discuss one client's setup with another client.** Even casually. "A previous client had this issue" is fine. Naming them is not.

---

## 📦 Service-Specific Quick Reference Cards

### SSH Key Auth — Quick Ref
```
Scripts:     setup-client.sh (local), harden-server.sh (server)
Key recipe:  Ed25519, passphrase optional but recommended
Safety net:  Keep 2nd SSH session open during hardening
Recovery:    cp /etc/ssh/backups/sshd_config.backup.* -> /etc/ssh/sshd_config
```

### Server Hardening — Quick Ref
```
Script:      harden.sh
Key recipe:  Custom SSH port, UFW default-deny, Fail2ban, unattended-upgrades
Safety net:  Confirm UFW allows the new SSH port before enabling
Recovery:    ufw disable (if locked out), restore sshd_config from backup
Post-check:  Fail2ban-client status sshd, ufw status verbose
```

### Backup System — Quick Ref
```
Recipe:      cron + rsync + compression + checksum + retention + alerts
Safety net:  Run first backup manually, verify destination reachable
Recovery:    Written runbook included — test it before leaving
Post-check:  grep CRON /var/log/syslog, check remote destination for files
```

### Monitoring — Quick Ref
```
Recipe:      Threshold-based alerts on CPU, mem, disk, services, auth
Safety net:  Set thresholds based on actual usage, not defaults
Recovery:    Check alert config if not receiving alerts
Post-check:  Trigger test alert, confirm receipt
```

### Docker SSL Stack — Quick Ref
```
Recipe:      Docker Compose + Nginx reverse proxy + certbot auto-renewal
Safety net:  Verify DNS points to server BEFORE requesting cert
Recovery:    certbot renew --dry-run, docker compose restart
Post-check:  https://domain loads with padlock, cron has certbot renewal
```

---

## 📁 File Checklist Before You Go

After every deployment, verify:

- [ ] Deployment scripts removed from server
- [ ] Your SSH key removed from authorized_keys (unless retainer)
- [ ] Config backups exist and client knows where
- [ ] Verification commands all passed
- [ ] Client has tested access from their own machine
- [ ] Handover message sent (email or DM)
- [ ] Payment confirmed received
- [ ] Calendar event set (for services with support window)

---

## 📞 Contact

> 📧 **micahdofori@gmail.com**  
> 🔗 [github.com/micplex](https://github.com/micplex)

*This document is for your reference. Do not share it with clients — it contains your operational details and pricing strategy.*