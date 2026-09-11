# ⚡ FrenzyKernel

<div align="center">

![Linux](https://img.shields.io/badge/Kernel-Linux%205.10%20GKI-blue?style=for-the-badge&logo=linux)
![Standard](https://img.shields.io/badge/Architecture-Android%20GKI%205.10-success?style=for-the-badge&logo=android)
![Target](https://img.shields.io/badge/Tested%20On-Tecno%20Pova%204%20Pro-orange?style=for-the-badge&logo=android)
![Arch](https://img.shields.io/badge/Arch-AArch64%20(ARM64)-red?style=for-the-badge)
![Root](https://img.shields.io/badge/Built--in%20Root-KernelSU--Next%20v3.3.0-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-GPL--2.0-yellow?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active%20%7C%20Production%20Ready-brightgreen?style=for-the-badge)

**High-Performance Android Generic Kernel Image (GKI 5.10) for Linux Server Hosting & Containerization**  
*A pure Android Generic Kernel Image (Linux 5.10 GKI) featuring Google BBRv3 backport, in-kernel NTSync driver, build-time /proc/config.gz cloaking, full LXC/Docker namespaces & CGroups, KernelSU-Next v3.3.0 integration, and Clang ThinLTO. Tested exclusively on Tecno Pova 4 Pro.*

[Overview](#-overview) •
[Core Kernel Architecture](#-core-kernel-architecture) •
[Userspace Companion Module](#-recommended-userspace-companion-frenzyserverksu) •
[Building](#-building-the-kernel) •
[Installation](#-installation) •
[Credits](#-credits--acknowledgments)

---

</div>

## 📖 Overview

**FrenzyKernel** is an enterprise-grade Linux 5.10 kernel adhering strictly to the universal **Android Generic Kernel Image (GKI)** standard (`gki_defconfig`).

Unlike conventional smartphone kernels optimized solely for conservative handheld use, FrenzyKernel transforms Android GKI devices into **high-performance Linux host nodes**. Built directly into the kernel source are the necessary drivers, subsystems, and kernel patches to run native Linux containers (LXC, Docker, Droidspaces), enterprise network stacks (Google BBRv3, CAKE), low-latency synchronization primitives (NTSync for Wine/Proton), and embedded root orchestration (KernelSU-Next).

> [!NOTE]
> **Validation Device**: While architecturally compatible with devices running the Android 12 GKI 5.10 common kernel, FrenzyKernel is developed, validated, and rigorously tested on the **Tecno Pova 4 Pro (`LG8n`)**.

---

## 🚀 Core Kernel Architecture

FrenzyKernel incorporates core subsystems, backports, and kernel drivers compiled directly into the kernel image:

```
+-------------------------------------------------------------------------+
|                        ⚡ FRENZYKERNEL ARCHITECTURE                     |
+-------------------------------------------------------------------------+
|  [Pillar 1] Build-Time Security & Dynamic /proc/config.gz Cloaking      |
|  [Pillar 2] In-Kernel Hardware Drivers & NT Emulation (NTSync, KSU)     |
|  [Pillar 3] Containerization & Virtualization Engine (LXC, Docker, DS) |
|  [Pillar 4] Next-Gen Kernel Networking & Firewall (BBRv3, CAKE, IPSet)  |
|  [Pillar 5] Scheduler Architecture & Compiler Tuning (PELT 12ms, LTO)   |
+-------------------------------------------------------------------------+
```

### 1. 🎭 Build-Time Security & Dynamic `/proc/config.gz` Cloaking
- **Kbuild Dynamic Config Stripping (`kernel/Makefile`)**:
  - Implements an automated cloaking mechanism during `config_data.gz` compilation via `CONFIG_FAKE_DISABLE`.
  - Targets sensitive kernel options (`CONFIG_KSU`, `CONFIG_KSU_SUSFS`, `CONFIG_SUSFS`, `CONFIG_BBG`).
  - Automatically redirects Kbuild to a sanitized `.config.patched` so that apps, root detectors, or security scanners reading `/proc/config.gz` at runtime receive:
    ```text
    # CONFIG_KSU is not set
    ```
  - Conceals custom root infrastructure directly at the kernel configuration level.

### 2. ⚡ In-Kernel Hardware Drivers & Native Primitives
- **Hardware NTSync Synchronization Driver (`/dev/ntsync`)**:
  - Integrated directly into `drivers/misc/ntsync.c` and `include/uapi/linux/ntsync.h` (`CONFIG_NTSYNC=y`).
  - Implements Windows NT synchronization primitives (mutexes, semaphores, events) directly in kernel space, eliminating heavy context-switch overhead for Wine, Proton, x86/ARM translation layers, and multi-threaded database engines.
- **Native KernelSU-Next v3.3.0 Integration**:
  - `CONFIG_KSU=y` embedded directly inside `drivers/kernelsu` at the driver source level, eliminating reliance on initramfs ramdisk hooks.
- **Enterprise IPC & Message Queuing**:
  - `CONFIG_SYSVIPC=y` and `CONFIG_POSIX_MQUEUE=y` enabled for high-throughput inter-process communication among containerized microservices.
- **Kernel CIFS/SMB Network Client**:
  - `CONFIG_CIFS=y`, `CONFIG_CIFS_XATTR=y`, and `CONFIG_CIFS_POSIX=y` for mounting remote NAS / Samba storage directly at the kernel VFS layer.

### 3. 🧊 Containerization & Virtualization Subsystem (LXC / Docker / Droidspaces Host)
- **Full Linux Namespaces Enabled**:
  - `CONFIG_NAMESPACES=y`, `CONFIG_UTS_NS=y`, `CONFIG_IPC_NS=y`, `CONFIG_USER_NS=y`, and `CONFIG_NET_NS=y`.
  - **PID Namespaces (`CONFIG_PID_NS=y`)**: Explicitly unlocked (disabled by default in stock Android GKI), enabling isolated process trees required by container init daemons (`systemd`, `openrc`, `init`).
- **Complete Control Groups (CGroups v1 & v2)**:
  - `CONFIG_CGROUPS=y`, `CONFIG_MEMCG=y`, `CONFIG_CPUSETS=y`, `CONFIG_BLK_CGROUP=y`, `CONFIG_CGROUP_SCHED=y`, `CONFIG_CGROUP_FREEZER=y`, and `CONFIG_CGROUP_BPF=y`.
  - **Device Access Controller (`CONFIG_CGROUP_DEVICE=y`)**: Built-in device whitelisting support, allowing containers secure, controlled access to `/dev/` nodes.
- **OverlayFS Custom Patches**: 1orz GKI custom patches integrated into `fs/overlayfs/util.c`, `include/linux/sched.h`, and `kernel/cgroup/cgroup.c` for full Docker/Podman overlay storage layer compatibility.
- **Native Devtmpfs & Syscall Handles**: `CONFIG_DEVTMPFS=y` and `CONFIG_FHANDLE=y` for mounting complete devfs trees inside Droidspaces (Debian 13 Trixie / Ubuntu rootfs).
- **POSIX ACL File Security**: `CONFIG_TMPFS_POSIX_ACL=y` and `CONFIG_NTFS3_FS_POSIX_ACL=y` enabling granular Linux permission bits for hosted server services.

### 4. 🌐 Next-Gen Kernel Networking, Congestion Control & Security
- **Backported Google TCP BBRv3**:
  - Full backport of Google's **BBRv3 (Bottleneck Bandwidth and RTT v3)** with Path Latency Based (PLB) congestion control (`net/ipv4/tcp_bbr3.c`, `net/ipv4/tcp_plb.c`).
  - Android KABI-compliant implementation.
  - Set as the kernel default congestion control: `CONFIG_TCP_CONG_BBR3=y`, `CONFIG_DEFAULT_BBR3=y` (`CONFIG_DEFAULT_TCP_CONG="bbr3"`).
- **CAKE Packet Scheduler (`sch_cake`)**:
  - `CONFIG_NET_SCH_CAKE=y` compiled directly into the kernel traffic control subsystem (`net/sched/sch_cake.c`) to eliminate bufferbloat and optimize bandwidth fairness.
- **Server Firewall & Packet Filtering Acceleration**:
  - **IPSet Framework (`CONFIG_IP_SET=y`)**: Full kernel hash support (`CONFIG_IP_SET_HASH_IP=y`, `CONFIG_IP_SET_HASH_NET=y`, `CONFIG_IP_SET_HASH_IPPORT=y`) for high-speed packet filtering matching thousands of IPs in $O(1)$ time.
  - **Rate-Limiting & Brute-Force Defense (`CONFIG_NETFILTER_XT_MATCH_RECENT=y`)**: In-kernel connection tracking required by `fail2ban` and `ufw` to block SSH/HTTP brute-force attacks at wire speed.
  - **IPv6 NAT Masquerade**: `CONFIG_IP6_NF_NAT=y` and `CONFIG_IP6_NF_TARGET_MASQUERADE=y` for container bridge routing over IPv6.

### 5. 🎛️ Scheduler Architecture & Compiler Tuning
- **PELT 12ms Half-Life Tracking**:
  - `CONFIG_PELT_UTIL_HALFLIFE_12=y` replaces the standard 32ms PELT window, speeding up task load tracking for instant CPU frequency scaling during bursty server request spikes.
- **Reflex CPU Governor**:
  - `CONFIG_CPU_FREQ_GOV_REFLEX=y` embedded as a built-in cpufreq governor option.
- **Clang ThinLTO (Link-Time Optimization)**:
  - `CONFIG_LTO_CLANG_THIN=y` provides whole-program interprocedural optimizations with manageable build-time memory footprints and robust KMI compatibility.
- **Aggressive Performance Optimization**:
  - `CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE=y` (-O2 compiler flags) with disabled power-efficient workqueues (`# CONFIG_WQ_POWER_EFFICIENT_DEFAULT is not set`) to prevent unsolicited thread sleeping under heavy multi-core load.

---

## 🎛️ Recommended Userspace Companion: FrenzyServerKSU

While **FrenzyKernel** provides the kernel infrastructure (`/dev/ntsync`, namespaces, BBRv3, CGroups v2, config cloaking), orchestrating userspace runtime states is handled by its official companion KernelSU module:

👉 **[FrenzyServerKSU](https://github.com/inimuqsith/FrenzyServerKSU)** — *Universal Headless Android Linux Server Suite & WebUI Dashboard (Exclusively for KernelSU / KernelSU-Next).*

### Separation of Responsibilities
| Domain | Layer | Handled By | Responsibilities |
| :--- | :--- | :--- | :--- |
| **Kernel Space** | VFS / Net / Drivers | **FrenzyKernel** | Namespaces, CGroups, NTSync driver, BBRv3, CAKE, IPSet, config cloaking, ThinLTO |
| **Userspace** | Daemons / Scripts / Web | **FrenzyServerKSU** | Dynamic sysctl tuning, `touch_blocker` daemon, 3-tier headless debloat, WebUI dashboard |

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
   - Pack `Image.gz` into an AnyKernel3 zip or flash directly via Fastboot / TWRP:
     ```bash
     fastboot flash boot boot.img
     ```
2. **Userspace Companion Module (Optional)**:
   - Install **[FrenzyServerKSU](https://github.com/inimuqsith/FrenzyServerKSU)** via KernelSU or KernelSU-Next for browser dashboard management and runtime headless orchestration.

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
