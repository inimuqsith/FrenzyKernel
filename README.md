# ⚡ FrenzyKernel

<div align="center">

![Linux](https://img.shields.io/badge/Kernel-Linux%205.10%20GKI-blue?style=for-the-badge&logo=linux)
![Standard](https://img.shields.io/badge/Architecture-Android%20GKI%205.10-success?style=for-the-badge&logo=android)
![Target](https://img.shields.io/badge/Tested%20On-Tecno%20Pova%204%20Pro-orange?style=for-the-badge&logo=android)
![Arch](https://img.shields.io/badge/Arch-AArch64%20(ARM64)-red?style=for-the-badge)
![License](https://img.shields.io/badge/License-GPL--2.0-yellow?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active%20%7C%20Production%20Ready-brightgreen?style=for-the-badge)

**High-Performance Android Generic Kernel Image (GKI 5.10) & Headless Server Engine**  
*A pure Android Generic Kernel Image (Linux 5.10 GKI) engineered for 24/7 Linux Server Hosting (Droidspaces LXC), Gaming Emulation, Hardware Shielding, and Enterprise-Grade Stability. Tested on Tecno Pova 4 Pro.*

[Overview](#-overview) •
[Core Pillars](#-core-pillars) •
[FrenzyServer WebUI & Engine](#-frenzyserver-engine--webui) •
[Building](#-building-the-kernel) •
[Installation](#-installation) •
[Credits](#-credits--acknowledgments)

---

</div>

## 📖 Overview

**FrenzyKernel** is a heavily enhanced, performance-optimized Linux 5.10 kernel strictly adhering to the **Android Generic Kernel Image (GKI)** standard. Because it is a true universal **GKI 5.10** kernel, it is architecture-compliant with any Android device running the common GKI 5.10 kernel. Development, validation, and real-world testing have been conducted on the **Tecno Pova 4 Pro (`LG8n`)**.

Unlike conventional smartphone kernels that prioritize aggressive thermal throttling over continuous throughput, FrenzyKernel transforms Android GKI devices into enterprise-grade **24/7 Linux Micro-Servers & Appliances**, capable of hosting full Linux distributions (Debian 13 / Ubuntu via Droidspaces LXC), Minecraft servers, Node.js applications, databases, and VPN meshes—while remaining a smooth, ultra-responsive daily driver phone when needed.

---

## 🚀 Core Pillars

### 1. Scheduler & Performance Optimization
- **CFS Granularity Tuning**: Fine-tuned `sched_latency_ns` (4ms) and `sched_min_granularity_ns` (750µs) for minimal frame drop and ultra-fast task switching.
- **UCLAMP Instant Ramp-Up**: Configured `sched_util_clamp_min_default = 50` with `up_rate_limit_us = 0` across clusters, guaranteeing instantaneous frequency ramp-up under burst workloads.
- **Sustained Throughput Scaling**: Guarantees sustained CPU performance under heavy multi-tasking without premature governor down-scaling.
- **Advanced Networking**: Defaults to **TCP BBRv3** congestion control paired with **CAKE queue discipline** (`sch_cake`) and Fast Open (`tcp_fastopen = 3`) for minimal latency and zero bufferbloat.

### 2. Containerization & Virtualization Engine
- **Full LXC / Namespaces Support**: Completely enabled CGroups v1 & v2 hierarchies, PID/mount/network namespaces, and user namespace isolation.
- **Droidspaces Container Host**: Out-of-the-box support for hosting Debian 13 (Trixie), Ubuntu, and Arch Linux rootfs directly on device.
- **NTSync Synchronization Driver**: Built-in `/dev/ntsync` kernel synchronization primitives, providing high-performance NT fast synchronization for Wine, Proton, Windows emulation, and database engines.

### 3. Hardware Shielding & Resilience
- **Touchscreen Ghost-Touch Shield**: Dedicated hardware-level `EVIOCGRAB` input interceptor (`touch_blocker`) isolating faulty digitizers and eliminating ghost touch inputs.
- **Broken Fingerprint HAL Isolator**: Suppresses hardware sensor failure loops (`fingerprint@2.1`), unloads faulty driver modules (`tran_fp`), and auto-purges tombstone crash dump accumulations.
- **Hardware Display Backlight Lock**: In headless server mode (Tier 2), the physical LCD backlight is locked via kernel sysfs (`chmod 000`) to absolute zero emission, preventing heat, power drain, and display burn-in during 24/7 continuous operation.

---

## 🎛️ Recommended Companion: FrenzyServer

For extreme 24/7 headless server operation, RAM debloating, hardware shielding, and remote WebUI monitoring (Port 8888), pair FrenzyKernel with the official companion root module:

👉 **[FrenzyServerKSU](https://github.com/inimuqsith/FrenzyServerKSU)** — *Universal All-in-One Headless Android Server Suite, Remote WebUI & System Optimizer.*

### Companion Highlights:
- **Remote WebUI on Port 8888**: Real-time RAM & CPU visualization, thermals, and one-click RAM trim from any browser.
- **Operational Tiers**: Instantly switch between Normal Phone Mode, Tier 1 (Smart Debloat), and Tier 2 (Extreme Headless with LCD screen locked off).
- **Hardware Shields**: Touchscreen ghost-touch blocker (`touch_blocker`) and biometric crash isolator.
- **Daemon Protection**: Anti-OOM protection for background server daemons (`sshd`, `nginx`, `node`, `python`, `dockerd`, etc.).

---

## 🔨 Building the Kernel

### Prerequisites
- Linux host (Debian / Ubuntu / Arch)
- AArch64 Clang toolchain (LLVM 14+ or Android NDK Clang)
- `bc`, `bison`, `flex`, `libssl-dev`, `make`, `python3`

### Build Steps

```bash
# Clone the repository
git clone https://github.com/inimuqsith/FrenzyKernel.git -b frenzy-v4-fusion
cd FrenzyKernel

# Export cross compiler environment
export ARCH=arm64
export SUBARCH=arm64
export PATH="/path/to/clang/bin:$PATH"

# Configure defconfig
make O=out ARCH=arm64 CC=clang LD=ld.lld gki_defconfig

# Compile kernel Image & DTB
make O=out ARCH=arm64 CC=clang LD=ld.lld -j$(nproc)
```

The compiled kernel image will be generated at `out/arch/arm64/boot/Image.gz`.

---

## 📦 Installation

1. **Kernel Image**:
   - Pack into an AnyKernel3 zip or flash directly via Fastboot / TWRP:
     ```bash
     fastboot flash boot boot.img
     ```
2. **Companion Module (Optional)**:
   - Install **[FrenzyServerKSU](https://github.com/inimuqsith/FrenzyServerKSU)** via KernelSU, Magisk, or APatch for remote WebUI dashboard and 24/7 headless server management.

---

## 👥 Credits & Acknowledgments

- **Lead Developer**: Abdul Muqsith ([@inimuqsith](https://github.com/inimuqsith))
- **Base Tree & Upstream**: [MillenniumOSS](https://github.com/MillenniumOSS) & Google Android Open Source Project (AOSP)
- **Linux Foundation**: The Linux Kernel Archives
- **Community**: KernelSU, Droidspaces, and Android GKI developer community

---

<div align="center">

*Engineered with precision for the Android GKI 5.10 architecture. Tested on Tecno Pova 4 Pro.*  
Licensed under the **GNU General Public License v2.0**.

</div>
