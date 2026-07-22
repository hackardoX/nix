0. sudo su
0. iwctl
station wlan0 scan
station wlan0 connect <SSID>
station wlan0 show
exit 
0. nix-shell -p git --run 'git clone -b asahi https://github.com/hackardoX/nix.git /root/nix
0. cd /root/nix
mkdir -p /root/nix/modules/hosts/HomeLab/firmware
0. mkdir -p /mnt/esp
mount /dev/disk/by-partuuid/e862caa4-cb82-4d97-94ce-c9e77a74ef83 /mnt/esp
cp /mnt/esp/asahi/all_firmware.tar.gz /mnt/esp/asahi/kernelcache* /root/nix/modules/hosts/HomeLab/firmware/
umount /mnt/esp
ls -la modules/hosts/HomeLab/firmware/
0. lsblk -o NAME,SIZE,FSTYPE,LABEL /dev/nvme0n1
sgdisk -d 5 /dev/nvme0n1
lsblk -o NAME,SIZE,FSTYPE,LABEL /dev/nvme0n1
0. wipefs -a /dev/nvme0n1p5
dd if=/dev/urandom of=/tmp/secret.key bs=512 count=8
nix-shell -p wget --run "wget 192.168.1.41:8000/opnix-token" && mv ./opnix-token /etc/
nix-shell -p wget --run "wget 192.168.1.41:8000/" && mv ./secret.key /tmp/secret.key
0. nix run github:nix-community/disko -- --mode disko --flake .#HomeLab
lsblk -o NAME,SIZE,FSTYPE,LABEL /dev/nvme0n1
0. mkdir -p /mnt/etc/secrets/initrd
export OP_SERVICE_ACCOUNT_TOKEN=$(cat /etc/opnix-token)
export NIXPKGS_ALLOW_UNFREE=1
nix-shell -p _1password-cli --run "op read 'op://HomeLab/Initrd Luks/private key' > /mnt/etc/secrets/initrd/ssh_host_ed25519_key && op read 'op://HomeLab/Initrd Luks/public key' > /mnt/etc/secrets/initrd/ssh_host_ed25519_key.pub"
chmod 600 /mnt/etc/secrets/initrd/ssh_host_ed25519_key
chmod 644 /mnt/etc/secrets/initrd/ssh_host_ed25519_key.pub"
0. mount /dev/mapper/crypted /mnt/btrfs-root -o subvolid=5
btrfs subvolume snapshot /mnt/btrfs-root/root /mnt/btrfs-root/root-blank
umount /mnt/btrfs-root
0. export NIX_CONFIG="experimental-features = nix-command flakes pipe-operators"
nixos-install --flake /root/nix#HomeLab --no-root-passwd
0. nixos-enter --root /mnt -c 'passwd root'
0. umount -R /mnt
swapoff -a
reboot
0. nmcli device wifi connect "YourSSID" password "YourPassword"
