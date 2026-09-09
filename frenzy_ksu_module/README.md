# Frenzy G99 Server Master (FSM-G99) - Fusion Edition

Modul KernelSU/Magisk hasil **Smart Fusion & Fork** dari 3 proyek optimasi Android terkemuka, dipadukan dengan inovasi kustom baru khusus untuk **Tecno Pova 4 Pro (LG8n / Helio G99 / MT6789)** yang menjalankan **YAAP (AOSP ROM)** sebagai **Server Container (Droidspaces / LXC)**.

---

## 🏛️ Arsitektur Smart Fusion

### 1. Pilar 1: Fork dari KTweak (oleh tytydraco)
- **Scheduler Granularity**: Menyetel periode penjadwalan ke 4ms (`sched_latency_ns=4000000`) untuk respon dispatch thread server yang cepat.
- **Cache-Hotness & Anti-Thrashing**: `sched_migration_cost_ns=5000000` mencegah task Geekbench/komputasi melompat-lompat liar antara cluster A55 dan A76.
- **Memory & Swap**: Menyetel `page-cluster=0` (krusial untuk menghilangkan lag read-ahead ZRAM di Android) dan buffer dirty writeback 20/5.
- **Block I/O**: Mengurangi antrean request UFS ke 64 dan mematikan random entropy overhead.

### 2. Pilar 2: Fork dari YC-Scheduler & Uperf (oleh yc9559 & MattYang9527)
- **Instant Schedutil Ramp**: Mengatur `up_rate_limit_us=0` pada Policy 0 (A55) dan Policy 6 (A76). Begitu kalkulasi komputasi server masuk, CPU langsung melonjak ke frekuensi tertinggi (2.2 GHz) tanpa menunggu delay window PELT 32ms.
- **Dynamic UCLAMP**: Mencegah PowerHAL AOSP menurunkan prioritas komputasi proses server dan Geekbench.

### 3. Pilar 3: Fork dari MTK PPM & Thermal Uncapper
- **PPM Policy Bypass**: Menonaktifkan `PPM_POLICY_THERMAL` di `/proc/ppm/policy_status`.
- **Frequency Ceiling Lift**: Membuka batasan frekuensi CPU (`userlimit_max_cpu_freq` & `hard_userlimit_cpu_freq`) ke nilai native silicon:
  - Cluster 0 (cpu0-5 Cortex-A55): **2.0 GHz** (2000000 KHz)
  - Cluster 1 (cpu6-7 Cortex-A76): **2.2 GHz** (2200000 KHz)
- **SoC Thermal Trip**: Menaikkan threshold thermal throttling CPU zone ke 85°C (aman untuk silikon TSMC 6nm).

### 4. Pilar 4: Inovasi Baru untuk Server Droidspaces (LXC)
- **CPUSet Unification**: Membuka `/dev/cpuset/` agar container Linux Droidspaces bebas menggunakan seluruh 8 Core (0-7).
- **Server Network Stack**: Mengaktifkan TCP BBR, `tcp_fastopen=3`, `tcp_tw_reuse=1`, dan buffer socket 8MB untuk throughput jaringan gigabit.
- **Silent SELinux Audit**: Menghilangkan overhead syscall audit di runtime (`audit_rate_limit=0`).

### 5. Pilar 5: Smart 24/7 Battery Thermal Guard & Anti-OOM Daemon
- **Anti-OOM Daemon**: Melindungi daemon `containerd`, `dockerd`, `lxc`, `sshd`, `mysqld`, dll. dari Android Low Memory Killer dengan mengunci `oom_score_adj=-900`.
- **Smart Battery Guard**: Watchdog cerdas di background. Jika HP ditancapkan charger 24/7 dan suhu baterai menyentuh > 46°C, script otomatis menurunkan clock A76 ke 1.8 GHz secara sementara. Begitu baterai dingin kembali (< 42°C), performa 2.2 GHz langsung dipulihkan. Ini menjaga baterai tidak kembung sambil tetap memberikan performa server maksimal!

---

## 🚀 Cara Pemasangan
1. Salin file `frenzy-g99-server-fusion-v2.0.zip` ke penyimpanan HP:
   ```bash
   adb push frenzy-g99-server-fusion-v2.0.zip /sdcard/Download/
   ```
2. Buka aplikasi **KernelSU** (atau Magisk / APatch).
3. Masuk ke tab **Modul** -> **Pasang dari penyimpanan**.
4. Pilih file `frenzy-g99-server-fusion-v2.0.zip`.
5. Reboot perangkat Anda.

## 📊 Verifikasi
Periksa log eksekusi setelah reboot:
```bash
su -c cat /data/local/tmp/frenzy_server.log
```
Pantau frekuensi core A76 saat menjalankan Geekbench 6 atau Droidspaces:
```bash
su -c cat /sys/devices/system/cpu/cpu6/cpufreq/scaling_cur_freq
```
*(Akan mencapai 2200000 KHz / 2.2 GHz).*
