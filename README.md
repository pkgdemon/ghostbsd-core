# ghostbsd-core
GhostBSD core ISO build

## Recommend System Requirements

* GhostBSD 20.04.1 or newer
* 128GB memory
* 48 cores
* 100GB of disk space

Lesser configurations should work but have not been tested

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

This scripts only for testing the core operating system for GhostBSD and for research puproses.

Build base packages
```
./01-build.packages.sh
```

Build core image
```
./02-build-iso.sh
```

Start VM with ISO and console for testing
```
./03-build-vm.sh
```

Kill VM session from another terminal
```
killall cu
```
