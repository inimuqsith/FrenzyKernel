# ⚡ FrenzyKernel

<div align="center">

![Linux](https://img.shields.io/badge/Kernel-Linux%205.10%20GKI-blue?style=for-the-badge&logo=linux)
![SoC](https://img.shields.io/badge/SoC-MediaTek%20Helio%20G99%20(MT6789)-orange?style=for-the-badge&logo=mediatek)
![Target](https://img.shields.io/badge/Device-Tecno%20Pova%204%20Pro%20(LG8n)-success?style=for-the-badge&logo=android)
![Arch](https://img.shields.io/badge/Arch-AArch64%20(ARM64)-red?style=for-the-badge)
![License](https://img.shields.io/badge/License-GPL--2.0-yellow?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active%20%7C%20Production%20Ready-brightgreen?style=for-the-badge)

**High-Performance Linux 5.10 Kernel & All-in-One Headless Server Engine for MediaTek MT6789 / Helio G99**  
*Engineered for 24/7 Linux Server Hosting (Droidspaces LXC), Gaming Emulation, Hardware Shielding, and Enterprise-Grade Stability.*

[Overview](#-overview) •
[Core Pillars](#-core-pillars) •
[FrenzyServer WebUI & Engine](#-frenzyserver-engine--webui) •
[Building](#-building-the-kernel) •
[Installation](#-installation) •
[Credits](#-credits--acknowledgments)

---

</div>

## 📖 Overview

**FrenzyKernel** is a heavily enhanced, performance-optimized Linux 5.10 kernel branch specifically engineered for the **MediaTek Helio G99 (MT6789)** platform, validated and refined on the **Tecno Pova 4 Pro (`LG8n`)**. 

Unlike conventional smartphone kernels that prioritize aggressive thermal throttling over continuous throughput, FrenzyKernel transforms the Helio G99 into an enterprise-grade **24/7 Linux Micro-Server & Appliance**, capable of hosting full Linux distributions (Debian 13 / Ubuntu via Droidspaces LXC), Minecraft servers, Node.js applications, databases, and VPN meshes—while remaining a smooth, ultra-responsive daily driver phone when needed.

---

## 🚀 Core Pillars

### 1. Scheduler & Performance Optimization
- **CFS Granularity Tuning**: Fine-tuned `sched_latency_ns` (4ms) and `sched_min_granularity_ns` (750µs) for minimal frame drop and ultra-fast task switching.
- **UCLAMP Instant Ramp-Up**: Configured `sched_util_clamp_min_default = 50` with `up_rate_limit_us = 0` across Little (A55) and Big (A76) clusters, guaranteeing instantaneous frequency ramp-up under burst workloads.
- **MediaTek PPM Uncap**: Enforces persistent dual Cortex-A76 performance at 2.2 GHz without premature thermal governor throttling.
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

## 🎛️ FrenzyServer Engine & WebUI

Included within the repository is **`frenzy_server/`**, a native KernelSU / Magisk module and daemon suite that exposes real-time system metrics, container controls, and headless switching via a **Remote WebUI on Port 8888** and an integrated CLI:

```text
======================================================
    ⚡ FRENZYSERVER ALL-IN-ONE LINUX SERVER ENGINE   
       Helio G99 (MT6789) | Droidspaces Host          
======================================================
[1] RAM & Memory Health:
  • Total RAM     : 7700 MB (~8 GB)
  • Free Physical : 4898 MB
  • Available RAM : 5754 MB (Dedicated to Linux/Server)
  • Battery Temp  : 31°C (Smart Guard Limit: 47°C)

[2] Server Mode (Current):
  • Active Mode   : TIER 2 (Extreme Headless Server)
  • Screen State  : Hardware Screen Locked OFF (Controlled via PC)
  • PC LAN Access : http://192.168.0.109:8888
  • Tailscale Web : http://100.72.229.46:8888
======================================================
```

### Operational Tiers

| Tier | Name | Target State | Available RAM | Primary Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Normal** | Consumer Phone Mode | All Android services, Launcher, SystemUI, and camera active | ~5.3 GB | Daily driver smartphone use |
| **Tier 1** | Smart Debloat Mode | 28 bloatware packages frozen, Camera HAL halted, full UI intact | ~5.4 GB | Extended gaming, daily multi-tasking |
| **Tier 2** | Extreme Headless Mode | Launcher & SystemUI frozen (`SIGSTOP`), screen locked off, 100% CPU dedicated to server | **>5.7 GB** | 24/7 Server, Minecraft, LXC, Node.js |

---

## 💻 CLI Commands

```bash
# Display live RAM, battery thermals, container & network status
frenzy-server status

# Switch operational tier
frenzy-server mode [normal|tier1|tier2]

# Quick RAM trim (drops caches, compacts memory & clears cached apps)
frenzy-server trim

# Tailscale VPN Mesh controls
frenzy-server vpn [connect|disconnect|open|status]

# Droidspaces Linux Container controls
frenzy-server droidspaces [restart|open|status]

# Dump metrics in JSON format (used by REST API & WebUI)
frenzy-server json
```

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
make O=out ARCH=arm64 CC=clang LD=ld.lld mt6789_defconfig

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
2. **FrenzyServer Module**:
   - Flash `frenzy_server.zip` in **KernelSU** or **Magisk** Manager.
   - Reboot device.
   - Access the WebUI from your PC browser: `http://<device-ip>:8888`.

---

## 👥 Credits & Acknowledgments

- **Lead Developer**: Abdul Muqsith ([@inimuqsith](https://github.com/inimuqsith))
- **Base Tree & Upstream**: [MillenniumOSS](https://github.com/MillenniumOSS) & Google Android Open Source Project (AOSP)
- **Linux Foundation**: The Linux Kernel Archives
- **Community**: KernelSU, Droidspaces, and Transsion MT6789 developer community

---

<div align="center">

*Engineered with precision for the MediaTek Helio G99 architecture.*  
Licensed under the **GNU General Public License v2.0**.

</div>
