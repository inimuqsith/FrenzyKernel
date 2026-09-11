# 🤖 AGENTS.md — Agent Guidelines & Repository Directives

This document defines the strict operating principles, architectural boundaries, and coding standards for all AI agents working on **FrenzyKernel**.

---

## 🎯 Repository Mission & Identity

**FrenzyKernel** is a high-performance Linux 5.10 kernel strictly adhering to the universal **Android Generic Kernel Image (GKI)** standard (`arch/arm64/configs/gki_defconfig`).

- **Target Architecture**: AArch64 (ARM64) Common Kernel (GKI 5.10).
- **Verified Hardware**: **Tecno Pova 4 Pro (`LG8n`)** is the sole real-world test and validation device.
- **Upstream Base**: `MillenniumOSS/android_kernel_common_millennium_android12-5.10` / AOSP Common Kernel 5.10.

---

## 🚨 Non-Negotiable Rules for AI Agents

### 1. Strict Separation: Kernel Space vs Userspace
- **NEVER mix userspace module logic into the kernel tree or documentation.**
- Features like `touch_blocker` (C binary intercepting `EVIOCGRAB`), display backlight `chmod 000` scripts, `sysctl` runtime execution, and WebUI dashboards belong **exclusively** to the standalone companion module **[FrenzyServerKSU](https://github.com/inimuqsith/FrenzyServerKSU)**.
- **FrenzyKernel** is purely kernel source code: in-kernel drivers, defconfig options, Kbuild makefiles, backports, and syscall patches.

### 2. No Hallucinated or Fake Tested Devices
- **Never claim untested devices**: Do NOT state that this kernel is tested on Poco, Xiaomi, Redmi Pad, etc.
- **No MT6789/Helio G99 exclusivity claim**: FrenzyKernel is built on `gki_defconfig` (universal Android GKI 5.10), tested on Tecno Pova 4 Pro. It is not an SoC-locked vendor kernel.

### 3. Git Author & Commit Standards
- All commits **MUST** be authored with the user's verified identity:
  ```bash
  git commit --author="Muqsith <muqsithpersonal@gmail.com>"
  ```
- Commit messages must follow Conventional Commits format:
  `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.

### 4. Communication & Confirmation Protocol
- **NEVER execute major modifications without explicit human approval.**
- Always present an actionable, comprehensive implementation plan first.
- Wait for explicit user confirmation in the conversation before modifying core files.

---

## 🌳 Branching Structure

| Branch | Status | Description |
| :--- | :--- | :--- |
| `main` | **Default Branch** | Latest production release (synced with `frenzy-v4-fusion`). |
| `frenzy-v4-fusion` | **Active Release** | v4 release: BBRv3, NTSync, `/proc/config.gz` cloaking, Droidspaces, ThinLTO. |
| `frenzy-v3-droidspaces` | Historical Archive | v3 release: DEVTMPFS, FHANDLE, UFW/Fail2ban netfilter modules. |
| `frenzy-v2-lxc` | Historical Archive | v2 release: LXC/Docker namespaces, CGroups v1/v2, OverlayFS patches. |
| `frenzy-v1-ksu` | Historical Archive | v1 release: KernelSU-Next v3.3.0 and ThinLTO. |
| `chihiro-main` | Pristine Upstream | Clean upstream tracking branch from MillenniumOSS. |

---

## ⚙️ In-Kernel Core Technologies Checklist

When editing or documenting FrenzyKernel, ensure the following native kernel components are accurately represented:
- [x] **KernelSU-Next v3.3.0** (`drivers/kernelsu`, `CONFIG_KSU=y`).
- [x] **In-Kernel NTSync Driver** (`drivers/misc/ntsync.c`, `include/uapi/linux/ntsync.h`, `CONFIG_NTSYNC=y`).
- [x] **Dynamic `/proc/config.gz` Cloaking** (`kernel/Makefile` build-time config stripping via `CONFIG_FAKE_DISABLE`).
- [x] **Google TCP BBRv3 Congestion Control** (`net/ipv4/tcp_bbr3.c`, `net/ipv4/tcp_plb.c`, `CONFIG_DEFAULT_BBR3=y`).
- [x] **CAKE Queue Discipline** (`net/sched/sch_cake.c`, `CONFIG_NET_SCH_CAKE=y`).
- [x] **Full Namespaces & CGroups v1/v2** (`CONFIG_PID_NS=y`, `CONFIG_USER_NS=y`, `CONFIG_CGROUP_DEVICE=y`).
- [x] **Droidspaces Rootfs Host Support** (`CONFIG_DEVTMPFS=y`, `CONFIG_FHANDLE=y`, `CONFIG_TMPFS_POSIX_ACL=y`).
- [x] **Server Firewall Acceleration** (`CONFIG_IP_SET=y`, `CONFIG_NETFILTER_XT_MATCH_RECENT=y`, `CONFIG_IP6_NF_NAT=y`).
- [x] **PELT 12ms Halflife & Reflex Governor** (`CONFIG_PELT_UTIL_HALFLIFE_12=y`, `CONFIG_CPU_FREQ_GOV_REFLEX=y`).
- [x] **Clang ThinLTO** (`CONFIG_LTO_CLANG_THIN=y`, `CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE=y`).
