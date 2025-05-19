package com.example.pp_bluetooth_kit_flutter.model

data class PPDfuPackageModel(
    val deviceSource: String,
    val packageVersion: String,
    val packages: PPDfuPackages
)

data class PPDfuPackages(
    val mcu: PPDfuPackageInfo?,
    val ble: PPDfuPackageInfo?,
    val res: PPDfuPackageInfo?
)

data class PPDfuPackageInfo(
    val filename: String,
    val version: String
)