#!/bin/bash

#BOOT_DISK=$(df -h | grep /boot | awk '{print $1}')

mount /dev/vda /mnt && mount --bind /proc /mnt/proc/ && mount --bind /dev /mnt/dev&& mount --bind /sys /mnt/sys && chroot /mnt /bin/bash -l
sed -i 's/GRUB_ENABLE_BLSCFG.*/GRUB_ENABLE_BLSCFG=false/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
cd / && umount /mnt/proc && umount /mnt/dev && umount /mnt/sys && umount /mnt
