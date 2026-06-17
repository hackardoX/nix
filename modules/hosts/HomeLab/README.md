# HomeLab - Mac Mini M1 (Asahi Linux)

## Disk Partitioning Notes

> **WARNING:** Damage to the GPT partition table, first partition (`iBootSystemContainer`), or the last partition (`RecoveryOSContainer`) could result in the loss of all data and render the Mac unbootable and unrecoverable without assistance from another computer.

### Prerequisites

This config assumes you've already run the Asahi Linux installer to create the free space and EFI partition following the [UEFI standalone guide](https://github.com/nix-community/nixos-apple-silicon/blob/main/docs/uefi-standalone.md).

### Manual Steps Before Running Disko

Before running disko, create the root partition manually to fill the free space:

```bash
sgdisk /dev/nvme0n1 -n 0:0 -s
```

Verify the partition layout:

```bash
sgdisk /dev/nvme0n1 -p
```

### WiFi Configuration

iwd is configured to auto-connect to your home network. Update `hostname.nix`:

1. Replace `YOUR_SSID` with your actual WiFi network name
2. Store the WiFi password in 1Password at `op://HomeLab/wifi password`

**Note:** WiFi works after boot. For initrd/LUKS unlock, use Ethernet (DHCP).

### Required Information for `disk.nix`

Before deploying, update `disk.nix` with the actual disk ID and partition UUIDs:

**1. Disk ID**
Run on the Mac Mini to find the actual NVMe device ID:
```bash
ls -l /dev/disk/by-id/
```
Update `disko.devices.disk.main.device` in `disk.nix` with the result (e.g., `/dev/disk/by-id/nvme-APPLE_SSD_AP1024Q_...`).

**2. Partition UUIDs**
Run one of the following to get each partition's UUID:
```bash
sgdisk /dev/nvme0n1 -p
# or
lsblk -o NAME,PARTUUID,LABEL,PARTLABEL
```
Update the `uuid` field for each partition in `disk.nix` (`iBootSystemContainer`, `Container`, `AsahiStub`, `ESP`, `RecoveryOSContainer`).

### What Disko Will Do

- Format the ESP as vfat and mount at `/boot`
- Format the LUKS partition with btrfs subvolumes (`/`, `/home`, `/nix`, `/swap`)

### What Disko Will NOT Touch

`destroy = false` is set, and all macOS partitions are declared in `disk.nix` to prevent accidental overwrites:

- `p1` - `iBootSystemContainer` (Apple firmware)
- `p2` - macOS Container (APFS)
- `p3` - Asahi stub partition
- `p6` - `RecoveryOSContainer` (Apple recovery)

### Required Information for `hardware-configuration.nix`

Before deploying, update `hardware-configuration.nix` with actual UUIDs:

**1. LUKS device UUID**
After creating the LUKS partition, get its UUID:
```bash
cryptsetup luksUUID /dev/nvme0n1p5
# or
lsblk -o NAME,UUID /dev/nvme0n1p5
```
Update `boot.initrd.luks.devices."crypted".device` in `hardware-configuration.nix`.

**2. ESP UUID**
```bash
blkid /dev/nvme0n1p4
```
Update `fileSystems."/boot".device` in `hardware-configuration.nix`.

### Peripheral Firmware

The Apple Silicon support module requires peripheral firmware files for WiFi/Bluetooth. Copy them from the EFI partition on the Mac Mini:

```bash
# From the Mac Mini (after Asahi Linux installation)
mkdir -p modules/hosts/HomeLab/firmware
cp /boot/asahi/all_firmware.tar.gz modules/hosts/HomeLab/firmware/
cp /boot/asahi/kernelcache* modules/hosts/HomeLab/firmware/
```

These files are referenced by `hardware.asahi.peripheralFirmwareDirectory = ./firmware;` in `hardware-configuration.nix`.
