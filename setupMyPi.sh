#!/bin/sh

# check if root

if [ $(id -u) -gt 0 ] ;then
    echo "Use sudo $0 "
    exit 1
fi

apt-get install ansible -y

ansible-playbook -vv setupPi.yml