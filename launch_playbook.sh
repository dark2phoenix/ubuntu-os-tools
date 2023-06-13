#!/bin/bash
set -o xtrace


sudo apt install ansible-core -y
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
ANSIBLE_LOCALHOST_WARNING=False \
ANSIBLE_INVENTORY_UNPARSED_WARNING=False \
ansible-playbook --connection=local configure-ubuntu.yml