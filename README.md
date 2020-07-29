# ghostbsd-core
GhostBSD core ISO build

These scripts are only for testing the core operating system for GhostBSD and for research purposes.

## Recommend System Requirements

* GhostBSD 20.04.1 or newer
* 128GB memory
* 48 cores
* 100GB of disk space
* GhostBSD src in /usr/src
* GhostBSD ports in /usr/ports
* Poudriere and vm-bhvye with one time configuration

Lesser configurations should work but have not been tested.

## Install poudriere

```
pkg install poudriere
```

## Configure poudriere

Edit poudriere default configuration:

```
edit /usr/local/etc/poudriere.conf
```

Define to the pool to be used for building packages:

```
ZPOOL=/tank
```

Define the local path for creating jails, ports trees:

```
BASEFS=/tank/poudriere
```

Save configuration then make distfiles location for building ports:

```
zfs create tank/usr/ports/distfiles
```

Create poudriere ports jail that uses /usr/ports for ports tree:
```
poudriere ports -c -p ghostbsd-ports -m null -M /usr/ports/
```

## Install nginx to monitor ports build (optional)

Install the nginx package:

```
pkg install nginx
```

Edit the default configuration:

```
edit /usr/local/etc/nginx.conf
```

Set root parameter, add data alias, and enable autoindex:

```
    server {
        listen       80;
        server_name  localhost;
        root         /usr/local/share/poudriere/html;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location /data {
            alias /tank/poudriere/data/logs/bulk;
            autoindex on;
        }
```

Save configuration then enable nginx service:

```
rc-update add nginx
```

Start nginx service:

```
service nginx start
```

Now you can access poudriere from http://127.0.0.1 in browser to monitor progress of base packages build.

## Install vm-bhyve

Install package for vm-bhyve
```
pkg install vm-bhyve
```

## Configure vm-bhyve
```
sysrc vm_enable="YES"
sysrc vm_dir="zfs:tank/usr/vms"
zfs set mountpoint=/usr/vms tank/usr/vms
vm init
rc-update add vm
```

Install firmware for UEFI
```
pkg-install bhyve-firmware
```

Create bridge for networking
```
vm switch create public
```

Add your ethernet adapter to brige (substitute igb0 for your adapter)

```
vm switch public add igb0
```

Note that ipfw must be stopped or bridge traffic must be allowed.  

## Build base packages
```
./01-build.packages.sh
```

## Build core image
```
./02-build-iso.sh
```

## Start VM with ISO and console for testing
```
./03-build-vm.sh
```

## Kill VM session from another terminal
```
killall cu
vm poweroff ghostbsd
```
