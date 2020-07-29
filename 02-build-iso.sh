#!/bin/sh

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Make sure we have /usr/src checked out first
if [ ! -f "/usr/src/sys/conf/package-version" ] ; then
  echo "Missing GhostBSD source in /usr/src"
  exit 1
fi

# Set our variables
CWD="`realpath | sed 's|/scripts||g'`"
PROJECT="GhostBSD"
EDITION="CORE"
PREFIX="/usr/local"
WORKSPACE_ROOT="${PREFIX}/ghostbsd-core"
PACKAGES_CACHE="${WORKSPACE_ROOT}/packages"
RELEASE="${WORKSPACE_ROOT}/release"
ISO9660_ROOT="${WORKSPACE_ROOT}/iso9660"
RAMDISK_ROOT="${ISO9660_ROOT}/data/ramdisk"
LABEL="GHOSTBSD"
VERSION=$(cat /usr/src/sys/conf/package-version)
IMAGES_DIR="${WORKSPACE_ROOT}/images"
ISO_FILE="${PROJECT}-${VERSION}-${EDITION}.iso"

# Define our functions

cleanup()
{
  # Cleanup previous release in workspace dir if needed
  if [ -d "${RELEASE}" ] ; then
    chflags -R noschg ${RELEASE}
    rm -rf ${RELEASE}
  fi
  # Cleanup previous cdroot in workspace dir if needed
  if [ -d "${ISO9660_ROOT}" ] ; then
    chflags -R noschg ${ISO9660_ROOT}
    rm -rf ${ISO9660_ROOT}
  fi
}

workspace()
{
  # Make the workspace root if needed
  if [ ! -d "${WORKSPACE_ROOT}" ] ; then
    mkdir -p ${WORKSPACE_ROOT}
  fi
  # Make the packages cache dir if needed
  if [ ! -d "${PACKAGES_CACHE}" ] ; then
    mkdir -p ${PACKAGES_CACHE}
  fi
  # Make the output dir for images if needed
  if [ ! -d "${IMAGES_DIR}" ] ; then
    mkdir -p ${IMAGES_DIR}
  fi
  # Make the release dir for installing base packages
  mkdir -p ${RELEASE}
  # Make the dir for building ISO image
  mkdir -p ${ISO9660_ROOT}
}

install_base_packages()
{
  mkdir -p ${RELEASE}/etc
  cp /etc/resolv.conf ${RELEASE}/etc/resolv.conf
  mkdir -p ${RELEASE}/var/cache/pkg
  mount_nullfs ${PACKAGES_CACHE} ${RELEASE}/var/cache/pkg
  pkg-static -r ${RELEASE} -R ${CWD}/pkg/ -C GhostBSD_PKG install -y -g os-generic-kernel os-generic-userland os-generic-userland-lib32 os-generic-userland-devtools
  rm ${RELEASE}/etc/resolv.conf
  umount ${RELEASE}/var/cache/pkg
}

services()
{
  chroot ${RELEASE} rc-update delete dumpon boot
  chroot ${RELEASE} rc-update delete savecore boot
  chroot ${RELEASE} rc-update --update
}

uzip()
{
  cp -R ${CWD}/overlays/core/ ${RELEASE}
  mkdir -p ${ISO9660_ROOT}/data
  makefs "${ISO9660_ROOT}/data/system.ufs" ${RELEASE}
  mkuzip -o "${ISO9660_ROOT}/data/system.uzip" "${ISO9660_ROOT}/data/system.ufs"
  rm -f "${ISO9660_ROOT}/data/system.ufs"
}

ramdisk()
{
  cp -R ${CWD}/overlays/ramdisk/ ${RAMDISK_ROOT}
  mkdir -p ${RAMDISK_ROOT}/dev
  cd "${RELEASE}" && tar -cf - rescue | tar -xf - -C "${RAMDISK_ROOT}"
  cp ${RELEASE}/etc/login.conf ${RAMDISK_ROOT}/etc/login.conf
  makefs -b '10%' "${ISO9660_ROOT}/data/ramdisk.ufs" "${RAMDISK_ROOT}"
  gzip "${ISO9660_ROOT}/data/ramdisk.ufs"
  rm -rf "${RAMDISK_ROOT}"
}

boot()
{
  cp -R ${CWD}/overlays/boot/ ${ISO9660_ROOT}
  cd "${RELEASE}" && tar -cf - --exclude boot/kernel boot | tar -xf - -C "${ISO9660_ROOT}"
  for kfile in kernel aesni.ko geom_eli.ko geom_uzip.ko nullfs.ko tmpfs.ko xz.ko; do
  tar -cf - boot/kernel/${kfile} | tar -xf - -C "${ISO9660_ROOT}"
  done
}

image()
{
  sh /usr/src/release/amd64/mkisoimages.sh -b ${LABEL} ${IMAGES_DIR}/${ISO_FILE} ${ISO9660_ROOT}
  echo "ISO 9660 image build complete for ${IMAGES_DIR}/${ISO_FILE}"
}

# Run our functions

cleanup
workspace
install_base_packages
services
uzip
ramdisk
boot
image
