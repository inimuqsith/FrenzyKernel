#!/system/bin/sh
SKIPUNZIP=1

ui_print "*****************************************************"
ui_print "       Frenzy G99 Server Master (FSM-G99)           "
ui_print "   Smart Fusion: KTweak + YC-Scheduler + MTK-PPM     "
ui_print "      Tailored for Tecno Pova 4 Pro (LG8n)           "
ui_print "       ROM: YAAP (AOSP) | Target: Droidspaces        "
ui_print "*****************************************************"

# Ekstraksi file modul
ui_print "- Mengekstrak file modul..."
unzip -o "$ZIPFILE" 'module.prop' 'service.sh' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'bin/*' -d "$MODPATH" >&2

# Atur permissions
ui_print "- Menyetel executable permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755
[ -d "$MODPATH/bin" ] && set_perm_recursive "$MODPATH/bin" 0 0 0755 0755

# Pasang CLI ke /data/adb/ksu/bin
if [ -f "$MODPATH/bin/frenzy-server" ]; then
    cp "$MODPATH/bin/frenzy-server" /data/adb/ksu/bin/frenzy-server 2>/dev/null
    chmod 755 /data/adb/ksu/bin/frenzy-server 2>/dev/null
    ln -sf /data/adb/ksu/bin/frenzy-server /data/adb/ksu/bin/frenzy-debloat 2>/dev/null
fi

# Deteksi Hardware
PLATFORM=$(getprop ro.board.platform)
HARDWARE=$(getprop ro.hardware)
DEVICE=$(getprop ro.product.device)
MODEL=$(getprop ro.product.model)
ui_print "- Perangkat: $MODEL ($DEVICE)"
ui_print "- Chipset  : $PLATFORM / $HARDWARE"

ui_print " "
ui_print "  [✓] Pilar 1: KTweak Engine (CFS 4ms, ZRAM page-cluster, UFS I/O)"
ui_print "  [✓] Pilar 2: YC-Scheduler (Instant 0us Ramp-up, UCLAMP 50)"
ui_print "  [✓] Pilar 3: MediaTek PPM Uncap (A76 2.2 GHz Unlocked)"
ui_print "  [✓] Pilar 4: Droidspaces Shield (Cgroup Full 0-7, TCP BBR)"
ui_print "  [✓] Pilar 5: Smart Battery Guard (Auto-Protect if Batt > 46°C)"
ui_print " "
ui_print "- Modul berhasil dipasang! Silakan REBOOT perangkat Anda."
ui_print "*****************************************************"
