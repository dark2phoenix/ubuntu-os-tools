# ansible-role-ubuntu

Ansible role for the basic setup of an Ubuntu Server instance.

## Requirements

- Ubuntu Server 24.04 (noble).
- ansible-core 2.16 or later, from Ubuntu's own `ansible-core` package. The role uses only `ansible.builtin` modules, so no Ansible Galaxy collections are needed.

Everything is done the Ubuntu way: packages come from the Ubuntu archive through apt (never system-wide pip, which Ubuntu refuses under PEP 668), services are managed with systemd drop-ins instead of edited unit files, the firewall is ufw, and certificates go through `update-ca-certificates`.

## Re-running on an existing host

The role is the starting configuration for a new host, and it is safe to re-run. Most settings are enforced on every run. Two files are never overwritten on a re-run, because other tools often take them over after the first boot:

**Table:** Files a re-run never overwrites

| File                                                        | Written when                                                              | To overwrite it anyway            |
| ----------------------------------------------------------- | ------------------------------------------------------------------------- | --------------------------------- |
| `/etc/docker/daemon.json`                                   | it doesn't exist yet                                                      | `force_reset_docker_config: true` |
| `/etc/ufw/user.rules`, `/etc/ufw/user6.rules` (ufw's rules) | every run adds `firewall_allowed_ports`; existing rules are never removed | `force_reset_firewall: true`      |

When the role leaves an existing `daemon.json` alone it says so in the play output and names the switch. Both switches are one-off: set them for the run that should reset the file, then remove them.

## Role Variables

### Docker

**Table:** Docker Configurable Parameters

| Parameter                    | Type    | Default     | Description                                                                                                                                                |
| :--------------------------- | :------ | :---------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `docker_group_id`            | integer | 995         | Unix id of the `docker` group                                                                                                                              |
| `docker_user_id`             | integer | 233         | Unix id of the user to run docker as                                                                                                                       |
| `docker_daemon_config`       | yaml    | see example | Contents of `/etc/docker/daemon.json`, declared as YAML and converted to JSON. Written only when the file doesn't exist yet                                |
| `force_reset_docker_config`  | boolean | false       | Replace an existing `/etc/docker/daemon.json` with `docker_daemon_config`                                                                                  |
| `docker_insecure_registries` | array   | \[\]        | Additional insecure registries, written to `insecure-registries` in daemon.json. Entries may be `'host:port'` strings or `{host: ..., port: ...}` mappings |
| `docker_replace_docker_ce`   | boolean | false       | Remove Docker Inc.'s `docker-ce` and install Ubuntu's `docker.io` (stops every container)                                                                  |

**Example:** docker

```yaml
docker_group_id: 995
docker_user_id: 233
docker_daemon_config:
  exec-opts:
    - "native.cgroupdriver=systemd"
  log-driver: "json-file"
  log-opts:
    max-size: "10m"
    max-file: "3"
  storage-driver: "overlay2"
docker_insecure_registries:
  - 'myregistry.domain.com:5000'
```

Docker comes from the Ubuntu archive (`docker.io`, `docker-compose-v2`, `docker-buildx`) and is updated by apt like any other package. The service runs with the `docker` group through `/etc/systemd/system/docker.service.d/group.conf`. The default `docker_daemon_config` is the systemd cgroup driver, overlay2, and json-file logs capped at 3 files of 10 MB per container.

Earlier versions installed Docker Inc.'s `docker-ce` from a repository hard-coded to jammy (22.04), which stops updating once a host moves to a later release. If `docker-ce` is installed, the role stops with an error, because replacing it stops every container on the host. Stop the workloads and re-run with `docker_replace_docker_ce: true`: it removes Docker Inc.'s packages, repository and key and installs `docker.io`. Images, containers and volumes in `/var/lib/docker` are kept.

### apt

**Table:** apt Configurable Parameters

| Parameter                 | Type    | Default        | Description                                |
| :------------------------ | :------ | :------------- | :----------------------------------------- |
| `apt_updatecache`         | boolean | true           | Refresh package metadata before installing |
| `apt_distrosync`          | boolean | false          | Upgrade every installed package            |
| `apt_packages`            | array   | see list below | Packages every host gets                   |
| `apt_additional_packages` | array   | []             | Extra packages for this host               |

Default packages:

- `sudo`
- `bind9utils`
- `openssl`
- `ansible-core`
- `vim`
- `vim-common`
- `vim-scripts`
- `nfs-common`
- `logrotate`
- `wget`
- `tzdata`
- `traceroute`
- `tar`
- `jq`
- `less`

**Example:** apt

```yaml
apt_updatecache: true
apt_distrosync: false
apt_additional_packages:
  - unzip
```

### Firewall

**Table:** Firewall Configurable Parameters

| Parameter                | Type    | Default                       | Description                                                  |
| :----------------------- | :------ | :---------------------------- | :----------------------------------------------------------- |
| `firewall_allowed_ports` | array   | `22/tcp`, `80/tcp`, `443/tcp` | Each entry is passed to `ufw allow`                          |
| `force_reset_firewall`   | boolean | false                         | Reset ufw and rebuild it from `firewall_allowed_ports` alone |

**Example:** firewall

```yaml
firewall_allowed_ports:
  - 22/tcp
  - 80/tcp
  - 443/tcp
```

After the allow rules, ufw is enabled if it isn't already, so SSH stays reachable. Existing ufw rules are left in place: the role only adds. `force_reset_firewall: true` instead runs `ufw --force reset` (ufw keeps timestamped backups of its rule files), rebuilds the rules from `firewall_allowed_ports` alone and enables ufw again; the role refuses to do that if the list has no `22/tcp`. ufw's defaults already allow loopback, established connections and ping. The `ufw` command is used directly because the ufw Ansible module is in a Galaxy collection.

### Syslog forwarding

**Table:** Syslog Configurable Parameters

| Parameter                  | Type    | Default        | Description                                                                                                                                  |
| :------------------------- | :------ | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| `syslog_remote_server`     | string  | unset          | DNS name of the syslog server; setting it turns on forwarding. Use a name, not an IP, so moving the server doesn't silently break forwarding |
| `syslog_remote_port`       | integer | 514            | Remote port                                                                                                                                  |
| `syslog_remote_transport`  | string  | tcp            | `tcp` or `udp`                                                                                                                               |
| `syslog_disk_buffer_bytes` | integer | 268435456      | Disk buffer for the remote destination, so messages survive a server restart. `0` keeps the memory queue only                                |
| `syslog_remote_dropin`     | string  | 90-remote.conf | Name of the drop-in written to `/etc/syslog-ng/conf.d/`                                                                                      |
| `syslog_verify_delivery`   | boolean | true           | Send a test line and fail unless the remote destination's `written` counter rises                                                            |
| `syslog_verify_timeout`    | integer | 15             | Seconds the delivery check waits                                                                                                             |

**Example:** syslog

```yaml
syslog_remote_server: logs.example.com
syslog_remote_port: 514
syslog_remote_transport: tcp
```

The role keeps Ubuntu's packaged `/etc/syslog-ng/syslog-ng.conf`, which already reads the journal and writes the usual `/var/log` files, and adds only the drop-in with the remote destination. Where the packaged file was changed (this role replaced it until 2026-11-09), it restores it with `apt-get install --reinstall` and keeps the old copy as `syslog-ng.conf.replaced-<time>`.

### Time

**Table:** Time Configurable Parameters

| Parameter              | Type             | Default              | Description                                                                                                     |
| :--------------------- | :--------------- | :------------------- | :-------------------------------------------------------------------------------------------------------------- |
| `ntp_timezone`         | string           | Etc/UTC              | Unix [standard time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones), set with `timedatectl` |
| `ntp_servers`          | array of strings | \[0-3\].pool.ntp.org | Primary NTP servers for `systemd-timesyncd`                                                                     |
| `ntp_fallback_servers` | array of strings | \[0-3\].pool.ntp.org | Fallback NTP servers used when no primary is reachable                                                          |

**Example:** time

```yaml
ntp_timezone: "America/New_York"
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
```

Don't add `ntp` to the package lists: on Ubuntu it pulls in `ntpsec`, which conflicts with `systemd-timesyncd`.

### Certificates

**Table:** Certificates Configurable Parameters

| Parameter                           | Type   | Default | Description                                                                                                               |
| :---------------------------------- | :----- | :------ | :------------------------------------------------------------------------------------------------------------------------ |
| `ssl_root_certificate_pem`          | string | unset   | Root and intermediate certificates in PEM format. Empty skips this task                                                   |
| `ssl_root_certificate_pem_filename` | string | unset   | File name in `/usr/local/share/ca-certificates` (a `.pem` suffix becomes `.crt`, which `update-ca-certificates` requires) |

**Example:** certificates

```yaml
ssl_root_certificate_pem: |
  -----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----
ssl_root_certificate_pem_filename: my_custom_root.pem
```

### Users

**Table:** Users Configurable Parameters

| Parameter                     | Type                      | Default | Description                                                                         |
| :---------------------------- | :------------------------ | :------ | :---------------------------------------------------------------------------------- |
| `users_root_pwd_no_expire`    | boolean                   | false   | Sets the root password to never expire, which is _NOT RECOMMENDED FOR PRODUCTION!!_ |
| `ssh_enabled_users`           | array of name and ssh_key | unset   | Users and keys to add to `~/.ssh/authorized_keys`                                   |
| `ssh_enabled_users[].name`    | string                    | unset   | Name of the user                                                                    |
| `ssh_enabled_users[].ssh_key` | string                    | unset   | Key in `authorized_keys` format                                                     |

**Example:** users

```yaml
ssh_enabled_users:
  - name: root
    ssh_key: "ssh-ed25519 AAAA... comment"
users_root_pwd_no_expire: false
```

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
