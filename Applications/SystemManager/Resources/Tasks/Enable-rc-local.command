#!/bin/bash

if [[ $HOSTNAME =~ fedora ]];then
  sudo touch /etc/rc.d/rc.local
else
  sudo touch /etc/rc.local
fi

sudo systemctl is-enabled rc-local.service
sudo systemctl status rc-local.service
