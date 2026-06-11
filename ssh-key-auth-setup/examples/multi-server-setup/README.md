# Example: Multi-Server SSH Key Setup

**Scenario:** You manage 3 servers — `web1`, `web2`, and `db1` — and you want to deploy the same SSH key to all of them. You also have a teammate, Alice, who needs access to all three.

---

## Walkthrough

### 1. Generate your keypair (once)

```bash
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519
```

### 2. Copy your key to all servers

```bash
SERVERS=("user@web1.example.com" "user@web2.example.com" "user@db1.example.com")

for SERVER in "${SERVERS[@]}"; do
    echo "=== Deploying key to $SERVER ==="
    ssh-copy-id -i ~/.ssh/id_ed25519.pub "$SERVER"
done
```

### 3. Configure ~/.ssh/config for convenience

```bash
# ~/.ssh/config
Host web1
    HostName web1.example.com
    User user
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host web2
    HostName web2.example.com
    User user
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host db1
    HostName db1.example.com
    User user
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Now instead of `ssh user@web1.example.com`, just type `ssh web1`.

### 4. Add Alice to all servers

Alice generates her key:
```bash
ssh-keygen -t ed25519 -C "alice@company.com" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
# She sends you: ssh-ed25519 AAAAC3NzaC... alice@company.com
```

Deploy Alice's key to all servers:
```bash
ALICE_KEY="ssh-ed25519 AAAAC3NzaC... alice@company.com"

for SERVER in "${SERVERS[@]}"; do
    echo "=== Adding Alice to $SERVER ==="
    ssh "$SERVER" "echo '$ALICE_KEY' >> ~/.ssh/authorized_keys"
done
```

Or create a Unix account for Alice on each server:
```bash
for SERVER in "${SERVERS[@]}"; do
    ssh "$SERVER" "sudo useradd -m -s /bin/bash alice && sudo mkdir -p /home/alice/.ssh && echo '$ALICE_KEY' | sudo tee -a /home/alice/.ssh/authorized_keys && sudo chown -R alice:alice /home/alice/.ssh && sudo chmod 700 /home/alice/.ssh && sudo chmod 600 /home/alice/.ssh/authorized_keys"
done
```

### 5. Harden all servers

Either run `harden-server.sh` on each one, or use Ansible:

```yaml
# ansible/playbook.yml
- hosts: all
  become: yes
  tasks:
    - name: Copy hardened sshd_config
      copy:
        src: ../templates/sshd_config.template
        dest: /etc/ssh/sshd_config
        owner: root
        group: root
        mode: '0644'
        backup: yes
      notify: restart sshd

  handlers:
    - name: restart sshd
      service:
        name: sshd
        state: restarted
```

### 6. Verify all servers

```bash
for SERVER in web1 web2 db1; do
    echo "=== Testing $SERVER ==="
    ssh -o PreferredAuthentications=publickey -o PasswordAuthentication=no "$SERVER" "echo 'OK'" || echo "FAILED"
done
```

---

## Result

| Before | After |
|--------|-------|
| Password auth on all 3 servers | Key-only auth on all 3 servers |
| You type long SSH commands | `ssh web1`, `ssh db1` via ~/.ssh/config |
| Alice not onboarded | Alice has access on all servers |
| Onboarding takes 10+ min per server | Scripted — 30 seconds total |

---

## Files Used

- [docs/03-generate-ssh-keypair.md](../../docs/03-generate-ssh-keypair.md)
- [docs/08-multi-user-setup.md](../../docs/08-multi-user-setup.md)
- [scripts/add-user-key.sh](../../scripts/add-user-key.sh)
- [scripts/harden-server.sh](../../scripts/harden-server.sh)
- [templates/ssh_config.template](../../templates/ssh_config.template)