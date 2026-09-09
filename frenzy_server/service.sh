#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Ensure /dev/ntsync has 0666 permissions
[ -c /dev/ntsync ] && chmod 0666 /dev/ntsync 2>/dev/null

write() {
    [ -e "$1" ] && echo "$2" > "$1" 2>/dev/null
}

##########################################################################################
# PILAR 1: KERNEL TWEAKS & CFS SCHEDULER
##########################################################################################
write /proc/sys/kernel/sched_latency_ns 4000000
write /proc/sys/kernel/sched_min_granularity_ns 750000
write /proc/sys/kernel/sched_wakeup_granularity_ns 1000000
write /proc/sys/kernel/sched_migration_cost_ns 500000
write /proc/sys/kernel/sched_child_runs_first 0

# Virtual Memory & ZRAM
write /proc/sys/vm/vfs_cache_pressure 100
write /proc/sys/vm/swappiness 100
write /proc/sys/vm/page-cluster 0
write /proc/sys/vm/dirty_background_ratio 5
write /proc/sys/vm/dirty_ratio 15

# UCLAMP & Frequency Instant Ramp-Up
write /proc/sys/kernel/sched_util_clamp_min_default 50
write /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us 0
write /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us 10000
write /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us 0
write /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us 10000

# MediaTek PPM Uncap (A76 2.2 GHz)
write /proc/ppm/enabled 1
write /proc/ppm/policy/ut_fix_core_num "4 2"
write /proc/ppm/policy/ut_fix_freq_idx "0 0"

# TCP BBRv3 & Network
write /proc/sys/net/ipv4/tcp_congestion_control bbr
write /proc/sys/net/core/default_qdisc cake
write /proc/sys/net/ipv4/tcp_fastopen 3
write /proc/sys/net/ipv4/tcp_slow_start_after_idle 0

##########################################################################################
# PILAR 2: TOUCHSCREEN GHOST-TOUCH SHIELD
##########################################################################################
TOUCH_EVENT=$(grep -A 5 -i "mtk-tpd" /proc/bus/input/devices 2>/dev/null | grep -E -o "event[0-9]+" | head -n 1)
[ -z "$TOUCH_EVENT" ] && TOUCH_EVENT="event3"
if [ -f "${MODDIR}/bin/touch_blocker" ] && ! pidof touch_blocker >/dev/null 2>&1; then
    "${MODDIR}/bin/touch_blocker" "/dev/input/${TOUCH_EVENT}" >> /data/local/tmp/touch_blocker.log 2>&1 &
fi

##########################################################################################
# PILAR 3: FINGERPRINT KILLER & TOMBSTONE CLEANER
##########################################################################################
stop vendor.fps_hal 2>/dev/null
stop fsfingerprint-hal-2.0 2>/dev/null
setprop ctl.stop vendor.fps_hal 2>/dev/null
setprop ctl.stop fsfingerprint-hal-2.0 2>/dev/null
rmmod tran_fp 2>/dev/null

for tb in /data/tombstones/tombstone_*; do
    if grep -q "fingerprint@2.1" "$tb" 2>/dev/null; then
        rm -f "$tb" "${tb}.pb" 2>/dev/null
    fi
done

##########################################################################################
# PILAR 4: HEADLESS SERVER DEBLOAT (TIER 1)
##########################################################################################
if [ -x "${MODDIR}/bin/frenzy-server" ]; then
    "${MODDIR}/bin/frenzy-server" enable >/dev/null 2>&1
elif [ -x /data/adb/ksu/bin/frenzy-server ]; then
    /data/adb/ksu/bin/frenzy-server enable >/dev/null 2>&1
fi

##########################################################################################
# PILAR 5: SMART 24/7 BATTERY THERMAL GUARD & DAEMON PROTECTOR
##########################################################################################
(
    while true; do
        # 1. Anti-OOM Daemon Shield
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

        # 2. Smart Battery Thermal Guard
        batt_temp=0
        if [ -f /sys/class/power_supply/battery/temp ]; then
            raw_temp=$(cat /sys/class/power_supply/battery/temp)
            batt_temp=$((raw_temp / 10))
        fi

        if [ "$batt_temp" -ge 47 ]; then
            echo 1800000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 2>/dev/null
        elif [ "$batt_temp" -le 42 ] && [ "$batt_temp" -gt 0 ]; then
            echo 2200000 > /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq 2>/dev/null
        fi

        sleep 25
    done
) &

exit 0
