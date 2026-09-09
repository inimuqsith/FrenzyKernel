SKIPUNZIP=0

ui_print "**********************************************"
ui_print "       Frenzy Fingerprint Killer v1.0         "
ui_print "   Broken Hardware Shield & Crash Neutralizer "
ui_print "**********************************************"

ui_print "- Setting permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/bin/tiny_exit" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755

ui_print "- Unloading tran_fp kernel driver..."
rmmod tran_fp 2>/dev/null

ui_print "- Stopping fingerprint HAL daemons..."
stop vendor.fps_hal 2>/dev/null
stop fsfingerprint-hal-2.0 2>/dev/null

ui_print "- Fingerprint Killer installed successfully!"
ui_print "- Reboot to apply complete framework-level masking."
