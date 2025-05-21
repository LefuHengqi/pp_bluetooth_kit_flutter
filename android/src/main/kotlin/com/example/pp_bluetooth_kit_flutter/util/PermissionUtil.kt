package com.example.pp_bluetooth_kit_flutter.util

import android.Manifest
import android.content.Context
import android.content.Context.LOCATION_SERVICE
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import androidx.core.content.ContextCompat

object PermissionUtil {

    var strings = arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)

    var strings31BlePermission = arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_ADVERTISE)

    /**
     * 判断是否已经赋予权限
     *
     * @return
     */
    fun isHasBluetoothPermissions(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            for (permission in strings31BlePermission) {
                if (!(ContextCompat.checkSelfPermission(context, permission) === PackageManager.PERMISSION_GRANTED)) {
                    return false
                }
            }
        } else {
            for (permission in strings) {
                if (!(ContextCompat.checkSelfPermission(context, permission) === PackageManager.PERMISSION_GRANTED)) {
                    return false
                }
            }
            if (!isLocationEnabled(context)) {
                return false
            }
        }
        return true
    }

    fun isLocationEnabled(context: Context): Boolean {
        val locationManager = context.getSystemService(LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

}