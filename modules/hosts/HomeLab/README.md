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
- Format the root partition as ext4 and mount at `/`

### What Disko Will NOT Touch

`destroy = false` is set, and all macOS partitions are declared in `disk.nix` to prevent accidental overwrites:

- `p1` - `iBootSystemContainer` (Apple firmware)
- `p2` - macOS Container (APFS)
- `p3` - Asahi stub partition
- `p6` - `RecoveryOSContainer` (Apple recovery)
