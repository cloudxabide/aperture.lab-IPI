# Install RHEL 8 on Laptop

## Pre-reqs
* Red Hat Login to download RHEL 8 Image
* USB stick greater than 8 GB (I'm not kidding)

Download the installation media from https://access.redhat.com  

https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.3/x86_64/product-software

Install RHEL from the media you create 

Run the "finish script"
```
sudo su -
bash <(curl -s https://raw.githubusercontent.com/cloudxabide/aperture.lab/main/Scripts/finish-rhel8.sh)
```

Update your desktop
```
bash <(curl -s https://raw.githubusercontent.com/cloudxabide/aperture.lab/main/Scripts/update_desktop.sh)
```


