MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

 LOG "- Adding \"ro.boot.uwbcountrycode\" prop with \"ff\" in /product/etc/build.prop"
 EVAL "sed -i \"/usb.config/a ro.boot.uwbcountrycode=ff\" \"$WORK_DIR/product/etc/build.prop\""

if [ -d "$FW_DIR/${MODEL}_${REGION}/vendor/firmware/uwb" ]; then
    LOG_STEP_IN "- Adding S24+ (e2sxxx) UWB blobs"
    ADD_TO_WORK_DIR "e2sxxx" "system" "system/app/UwbTest"
    ADD_TO_WORK_DIR "e2sxxx" "system" "system/etc/init/init.system.uwb.rc"
    ADD_TO_WORK_DIR "e2sxxx" "system" "system/etc/permissions/com.samsung.android.uwb_extras.xml"
    ADD_TO_WORK_DIR "e2sxxx" "system" "system/framework/com.samsung.android.uwb_extras.jar"
    ADD_TO_WORK_DIR "e2sxxx" "system" "system/lib64/libtflite_uwb_jni.so"
    LOG_STEP_OUT
else
    LOG "- Target has no UWB. Ignoring."
fi