# ansible-role-ubuntu

Ansible role for the basic setup of an Ubuntu Server instance.

## Requirements

- Ubuntu Server 24.04 (noble).
- ansible-core 2.16 or later, from Ubuntu's own `ansible-core` package. The role uses only `ansible.builtin` modules, so no Ansible Galaxy collections are needed.

Everything is done the Ubuntu way: packages come from the Ubuntu archive through apt (never system-wide pip, which Ubuntu refuses under PEP 668), services are managed with systemd drop-ins instead of edited unit files, the firewall is ufw, and certificates go through `update-ca-certificates`.

## Re-running on an existing host

The role is the starting configuration for a new host, and it is safe to re-run. Most settings are enforced on every run. `/etc/docker/daemon.json` is only written when it doesn't exist, and ufw rules are only ever added, because other tools often take these over after the first boot. To overwrite them anyway, set the one-off switch for that run: `force_reset_docker_config: yes` or `force_reset_firewall: yes`.

## Role Variables

### Docker

```yaml
docker_group_id: 995
docker_user_id: 233
docker_insecure_registries: []
docker_daemon_config: {...}
force_reset_docker_config: no
docker_replace_docker_ce: no
```

Docker comes from the Ubuntu archive (`docker.io`, `docker-compose-v2`, `docker-buildx`) and is updated by apt like any other package. The service runs with the `docker` group through `/etc/systemd/system/docker.service.d/group.conf`. `docker_daemon_config` (default: systemd cgroup driver, overlay2, json-file logs capped at 3 files of 10 MB per container) becomes `/etc/docker/daemon.json`, written only when that file doesn't exist yet. An existing `daemon.json` is left alone and the play says so; set `force_reset_docker_config: yes` for a run that should overwrite it. `docker_insecure_registries` entries (`host:port` strings or `{host, port}` mappings) are merged into it as `insecure-registries`.

Earlier versions installed Docker Inc.'s `docker-ce` from a repository hard-coded to jammy (22.04), which stops updating once a host moves to a later release. If `docker-ce` is installed, the role stops with an error, because replacing it stops every container on the host. Stop the workloads and re-run with `docker_replace_docker_ce: yes`: it removes Docker Inc.'s packages, repository and key and installs `docker.io`. Images, containers and volumes in `/var/lib/docker` are kept.

### apt

```yaml
apt_updatecache: yes
apt_distrosync: no
apt_packages: [...]
apt_additional_packages: []
```

`apt_updatecache` refreshes package metadata first. `apt_distrosync` upgrades every installed package.

### Firewall

```yaml
firewall_allowed_ports:
  - 22/tcp
  - 80/tcp
  - 443/tcp
force_reset_firewall: no
```

Each entry is passed to `ufw allow`, then ufw is enabled if it isn't already (after the allow rules, so SSH stays reachable). Existing ufw rules are left in place: the role only adds. `force_reset_firewall: yes` instead runs `ufw --force reset` (ufw keeps timestamped backups of its rule files), rebuilds the rules from `firewall_allowed_ports` alone and enables ufw again; the role refuses to do that if the list has no `22/tcp`. ufw's defaults already allow loopback, established connections and ping. The `ufw` command is used directly because the ufw Ansible module is in a Galaxy collection.

### Syslog forwarding

```yaml
syslog_remote_server: lab01-flt-logs01.lab.mccannical.net
syslog_remote_port: 514
syslog_remote_transport: tcp
syslog_disk_buffer_bytes: 268435456
syslog_remote_dropin: 90-remote.conf
syslog_verify_delivery: true
syslog_verify_timeout: 15
```

Setting `syslog_remote_server` turns on forwarding. Use a DNS name, not an IP, so moving the server doesn't silently break forwarding. The role keeps Ubuntu's packaged `/etc/syslog-ng/syslog-ng.conf`, which already reads the journal and writes the usual `/var/log` files, and adds only `/etc/syslog-ng/conf.d/<syslog_remote_dropin>` with the remote destination. Where the packaged file was changed (this role replaced it until 2026-11-09), it restores it with `apt-get install --reinstall` and keeps the old copy as `syslog-ng.conf.replaced-<time>`. The disk buffer keeps messages through a server restart; `0` means memory queue only. After restarting syslog-ng the role sends a `logger` test line and fails unless the remote destination's `written` counter rises within `syslog_verify_timeout` seconds, because a running service proves nothing.

### Time

```yaml
ntp_timezone: "Etc/UTC"
ntp_servers: [...]
ntp_fallback_servers: [...]
```

The timezone is set with `timedatectl` and time is kept by `systemd-timesyncd`. Don't add `ntp` to the package lists: on Ubuntu it pulls in `ntpsec`, which conflicts with `systemd-timesyncd`.

### Certificates

```yaml
ssl_root_certificate_pem: |
  -----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----
ssl_root_certificate_pem_filename: home_mccannical_net_root.pem
```

The PEM is written to `/usr/local/share/ca-certificates/<name>.crt` (a `.pem` suffix becomes `.crt`, which `update-ca-certificates` requires) and compiled into the system bundle. Leave `ssl_root_certificate_pem` empty to skip this.

### Users

```yaml
ssh_enabled_users:
  - name: root
    ssh_key: "ssh-ed25519 AAAA... comment"
users_root_pwd_no_expire: no
```

Each key is added to the user's `~/.ssh/authorized_keys`.

## Example playbook

See `configure-ubuntu-sample.yml` in the repository root.

```yaml
---
- hosts: ubuntu
  become: true
  roles:
    - ubuntu
```

## License and Copyright

Copyright 2015 VMware, Inc.  All rights reserved.

SPDX-License-Identifier: Apache-2.0 OR GPL-3.0-only

This code is Dual Licensed Apache-2.0 or GPLv3

## Author Information

This role was created in 2015 by [Tom Hite / VMware](http://www.vmware.com/) and ported to Ubuntu by Christopher McCann.
