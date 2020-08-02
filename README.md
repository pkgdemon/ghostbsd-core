# ghostbsd-core
GhostBSD core ISO build

These scripts will assemble the core operating system of GhostBSD for research, testing, and development purposes.  The first script will build base packages.  The second script will assemble a hybrid ISO that will boot with full read write support by rerooting into a memory filesystem after GhostBSD is cloned to it.  The third script will boot the ISO in a bhyve VM for quicker testing, and development purposes.  

## Recommend System Requirements for building base packages

* GhostBSD 20.07.14 or newer
* 32GB memory
* 8 cores
* 50GB of disk space
* C Compiler
* Git
* GhostBSD src in /usr/src
* GhostBSD ports in /usr/ports
* Poudriere with one time manual configuration required

## System Requirements for VM testing

* GhostBSD 20.07.14 or newer
* 2GB memory for VM
* 2 cores for VM
* vm-bhyve with one time manual configuration required

Lesser configurations should work but have not been tested.

## Install C compliler
```
    pkg install os-generic-userland-devtools
```
## Install Git
```
    pkg install git
```
## Install GhostBSD kernel source
```
    git clone https://github.com/ghostbsd/ghostbsd.git /usr/src
```
## Install GhostBSD Ports
```
    git clone https://github.com/ghostbsd/ghostbsd-ports.git /usr/ports/
```
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
ZPOOL=tank
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
edit /usr/local/etc/nginx/nginx.conf
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
pkg install bhyve-firmware
```

Create bridge for networking
```
vm switch create public
```

Add your ethernet adapter to brige (substitute igb0 for your adapter)

```
vm switch add public igb0
```

Note that ipfw must be stopped if it is enabled, or bridge traffic must be allowed for networking to function (not covered here).  

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
