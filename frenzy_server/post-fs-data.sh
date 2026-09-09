#!/system/bin/sh
MODDIR=${0%/*}

# 1. Unload kernel driver tran_fp immediately
rmmod tran_fp 2>/dev/null

# 2. Mask Android PackageManager feature XML (prevents SystemServer from starting FingerprintService)
if [ -f /vendor/etc/permissions/android.hardware.fingerprint.xml ]; then
    chcon u:object_r:vendor_configs_file:s0 "${MODDIR}/etc/permissions/android.hardware.fingerprint.xml" 2>/dev/null
    mount -o bind "${MODDIR}/etc/permissions/android.hardware.fingerprint.xml" /vendor/etc/permissions/android.hardware.fingerprint.xml 2>/dev/null
fi

# 3. Mask VINTF manifest for fingerprint HAL
if [ -f /vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml ]; then
    chcon u:object_r:vendor_configs_file:s0 "${MODDIR}/etc/vintf/android.hardware.biometrics.fingerprint@2.1-service.xml" 2>/dev/null
    mount -o bind "${MODDIR}/etc/vintf/android.hardware.biometrics.fingerprint@2.1-service.xml" /vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml 2>/dev/null
fi

# 4. Mask init RC files to disable vendor.fps_hal and fsfingerprint-hal-2.0
if [ -f /vendor/etc/init/android.hardware.biometrics.fingerprint@2.1-service.rc ]; then
    chcon u:object_r:vendor_configs_file:s0 "${MODDIR}/etc/init/android.hardware.biometrics.fingerprint@2.1-service.rc" 2>/dev/null
    mount -o bind "${MODDIR}/etc/init/android.hardware.biometrics.fingerprint@2.1-service.rc" /vendor/etc/init/android.hardware.biometrics.fingerprint@2.1-service.rc 2>/dev/null
fi

if [ -f /vendor/etc/init/vendor.fptool.fingerprint@2.0-service.rc ]; then
    chcon u:object_r:vendor_configs_file:s0 "${MODDIR}/etc/init/vendor.fptool.fingerprint@2.0-service.rc" 2>/dev/null
    mount -o bind "${MODDIR}/etc/init/vendor.fptool.fingerprint@2.0-service.rc" /vendor/etc/init/vendor.fptool.fingerprint@2.0-service.rc 2>/dev/null
fi

# 5. Mask binaries with tiny_exit (safe 904-byte static binary returning 0)
if [ -f /vendor/bin/hw/android.hardware.biometrics.fingerprint@2.1-service ]; then
    chcon u:object_r:hal_fingerprint_default_exec:s0 "${MODDIR}/bin/tiny_exit" 2>/dev/null
    mount -o bind "${MODDIR}/bin/tiny_exit" /vendor/bin/hw/android.hardware.biometrics.fingerprint@2.1-service 2>/dev/null
fi

if [ -f /vendor/bin/hw/vendor.fptool.fingerprint@2.0-service ]; then
    chcon u:object_r:hal_fingerprint_default_exec:s0 "${MODDIR}/bin/tiny_exit" 2>/dev/null
    mount -o bind "${MODDIR}/bin/tiny_exit" /vendor/bin/hw/vendor.fptool.fingerprint@2.0-service 2>/dev/null
fi

# 6. Ensure /dev/ntsync has 0666 permissions early
[ -c /dev/ntsync ] && chmod 0666 /dev/ntsync 2>/dev/null
