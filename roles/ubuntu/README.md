# ansible-role-photon

Ansible playbook to automate basic setup of Photon OS instance.

## Requirements

One instance of Photon OS running

## Role Variables

    docker_gid: 995

The docker group id to set (gets created if missing) for socket access and similar.

    docker_insecure_registries: []

Array of URLs to setup to allow the use of Docker insecure registries.

    syslog_remote_server: lab01-flt-logs01.lab.mccannical.net
    syslog_remote_port: 514
    syslog_remote_transport: tcp
    syslog_disk_buffer_bytes: 268435456
    syslog_remote_dropin: 90-remote.conf
    syslog_verify_delivery: true
    syslog_verify_timeout: 15

Setting `syslog_remote_server` turns on forwarding. Use a DNS name, not an IP, so moving the server doesn't silently break forwarding. The role keeps Ubuntu's packaged `/etc/syslog-ng/syslog-ng.conf`, which already reads the journal and writes the usual `/var/log` files, and adds only `/etc/syslog-ng/conf.d/<syslog_remote_dropin>` with the remote destination. Where the packaged file was changed (this role replaced it until 2026-11-09), it restores it with `apt-get install --reinstall` and keeps the old copy as `syslog-ng.conf.replaced-<time>`. The disk buffer keeps messages through a server restart; `0` means memory queue only. After restarting syslog-ng the role sends a `logger` test line and fails unless the remote destination's `written` counter rises within `syslog_verify_timeout` seconds, because a running service proves nothing.

    photon_yum_repo: https://dl.bintray.com/vmware/photon_release_1.0_TP2_x86_64
    photon_yum_repo_enabled: yes|no

Set these to utilize specifig Photon OS binary package repos.

## Example playbook

```

---
- hosts: photons
  sudo: no
  remote_user: root
  roles:
    - photon

```

# License and Copyright

Copyright 2015 VMware, Inc.  All rights reserved.

SPDX-License-Identifier: Apache-2.0 OR GPL-3.0-only

This code is Dual Licensed Apache-2.0 or GPLv3

## Author Information

This role was created in 2015 by [Tom Hite / VMware](http://www.vmware.com/).
