#!/bin/bash

sudo chown $USER:users /etc/nixos -R
machineId=$(sudo cat /etc/machine-id)
mkdir -p /etc/nixos/profiles/$machineId
read -p "Profile name for $machineId : " profileName
ln -s $machineId /etc/nixos/profiles/$profileName
