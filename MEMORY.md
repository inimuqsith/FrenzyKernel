# 🧠 MEMORY.md — FrenzyKernel Architectural Memory & Decision Records

This document preserves architectural context, critical engineering decisions, hardware constraints, and lessons learned across the evolution of **FrenzyKernel**.

---

## 📌 Project Overview & Lineage

- **Name**: FrenzyKernel
- **Architecture**: Android Generic Kernel Image (GKI 5.10) for AArch64 (ARM64).
- **Upstream Repository**: `MillenniumOSS/android_kernel_common_millennium_android12-5.10`
- **Fork Repository**: `inimuqsith/FrenzyKernel` (official GitHub fork).
- **Target / Tested Device**: **Tecno Pova 4 Pro (`LG8n`)**.
- **Defconfig**: `arch/arm64/configs/gki_defconfig`.

---

## 🏛️ Architecture Decision Records (ADRs)

### ADR-001: True GKI 5.10 Standard Compliance
- **Context**: Consumer smartphone kernels often use heavily modified vendor trees tied to specific SoCs.
- **Decision**: FrenzyKernel uses `gki_defconfig` and preserves Android Kernel Module Interface (KMI) / Kernel ABI compliance.
- **Consequence**: Universal compatibility across Android GKI 5.10 devices, but real-world testing and hardware verification is strictly limited to the Tecno Pova 4 Pro.

### ADR-002: Dynamic `/proc/config.gz` Build-Time Cloaking
- **Context**: Root detectors, anti-cheat mechanisms, and security scanners inspect `/proc/config.gz` to check if `CONFIG_KSU=y` or root-related configs are present.
- **Decision**: In `kernel/Makefile`, implemented dynamic config cloaking (`CONFIG_FAKE_DISABLE` / `KCONFIG_CONFIG_PATCHED`).
- **Mechanism**: When `config_data.gz` is compressed during build, Kbuild is pointed to `.config.patched` which strips sensitive configs (`CONFIG_KSU`, `CONFIG_SUSFS`, `CONFIG_BBG`) and outputs `# CONFIG_* is not set`.

### ADR-003: In-Kernel Windows NT Primitives (`/dev/ntsync`)
- **Context**: Running Windows games, emulators (Wine, Proton, Box64/FEX-Emu), or multi-threaded databases inside Android containers incurs heavy context-switching overhead using userspace event emulation.
- **Decision**: Built in the native NTSync driver (`drivers/misc/ntsync.c`, `include/uapi/linux/ntsync.h`, `CONFIG_NTSYNC=y`).
- **Mechanism**: Exposes `/dev/ntsync` to provide in-kernel mutexes, semaphores, and synchronization events.

### ADR-004: In-Kernel Google TCP BBRv3 & CAKE Scheduler
- **Context**: Android stock GKI defaults to conservative Westwood or Cubic congestion control and fq_codel, causing latency spikes and bufferbloat under continuous server loads.
- **Decision**: Backported Google's BBRv3 stack (`net/ipv4/tcp_bbr3.c`, `net/ipv4/tcp_plb.c`) directly into the kernel source and enabled the CAKE packet scheduler (`CONFIG_NET_SCH_CAKE=y`). Set `CONFIG_DEFAULT_BBR3=y` as the default TCP algorithm.

### ADR-005: High-Performance Containerization Host (Droidspaces / LXC)
- **Context**: Standard Android GKI disables `CONFIG_PID_NS`, lacks `CONFIG_CGROUP_DEVICE`, and lacks native `CONFIG_DEVTMPFS`, preventing rootfs containers from booting or isolating hardware.
- **Decision**: Unlocked `CONFIG_PID_NS=y`, `CONFIG_USER_NS=y`, `CONFIG_CGROUP_DEVICE=y`, `CONFIG_DEVTMPFS=y`, `CONFIG_FHANDLE=y`, and integrated 1orz OverlayFS patches.
- **Consequence**: Full out-of-the-box hosting of Debian 13 (Trixie), Ubuntu, and Arch Linux containers directly on the device.

### ADR-006: In-Kernel Root via KernelSU-Next v3.3.0
- **Context**: Traditional root solutions (Magisk) require initramfs ramdisk patching.
- **Decision**: Integrate KernelSU-Next v3.3.0 directly into `drivers/kernelsu` (`CONFIG_KSU=y`).

### ADR-007: Clang ThinLTO & Scheduler Responsiveness
- **Context**: Full LTO (`CONFIG_LTO_CLANG_FULL=y`) causes high memory consumption during compilation and fragile symbol resolution, while 32ms PELT causes delayed frequency scaling.
- **Decision**: Adopted `CONFIG_LTO_CLANG_THIN=y`, enabled `CONFIG_PELT_UTIL_HALFLIFE_12=y` for faster load tracking, and built in `CONFIG_CPU_FREQ_GOV_REFLEX=y`.

### ADR-008: Separation of Concerns with FrenzyServerKSU
- **Context**: Userspace scripts and binaries (`touch_blocker`, display backlight locking, sysctl execution, WebUI) were previously mixed into kernel documentation.
- **Decision**: All userspace orchestration is strictly separated into the standalone repository **[FrenzyServerKSU](https://github.com/inimuqsith/FrenzyServerKSU)**.
- **Special Device Note**: Phone-specific hardware workarounds (such as disabling broken fingerprint sensors via `tran_fp` unloader and `tiny_exit`) are preserved strictly in the local branch `local-pova4pro` of `FrenzyServerKSU`, keeping the public repos universal and clean.

---

## 📦 Version History Reference

- **v1.0** (`frenzy-v1-ksu`, commit `48237beda`): KernelSU-Next v3.3.0 driver integration and Clang ThinLTO.
- **v2.0** (`frenzy-v2-lxc`, commit `651d42d1b`): LXC/Docker containerization, CGroups v1/v2, 1orz OverlayFS patches.
- **v3.0** (`frenzy-v3-droidspaces`, commit `fe08e9adf`): Droidspaces host support, DEVTMPFS, FHANDLE, Fail2ban `xt_recent`, IPSet.
- **v4.0** (`frenzy-v4-fusion` / `main`, commit `b1bdc5b76`): Backported Google BBRv3, NTSync driver, dynamic `/proc/config.gz` cloaking, CAKE packet scheduler.
