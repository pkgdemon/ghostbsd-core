#!/bin/sh

# Make sure we have /usr/src checked out first
if [ ! -f "/usr/src/sys/conf/package-version" ] ; then
  echo "Missing GhostBSD source in /usr/src"
  exit 1
fi

killall cu
yes | vm poweroff ghostbsd || true
vm iso /usr/local/ghostbsd-core/images/GhostBSD-20.07.14-CORE.iso
vm install ghostbsd GhostBSD-20.07.14-CORE.iso
echo "==> Waiting for GHOSTBSD VM to initialize"
while : ; do
    [ -e "/dev/vmm/ghostbsd" ] && echo "==> Found /dev/vmm/ghostbsd" && break
    sleep 1
done
stty -raw -echo
tput clear
vm console ghostbsd
