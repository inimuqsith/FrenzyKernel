#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Ensure services are stopped
stop vendor.fps_hal 2>/dev/null
stop fsfingerprint-hal-2.0 2>/dev/null
setprop ctl.stop vendor.fps_hal 2>/dev/null
setprop ctl.stop fsfingerprint-hal-2.0 2>/dev/null

# Ensure kernel module tran_fp is unloaded
rmmod tran_fp 2>/dev/null

# Clean up fingerprint crash tombstones to save storage & remove log garbage
for tb in /data/tombstones/tombstone_*; do
    if grep -q "fingerprint@2.1" "$tb" 2>/dev/null; then
        rm -f "$tb" "${tb}.pb" 2>/dev/null
    fi
done

# Update description
sed -i "s|^description=.*|description=🟢 Fingerprint KILLED & SILENCED: tran_fp unloaded, HAL stopped, no crashes or tombstones.|g" "$MODDIR/module.prop"
