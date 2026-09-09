#!/system/bin/sh
##########################################################################################
# Frenzy G99 Server Master (FSM-G99)
# Fusion Engine: KTweak + YC-Scheduler/Uperf + MTK PPM/Thermal + Droidspaces Shield
# Author: Muqsith & FrenzyKernel
##########################################################################################

LOG_FILE="/data/local/tmp/frenzy_server.log"
exec > "$LOG_FILE" 2>&1

echo "=========================================================="
echo " Frenzy G99 Server Master (Fusion Edition) Initializing"
echo " Time: $(date)"
echo " Device: $(getprop ro.product.device) | SoC: Helio G99 (MT6789)"
echo " ROM: YAAP (AOSP) | Target: Droidspaces (LXC) Server"
echo "=========================================================="

# Safe write helper
write() {
    [ ! -f "$1" ] && return 1
    chmod +w "$1" 2>/dev/null
    echo "$2" > "$1" 2>/dev/null && echo "  [OK] $1 -> $2" || echo "  [FAIL] $1 -> $2"
}

# Tunggu sampai Android selesai booting sepenuhnya
echo "[0/5] Waiting for Android boot completion..."
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# Tunggu sejenak agar libperfmgr dan services selesai inisialisasi awal
sleep 5
echo "  [OK] Android boot completed. Starting optimization..."

# Otomatis aktifkan Tailscale di Host Android
echo "  [Tailscale] Activating Host Tailscale VPN..."
settings put secure always_on_vpn_app com.tailscale.ipn 2>/dev/null
am broadcast -a com.tailscale.ipn.CONNECT_VPN -n com.tailscale.ipn/.IPNReceiver >/dev/null 2>&1

##########################################################################################
# PILAR 1: FORK DARI KTWEAK (Scheduler & Memory Subsystem)
##########################################################################################
echo "----------------------------------------------------------"
echo "[1/5] Applying KTweak Evidence-Based Kernel Tweaks..."
echo "----------------------------------------------------------"

# Scheduler Latency & Granularity Tuning
SCHED_PERIOD=$((4 * 1000 * 1000))
SCHED_TASKS=8

write /proc/sys/kernel/sched_tunable_scaling 0
write /proc/sys/kernel/sched_latency_ns "$SCHED_PERIOD"
write /proc/sys/kernel/sched_min_granularity_ns "$((SCHED_PERIOD / SCHED_TASKS))"
write /proc/sys/kernel/sched_wakeup_granularity_ns "$((SCHED_PERIOD / 2))"

# 5ms migration cost: Mencegah task komputasi loncat liar antara A55 dan A76 (Cache Hotness)
write /proc/sys/kernel/sched_migration_cost_ns 5000000
write /proc/sys/kernel/sched_nr_migrate 32
write /proc/sys/kernel/sched_child_runs_first 1

# Matikan overhead scheduler stats dan perf limits
write /proc/sys/kernel/sched_schedstats 0
write /proc/sys/kernel/perf_cpu_time_max_percent 5
write /proc/sys/kernel/printk_devkmsg off

# Virtual Memory & ZRAM Tuning
write /proc/sys/vm/dirty_background_ratio 5
write /proc/sys/vm/dirty_ratio 20
write /proc/sys/vm/dirty_expire_centisecs 3000
write /proc/sys/vm/dirty_writeback_centisecs 3000
write /proc/sys/vm/page-cluster 0            # Krusial untuk ZRAM: hilangkan overhead read-ahead
write /proc/sys/vm/stat_interval 10          # Kurangi jitter CPU timer wakeup
write /proc/sys/vm/swappiness 40             # Optimal untuk server: memori swap stabil
write /proc/sys/vm/vfs_cache_pressure 100

# Block Storage I/O Optimization (Target UFS & eMMC physical storage)
for queue in /sys/block/sd*/queue /sys/block/mmcblk*/queue; do
    [ ! -d "$queue" ] && continue
    write "$queue/add_random" 0
    write "$queue/iostats" 0
    write "$queue/read_ahead_kb" 128
    write "$queue/nr_requests" 64
done

##########################################################################################
# PILAR 2: FORK DARI YC-SCHEDULER & UPERF (Governor & UCLAMP Tuning)
##########################################################################################
echo "----------------------------------------------------------"
echo "[2/5] Applying Governor & UCLAMP Performance Tuning..."
echo "----------------------------------------------------------"

# Tuning Governor Reflex (jika aktif)
for gov in /sys/devices/system/cpu/cpufreq/policy*/reflex; do
    [ ! -d "$gov" ] && continue
    # 2000us hispeed window: 2x lebih responsif mendeteksi lonjakan komputasi
    write "$gov/hispeed_window_us" 2000
    write "$gov/rate_limit_us" 500
    write "$gov/hispeed_filter_shift" 1
done

# Tuning Governor Schedutil (jika aktif)
for gov in /sys/devices/system/cpu/cpufreq/policy*/schedutil; do
    [ ! -d "$gov" ] && continue
    write "$gov/up_rate_limit_us" 0
    write "$gov/down_rate_limit_us" 2000
    write "$gov/rate_limit_us" 500
    write "$gov/hispeed_load" 85
    write "$gov/hispeed_freq" 2200000
done

# Dynamic UCLAMP Cgroup Tuning
if [ -d /dev/cpuctl ]; then
    write /dev/cpuctl/top-app/cpu.uclamp.min 50
    write /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive 1
    write /dev/cpuctl/foreground/cpu.uclamp.min 25
    write /dev/cpuctl/cpu.uclamp.min 20
    [ -f /dev/cpuctl/background/cpu.uclamp.latency_sensitive ] && write /dev/cpuctl/background/cpu.uclamp.latency_sensitive 1
fi

##########################################################################################
# PILAR 3: FORK DARI MTK THERMAL UNCAPPER (Pemberantas Throttling Helio G99)
##########################################################################################
echo "----------------------------------------------------------"
echo "[3/5] Disabling CPU Thermal Throttling Limits..."
echo "----------------------------------------------------------"

# Pastikan limit frekuensi maksimal CPU6-7 berada di 2.2 GHz
write /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 2000000
write /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 2200000

# Menaikkan threshold thermal zone CPU secara aman
for zone in /sys/class/thermal/thermal_zone*; do
    type=$(cat "$zone/type" 2>/dev/null)
    case "$type" in
        *cpu*|*soc*|*mtktscpu*|*cluster*)
            for trip in "$zone"/trip_point_*_temp; do
                [ ! -f "$trip" ] && continue
                curr_temp=$(cat "$trip" 2>/dev/null)
                if [ -n "$curr_temp" ] && [ "$curr_temp" -lt 85000 ] && [ "$curr_temp" -gt 45000 ]; then
                    write "$trip" 85000
                fi
            done
            ;;
    esac
done

##########################################################################################
# PILAR 4: FITUR BARU KUSTOM KAMI (Droidspaces Shield, Server Networking)
##########################################################################################
echo "----------------------------------------------------------"
echo "[4/5] Applying Droidspaces (LXC) Shield & Networking..."
echo "----------------------------------------------------------"

# 1. Droidspaces CPUSet Shield: Pastikan container diizinkan memakai seluruh Core 0-7
for cpuset in /dev/cpuset/top-app /dev/cpuset/foreground /dev/cpuset/background /dev/cpuset/system-background; do
    [ -f "$cpuset/cpus" ] && write "$cpuset/cpus" "0-7"
done

# Buka akses cpuset Droidspaces jika cgroup container ada
for dspaces_cgroup in /sys/fs/cgroup/cpuset/droidspaces /dev/cpuset/droidspaces; do
    [ -d "$dspaces_cgroup" ] && [ -f "$dspaces_cgroup/cpus" ] && write "$dspaces_cgroup/cpus" "0-7"
done

# Buka akses driver Windows NT Synchronization (/dev/ntsync) untuk Winlator/Mobox/Wine
[ -e /dev/ntsync ] && chmod 666 /dev/ntsync

# 2. Server High-Throughput Networking Stack (TCP BBR & Fastopen)
write /proc/sys/net/ipv4/tcp_fastopen 3
write /proc/sys/net/ipv4/tcp_ecn 1
write /proc/sys/net/ipv4/tcp_tw_reuse 1
write /proc/sys/net/ipv4/tcp_syncookies 1
write /proc/sys/net/core/somaxconn 1024
write /proc/sys/net/core/rmem_max 8388608
write /proc/sys/net/core/wmem_max 8388608

# Aktifkan BBR
if grep -q "bbr" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
    write /proc/sys/net/ipv4/tcp_congestion_control bbr
fi

# 3. Mute SELinux runtime audit log overhead
write /proc/sys/kernel/audit_rate_limit 0
# 4. Aktifkan Tier 1 Smart Headless Debloat secara otomatis
if [ -x /data/adb/ksu/bin/frenzy-server ]; then
    /data/adb/ksu/bin/frenzy-server enable >/dev/null 2>&1
elif [ -x "$MODDIR/bin/frenzy-server" ]; then
    "$MODDIR/bin/frenzy-server" enable >/dev/null 2>&1
fi

##########################################################################################
# PILAR 5: SMART 24/7 BATTERY THERMAL GUARD & DAEMON PROTECTOR
##########################################################################################
echo "----------------------------------------------------------"
echo "[5/5] Launching Smart Background Guard Daemon..."
echo "----------------------------------------------------------"

(
    while true; do
        # 1. Anti-OOM Daemon Shield: Lindungi proses server container Droidspaces dari LMK
        for proc in containerd dockerd lxc-start proot mysqld mongod node python nginx apache2 sshd droidspaces com.tailscale.ipn; do
            pids=$(pidof "$proc" 2>/dev/null)
            for pid in $pids; do
                if [ -f "/proc/$pid/oom_score_adj" ]; then
                    current=$(cat "/proc/$pid/oom_score_adj")
                    if [ "$current" -gt -800 ]; then
                        echo -900 > "/proc/$pid/oom_score_adj" 2>/dev/null
                    fi
                fi
            done
        done

        # Pastikan Tailscale Host selalu aktif
        if ! pidof com.tailscale.ipn >/dev/null 2>&1; then
            am broadcast -a com.tailscale.ipn.CONNECT_VPN -n com.tailscale.ipn/.IPNReceiver >/dev/null 2>&1
        fi

        # 2. Smart Battery Thermal Guard (Keamanan 24/7 Server Plugged-in)
        # SoC boleh panas hingga 80C+, tapi baterai WAJIB dijaga di bawah 47C agar tidak kembung!
        batt_temp=0
        if [ -f /sys/class/power_supply/battery/temp ]; then
            raw_temp=$(cat /sys/class/power_supply/battery/temp)
            batt_temp=$((raw_temp / 10))
        fi

        if [ "$batt_temp" -ge 47 ]; then
            # Baterai terlalu panas: turunkan frekuensi A76 sementara ke 1.8 GHz agar adem
            echo 1800000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 2>/dev/null
        elif [ "$batt_temp" -le 42 ] && [ "$batt_temp" -gt 0 ]; then
            # Baterai sudah dingin: pulihkan kembali ke 2.2 GHz maksimal!
            echo 2200000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 2>/dev/null
        fi

        sleep 25
    done
) &

echo "  [OK] Smart Background Guard Daemon running (PID: $!)."
echo "=========================================================="
echo " Frenzy G99 Server Master Optimization Successfully Applied!"
echo " Current Scaling Frequencies:"
for i in 0 1 2 3 4 5 6 7; do
    echo "  cpu$i: $(cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq 2>/dev/null)"
done
echo "=========================================================="
exit 0
