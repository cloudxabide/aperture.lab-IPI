#!/bin/bash


sudo yum -y install golang-bin gcc-c++ libvirt-devel libvirt-daemon-driver-network

cat << EOF > /etc/dnsmasq.conf

# Increase the default query limit
# https://access.redhat.com/solutions/2339941
dns-forward-max=300
EOF 
systemctl restart NetworkManager

exit 0

