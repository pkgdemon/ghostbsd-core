#!/rescue/sh

PATH="/rescue"

if [ "`ps -o command 1 | tail -n 1 | ( read c o; echo ${o} )`" = "-s" ]; then
	echo "==> Running in single-user mode"
	SINGLE_USER="true"
fi

echo "==> Waiting for GHOSTBSD media to initialize"
while : ; do
    [ -e "/dev/iso9660/GHOSTBSD" ] && echo "==> Found /dev/iso9660/GHOSTBSD" && break
    sleep 1
done

echo "==> Remount rootfs as read-write"
mount -u -w /

echo "==> Make mountpoints for cloning"
mkdir -p /cdrom /memdisk /sysroot /tmp

echo "==> Mount cdrom for cloning"
mount_cd9660 /dev/iso9660/GHOSTBSD /cdrom

echo "==> Mount tmpfs for cloning"
mount -t tmpfs tmpfs /tmp

echo "==> Mount /cdrom/system.uzip to /sysroot to get /dev/md1.uzip for cloning"
mdmfs -P -F /cdrom/data/system.uzip -o ro md.uzip /sysroot

echo "==> Waiting for /dev/md1.uzip to initialize"
while : ; do
    [ -e "/dev/md1.uzip" ] && echo "==> Found /dev/md1.uzip" && break
    sleep 1
done

echo "==> Create and mount swap-based /dev/md2 at /memdisk for cloning"
mdmfs -s 2048m md /memdisk || exit 1

echo "==> Cloning /dev/md1.uzip to /memdisk with dump | restore"
dump -0f - /dev/md1.uzip | (cd /memdisk; restore -rf -)
rm /memdisk/restoresymtable

if [ "$SINGLE_USER" = "true" ]; then
	echo "Starting interactive shell in temporary rootfs ..."
	exit 0
fi

echo "==> Exit to /etc/rc for reroot"
kenv init_shell="/rescue/sh"
exit 0
