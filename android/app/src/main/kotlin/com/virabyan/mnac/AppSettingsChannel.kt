package com.virabyan.mnac

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Opens the app's notification settings in the system settings app.
 *
 * The escape hatch for a permission the user has refused: from Android 13 the
 * runtime prompt is offered twice, after which `requestPermissions` returns
 * false without showing anything and the toggle can only be flipped here.
 *
 * Falls back to the app's details page on anything older than Android 8, which
 * has no per-app notification screen to open.
 */
object AppSettingsChannel {
    const val CHANNEL = "com.virabyan.mnac/app_settings"

    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openNotificationSettings" -> result.success(open(activity))
            else -> result.notImplemented()
        }
    }

    private fun open(activity: Activity): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && start(activity, notificationSettings(activity))) {
            return true
        }
        return start(activity, appDetails(activity))
    }

    private fun notificationSettings(activity: Activity) =
        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)

    private fun appDetails(activity: Activity) =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", activity.packageName, null))

    private fun start(activity: Activity, intent: Intent): Boolean = try {
        activity.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: Exception) {
        // No settings activity resolves (heavily customised ROMs, work profiles).
        false
    }
}
