#!/bin/bash
#set -o xtrace

# The role uses only ansible.builtin modules, so the distribution's
# ansible-core is enough: no ansible-galaxy collections to install.
export DEBIAN_FRONTEND=noninteractive
apt-get install -y ansible-core
ansible-playbook --connection=local configure-ubuntu.yml
