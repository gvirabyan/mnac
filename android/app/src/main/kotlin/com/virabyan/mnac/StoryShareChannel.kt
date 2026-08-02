package com.virabyan.mnac

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Shares a rendered story image straight into the Instagram Stories composer,
 * skipping the system share sheet.
 *
 * Uses Instagram's documented ADD_TO_STORY intent. Since January 2023 Meta
 * requires a Facebook App ID in `source_application`; without it Instagram
 * opens and immediately reports that sharing is unsupported.
 */
object StoryShareChannel {
    const val CHANNEL = "com.virabyan.mnac/story_share"

    private const val INSTAGRAM_PACKAGE = "com.instagram.android"
    private const val ADD_TO_STORY = "com.instagram.share.ADD_TO_STORY"

    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isInstagramInstalled" -> result.success(isInstagramInstalled(activity))
            "shareToInstagramStory" -> shareToStory(activity, call, result)
            else -> result.notImplemented()
        }
    }

    private fun isInstagramInstalled(activity: Activity): Boolean = try {
        activity.packageManager.getPackageInfo(INSTAGRAM_PACKAGE, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun shareToStory(
        activity: Activity,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val imagePath = call.argument<String>("imagePath")
        val appId = call.argument<String>("appId")
        if (imagePath.isNullOrBlank() || appId.isNullOrBlank()) {
            result.error("bad_args", "imagePath and appId are required", null)
            return
        }

        val file = File(imagePath)
        if (!file.exists()) {
            result.error("missing_file", "Story image not found: $imagePath", null)
            return
        }

        try {
            val uri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.storyshare",
                file,
            )

            val intent = Intent(ADD_TO_STORY).apply {
                setDataAndType(uri, "image/png")
                putExtra("source_application", appId)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                `package` = INSTAGRAM_PACKAGE
            }

            // resolveActivity needs the <queries> entry in the manifest to see
            // Instagram at all on API 30+.
            if (intent.resolveActivity(activity.packageManager) == null) {
                result.success(false)
                return
            }

            // The intent flag alone is not enough on every OEM build; granting
            // explicitly keeps Instagram from failing to read the file.
            activity.grantUriPermission(
                INSTAGRAM_PACKAGE,
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("share_failed", e.message, null)
        }
    }
}
