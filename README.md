# WAW OS — World At War Operating System
### Powered by Brainfuck™ · No Survivors

---

## What is this?

A bootable ISO of WAW OS — a fully functional operating system whose only feature
is crashing whenever you do anything. Mouse move? Crash. Click? Crash. Press a key?
Court-martialed and crashed.

Built on:
- GRUB2 bootloader
- Minimal Debian Linux kernel + initramfs
- Chromium in kiosk mode running the WAW OS HTML interface
- A Brainfuck™ crash subsystem (simulated, for legal reasons)

---

## Requirements (Ubuntu / Debian / WSL2)

```bash
sudo apt-get update
sudo apt-get install -y \
  xorriso \
  grub-pc-bin \
  grub-efi-amd64-bin \
  wget \
  debootstrap \
  mtools
```

---

## Build

```bash
chmod +x build.sh
sudo ./build.sh
```

Build time: ~5–15 minutes depending on your internet speed (downloads Debian packages).
Output: `wawos.iso`

---

## Run in a VM

### VirtualBox
1. New VM → Name: WAW OS, Type: Linux, Version: Other Linux (64-bit)
2. RAM: 1024 MB minimum (2048 recommended for Chromium)
3. No hard disk needed
4. Settings → Storage → Add optical drive → select `wawos.iso`
5. Boot

### VMware
1. New VM → Custom
2. Guest OS: Linux → Other Linux 5.x kernel 64-bit
3. RAM: 1024 MB
4. No disk → Use ISO image: `wawos.iso`
5. Boot

### QEMU (fastest)
```bash
qemu-system-x86_64 \
  -cdrom wawos.iso \
  -m 1G \
  -vga std \
  -display gtk \
  -boot d
```

---

## Boot Sequence

```
WAW OS v1.0 — World At War Operating System
Powered by Brainfuck™ Kernel

[ OK ] Loading brainfuck interpreter...
[ OK ] Mounting tape drive at /dev/null...
[ OK ] Initializing crash subsystem...
[ OK ] Starting instability daemon...
[ OK ] Arming self-destruct on all user inputs...
[ !! ] Stability module: NOT FOUND (expected)

Welcome to WAW OS. No survivors. _
```

---

## Things That Crash It

| Action | Crash Reason |
|--------|-------------|
| Move mouse | "Mouse advanced N pixels into enemy territory" |
| Click any icon | Each has a unique death message |
| Press any key | "The keyboard has been court-martialed" |
| Right-click | "Friendly fire incident. Court martial pending." |
| Double-click | "WAW OS can only process single inputs. It cannot process those either." |
| Click Reboot | "Reinforcements arrived. They also ran on Brainfuck. They also crashed." |
| Wait long enough | Random clock tick causes "time-based paradox in the Brainfuck scheduler" |

---

## Troubleshooting

**Build fails on debootstrap:** Make sure you have internet access and run as root.

**VM shows black screen:** Give it 30–60 seconds — Chromium takes time to start.

**No graphics / text mode only:** WAW OS falls back to a text-mode crash terminal.
Type anything at the `WAW>` prompt. It will crash. This is correct behavior.

**"Stability module: NOT FOUND"**: This is expected. It was never found.

---

*WAW OS is not responsible for any data loss, existential dread, or appreciation
for operating systems that don't crash when you move the mouse.*
