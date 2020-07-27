#!/bin/sh

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Set our variables
CWD="`realpath | sed 's|/scripts||g'`"
PREFIX="/usr/local"
WORKSPACE_ROOT="${PREFIX}/ghostbsd-core"
BASE_PACKAGES_CACHE="${WORKSPACE_ROOT}/base_packages"
RELEASE="${WORKSPACE_ROOT}/release"
CD_ROOT="${WORKSPACE_ROOT}/cdroot"
RAMDISK_ROOT="${CD_ROOT}/data/ramdisk"
LABEL="GHOSTBSD"
ISO_DIR="${WORKSPACE_ROOT}/iso"
ISO_PATH="${ISO_DIR}/GhostBSD-20.07-CORE.iso"

# Define our functions

cleanup()
{
  # Cleanup previous release in workspace dir if needed
  if [ -d "${RELEASE}" ] ; then
    chflags -R noschg 	${RELEASE}
    rm -rf ${RELEASE}
  fi
  # Cleanup previous cdroot in workspace dir if needed
  if [ -d "${CD_ROOT}" ] ; then
    chflags -R noschg ${CD_ROOT}
    rm -rf ${CD_ROOT}
  fi
  # Cleanup previous iso in workspace dir if needed
  if [ -d "${ISO_DIR}" ] ; then
    rm -rf ${ISO_DIR}
  fi
}

workspace()
{
  # Make the workspace root if needed
  if [ ! -d "${WORKSPACE_ROOT}" ] ; then
    mkdir -p ${WORKSPACE_ROOT}
  fi
  # Make the base packages cache dir if needed
  if [ ! -d "${BASE_PACKAGES_CACHE}" ] ; then
    mkdir -p ${BASE_PACKAGES_CACHE}
  fi
  # Make the release dir for installing base packages
  mkdir -p ${RELEASE}
  # Make the dir for building ISO image
  mkdir -p ${CD_ROOT}
  # Make the output dir for ISO image
  mkdir -p ${ISO_DIR}
}

install_base_packages()
{
  mkdir -p ${RELEASE}/etc
  cp /etc/resolv.conf ${RELEASE}/etc/resolv.conf
  mkdir -p ${RELEASE}/var/cache/pkg
  mount_nullfs ${BASE_PACKAGES_CACHE} ${RELEASE}/var/cache/pkg
  pkg-static -r ${RELEASE} -R ${CWD}/pkg/ -C GhostBSD_PKG install -y -g os-generic-kernel os-generic-userland os-generic-userland-lib32 os-generic-userland-devtools

  rm ${RELEASE}/etc/resolv.conf
  umount ${RELEASE}/var/cache/pkg
}

uzip()
{
  cp -R ${CWD}/overlays/core/ ${RELEASE}
  mkdir -p ${CD_ROOT}/data
  makefs "${CD_ROOT}/data/system.ufs" ${RELEASE}
  mkuzip -o "${CD_ROOT}/data/system.uzip" "${CD_ROOT}/data/system.ufs"
  rm -f "${CD_ROOT}/data/system.ufs"
}

ramdisk()
{
  cp -R ${CWD}/overlays/ramdisk/ ${RAMDISK_ROOT}
  mkdir -p ${RAMDISK_ROOT}/dev
  cd "${RELEASE}" && tar -cf - rescue | tar -xf - -C "${RAMDISK_ROOT}"
  cp ${CWD}/fstab ${RAMDISK_ROOT}/etc
  cp ${CWD}/init-reroot.sh ${RAMDISK_ROOT}/init-reroot.sh
  cp ${RELEASE}/etc/login.conf ${RAMDISK_ROOT}/etc/login.conf
  makefs -b '10%' "${CD_ROOT}/data/ramdisk.ufs" "${RAMDISK_ROOT}"
  gzip "${CD_ROOT}/data/ramdisk.ufs"
  rm -rf "${RAMDISK_ROOT}"
}

boot()
{
  cp -R ${CWD}/overlays/boot/ ${CD_ROOT}
  cd "${RELEASE}" && tar -cf - --exclude boot/kernel boot | tar -xf - -C "${CD_ROOT}"
  for kfile in kernel aesni.ko geom_eli.ko geom_uzip.ko nullfs.ko tmpfs.ko xz.ko; do
  tar -cf - boot/kernel/${kfile} | tar -xf - -C "${CD_ROOT}"
  done
}

image()
{
  sh /usr/src/release/amd64/mkisoimages.sh -b ${LABEL} ${ISO_PATH} ${CD_ROOT}
}

# Run our functions

cleanup
workspace
install_base_packages
uzip
ramdisk
boot
image
