LOG "- Disabling encryption"
# Encryption
LINE=$(sed -n "/^\/dev\/block\/by-name\/userdata/=" "$WORK_DIR/vendor/etc/fstab.exynos2100")
sed -i "${LINE}s/,fileencryption=aes-256-xts:aes-256-cts:v2//g" "$WORK_DIR/vendor/etc/fstab.exynos2100"

LOG "- Fixing screenrecorder"
# OMX
sed -i '/^debug\.stagefright\.ccodec=/d' "$WORK_DIR/system/system/build.prop"
sed -i '/#Property to enable Codec2 for audio and OMX for Video/d' "$WORK_DIR/system/system/build.prop"

LOG "- Adjusting DPI"
# DPI
SET_PROP "vendor" "ro.sf.init.lcd_density" "$(GET_PROP "vendor" "ro.sf.lcd_density")"