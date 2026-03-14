LOG "- Disabling encryption"
# Encryption
LINE=$(sed -n "/^\/dev\/block\/by-name\/userdata/=" "$WORK_DIR/vendor/etc/fstab.exynos2100")
sed -i "${LINE}s/,fileencryption=aes-256-xts:aes-256-cts:v2//g" "$WORK_DIR/vendor/etc/fstab.exynos2100"

LOG "- Fixing screenrecorder"
# OMX
SET_PROP "system" "debug.stagefright.ccodec" "0"
 
LOG "- Adjusting DPI"
# DPI
SET_PROP "vendor" "ro.sf.init.lcd_density" "$(GET_PROP "vendor" "ro.sf.lcd_density")"