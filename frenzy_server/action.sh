#!/system/bin/sh
MODDIR=${0%/*}
CLI="${MODDIR}/bin/frenzy-server"
[ ! -x "$CLI" ] && CLI="/data/adb/ksu/bin/frenzy-server"

if [ -x "$CLI" ]; then
    exec "$CLI" status
else
    echo "FrenzyServer CLI not found!"
fi
