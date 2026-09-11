SKIPUNZIP=0

ui_print "*****************************************************"
ui_print "       ⚡ FrenzyServer All-in-One Engine ⚡         "
ui_print "     Linux Server Fusion for Android GKI 5.10        "
ui_print "       ROM: YAAP (AOSP) | Target: Droidspaces        "
ui_print "*****************************************************"

# 1. Bersihkan modul standalone lama jika ada
ui_print "- Memeriksa dan membersihkan modul standalone lama..."
for old_mod in frenzy_g99_server_fusion frenzy_touch_blocker frenzy_fp_killer; do
    if [ -d "/data/adb/modules/$old_mod" ]; then
        ui_print "  • Menggabungkan & menghapus modul lama: $old_mod"
        rm -rf "/data/adb/modules/$old_mod" 2>/dev/null
    fi
done

# 2. Permissions
ui_print "- Menyetel executable permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/system/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/webroot/cgi-bin" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755

# 3. Pasang CLI ke /data/adb/ksu/bin agar langsung aktif
ui_print "- Memasang FrenzyServer CLI ke sistem..."
mkdir -p /data/adb/ksu/bin
cp "$MODPATH/bin/frenzy-server" /data/adb/ksu/bin/frenzy-server 2>/dev/null
chmod 755 /data/adb/ksu/bin/frenzy-server 2>/dev/null
ln -sf /data/adb/ksu/bin/frenzy-server /data/adb/ksu/bin/frenzy-debloat 2>/dev/null

ui_print " "
ui_print "  [✓] Pilar 1: Android GKI Server Engine (CFS 4ms, UCLAMP, NTSync 0666)"
ui_print "  [✓] Pilar 2: Touchscreen Shield (Anti-Ghost Touch ioctl)"
ui_print "  [✓] Pilar 3: Fingerprint Killer (Crash Loops Neutralized)"
ui_print "  [✓] Pilar 4: Headless Debloat (29 Bloat Apps & Camera HAL Frozen)"
ui_print "  [✓] Pilar 5: WebUI & CLI Controller (/data/adb/ksu/bin/frenzy-server)"
ui_print " "
ui_print "- FrenzyServer berhasil dipasang!"
ui_print "*****************************************************"
