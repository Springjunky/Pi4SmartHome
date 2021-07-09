#!/bin/sh

# check if root

if [ $(id -u) -gt 0 ] ;then
    echo "Use sudo $0 "
    exit 1
fi
# We need to insall a modern ansible, so we use pip

sudo apt-get install python3 python3-pip -y

ANSIBLE_INSTALLED=$(which ansible)

if [ -z $ANSIBLE_INSTALLED ]; then
  echo "Install ansible "
  pip3 install ansible-base
  echo "Install docker collection for ansible"
  ansible-galaxy collection install community.docker
else
  echo "Ansible installed"
fi


ansible-playbook -v setupPi.yml
