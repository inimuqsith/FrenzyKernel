SKIPUNZIP=0

ui_print "**********************************************"
ui_print "    Frenzy Touch Blocker (Anti-Ghost Touch)   "
ui_print "       Hardware-Level Touchscreen Shield      "
ui_print "**********************************************"

ui_print "- Setting up permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/bin/touch_blocker" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755

ui_print "- Touch blocker module installed successfully!"
ui_print "- Ghost touch will be blocked automatically on boot."
ui_print "- You can use the Action button in KernelSU Manager to toggle touch ON/OFF anytime."
