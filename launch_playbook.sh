#!/bin/bash
#set -o xtrace

DEBIAN_FRONTEND=noninteractive
apt install -y python3-pip ansible
ansible-galaxy collection install community.general --force
ansible-galaxy collection install ansible.posix --force
ANSIBLE_LOCALHOST_WARNING=False \
ANSIBLE_INVENTORY_UNPARSED_WARNING=False \
ansible-playbook --connection=local configure-ubuntu.yml