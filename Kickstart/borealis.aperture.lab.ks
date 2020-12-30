#version=RHEL8
# License agreement
eula --agreed
# Use graphical install
graphical
# Network information
network  --bootproto=dhcp --device=enp0s31f6 --onboot=off --ipv6=auto --no-activate
network  --bootproto=dhcp --hostname=borealis.aperture.lab
ignoredisk --only-use=nvme0n1
# Use CDROM installation media
cdrom
# Run the Setup Agent on first boot
firstboot --enable

repo --name="AppStream" --baseurl=file:///run/install/sources/mount-0000-cdrom/AppStream
# System bootloader configuration
bootloader --location=none
autopart --encrypted
# Partition clearing information
clearpart --none --initlabel

%packages
@^graphical-server-environment
kexec-tools

%end

# Keyboard layouts
keyboard --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=enp0s31f6 --onboot=off --ipv6=auto --no-activate
network  --hostname=borealis.aperture.lab

# Run the Setup Agent on first boot
firstboot --enable

# System timezone
timezone America/New_York --isUtc

# Root password
rootpw --iscrypted $6$ymCkw9maKGobZX.A$5///nyAy9IUgiUSHaZlGA2N8p8E03OBPjOMWUygoexnG/f2U5By4pweMdAiYCSGSZocWEd9ePsACGzxlUkdm00
user --groups=wheel --name=mansible --password=$6$ymCkw9maKGobZX.A$5///nyAy9IUgiUSHaZlGA2N8p8E03OBPjOMWUygoexnG/f2U5By4pweMdAiYCSGSZocWEd9ePsACGzxlUkdm00 --iscrypted --uid=1000 --gecos="My Ansible" --gid=1000

%addon com_redhat_subscription_manager 
%end
%addon ADDON_placeholder --enable --reserve-mb=auto
%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
