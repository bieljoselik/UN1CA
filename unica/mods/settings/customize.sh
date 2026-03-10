DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

# Show real device model number
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes5/com/samsung/android/settings/deviceinfo/aboutphone/ModelNameGetter.smali" "replace" \
    'getModelName()Ljava/lang/String;' \
    'ro.product.model' \
    'ro.boot.em.model'

LOG_STEP_OUT
