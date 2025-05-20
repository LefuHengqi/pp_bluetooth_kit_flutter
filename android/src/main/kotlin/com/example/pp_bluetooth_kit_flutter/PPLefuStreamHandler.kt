package com.example.pp_bluetooth_kit_flutter

import io.flutter.plugin.common.EventChannel

class PPLefuStreamHandler : EventChannel.StreamHandler {
    var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    fun sendEvent(event: Any) {
        this.eventSink?.success(event)
    }

    fun sendState(state: Any) {
        val map = mutableMapOf<String, Any?>()
        map.put("state", state)
        this.eventSink?.success(map)
    }

}