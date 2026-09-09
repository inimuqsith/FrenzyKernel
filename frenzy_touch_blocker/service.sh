#!/system/bin/sh
# Frenzy Touch Blocker - Background Service
MODDIR=${0%/*}
LOGFILE="/data/local/tmp/touch_blocker.log"
BIN="${MODDIR}/bin/touch_blocker"

# Tunggu sampai input devices terdaftar
sleep 3

# Cari event node touchscreen mtk-tpd secara dinamis
TOUCH_EVENT=$(grep -A 5 -i "mtk-tpd" /proc/bus/input/devices 2>/dev/null | grep -E -o "event[0-9]+" | head -n 1)

if [ -z "$TOUCH_EVENT" ]; then
    # Fallback: Cari device input dengan nama tpd atau touch
    TOUCH_EVENT=$(grep -A 5 -iE "touch|tpd" /proc/bus/input/devices 2>/dev/null | grep -E -o "event[0-9]+" | head -n 1)
fi

[ -z "$TOUCH_EVENT" ] && TOUCH_EVENT="event3"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Frenzy Touch Blocker on /dev/input/${TOUCH_EVENT}..." > "$LOGFILE"

# Matikan instance lama jika ada
killall touch_blocker 2>/dev/null

# Jalankan daemon touch_blocker
if [ -x "$BIN" ]; then
    "$BIN" "/dev/input/${TOUCH_EVENT}" >> "$LOGFILE" 2>&1 &
    PID=$!
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Frenzy Touch Blocker running with PID ${PID} on /dev/input/${TOUCH_EVENT}." >> "$LOGFILE"
    sed -i "s|^description=.*|description=🔴 Touchscreen BLOCKED (PID: ${PID}, ${TOUCH_EVENT}). Tap Action to UNBLOCK.|g" "$MODDIR/module.prop"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: ${BIN} not executable!" >> "$LOGFILE"
fi
