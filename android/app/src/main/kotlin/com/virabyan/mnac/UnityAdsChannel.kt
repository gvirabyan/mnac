package com.virabyan.mnac

import android.app.Activity
import android.util.Log
import com.unity3d.ads.IUnityAdsInitializationListener
import com.unity3d.ads.IUnityAdsLoadListener
import com.unity3d.ads.IUnityAdsShowListener
import com.unity3d.ads.UnityAds
import com.unity3d.ads.UnityAdsShowOptions
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Unity Ads called directly, without AdMob in between.
 *
 * Used only while the app is in Armenian: AdMob's policies forbid ads beside
 * Armenian content, so in that mode the Mobile Ads SDK is never started and
 * Unity serves on its own. Every other language keeps going through AdMob,
 * with Unity as one of its mediated networks.
 *
 * The Unity Ads SDK itself is the one the AdMob Unity adapter already pulls
 * in; the app depends on the same version so Gradle doesn't have to choose.
 * A hand-written channel rather than a Flutter plugin because every plugin for
 * it also ships an iOS copy of the SDK, which would clash with the one the
 * adapter brings there — and this mode doesn't exist on iOS at all.
 *
 * Each call answers only once Unity has: `initialize` and `load` with null on
 * success or the error text, `show` once the ad has left the screen.
 */
object UnityAdsChannel {
    const val CHANNEL = "com.virabyan.mnac/unity_ads"
    private const val TAG = "UnityAdsChannel"

    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(activity, call, result)
            "load" -> load(call, result)
            "show" -> show(activity, call, result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        val gameId = call.argument<String>("gameId")
        if (gameId.isNullOrBlank()) {
            result.success("gameId is required")
            return
        }
        if (UnityAds.isInitialized) {
            result.success(null)
            return
        }
        val testMode = call.argument<Boolean>("testMode") ?: false
        val reply = OneShot(result)
        try {
            UnityAds.initialize(
                activity.applicationContext,
                gameId,
                testMode,
                object : IUnityAdsInitializationListener {
                    override fun onInitializationComplete() = reply.send(null)

                    override fun onInitializationFailed(
                        error: UnityAds.UnityAdsInitializationError?,
                        message: String?,
                    ) = reply.send("init failed: $error $message")
                },
            )
        } catch (e: Exception) {
            Log.w(TAG, "initialize threw", e)
            reply.send("init threw: ${e.message}")
        }
    }

    private fun load(call: MethodCall, result: MethodChannel.Result) {
        val placementId = call.argument<String>("placementId")
        if (placementId.isNullOrBlank()) {
            result.success("placementId is required")
            return
        }
        val reply = OneShot(result)
        try {
            UnityAds.load(
                placementId,
                object : IUnityAdsLoadListener {
                    override fun onUnityAdsAdLoaded(placementId: String?) = reply.send(null)

                    override fun onUnityAdsFailedToLoad(
                        placementId: String?,
                        error: UnityAds.UnityAdsLoadError?,
                        message: String?,
                    ) = reply.send("load failed: $error $message")
                },
            )
        } catch (e: Exception) {
            Log.w(TAG, "load threw", e)
            reply.send("load threw: ${e.message}")
        }
    }

    private fun show(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        val placementId = call.argument<String>("placementId")
        if (placementId.isNullOrBlank()) {
            result.success("placementId is required")
            return
        }
        val reply = OneShot(result)
        try {
            UnityAds.show(
                activity,
                placementId,
                UnityAdsShowOptions(),
                object : IUnityAdsShowListener {
                    override fun onUnityAdsShowFailure(
                        placementId: String?,
                        error: UnityAds.UnityAdsShowError?,
                        message: String?,
                    ) = reply.send("show failed: $error $message")

                    override fun onUnityAdsShowStart(placementId: String?) {}

                    override fun onUnityAdsShowClick(placementId: String?) {}

                    // Fires once the ad is closed, whether watched through or skipped.
                    override fun onUnityAdsShowComplete(
                        placementId: String?,
                        state: UnityAds.UnityAdsShowCompletionState?,
                    ) = reply.send(null)
                },
            )
        } catch (e: Exception) {
            Log.w(TAG, "show threw", e)
            reply.send("show threw: ${e.message}")
        }
    }

    /**
     * A channel result answers at most once, and Unity's listeners are not
     * guaranteed to be called exactly once — a second answer would crash.
     */
    private class OneShot(private val result: MethodChannel.Result) {
        private var sent = false

        fun send(error: String?) {
            if (sent) return
            sent = true
            result.success(error)
        }
    }
}
