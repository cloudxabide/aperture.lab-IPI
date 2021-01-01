#!/bin/bash
ENV_FILE=../Files/ENV.txt

[ -f ${ENV_FILE} ] || { echo "ERROR: environment file not found"; exit 9; } && { echo "Sourcing ENV file"; . ${ENV_FILE}; }

/usr/bin/cp /usr/share/libvirt/networks/default.xml /tmp/new-net.xml
sed -i "s/default/ocp-${BRIDGE_3RD_OCTET}/" /tmp/new-net.xml
sed -i "s/virbr0/ocp-$BRIDGE_3RD_OCTET/" /tmp/new-net.xml
sed -i "s/122/${BRIDGE_3RD_OCTET}/g" /tmp/new-net.xml
virsh net-define /tmp/new-net.xml
virsh net-autostart ocp-${BRIDGE_3RD_OCTET}
virsh net-start ocp-${BRIDGE_3RD_OCTET}
systemctl restart libvirtd


exit 0
virsh net-destroy ocp-${BRIDGE_3RD_OCTET}
 
