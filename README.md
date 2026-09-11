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
- **Hardware Display Backlight Lock**: In headless server mode (Tier 2), the physical LCD backlight is locked via kernel sysfs (`chmod 000`) to absolute zero emission, preventing heat, power drain, and display burn-in during 24/7 continuous operation.

---

## 🎛️ Recommended Companion: FrenzyServer (KernelSU)

For maximum performance, hardware protection, and 24/7 headless server orchestration, pair FrenzyKernel with its official companion root module:

👉 **[FrenzyServerKSU](https://github.com/inimuqsith/FrenzyServerKSU)** — *All-in-One Headless Android Linux Server Engine, Remote WebUI & Hardware Optimizer (Exclusively for KernelSU).*

### Why Pair FrenzyKernel with FrenzyServer?
FrenzyServer integrates multiple specialized KernelSU module forks into a unified daemon and CLI engine, seamlessly complementing FrenzyKernel's kernel-level features:
- **⚡ CPU Uncap & Governor Optimization**: Sets `up_rate_limit_us = 0` (zero latency frequency ramp-up), `sched_util_clamp_min_default = 50`, and overrides aggressive thermal throttling policies to sustain continuous multi-core execution during heavy server workloads.
- **🛑 Hardware Touchscreen Ghost Shield (`touch_blocker`)**: Intercepts `/dev/input/event*` hardware touch events via Linux kernel `EVIOCGRAB`, preventing broken digitizers or ghost touches from interfering with server operations.
- **🧊 3-Tier Headless Server Architecture**:
  - **Normal Mode**: Standard phone mode with all services active.
  - **Tier 1 (Smart Debloat)**: Freezes 28 bloatware packages via `pm disable-user` and halts Camera HAL.
  - **Tier 2 (Extreme Headless)**: Freezes Launcher & SystemUI via `SIGSTOP`, locks physical LCD backlight to zero, and sweeps cached apps—dedicating maximum RAM to Linux servers and databases.
- **🛡️ Anti-OOM Daemon Shield**: Automatically pins `oom_score_adj = -900` for server processes (`sshd`, `nginx`, `node`, `python`, `dockerd`, `containerd`, `mysqld`, `redis-server`, `tailscale`) so Android's LowMemoryKiller (LMK) never terminates your servers.
- **🌐 Remote WebUI Dashboard on Port 8888**: Complete browser-based dashboard for live RAM/thermal monitoring, quick RAM trim, and tier switching.
- **⚠️ Platform Compatibility**: Engineered exclusively for **KernelSU** and **KernelSU-Next**.

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
   - Install **[FrenzyServerKSU](https://github.com/inimuqsith/FrenzyServerKSU)** via KernelSU or KernelSU-Next for remote WebUI dashboard and 24/7 headless server management.

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
