#!/bin/sh

# Make sure we have /usr/src checked out first
if [ ! -f "/usr/src/sys/conf/package-version" ] ; then
  echo "Missing GhostBSD source in /usr/src"
  exit 1
fi

cd /usr/src && make clean || true
cd /usr/src && make buildkernel -j $(sysctl -n hw.ncpu)
cd /usr/src && make buildworld -j $(sysctl -n hw.ncpu)
yes | poudriere jail -d -j ghostbsd-12 || true
poudriere jail -c -j ghostbsd-12 -K GENERIC -m src=/usr/src/
rm -rf /tank/poudriere/data/ || true
poudriere bulk -j ghostbsd-12 -p ghostbsd-ports -f /root/ghostbsd-pkglist
