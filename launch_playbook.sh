#!/bin/bash
set -o xtrace


tdnf install ansible -y
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
ansible-playbook --connection=local configure-photon.yml