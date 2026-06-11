# Example: GitHub SSH Key Setup

**Scenario:** You want to use SSH keys to authenticate with GitHub instead of typing your username and password (or personal access token) every time you push or pull.

---

## Walkthrough

### 1. Generate a keypair for GitHub

```bash
ssh-keygen -t ed25519 -C "your-email@github.com" -f ~/.ssh/id_ed25519_github
# Set a passphrase — GitHub recommends it, but it's optional for automation
```

### 2. Add the key to ssh-agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github
```

### 3. Copy the public key

```bash
cat ~/.ssh/id_ed25519_github.pub
# Copy the entire output
```

### 4. Add to GitHub

1. Go to [github.com/settings/keys](https://github.com/settings/keys)
2. Click **New SSH Key**
3. Title: `Personal Laptop (May 2026)` (or whatever identifies this machine)
4. Paste your public key
5. Click **Add SSH Key**

GitHub will ask for your password to confirm.

### 5. Test the connection

```bash
ssh -T git@github.com
```

Expected output:
```
Hi your-username! You've successfully authenticated, but GitHub does not provide shell access.
```

**This is success.** "does not provide shell access" is normal — GitHub uses SSH for Git operations only, not interactive shell access.

### 6. Configure ~/.ssh/config

```bash
# ~/.ssh/config (add this section)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
```

### 7. Clone a repo using SSH

```bash
# Use the SSH clone URL, not HTTPS
git clone git@github.com:username/repo.git
```

---

## Multiple GitHub Accounts

If you have personal and work GitHub accounts on the same machine:

```bash
# Generate separate keys
ssh-keygen -t ed25519 -C "personal@email.com" -f ~/.ssh/id_ed25519_github_personal
ssh-keygen -t ed25519 -C "work@company.com" -f ~/.ssh/id_ed25519_github_work

# ~/.ssh/config
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_personal
    IdentitiesOnly yes

Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_work
    IdentitiesOnly yes
```

Clone with:
```bash
git clone git@github.com-personal:personal/repo.git
git clone git@github.com-work:company/repo.git
```

---

## Adding a Deploy Key (CI/CD)

For a server or CI pipeline that needs read-only access to a single repo:

1. Generate a key on the server:
   ```bash
   ssh-keygen -t ed25519 -C "deploy@production" -f ~/.ssh/id_ed25519_deploy
   ```

2. In GitHub: **Repo → Settings → Deploy Keys → Add Deploy Key**
   - Paste the public key
   - Check **Allow write access** only if the pipeline pushes code

3. Test:
   ```bash
   ssh -T -i ~/.ssh/id_ed25519_deploy git@github.com
   ```

---

## Security Notes

- Use a **different key per context** (work vs personal, laptop vs CI server)
- GitHub has [verified commit signing](https://docs.github.com/en/authentication/managing-commit-signature-verification) — this is separate from SSH, though you can now sign commits with your SSH key
- Rotate your GitHub SSH keys every 6-12 months (see [key rotation guide](../../docs/09-key-rotation.md))
- Review active keys at [github.com/settings/keys](https://github.com/settings/keys) — revoke any you don't recognize

---

## Files Used

- [docs/03-generate-ssh-keypair.md](../../docs/03-generate-ssh-keypair.md)
- [templates/ssh_config.template](../../templates/ssh_config.template)