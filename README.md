# ubuntu-os-tools

Ansible playbooks for configuring Ubuntu in the home lab.

## Running

On the Ubuntu host, as root:

1. Copy `configure-ubuntu-sample.yml` to `configure-ubuntu.yml` and set your values. `configure-ubuntu.yml` is gitignored, so host-specific settings never reach the repository.
2. Run `./launch_playbook.sh`. It installs Ubuntu's `ansible-core` package and runs the playbook against `localhost` (see `inventory.ini`).

The role uses only `ansible.builtin` modules, so nothing is fetched from Ansible Galaxy. See `roles/ubuntu/README.md` for every setting.
