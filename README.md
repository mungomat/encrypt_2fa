# encrypt_2fa
`encrypt_2fa` is an initramfs-hook for ArchLinux which provides a two factor authorization for decrypting a LUKS encrypted root partition.
At boot time the user has to insert a USB drive with a secret key as well as enter a password. This increases security for the system. In a way `encrypt_2fa` just combines the kernel options `cryptdevice` and `cryptkey`.

## Prerequisites
The starting point is an ArchLinux system with an encrypted LUKS root file system. A good tutorial video can be found at ['youtube - Archlinux encrypted install - theft proof laptop install'](https://www.youtube.com/watch?v=rT7h62OYQv8).

For a fresh automatic ArchLinux installation on an EFI system the scripts from `install_archlinux/` can be used:
- Boot from an ArchLinux Boot-Cd
  - Start the ssh daemon: `systemctl start sshd`
  - Enter a installation root-password: `echo "root:install" | chpasswd`
  - Get the systems ip-address: `ip address`
- Now the script can be started remotely:
  - Change directory: `cd install_archlinux`
  - Run the installation-script: `./install.sh <ip-of-system-archlinux-has-to-be-installed> <partition to install ArchLinux to>`
  - ssh-password is `install` (2x)
  - Enter `YES` to confirm encryption of the root partition
  - Enter a temporary LUKS password (2x) to install and 1x to to open the encrypted file system - We will change authorization of the LUKS partition later
  - Reboot to your new ArchLinux: `ssh root@<same-ip-as-before> reboot`
  - During reboot you have to enter the temporary LUKS password

## !!! WARNING !!!
**Make sure you have a backup of your system. Otherwise a wrong configuration can lead to an unresponsive system where all your data is lost.**

## Installation
1. Install `encrypt_2fa`:
- Copy the hook: `sudo cp -r initcpio/* /etc/initcpio/`
- Rename `encrypt` to `encrypt_2fa` in the `HOOKS`-line in file `/etc/mkinitcpio.conf`: `HOOKS=(base udev autodetect modconf block filesystems keyboard fsck encrypt_2fa)`
- If there is a fat-partition on the USB-drive, change the `modules`-line in `/etc/mkinitcpio.conf`: ` MODULES=(vfat)`
- Update the initramfs: `mkinitcpio -p linux`

2. Create Keyfiles
- Create any secret file `secret.key`. For example: `pwgen -s 50 1 > secret.key`
- Copy `secret.key` to your USB drive
- Create the LUKS-2fa-code from `secret.key` and your LUKS-Password: `echo "enter password"; read -s password; (cat secret.key; echo "$password") > /tmp/lukfs_2fa.key`

3. Make LUKS accept the LUKS-2fa-code
- To figure out your LUKS-device see the partition start `lsblk`. It is the device right above the line containing `cryptroot`
- List keyslots in your LUKS device: `cryptsetup luksDump /dev/nvme0n1p2`
- Add the LUKS-2fa-code to a new keyslot - entering the temporary LUKS password: `cryptsetup luksAddKey /dev/nvme0n1p2 /tmp/lukfs_2fa.key`
- See a new Keyslot has been added: `cryptsetup luksDump /dev/nvme0n1p2`

4. Tell the Bootload the location of the keyfile.
- See the uuid of the root-filesystem: `lsblk -b -l -p -n -o NAME,TYPE,UUID`
- Add the `crypt2fa`-option in `/boot/loader/entries/arch.conf`: `options cryptdevice=UUID=...:cryptroot crypt2fa=UUID=<uuid-of-usb-partition>:vfat:secret.key root=/dev/mapper/cryptroot rw` (adjust uuid, device, filesystem and my_keyfile to your needs)
- `mkinitcpio -p linux`
- reboot and test

5. Remove old password from LUKS:
- Optional: Add a single very long Password to LUKS. Keep this password at a secret place: `pwgen -s 50 1; cryptsetup luksAddKey /dev/nvme0n1p2`
- Remove old password: `cryptsetup luksRemoveKey /dev/nvme0n1p2` and enter the temporary (old) LUKS password

