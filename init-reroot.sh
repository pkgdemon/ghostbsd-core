#!/bin/sh

PATH="/rescue"
kenv init_shell="/bin/sh" >/dev/null 2>/dev/null

if [ ! -d "/memdisk" ] ; then
  mount -uw /
  mdconfig -du md0
  mdconfig -du md1
  rm /init-reroot.sh
fi

exit 0
