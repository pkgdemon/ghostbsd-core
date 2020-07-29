#!/bin/sh

# Make sure we have /usr/src checked out first
if [ ! -f "/usr/src/sys/conf/package-version" ] ; then
  echo "Missing GhostBSD source in /usr/src"
  exit 1
fi

CWD="`realpath | sed 's|/scripts||g'`"

echo "==> Checking for GhostBSD VM"
if [ -e "dev/vmm/ghostbsd" ] ; then
  echo "GhostBSD VM running will be shut down"
fi
while : ; do
    [ ! -e "/dev/vmm/ghostbsd" ] && echo "==> /dev/vmm/ghostbsd has been powered off" && break
    sleep 1
    yes | vm poweroff ghostbsd || true
    bhyvectl --destroy --vm=ghostbsd || true
    killall bhyve
done
echo "==> Checking for locks"
if [ -f "/usr/vms/ghostbsd/run.lock" ] ; then
  echo "Lock found will be removed"
fi
while : ; do
    [ ! -f "/usr/vms/ghostbsd/run.lock" ] && echo "==> /usr/vms/ghostbsd/run.lock has been removed" && break
    sleep 1
    rm /usr/vms/ghostbsd/run.lock
done
killall cu
cp ${CWD}/ghostbsd.conf /usr/vms/.templates/
yes | vm destroy ghostbsd || true
vm create -t ghostbsd ghostbsd
vm iso /usr/local/ghostbsd-core/images/GhostBSD-20.07.14-CORE.iso
sleep 2
vm install ghostbsd GhostBSD-20.07.14-CORE.iso
echo "==> Waiting for GHOSTBSD VM to initialize"
while : ; do
    [ -e "/dev/vmm/ghostbsd" ] && echo "==> Found /dev/vmm/ghostbsd" && break
    sleep 1
done
echo "==> Waiting for console devices"
while : ; do
    [ -e "/dev/nmdm-ghostbsd.1A" ] && echo "==> /dev/nmdm-ghostbsd.1A has been found" && break
    sleep 1
done
while : ; do
    [ -e "/dev/nmdm-ghostbsd.1B" ] && echo "==> /dev/nmdm-ghostbsd.1B has been found" && break
    sleep 1
done
stty -raw -echo
tput clear
vm console ghostbsd
