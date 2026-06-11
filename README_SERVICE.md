# Micah Ofori — Linux Server & Infrastructure Services

**I set up, harden, and maintain Linux servers for small businesses, startups, and solo developers. You get a working production server. I handle the practical technical configuration.**

---

## What Problem This Solves

You run a business, an indie SaaS, or a web project that needs a reliable Linux server. You don't want to spend hours reading UFW firewall man pages, debugging Docker container networking at 2:00 AM, or wondering if your SSH access is actually secure. You want someone to configure it correctly the first time — leaving you with a server that simply works.

That's what I do.

I'm a computer science student and freelance infrastructure technician. I work directly on your server, configure everything natively using proven Linux workflows, verify it all works under test conditions, and hand it over. No vague automation promises, no corporate fluff, and no enterprise upselling. Just clean, reliable Linux systems work.

---

## 📦 Configuration Bundles (Best Value)

If you need a complete setup rather than individual component configurations, these flat-rate packages cover everything from initial login to deployment:

| Bundle | Inclusions | Price (USD) |
| :--- | :--- | :--- |
| **🔐 Essentials Bundle** | SSH Key Setup + Full OS Server Hardening | **$110** *(Save $15)* |
| **💾 Production Starter** | OS Hardening + Local Backup Scripts + Alerting Stacks | **$220** *(Save $30)* |
| **🚀 Full Stack Launch** | Docker/Nginx/SSL Setup + Server Hardening + Alerts | **$270** *(Save $30)* |
| **🌐 Complete Platform** | Comprehensive integration of all 5 core service tiers | **$400** *(Save $50)* |

---

## 🛠️ Individual Services Offered

### SSH Key Authentication Setup — from $50
Replace dangerous, password-based SSH login setups with cryptographic keypair authentication. I configure secure Ed25519 keys, harden your system's `sshd` configuration, and explicitly verify that key-only login functions perfectly before disabling password access entirely. 

* **What I do:** Audit current access parameters, deploy secure Ed25519 keys, disable root/password logins, enforce secure ciphers, and save a timestamped backup of your original settings.

### Linux Server Hardening — from $75
Turn a fresh, vulnerable Ubuntu or Debian VPS into a locked-down production server using a native security configuration baseline.
* **What I do:** Pre-deployment environment audit, configure strict UFW rules (default deny incoming), install Fail2ban for automated brute-force IP blocking, enable `unattended-upgrades` for automated security patching, and apply hardened kernel parameters via `sysctl`.

### Automated Backup System — from $100
Scheduled, compressed backup routines running silently in the background, synced cleanly to a secondary storage destination with automated retention purging.
* **What I do:** Identify target data directories, configure custom cron-scheduled `tar`/`gzip` backup scripts inside `/opt/backups/`, implement a strict retention policy (e.g., keep the last 7 days) to protect disk space, wire up failure alerts to an incoming Slack Webhook, and sync archives to a secondary server you provide via `rsync` over SSH.

### Server Alerting & Monitoring Setup — from $75
Lightweight, script-based monitoring tasks that track core system resource thresholds (CPU, memory, disk usage) and critical system services. 
* **What I do:** Deploy clean Bash resource-checking scripts inside `/opt/monitoring/`, establish alert triggers matched to your standard baseline (e.g., warning at 85% disk capacity), route automatic alert updates to a Slack channel Webhook or local server email utilities, and implement automated `logrotate` rules to compress monitoring logs weekly.

### Docker + Nginx + SSL Stack — from $150
Your application workload cleanly containerized, isolated behind an Nginx reverse proxy, and secured using Let's Encrypt SSL certificates configured to auto-renew.
* **What I do:** Review your application structure, write clean `docker-compose.yml` blueprints using isolated internal container networks, install Nginx as a dedicated reverse proxy with clean header forwarding, provision Let's Encrypt certificates via automated Certbot hooks, and enforce container restart policies.

---

## 🤝 What You Receive at Handoff

* **A Deployed, Verified Server Environment:** I do not mark a job complete until every script and configuration has been verified under manual test runs.
* **Total Local Ownership:** Every single configuration file (`sshd_config`, Nginx server blocks, Docker Compose manifests, firewall parameters, and automation scripts) is deployed directly on your infrastructure.
* **A Plain-Text Reference Note:** A clear markdown guide detailing exactly where your tools live, what cron schedules are running, and how to inspect logs.
* **Pre-Change Safety Backups:** Copies of your system configuration files preserved prior to my technical intervention.

> ### 🛑 What you do NOT get:
> * Intellectual property rights, source code repository distribution, or resale licenses for my personal automation macros or internal template scripts.
> * Graphical user interfaces (GUIs), managed platform dashboards, cloud-native load balancers, or centralized telemetry suites (Grafana/Prometheus).
> * Free environment re-tuning or configuration additions after the post-deployment window closes.

---

## 📊 Supported Technologies

* **Operating Systems:** Ubuntu Server (20.04 / 22.04 / 24.04 LTS), Debian Linux (11 / 12)
* **VPS Providers:** DigitalOcean, Hetzner, Linode, Vultr, AWS EC2 (Any KVM-based Linux instance)
* **Firewalls & Security:** UFW Firewall, Fail2ban (SSH access jails)
* **Proxy Routing:** Nginx (Reverse proxy configurations, server blocks, SSL termination)
* **SSL Management:** Let's Encrypt via native Certbot automation
* **Containers:** Docker Engine, Docker Compose v2
* **Backups & Automation:** Native `rsync`, system `cron` tasks, `tar`/`gzip` compression tools
* **Init Software:** Systemd (Service unit states, management, timers)

* **Explicit Out-of-Scope Stacks:** I do not engineer or support Kubernetes clusters, Terraform, Ansible, Prometheus/Grafana stacks, complex CI/CD pipeline infrastructure, AWS cloud load balancers, or multi-region high-availability syncing architecture.

---

## 📑 The Deployment Process

1. **Intake Evaluation:** You share your project goals, server operating system, hosting provider, and target alert paths.
2. **Fixed Scoping:** I confirm technical compatibility and outline a clear, non-negotiable fixed price before you fund any project milestone.
3. **Escrow Funding & Access:** You fund the full fixed project cost into platform escrow (Upwork, Fiverr, etc.) or establish payment security, then provision a temporary `sudo` user account on your machine. I never request primary root passwords.
4. **Execution & Configuration:** I log into the server via SSH, implement the designated services, check execution paths, and trigger a simulated failure run to verify alerts arrive successfully.
5. **Review & Handover:** I deliver your text-based reference notes and walk you through the system verification. Once confirmed, you immediately remove my SSH key from your server and release the escrow milestone.

---

## ⚙️ Optional Add-ons
* **Fail2ban Extended Tracking** (Adding jails for custom application layers beyond basic SSH) — **$20**
* **Multi-User Access Provisioning** — **$15** per additional teammate SSH key setup
* **Database Backup Integration** (Automated script logic wrapping `mysqldump` or `pg_dump`) — **$40**
* **Quarterly Server Check-In Session** (Ad-hoc manual review of updates, disk allocation, and logs) — **$45** per check

---

## ⚠️ Technical & Support Boundaries

* **The 14-Day Configuration Fix Window:** Every configuration includes a strict 14-day window following handover. If a script throws a syntax bug or an Nginx routing block fails to function exactly as implemented, I log back in and calibrate it at zero additional charge.
* **Voiding Support:** This window is instantly voided if you or your secondary developers modify directory locations, alter file permissions within `/opt/monitoring/`, introduce syntax typos to configuration scripts, change internal application environment credentials, or allow primary storage drives to run completely out of disk allocation space.
* **Strict Exclusions:** I do not provide custom application feature coding, frontend or backend software development, database query debugging, live ongoing structural platform monitoring, CDN caching optimization (Cloudflare policies), or formal compliance auditing (SOC 2, PCI, HIPAA).
* **No Data Recovery Guarantees:** I configure and verify a functional local tool configuration. The long-term durability of your data depends on your server environment health and whether my operational parameters are left unedited by your team.

---

## 💳 Payment Terms

* **Freelance Platforms:** Native Platform Escrow Milestones (Upwork, Fiverr) funded 100% upfront prior to server log-in.
* **Direct Independent Engagements:** Wise, Payoneer, or Cryptocurrency (USDT). For off-platform direct consulting sessions, fixed tier capital must clear payment processing milestones before technical production commands are run.

---

## 📬 Contact Micah Ofori

* **Email:** micahdofori@gmail.com
* **GitHub Profile:** [github.com/micplex](https://github.com/micplex)

**Ready to lock down your server or deploy your app architecture correctly? Send me an email.** Please include a high-level overview of your target stack, your server's current operating system distribution, your cloud hosting provider, and your chosen configuration tier or bundle. I respond to all professional inquiries within one business day.