#!/bin/sh

echo "install synaptics packages"

if type apt 2>/dev/null ;then
  sudo apt install xserver-xorg-input-synaptics synaptic
fi

if type dnf 2>/dev/null ;then
  sudo dnf install xorg-x11-drv-synaptics-legacy
fi

echo "restart the X server"
