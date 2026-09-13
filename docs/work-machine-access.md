# Read-write access to this private repo from another machine

Use a **deploy key**, not your account SSH key.

An account-level key (github.com/settings/keys) authenticates *you* — it grants that
machine access to every repository you can reach, personal and organisational, read and
write. On employer-managed hardware that is more than you want to hand over: the machine
may be imaged, monitored, or retained after you leave, and the key stays valid until you
notice and revoke it.

A deploy key is scoped to **one repository**. Revoking it affects nothing else.

---

## 0. On WSL specifically

Do all of this **inside the WSL distro**, not Windows. Git runs there, so the key belongs
there too.

Keep `~/.ssh` in the WSL filesystem — never under `/mnt/c/`. Windows-mounted paths cannot
express Unix permissions, so SSH sees a world-readable private key and refuses it:

```text
Permissions 0777 for '/mnt/c/.../id_dotfiles' are too open.
```

To get the public key into the Windows clipboard for pasting into GitHub:

```bash
clip.exe < ~/.ssh/id_dotfiles.pub
```

Clone inside WSL too (`~/dotfiles`, not `/mnt/c/...`) — a repo on the Windows filesystem
is far slower and picks up CRLF line endings that break the shell scripts.

## 1. On the other machine — generate a key

It must never leave that machine. Do not copy a private key between machines.

```bash
ssh-keygen -t ed25519 -C "work-wsl-dotfiles" -f ~/.ssh/id_dotfiles
cat ~/.ssh/id_dotfiles.pub
```

A passphrase is worth it; `AddKeysToAgent yes` means you type it once per login.

## 2. Register the public half

Paste the public key at:

```text
https://github.com/erespebrn/dotfiles/settings/keys  ->  Add deploy key
[x] Allow write access
```

Adding it through the web UI is deliberate. `gh repo deploy-key add -w` also works, but
keys added that way are tied to the CLI's auth token — de-authorising the GitHub CLI
later silently deletes them.

To check what exists: `gh repo deploy-key list --repo erespebrn/dotfiles`

## 3. On the other machine — bind the key to a host alias

`~/.ssh/config`:

```text
Host github-dotfiles
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_dotfiles
  IdentitiesOnly yes
  AddKeysToAgent yes
```

`IdentitiesOnly yes` is required. Without it SSH offers every key the agent holds, GitHub
matches whichever it recognises first, and a deploy key only authenticates when it is the
one presented.

## 4. Clone and verify

```bash
git clone git@github-dotfiles:erespebrn/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
ssh -T git@github-dotfiles     # expect: "... successfully authenticated, but GitHub does
                               #  not provide shell access." plus the repo name
```

Already cloned with a different URL:

```bash
git remote set-url origin git@github-dotfiles:erespebrn/dotfiles.git
```

## 5. Set the identity for that machine

Commits pushed over a deploy key still take their author from git config, so fill in
`~/.gitconfig.local` (untracked, seeded by `install.sh`):

```ini
[user]
	name = Your Name
	email = work@example.com
```

---

## Notes

- **A deploy key works on exactly one repository** across all of GitHub. The same key
  cannot be reused for a second repo.
- **Commits pushed via a deploy key do not appear on your contribution graph.** They are
  attributed to the key, not the account. The commit author line is unaffected.
- **Never force-push once two machines have clones.** A rewritten history leaves the other
  machine on an orphaned branch and `git pull` will produce a mess. If it happens:
  `git fetch && git reset --hard origin/main` on the machine that is behind.
- **Keep genuinely machine-specific settings out of the repo.** Toolchain paths, a work
  email, proxies belong in `~/.bashrc.local` and `~/.gitconfig.local`. Only things you
  want on *both* machines should travel through git.
- **Check your employer's policy** before connecting a personal repository to managed
  hardware. A read-write deploy key for a config repo is easy to justify — one repo, no
  account access, nothing proprietary in either direction — but some policies prohibit
  personal accounts on work machines outright.

## Alternative: fine-grained personal access token

If SSH is blocked outbound (some corporate networks allow only 443):

1. github.com/settings/personal-access-tokens — **Fine-grained token**
2. Repository access: *Only select repositories* -> `dotfiles`
3. Permissions: **Contents: Read and write**
4. Set an expiry — 90 days is a reasonable default

```bash
git clone https://github.com/erespebrn/dotfiles.git ~/dotfiles
git config --global credential.helper store   # or libsecret
```

Push once; the token is stored. It expires on schedule, which is a feature on hardware you
do not fully control. SSH over 443 is also an option if only port 22 is blocked — add
`Port 443` and `HostName ssh.github.com` to the Host block in step 3.
