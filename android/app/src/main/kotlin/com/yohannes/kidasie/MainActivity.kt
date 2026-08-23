package com.yohannes.kidasie

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApkPath" -> result.success(applicationInfo.sourceDir)
                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        const val APP_CHANNEL = "com.yohannes.kidasie/app"
    }
}
