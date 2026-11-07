package com.virabyan.mnac

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            StoryShareChannel.CHANNEL,
        ).setMethodCallHandler { call, result ->
            StoryShareChannel.handle(this, call, result)
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AppSettingsChannel.CHANNEL,
        ).setMethodCallHandler { call, result ->
            AppSettingsChannel.handle(this, call, result)
        }
    }
}
