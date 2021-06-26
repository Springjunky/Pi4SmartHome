#!/bin/sh

apt-get install ansible -y

ansible-playbook -vvv setupPi.yml