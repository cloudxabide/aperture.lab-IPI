# OpenShift Container Platform 4


## Overview (topology)
![MatrixLab OCP4 Overview](../images/MatrixLab-OCP4-Overivew.png)

## "Hardware Requirements"

### OCP and OCS Cluster
| Machine       | Operating System  | vCPU | Virtual RAM | Storage | Qty        |   | vCPU | RAM | Storage
|:--------------|:------------------|:----:|:------------|:--------|:-----------|:-:|-----|:----|:-------
| Bootstrap     | RHCOS             | 4    | 16 GB       | 120 GB  | 1          | - | 4    | 16  | 120
| Control plane | RHCOS             | 4    | 8 GB        | 120 GB  | 3          | - | 12   | 24  | 360
| Compute       | RHCOS or RHEL 7.6 | 2    | 8 GB        | 120 GB  | 3          | - | 6    | 16  | 360
|               |                   |      |             |         | **totals** | = | 22   | 58  | 840

## libvirt nuances
I (almost) always configure a separate volume which my VM images reside in.  This is typically /var/lib/libvirt/images.  


Well, for some reason the openshift installer configured for libvirt instead uses /var/lib/libvirt/openshift-images/

```
[root@borealis openshift-install-314417930]# find /var/lib/libvirt/openshift-images/
/var/lib/libvirt/openshift-images/
/var/lib/libvirt/openshift-images/ocp4test-9ftgq
/var/lib/libvirt/openshift-images/ocp4test-9ftgq/ocp4test-9ftgq-base
/var/lib/libvirt/openshift-images/ocp4test-9ftgq/ocp4test-9ftgq-master.ign
/var/lib/libvirt/openshift-images/ocp4test-9ftgq/ocp4test-9ftgq-bootstrap.ign
/var/lib/libvirt/openshift-images/ocp4test-9ftgq/ocp4test-9ftgq-master-2
/var/lib/libvirt/openshift-images/ocp4test-9ftgq/ocp4test-9ftgq-bootstrap
/var/lib/libvirt/openshift-images/ocp4test-9ftgq/ocp4test-9ftgq-master-1
/var/lib/libvirt/openshift-images/ocp4test-9ftgq/ocp4test-9ftgq-master-0
```
Therefore, I will mount /home/images as /var/lib/libvirt/openshift-images/ (and see what happens)

