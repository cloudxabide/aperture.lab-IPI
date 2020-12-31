# OCP4 Installation (Libvirt/IPI)

STATUS:  Work in Progress.  Trying to make this less dependent on the host it's running on and PULL 
           everything needed for all the tasks.

NOTES:  This (at this time) should be run as root.  I have opted to use qemu+ssh - this is kind of
          ridiculous actually.  I'm not sure I care (much) to get this working using (libvirt + IPI)

## Pre-reqs 
NOTE:  you don't *always* need to do this part.  It is here (mostly) as a reference.
 
### Download the Installer and Client
```
# TODO: instead of doing an rm, figure out how to rename it based on the version or something
FILES="openshift-install-linux.tar.gz openshift-client-linux.tar.gz"
for FILE in $FILES
do 
  [ -f $FILE ] && mv $FILE $FILE-`date +%F`
done

case `uname` in 
  Linux)
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
  ;;
  Darwin) 
    curl https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-mac.tar.gz -o openshift-install-mac.tar.gz
    curl https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-mac.tar.gz -o openshift-client-mac.tar.gz  
  ;;
esac 

for FILE in openshift-install-*.tar.gz openshift-client-*.tar.gz; do tar -xvzf $FILE; done
```

## Getting Started | Typical OCP4 Install
### Start your TMUX Session
```
which tmux || yum -y install tmux
cd ${HOME}/OCP4/
tmux new -s OCP4install || tmux attach -t OCP4install
```

### Set ENVIRONMENT VARS
```
SHORTDATE=`date +%F`
THEDATE=`date +%F-%H%M`
CLUSTER_NAME=laptop
OCP4_BASE=${HOME}/OCP4/
OCP4DIR=${OCP4_BASE}/${CLUSTER_NAME}.${BASE_DOMAIN}-${THEDATE}
INSTALLER_DIR="installer-${SHORTDATE}"
SSH_KEY_FILE="${HOME}/.ssh/id_rsa-${BASE_DOMAIN}.pub"
PULL_SECRET_FILE=~jradtke/Downloads/pull-secret.txt
BASE_DOMAIN=aperture.lab
BRIDGE_NAME="ocp4br"
SSH_KEY=$(cat $SSH_KEY_FILE)
PULL_SECRET=$(cat $PULL_SECRET_FILE)
export BASE_DOMAIN BRIDGE_NAME SSH_KEY PULL_SECRET CLUSTER_NAME

[ ! -d ${OCP4_BASE} ] && { mkdir ${OCP4_BASE}; cd $_; } || { cd ${OCP4_BASE}; }
```

## Initial Setup (should be done once)
```
[ $(sysctl -n net.ipv4.ip_forward) != 1 ] && { echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-ipforward.conf; sudo sysctl -p /etc/sysctl.d/99-ipforward.conf; }

systemctl stop libvirtd.service
cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf-${SHORTDATE}
sed -i -e 's/#auth_tcp = "sasl"/auth_tcp = "none"/g' /etc/libvirt/libvirtd.conf
sudo systemctl enable libvirtd-tcp.socket --now
sudo systemctl restart libvirtd
# Test the connection while dumping the default CIDR
virsh --connect qemu+tcp:///system net-dumpxml default

# The following should be done on a Libvirt Hypervisor on an "untrusted network"
#  My laptop is only on my own network, therefore I am not worried about it
sudo firewall-cmd --add-rich-rule "rule service name="libvirt" reject"
virsh --connect qemu+tcp://192.168.122.1/system net-dumpxml default
virsh --connect qemu+ssh://192.168.122.1/system net-dumpxml default
sudo firewall-cmd --zone=libvirt --add-service=libvirt
echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/openshift.conf
echo server=/${BASE_DOMAIN}/192.168.126.1 | sudo tee /etc/NetworkManager/dnsmasq.d/openshift.conf
sudo systemctl reload NetworkManager
```

### SSH tweaks
I create a separate SSH key just for this lab stuff (${HOME}/.ssh/id_rsa-${BASE_DOMAIN}
```
echo | ssh-keygen -trsa -b2048 -N '' -f ${HOME}/.ssh/id_rsa-$BASE_DOMAIN
```

I then create an entry in my SSH config to utilize that key and connect with the "core" user
```
cat << EOF >> ${HOME}/.ssh/config 
Host 192.168.126.*
  User core
  IdentityFile ~/.ssh/id_rsa-${BASE_DOMAIN}
EOF
```

## Build the Installer (with libvirt support)
```
git clone https://github.com/openshift/installer.git ${INSTALLER_DIR}
cd ${INSTALLER_DIR}
TAGS=libvirt hack/build.sh
cd -
```

## Deploy (create) the cluster
```
eval "$(ssh-agent -s)"
ssh-add ${HOME}/.ssh/id_rsa-${BASE_DOMAIN}
sed -i -e '/^192.168.126/d' ~/.ssh/known_hosts
cd ${OCP4_BASE}
[ ! -f install-config-libvirt-${CLUSTER_NAME}.${BASE_DOMAIN}.yaml ] && { wget https://raw.githubusercontent.com/cloudxabide/aperture.lab/main/Files/install-config-libvirt-${CLUSTER_NAME}.${BASE_DOMAIN}.yaml; echo "You need to update the config file found in this directory"; }

# Update the following values
#   platform.libvirt.network.if << This is the bridge that will be created
#   baseDomain  << the domain you plan to use 
#   compute.replicas << you *may* wish to add compute nodes?

# The following creates the "install-config" - copy it out of the directory
#./openshift-install create install-config --dir=${OCP4DIR}/ --log-level=info
# Using the previously created install config....
[ ! -d ${OCP4DIR}/ ] && mkdir ${OCP4DIR}/
envsubst < install-config-libvirt-${CLUSTER_NAME}.${BASE_DOMAIN}.yaml > ${OCP4DIR}/install-config.yaml

${INSTALLER_DIR}/bin/openshift-install create cluster --dir=${OCP4DIR}/ --log-level=debug
sudo virsh net-list


ssh -i ~/.ssh/id_rsa-aperturelab core@192.168.126.10
  journalctl -b -f -u release-image.service -u bootkube.service

export KUBECONFIG=${OCP4DIR}/auth/kubeconfig
```





















## Login to the Environment

```
oc login -u kubeadmin -p `cat $(find $OCP4DIR/ -name kubeadmin-password)`  https://api.ocp4-mwn.aperture.lab:6443/
# export KUBECONFIG=/root/OCP4/${OCP4DIR}/auth/kubeconfig
oc get nodes
```

## Registry (NFS)
For *my* enviromment, NFS was the ideal target for the registry as it provides RWX as is ideal.
NOTE: it is assumed that OCP has been successfully installed by this time.
Also - I had to do some nonsense to make my freeNAS work for this (and it's likely NOT ideal)


### Create the yaml definition for the registry PV and PVC
#### NOTE: go remove seraph:/mnt/raidZ/nfs-registry/docker
```
mkdir ${OCP4DIR}/Registry; cd $_
cat << EOF > image-registry-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: image-registry-pv
spec:
  accessModes:
    - ReadWriteMany
  capacity:
      storage: 100Gi
  nfs:
    path: /mnt/raidZ/nfs-registry
    server: 10.10.10.19
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-registry
EOF

cat << EOF > image-registry-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: image-registry-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources: 
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  storageClassName: nfs-registry
EOF
```

### Create and Validate the PV/PVC
```
kubectl apply -f image-registry-pv.yaml
kubectl -n openshift-image-registry apply -f image-registry-pvc.yaml
kubectl -n openshift-image-registry get pvc
```

### Update the ImageRegistry Operator Config 
TL;DR: update  
```
managementState: Removed
managementState: Managed
```

```
strorage: {}
storage:  
  pvc:  
    claim: image-registry-pvc
```

NOTE:  you are editing the lower section of the config once it's opened
```
oc edit configs.imageregistry.operator.openshift.io -o yaml
## Apply the changes (above) and close the file
oc get clusteroperator image-registry
while true; do oc get clusteroperator image-registry; sleep 2; done
```

### Increase the worker node capacity, if necessary:
```
oc edit machineset -n openshift-machine-api

          memoryMiB: 8192
          numCPUs: 2
          numCoresPerSocket: 1

          memoryMiB: 12288 
          numCPUs: 2
          numCoresPerSocket: 2
```
Then scale-down and scale-up
```
MACHINESET=$(oc get machineset -n openshift-machine-api | grep -v ^NAME | awk '{ print $1 }')
oc scale --replicas=6 machineset $MACHINESET  -n openshift-machine-api
oc scale --replicas=3 machineset $MACHINESET  -n openshift-machine-api
```

## Customize the OpenShift Console logo

```
wget https://github.com/cloudxabide/matrix.lab/raw/main/images/LinuxRevolution_RedGradient.png -O ${OCP4DIR}/LinuxRevolution_RedGradient.png

oc create configmap console-custom-logo --from-file ${OCP4DIR}/LinuxRevolution_RedGradient.png  -n openshift-config
oc edit console.operator.openshift.io cluster
# Update spec: customization: customLogoFile: {key,name}:
## add after "operatorLogLevel: Normal"
  operatorLogLevel: Normal
  customization:
    customLogoFile:
      key: LinuxRevolution_RedGradient.png
      name: console-custom-logo
    customProductName: LinuxRevolution Console
```

## Add htpasswd 
### Create an HTPASSWD file

```
PASSWORD=""
HTPASSWD_FILE=${OCP4DIR}/htpasswd

htpasswd -b -c $HTPASSWD_FILE morpheus $PASSWORD
htpasswd -b $HTPASSWD_FILE ocpguest $PASSWORD
htpasswd -b $HTPASSWD_FILE ocpadmin $PASSWORD

oc create secret generic htpass-secret --from-file=htpasswd=${HTPASSWD_FILE} -n openshift-config
cat << EOF > ${OCP4DIR}/HTPasswd-CR
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: my_htpasswd_provider 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret 
EOF

oc apply -f ${OCP4DIR}/HTPasswd-CR
# You need to login to the cluster with 'ocpadmin' user
oc adm policy add-cluster-role-to-user cluster-admin ocpadmin
```

## Add Legit Certs
review [LetsEncrypt-HowTo](./lets_encrypt.md)  
NOTE:  This *should* be done with CertManager (some time in the future).

## References
https://www.virtuallyghetto.com/2020/07/using-the-new-installation-method-for-deploying-openshift-4-5-on-vmware-cloud-on-aws.html
https://docs.openshift.com/container-platform/4.6/web_console/customizing-the-web-console.html

### Custom Machinesets during IPI install
https://github.com/openshift/installer/blob/master/docs/user/customization.md
https://github.com/openshift/installer/blob/master/docs/user/vsphere/customization.md#machine-pools

## Random foo
```
for IP in `oc get nodes -o wide | awk '{ print $6 }' | grep -v INT`; do ssh core@${IP} "grep proc /proc/cpuinfo"; done
for IP in `oc get nodes -o wide | awk '{ print $6 }' | grep -v INT`; do ssh core@${IP} "uptime"; done
```

```
oc get pods --all-namespaces | egrep -v 'Running' | awk '{ print "oc delete pod " $2 " -n " $1 }' > /tmp/blah
sh /tmp/blah
```
### Clean up between cluster deploys
```
ssh seraph.matrix.lab
rm -rf /mnt/raidZ/nfs-registry/docker
```

```
export KUBECONFIG=$(find ~/OCP4/*acm* -name kubeconfig)
cat $(find ~/OCP4/*acm* -name kubeadmin-password)
oc login -u kubeadmin -p `cat $(find ${HOME}/OCP4/*acm* -name kubeadmin-password)`  https://api.ocp4-acm.aperture.lab:6443/

export KUBECONFIG=$(find ~/OCP4/*mwn* -name kubeconfig)
cat $(find ~/OCP4/*mwn* -name kubeadmin-password)
oc login -u kubeadmin -p `cat $(find ${HOME}/OCP4/*mwn* -name kubeadmin-password)`  https://api.ocp4-mwn.aperture.lab:6443/


## Quick and Dirty
```
sudo su -
cd ${HOME}/OCP4
OCP4DIR=${HOME}/OCP4/laptop.aperture.lab-2020-12-26-1440
cp install-config-libvirt-laptop.aperture.lab.yaml ${OCP4DIR=}/install-config.yaml
${HOME}/OCP4/installer/bin/openshift-install create cluster --dir=${OCP4DIR}/ --log-level=debug
virsh net-list
```
