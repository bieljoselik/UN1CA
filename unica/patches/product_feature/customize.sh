# [
GET_FINGERPRINT_SENSOR_TYPE()
{
    if [[ "$1" == *"ultrasonic"* ]]; then
        echo "ultrasonic"
    elif [[ "$1" == *"optical"* ]]; then
        echo "optical"
    elif [[ "$1" == *"side"* ]]; then
        echo "side"
    else
        ABORT "Unknown fingerprint sensor type: \"$1\". Aborting"
    fi
}

LOG_MISSING_PATCHES()
{
    local MESSAGE="Missing SPF patches for condition ($1: [${!1}], $2: [${!2}])"

    if $DEBUG; then
        LOGW "$MESSAGE"
    else
        ABORT "${MESSAGE}. Aborting"
    fi
}
# ]

# SEC_PRODUCT_FEATURE_BUILD_MAINLINE_API_LEVEL
if [[ "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" != "$TARGET_PRODUCT_SHIPPING_API_LEVEL" ]]; then
    SMALI_PATCH "system" "system/framework/esecomm.jar" \
        "smali/com/sec/esecomm/EsecommAdapter.smali" "replace" \
        "<clinit>()V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/enterprise/hdm/HdmSakManager.smali" "replace" \
        "isSupported(Landroid/content/Context;)Z" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/knox/dar/ddar/ta/TAProxy.smali" "replace" \
        "updateServiceHolder(Z)V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/SystemServer.smali" "replace" \
        "startOtherServices(Lcom/android/server/utils/TimingsTraceAndSlog;)V" \
        "MAINLINE_API_LEVEL: $SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "MAINLINE_API_LEVEL: $TARGET_PRODUCT_SHIPPING_API_LEVEL"
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/SystemServer.smali" "replace" \
        "startOtherServices(Lcom/android/server/utils/TimingsTraceAndSlog;)V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali_classes2/com/android/server/power/PowerManagerUtil.smali" "replace" \
        "<clinit>()V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali_classes2/com/android/server/sepunion/EngmodeService\$EngmodeTimeThread.smali" "replace" \
        "<clinit>()V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"
fi

# SEC_PRODUCT_FEATURE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION
if [[ "$SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" != "$TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" ]]; then
    if [[ "$SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" != "none" ]]; then
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "smali_classes6/com/samsung/android/camera/mic/SemMultiMicManager.smali" "replace" \
            "isSupported()Z" \
            "$SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" \
            "${TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION//none/}"
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "smali_classes6/com/samsung/android/camera/mic/SemMultiMicManager.smali" "replace" \
            "isSupported(I)Z" \
            "$SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" \
            "${TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION//none/}"
    else
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" "TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION"
    fi
fi

# SEC_PRODUCT_FEATURE_COMMON_CONFIG_MDNIE_MODE
if [[ "$SOURCE_COMMON_CONFIG_MDNIE_MODE" != "$TARGET_COMMON_CONFIG_MDNIE_MODE" ]]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_MDNIE_MODE" "$TARGET_COMMON_CONFIG_MDNIE_MODE"

    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali_classes2/com/samsung/android/hardware/display/SemMdnieManagerService.smali" "replace" \
        "<init>(Landroid/content/Context;)V" \
        "$SOURCE_COMMON_CONFIG_MDNIE_MODE" \
        "$TARGET_COMMON_CONFIG_MDNIE_MODE"
fi

# SEC_PRODUCT_FEATURE_COMMON_SUPPORT_EMBEDDED_SIM
if $SOURCE_COMMON_SUPPORT_EMBEDDED_SIM; then
    if ! $TARGET_COMMON_SUPPORT_EMBEDDED_SIM; then
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_EMBEDDED_SIM_SLOTSWITCH" --delete
    fi
else
    if $TARGET_COMMON_SUPPORT_EMBEDDED_SIM; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_COMMON_SUPPORT_EMBEDDED_SIM" "TARGET_COMMON_SUPPORT_EMBEDDED_SIM"
    fi
fi

# SEC_PRODUCT_FEATURE_SECURITY_SUPPORT_STRONGBOX
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/vendor/etc/permissions/android.hardware.strongbox_keystore.xml" ]; then
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "smali_classes6/com/samsung/android/service/DeviceIDProvisionService/DeviceIDProvisionManager\$DeviceIDProvisionWorker.smali" "return" \
        "isSupportStrongboxDeviceID()Z" \
        "false"
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MBO
if ! $SOURCE_WLAN_SUPPORT_MBO && $TARGET_WLAN_SUPPORT_MBO; then
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali" "return" \
        "isMBOSupported()Z" \
        "true"
elif $SOURCE_WLAN_SUPPORT_MBO && ! $TARGET_WLAN_SUPPORT_MBO; then
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali" "return" \
        "isMBOSupported()Z" \
        "false"
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY; then
    if $TARGET_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/5g_basedon_country/semwifi-service.jar/0001-Enable-MOBILEAP_5G_BASEDON_COUNTRY-support.patch"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali" "replaceall" \
            "SPF_5G_BASEDON_COUNTRY=false" \
            "SPF_5G_BASEDON_COUNTRY=true"
    fi
else
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY" "TARGET_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY"
    fi
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_6G
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_6G && $TARGET_WLAN_SUPPORT_MOBILEAP_6G; then
    ADD_TO_WORK_DIR "b0qxxx" "product" "overlay/SoftapOverlay6GHz/SoftapOverlay6GHz.apk" 0 0 644 "u:object_r:system_file:s0"

    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali" "replaceall" \
        "SPF_6G=false" \
        "SPF_6G=true"
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali" "return" \
        "isSupportMobileAp6G()Z" \
        "true"
elif $SOURCE_WLAN_SUPPORT_MOBILEAP_6G && ! $TARGET_WLAN_SUPPORT_MOBILEAP_6G; then
    DELETE_FROM_WORK_DIR "product" "overlay/SoftapOverlay6GHz"

    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali" "replaceall" \
        "SPF_6G=true" \
        "SPF_6G=false"
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali" "return" \
        "isSupportMobileAp6G()Z" \
        "false"
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_DUALAP
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_DUALAP; then
    if $TARGET_WLAN_SUPPORT_MOBILEAP_DUALAP; then
        ADD_TO_WORK_DIR "dm1qxxx" "product" "overlay/SoftapOverlayDualAp/SoftapOverlayDualAp.apk" 0 0 644 "u:object_r:system_file:s0"

        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/dualap/semwifi-service.jar/0001-Enable-MOBILEAP_DUALAP-support.patch"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali" "replaceall" \
            "SPF_DualAp=false" \
            "SPF_DualAp=true"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration\$6.smali" "remove"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration\$12.smali" "remove"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration\$16.smali" "remove"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$MODPATH/wifi/dualap/SecSettings.apk/0001-Enable-MOBILEAP_DUALAP-support.patch"
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "smali_classes3/com/samsung/android/settings/wifi/mobileap/WifiApSmartSwitchBackupRestore\$5.smali" "remove"
    fi
else
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_DUALAP; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_DUALAP" "TARGET_WLAN_SUPPORT_MOBILEAP_DUALAP"
    fi
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_OWE
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_OWE; then
    if $TARGET_WLAN_SUPPORT_MOBILEAP_OWE; then
        ADD_TO_WORK_DIR "dm1qxxx" "product" "overlay/SoftapOverlayOWE/SoftapOverlayOWE.apk" 0 0 644 "u:object_r:system_file:s0"

        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/owe/semwifi-service.jar/0001-Enable-MOBILEAP_OWE-support.patch"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali" "replaceall" \
            "SPF_OWE=false" \
            "SPF_OWE=true"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$MODPATH/wifi/owe/SecSettings.apk/0001-Enable-MOBILEAP_OWE-support.patch"
    fi
else
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_OWE; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_OWE" "TARGET_WLAN_SUPPORT_MOBILEAP_OWE"
    fi
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE
if $SOURCE_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE; then
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/power_savemode/semwifi-service.jar/0001-Disable-MOBILEAP_POWER_SAVEMODE-support.patch"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali" "replaceall" \
            "SPF_POWER_SAVEMODE=true" \
            "SPF_POWER_SAVEMODE=false"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemWifiApPowerSaveImpl\$\$ExternalSyntheticLambda0.smali" "remove"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemWifiApPowerSaveImpl\$\$ExternalSyntheticLambda1.smali" "remove"
    fi
else
    if $TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE" "TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE"
    fi
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC
if $SOURCE_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC; then
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC; then
        DELETE_FROM_WORK_DIR "system" "system/app/MhsAiService"
        DELETE_FROM_WORK_DIR "system" "system/etc/xgb_mhs_l1.model"

        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/prioritize_traffic/semwifi-service.jar/0001-Disable-MOBILEAP_PRIORITIZE_TRAFFIC-support.patch"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali" "replaceall" \
            "SPF_Prio_Traffic=true" \
            "SPF_Prio_Traffic=false"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$MODPATH/wifi/prioritize_traffic/SecSettings.apk/0001-Disable-MOBILEAP_PRIORITIZE_TRAFFIC-support.patch"
    fi
else
    if $TARGET_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC" "TARGET_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC"
    fi
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE; then
    if $TARGET_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE; then
        # Check for target flag instead as we've already took care of this SPF above
        if ! $TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE; then
            APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                "$MODPATH/wifi/power_savemode/semwifi-service.jar/0003-Enable-MOBILEAP_WIFISHARING_LITE-support.patch"
        else
            APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                "$MODPATH/wifi/wifisharing/semwifi-service.jar/0002-Enable-MOBILEAP_WIFISHARING_LITE-support.patch"
        fi
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali" "replaceall" \
            "SPF_WS_Lite=false" \
            "SPF_WS_Lite=true"
    fi
else
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE" "TARGET_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE"
    fi
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS
if $SOURCE_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS; then
    if ! $TARGET_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/individual_apps/semwifi-service.jar/0001-Disable-SWITCH_FOR_INDIVIDUAL_APPS-support.patch"
    fi
else
    if $TARGET_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS; then
        # TODO handle this condition
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS" "TARGET_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS"
    fi
fi

# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_WIFI_TO_CELLULAR
if ! $SOURCE_WLAN_SUPPORT_WIFI_TO_CELLULAR && $TARGET_WLAN_SUPPORT_WIFI_TO_CELLULAR; then
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali" "return" \
        "isWifiToCellularSupported()Z" \
        "true"
elif $SOURCE_WLAN_SUPPORT_WIFI_TO_CELLULAR && ! $TARGET_WLAN_SUPPORT_WIFI_TO_CELLULAR; then
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali" "return" \
        "isWifiToCellularSupported()Z" \
        "false"
fi

unset TARGET_FIRMWARE_PATH
unset -f GET_FINGERPRINT_SENSOR_TYPE LOG_MISSING_PATCHES