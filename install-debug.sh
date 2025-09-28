#!/bin/bash
set -e

echo "--- Arch Linux Minimal Installer ---"

# --- Manuelle Eingabe ---
read -p "Root-Partition (z. B. /dev/sda2): " ROOT_PART
read -p "EFI-Partition (z. B. /dev/sda1): " EFI_PART
read -p "Home-Partition (z. B. /dev/sda3): " HOME_PART
read -p "Mountpunkt (Standard: /mnt): " MOUNTPOINT
MOUNTPOINT=${MOUNTPOINT:-/mnt}

# --- Mounten ---
echo "[1] Mount root partition: $ROOT_PART"
mount "$ROOT_PART" "$MOUNTPOINT"

echo "[2] Mount EFI partition: $EFI_PART"
mount "$EFI_PART" "$MOUNTPOINT/boot"

echo "[3] Mount home partition: $HOME_PART"
mount "$HOME_PART" "$MOUNTPOINT/home"

# --- Basisinstallation ---
echo "[4]d Installiere Basis-System"
pacstrap "$MOUNTPOINT" base base-devel linux linux-firmware dhcpcd nano iwd

# --- fstab generieren ---
echo "[5] Generiere fstab"
genfstab -U "$MOUNTPOINT" >> "$MOUNTPOINT/etc/fstab"

# --- Konfiguration im chroot ---
echo "[6] Konfiguriere System im chroot"
arch-chroot "$MOUNTPOINT" /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/Europe/Vienna /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname
echo "LANG=en_US.UTF-8" > /etc/locale.conf
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
mkinitcpio -P
bootctl install
cat <<BOOT > /boot/loader/entries/arch-uefi.conf
title	Arch Linux
linux	/vmlinuz-linux
initrd	/initramfs-linux.img
options	root=UUID=$(blkid -s UUID -o value $ROOT_PART) rw lang=en init=/usr/lib/systemd/systemd locale=en_US.UTF-8
BOOT
cat <<BOOT > /boot/loader/entries/arch-uefi-fallback.conf
title	Arch Linux Fallback
linux	/vmlinuz-linux-fallback
initrd	/initramfs-linux-fallback.img
options	root=UUID=$(blkid -s UUID -o value $ROOT_PART) rw lang=en init=/usr/lib/systemd/systemd locale=en_US.UTF-8
BOOT
passwd << root
root
EOF


# --- Abschluss ---
echo "[6] Unmount und Neustart"
# umount -R "$MOUNTPOINT"
echo "Installation abgeschlossen. Manuell unmounten."
