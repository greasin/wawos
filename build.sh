#!/bin/bash
# =============================================================
#  WAW OS - World At War Operating System - ISO Builder
#  Powered by Brainfuck(tm) - No survivors
# =============================================================
# REQUIREMENTS (Ubuntu/Debian/WSL):
#   sudo apt-get install -y grub-pc-bin grub-efi-amd64-bin \
#     xorriso squashfs-tools wget debootstrap
#
# USAGE:
#   chmod +x build.sh
#   sudo ./build.sh
#
# OUTPUT: wawos.iso  (~50-200MB depending on method)
# =============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
ISO_DIR="$BUILD_DIR/iso"
OUTPUT="$SCRIPT_DIR/wawos.iso"

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
NC='\033[0m'

log()  { echo -e "${YEL}[WAW]${NC} $1"; }
ok()   { echo -e "${GRN}[ OK]${NC} $1"; }
die()  { echo -e "${RED}[KIA]${NC} $1"; exit 1; }

echo ""
echo -e "${YEL}"
echo "  ██╗    ██╗ █████╗ ██╗    ██╗     ██████╗ ███████╗"
echo "  ██║    ██║██╔══██╗██║    ██║    ██╔═══██╗██╔════╝"
echo "  ██║ █╗ ██║███████║██║ █╗ ██║    ██║   ██║███████╗"
echo "  ██║███╗██║██╔══██║██║███╗██║    ██║   ██║╚════██║"
echo "  ╚███╔███╔╝██║  ██║╚███╔███╔╝    ╚██████╔╝███████║"
echo "   ╚══╝╚══╝ ╚═╝  ╚═╝ ╚══╝╚══╝      ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo "  World At War OS - ISO Builder"
echo "  Powered by Brainfuck(tm) - No survivors"
echo ""

# Check root
[ "$EUID" -eq 0 ] || die "Run as root (sudo ./build.sh)"

# Check dependencies
for cmd in xorriso grub-mkrescue wget debootstrap; do
    command -v $cmd >/dev/null 2>&1 || die "Missing: $cmd  →  sudo apt-get install xorriso grub-pc-bin grub-efi-amd64-bin wget debootstrap"
done

log "Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$ISO_DIR/boot/grub" "$ISO_DIR/wawos"

# ── Step 1: Copy WAW OS files ──────────────────────────────
log "Deploying WAW OS assets..."
cp "$SCRIPT_DIR/iso_root/wawos/index.html" "$ISO_DIR/wawos/"
cp "$SCRIPT_DIR/iso_root/boot/grub/grub.cfg" "$ISO_DIR/boot/grub/"
ok "WAW OS HTML deployed"

# ── Step 2: Build minimal initramfs with debootstrap ──────
log "Building minimal root filesystem (this takes a few minutes)..."
ROOTFS="$BUILD_DIR/rootfs"
mkdir -p "$ROOTFS"

# Use a tiny debootstrap with just the essentials
debootstrap --variant=minbase --include=\
busybox-static,\
xorg,\
xinit,\
chromium,\
openbox,\
xdotool \
bookworm "$ROOTFS" http://deb.debian.org/debian/ 2>&1 | tail -5 || {

    log "Full debootstrap failed, trying minimal fallback..."
    debootstrap --variant=minbase bookworm "$ROOTFS" http://deb.debian.org/debian/ 2>&1 | tail -5
}
ok "Root filesystem built"

# ── Step 3: Install WAW OS init ───────────────────────────
log "Installing WAW OS init system..."
cp "$SCRIPT_DIR/scripts/init" "$ROOTFS/init"
chmod +x "$ROOTFS/init"

# Write xsession for auto-launch
mkdir -p "$ROOTFS/etc"
cat > "$ROOTFS/etc/xsession" << 'EOF'
#!/bin/sh
chromium --kiosk --no-sandbox --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-translate \
  --no-first-run \
  --app=file:///tmp/www/index.html
EOF
chmod +x "$ROOTFS/etc/xsession"

# Auto-login and start X
cat > "$ROOTFS/etc/inittab" << 'EOF'
::sysinit:/init
::respawn:/bin/sh /etc/rc.local
EOF

cat > "$ROOTFS/etc/rc.local" << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null
echo 0 > /proc/sys/kernel/printk 2>/dev/null
mkdir -p /media/cdrom /tmp/www
mount -o ro /dev/sr0 /media/cdrom 2>/dev/null || true
[ -f /media/cdrom/wawos/index.html ] && cp /media/cdrom/wawos/index.html /tmp/www/index.html
cd /tmp/www
export HOME=/root
export DISPLAY=:0
Xorg :0 -nolisten tcp -nocursor vt1 &
sleep 3
chromium --kiosk --no-sandbox --disable-infobars \
  --no-first-run --disable-translate \
  --app=file:///tmp/www/index.html &
wait
EOF
chmod +x "$ROOTFS/etc/rc.local"
ok "Init system installed"

# ── Step 4: Pack initramfs ────────────────────────────────
log "Packing initramfs..."
cd "$ROOTFS"
find . | cpio -H newc -o 2>/dev/null | gzip -9 > "$ISO_DIR/boot/initrd.img"
ok "initramfs packed: $(du -sh "$ISO_DIR/boot/initrd.img" | cut -f1)"

# ── Step 5: Grab a kernel ─────────────────────────────────
log "Extracting kernel from rootfs..."
VMLINUZ=$(find "$ROOTFS/boot" -name "vmlinuz*" | head -1)
if [ -n "$VMLINUZ" ]; then
    cp "$VMLINUZ" "$ISO_DIR/boot/vmlinuz"
    ok "Kernel copied: $(basename $VMLINUZ)"
else
    die "No kernel found in rootfs. Install linux-image-amd64 manually."
fi

# ── Step 6: Build ISO ─────────────────────────────────────
log "Building bootable ISO with GRUB..."
grub-mkrescue -o "$OUTPUT" "$ISO_DIR" \
    --compress=xz \
    -- -volid "WAWOS" 2>&1 | tail -3

ok "ISO built: $OUTPUT"
echo ""
echo -e "${YEL}┌─────────────────────────────────────────────┐${NC}"
echo -e "${YEL}│         WAW OS ISO BUILD COMPLETE           │${NC}"
echo -e "${YEL}│                                             │${NC}"
printf  "${YEL}│  File: %-36s│${NC}\n" "$(basename $OUTPUT)"
printf  "${YEL}│  Size: %-36s│${NC}\n" "$(du -sh "$OUTPUT" | cut -f1)"
echo -e "${YEL}│                                             │${NC}"
echo -e "${YEL}│  Load in VirtualBox / VMware / QEMU:        │${NC}"
echo -e "${YEL}│  - New VM → Other Linux 64-bit              │${NC}"
echo -e "${YEL}│  - 512MB RAM minimum                        │${NC}"
echo -e "${YEL}│  - Attach wawos.iso as optical drive        │${NC}"
echo -e "${YEL}│  - Boot → enjoy the crashes                 │${NC}"
echo -e "${YEL}│                                             │${NC}"
echo -e "${YEL}│  QEMU one-liner:                            │${NC}"
echo -e "${YEL}│  qemu-system-x86_64 -cdrom wawos.iso -m 1G │${NC}"
echo -e "${YEL}└─────────────────────────────────────────────┘${NC}"
echo ""
