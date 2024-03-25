#!/bin/bash -eux

#
#if [[ $id == "debian" || $id == "ubuntu" || $id == "centos" || $id == "ol" ]]; then
#  echo "==> Clear out swap and disable until reboot"
#  set +e
#  swapuuid=$(blkid -o value -l -s UUID -t TYPE=swap)
#  case "$?" in
#      2|0) ;;
#      *) exit 1 ;;
#  esac
#  set -e
#  if [ "x${swapuuid}" != "x" ]; then
#      echo "==> Whiteout the swap partition to reduce box size"
#      # Swap is disabled till reboot
#      swappart=$(readlink -f /dev/disk/by-uuid/$swapuuid)
#      swapoff "${swappart}"
#      dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
#      mkswap -U "${swapuuid}" "${swappart}"
#  fi
#
#fi
#
## Zero out the free space to save space in the final image
#if [ -d /boot/efi ]; then
#  echo "==> Clearing /boot/efi"
#  dd if=/dev/zero of=/boot/efi/EMPTY bs=1M || echo "dd exit code $? is suppressed"
#  rm -f /boot/efi/EMPTY
#fi
#
#echo "==> Clearing /"
#dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
#rm -f /EMPTY
#
## Add `sync` so Packer doesn't quit too early, before the large file is deleted.
#sync
#
#echo "==> Disk usage after cleanup"
#df -h

## ref: https://superuser.com/questions/1490371/error-writing-wipefile-no-space-left-on-device
echo "==> Zero out the free space to save space in the final image:"
dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
rm -f /EMPTY

echo "==> Sync to ensure that the delete completes before this moves on."
sync
sync
sync

echo "==> Disk usage after cleanup"
df -h
