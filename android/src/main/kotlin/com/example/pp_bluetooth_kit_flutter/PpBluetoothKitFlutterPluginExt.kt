package com.example.pp_bluetooth_kit_flutter

import android.content.Context
import com.lefu.ppbase.PPSDKKit
import com.lefu.ppbase.util.OnLogCallBack
import com.lefu.ppcalculate.PPCalculateKit
import com.peng.ppscale.PPBluetoothKit

fun PpBluetoothKitFlutterPlugin.initSDK(context: Context, appKey: String, appSecret: String, encryptStr: String) {
    /**
     * SDK日志打印
     * SDK日志写入文件，App内日志管理可控
     */
    PPSDKKit.setDebugLogCallBack(object : OnLogCallBack() {
        override fun logd(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun logi(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }

        }

        override fun logv(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun logw(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun loge(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }
    })

    /*********************以下内容为SDK的配置项***************************************/
    /**
     *  SDK日志打印控制，true会打印
     */
    PPBluetoothKit.setDebug(true)
    /**
     * PPBluetoothKit 蓝牙库初始化 所需参数需要自行到开放平台自行申请，请勿直接使用Demo中的参数，
     * Demo中的参数仅供Demo使用
     * @param appKey App的标识
     * @param appSecret Appp的密钥
     * @param configPath 在开放平台下载相应的配置文件以.config结尾，并放到assets目录下，将config文件全名传给SDK
     */
    PPBluetoothKit.setNetConfig(context, appKey, appSecret, encryptStr)
    /**
     * PPCalculateKit 计算库初始化
     */
    PPCalculateKit.initSdk(context)

}


fun PpBluetoothKitFlutterPlugin.setDeviceSetting(context: Context, encryptStr: String) {
    /**
     * SDK日志打印
     * SDK日志写入文件，App内日志管理可控
     */
    PPSDKKit.setDebugLogCallBack(object : OnLogCallBack() {
        override fun logd(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun logi(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }

        }

        override fun logv(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun logw(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }

        override fun loge(s: String?, s1: String?) {
            s1?.let { bleManager.loggerStreamHandler?.sendEvent(it) }
        }
    })


    /*********************以下内容为SDK的配置项***************************************/
    /**
     *  SDK日志打印控制，true会打印
     */
    PPBluetoothKit.setDebug(true)
    /**
     * PPBluetoothKit 蓝牙库初始化 所需参数需要自行到开放平台自行申请，请勿直接使用Demo中的参数，
     * Demo中的参数仅供Demo使用
     * @param appKey App的标识
     * @param appSecret Appp的密钥
     * @param configPath 在开放平台下载相应的配置文件以.config结尾，并放到assets目录下，将config文件全名传给SDK
     */
    PPBluetoothKit.initSdk(context, "", "", "")
    PPBluetoothKit.setDeviceConfigJsonStr(encryptStr)
    /**
     * PPCalculateKit 计算库初始化
     */
    PPCalculateKit.initSdk(context)

}