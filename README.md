# aperture.lab
Repo for my OCP4 installation on my laptop

## Assumptions:  
You have:
* a valid subscription to acquire OpenShift Images
* a (reasonably) powerful machine - 
  * 8 cores
  * 64GB RAM (memory is key)
  * 600GB HDD (each VM takes 120GB + bootstrap, etc..)

### My Hardware
```
echo "`dmidecode -s system-manufacturer` `dmidecode -s baseboard-product-name`,`lscpu | grep "^Model name:" | grep -o -P '(?<=Intel\(R\)).*(?=\@)'`, `free -h | grep "Mem:" | awk '{ print $2 }'`"  
```
Lenovo T580  
LENOVO 20LAS3NJ00, Core(TM) i7-8650U CPU , 62Gi

## Pre-reqs:  
Confirm Red Hat access and get your pull secret  
  * visit https://cloud.redhat.com and click through the following:  
    Red Hat OpenShift Cluster Manager (Cluster manger) | Create Cluster | Red Hat OpenShift Container Platform | Run on Bare Metal | User-provisioned infrastructure  | Download pull secret

## Steps
* Instsall Virtualization Foundation (KVM)
* Download and instantiate freeSCO (DHCP and router)
* Install virtual machine for Red Hat Identity Management (DNS)

## Details 

| hostname      | vCPU | Memory | HDD  | IP            | Purpose      |
|:-------------:|:----:|:------:|:-----|:--------------|:------------:|
| freesco       | 1    | 256M   | 1.4M | 192.168.200.1 | dhcp, router |
| rh7-idm-srv01 | 1    | 1024M  | 25G  | 192.168.200.2 | dns, IdM     |


| Item       | Value               |
|:-----------|:--------------------|
| domain     | aperture.lab        |
| dhcp range | 192.168.200.100-248 |
