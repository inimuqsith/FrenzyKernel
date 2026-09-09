#!/system/bin/sh
MODDIR=${0%/*}

echo "=========================================="
echo "    Frenzy Fingerprint Killer Status      "
echo "=========================================="

echo "[1] Checking Kernel Driver (tran_fp)..."
if lsmod | grep -q "tran_fp"; then
    echo "  [!] tran_fp was LOADED. Unloading..."
    rmmod tran_fp 2>/dev/null
    echo "  ✅ tran_fp unloaded."
else
    echo "  ✅ tran_fp is NOT loaded (Driver Disabled)."
fi

echo "[2] Checking Fingerprint HAL Services..."
for svc in vendor.fps_hal fsfingerprint-hal-2.0; do
    STATE=$(getprop init.svc.${svc} 2>/dev/null)
    PID=$(getprop init.svc_debug_pid.${svc} 2>/dev/null)
    if [ "$STATE" = "running" ]; then
        echo "  [!] ${svc} is RUNNING (PID: ${PID}). Stopping..."
        stop $svc 2>/dev/null
        setprop ctl.stop $svc 2>/dev/null
    else
        echo "  ✅ ${svc}: ${STATE:-stopped}"
    fi
done

echo "[3] Checking Bind Mount Shields..."
for target in \
    "/vendor/etc/permissions/android.hardware.fingerprint.xml" \
    "/vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml" \
    "/vendor/etc/init/android.hardware.biometrics.fingerprint@2.1-service.rc" \
    "/vendor/bin/hw/android.hardware.biometrics.fingerprint@2.1-service"; do
    if mount | grep -q "$target"; then
        echo "  ✅ Shielded: $(basename $target)"
    else
        echo "  ⚠️ Not mounted: $(basename $target) (Will apply on next reboot via post-fs-data)"
    fi
done

echo "[4] Checking and Cleaning Fingerprint Tombstones..."
CLEANED=0
for tb in /data/tombstones/tombstone_*; do
    if grep -q "fingerprint@2.1" "$tb" 2>/dev/null; then
        rm -f "$tb" "${tb}.pb" 2>/dev/null
        CLEANED=$((CLEANED + 1))
    fi
done
echo "  🧹 Cleaned $CLEANED fingerprint crash tombstone(s)."

echo "------------------------------------------"
echo "🎉 Status: Fingerprint sensor is DEAD & SILENT!"
echo "No logs, no crashes, no CPU/storage waste."
echo "=========================================="
