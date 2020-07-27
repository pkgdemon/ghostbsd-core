#!/rescue/sh

PATH="/rescue"

if [ "`ps -o command 1 | tail -n 1 | ( read c o; echo ${o} )`" = "-s" ]; then
	echo "==> Running in single-user mode"
	SINGLE_USER="true"
fi

echo "==> Remount rootfs as read-write"
mount -u -w /

echo "==> Make mountpoints"
mkdir -p /cdrom /usr/dists /memdisk /mnt /sysroot /usr /tmp

echo "==> Waiting for GHOSTBSD media to initialize"
while : ; do
    [ -e "/dev/iso9660/GHOSTBSD" ] && echo "==> Found /dev/iso9660/GHOSTBSD" && break
    sleep 1
done

echo "==> Mount cdrom"
mount_cd9660 /dev/iso9660/GHOSTBSD /cdrom

if [ -f "/cdrom/data/system.uzip" ] ; then
  mdmfs -P -F /cdrom/data/system.uzip -o ro md.uzip /sysroot
fi

# Make room for backup in /tmp
mount -t tmpfs tmpfs /tmp

echo "==> Create and mount swap-based memdisk"
mdmfs -s 2048m md /memdisk || exit 1

echo "==> Cloning GhostBSD to memdisk"
if [ -d "/sysroot" ] ; then
  dump -0f - /dev/md1.uzip | (cd /memdisk; restore -rf -)
  rm /memdisk/restoresymtable
  cp /etc/fstab /memdisk
  cp /init-reroot.sh /memdisk
  kenv vfs.root.mountfrom=ufs:/dev/md2
  kenv init_script="/init-reroot.sh"
fi

echo "==> Rerooting into memdisk"

if [ "$SINGLE_USER" = "true" ]; then
	echo "Starting interactive shell in temporary rootfs ..."
	exit 0
fi

kenv init_shell="/rescue/sh"
exit 0
