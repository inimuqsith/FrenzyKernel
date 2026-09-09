#!/system/bin/sh
# Frenzy Touch Blocker - 1-Click Toggle Action
MODDIR=${0%/*}
BIN="${MODDIR}/bin/touch_blocker"
LOGFILE="/data/local/tmp/touch_blocker.log"

echo "=========================================="
echo "    Frenzy Touch Blocker Controller       "
echo "=========================================="

PID=$(pidof touch_blocker 2>/dev/null)

if [ -n "$PID" ]; then
    echo "[!] Touch blocker saat ini AKTIF (PID: ${PID})."
    echo "[*] Menghentikan touch blocker..."
    kill -9 $PID 2>/dev/null
    sleep 1
    sed -i "s|^description=.*|description=🟢 Touchscreen UNBLOCKED (Sentuhan Normal Aktif). Tap Action to BLOCK.|g" "$MODDIR/module.prop"
    echo "------------------------------------------"
    echo "✅ SUKSES: Touchscreen TELAH DIAKTIFKAN!"
    echo "Layar sekarang bisa disentuh normal kembali."
    echo "=========================================="
else
    echo "[!] Touch blocker saat ini NONAKTIF."
    echo "[*] Menemukan event node touchscreen..."
    TOUCH_EVENT=$(grep -A 5 -i "mtk-tpd" /proc/bus/input/devices 2>/dev/null | grep -E -o "event[0-9]+" | head -n 1)
    [ -z "$TOUCH_EVENT" ] && TOUCH_EVENT="event3"
    
    echo "[*] Mengaktifkan blokir sentuhan pada /dev/input/${TOUCH_EVENT}..."
    "$BIN" "/dev/input/${TOUCH_EVENT}" >> "$LOGFILE" 2>&1 &
    NEW_PID=$!
    sleep 1
    sed -i "s|^description=.*|description=🔴 Touchscreen BLOCKED (PID: ${NEW_PID}, ${TOUCH_EVENT}). Tap Action to UNBLOCK.|g" "$MODDIR/module.prop"
    echo "------------------------------------------"
    echo "🛡️ SUKSES: Touchscreen TELAH DIBLOKIR!"
    echo "Ghost touch / sentuhan layar dinonaktifkan (PID: ${NEW_PID})."
    echo "=========================================="
fi
