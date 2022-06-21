## step_1:  new dir/folder
sudo mkdir /home/myname/pan1

## step_2:  check unmount disk
fdisk -l

## step_3:  check disk format and get UUID
sudo blkid /dev/sdb1

## step_4: key step for mount permanently
sudo gedit /etc/fstab

UUID=9E5ED2D65ED2A5F5  /home/myname/pan1 ext4  defaults 0  1

