# ubuntu-os-tools

Ansible playbooks for configuring Ubuntu in the home lab.

## Running

On the Ubuntu host, as root:

1. Copy `configure-ubuntu-sample.yml` to `configure-ubuntu.yml` and set your values. `configure-ubuntu.yml` is gitignored, so host-specific settings never reach the repository.
2. Run `./launch_playbook.sh`. It installs Ubuntu's `ansible-core` package and runs the playbook against `localhost` (see `inventory.ini`).

The role uses only `ansible.builtin` modules, so nothing is fetched from Ansible Galaxy. See `roles/ubuntu/README.md` for every setting.

## Secret scan

This repository is public. SSH keys of any kind (public or private), certificates and passwords never go in it; a host's real keys and CA belong in its own `configure-*.yml`, which is gitignored. The `secret-scan` workflow runs [gitleaks](https://github.com/gitleaks/gitleaks) over the full history on every push and pull request, with gitleaks' default rules plus the SSH-key and certificate rules in `.gitleaks.toml`. Placeholders such as `ssh-rsa AAAA...your-public-key...` or a `root certificate` line pass. To check before pushing:

```bash
gitleaks git . --config .gitleaks.toml --redact
```
