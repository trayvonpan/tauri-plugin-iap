package com.plugin.iap

import android.app.Activity
import app.tauri.annotation.TauriPlugin
import app.tauri.plugin.Plugin

@TauriPlugin
class IapPlugin(private val activity: Activity): Plugin(activity) {
    private val implementation = Iap()
}
