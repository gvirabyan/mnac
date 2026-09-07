package com.virabyan.mnac

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.io.File

/**
 * Home-screen widget showing days remaining until discharge.
 *
 * All soldiers are written from Flutter via `home_widget` (see
 * HomeWidgetService) as a JSON list. The widget shows one at a time; the "next"
 * button pages through them (hidden when only one soldier exists). Tapping the
 * card opens the app. When a soldier has a photo it is drawn behind the text
 * (with a scrim), mirroring the app's home background.
 */
class DepitunWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val ACTION_NEXT = "com.virabyan.mnac.WIDGET_NEXT"
        private const val DATA_PREFS = "HomeWidgetPreferences"
        private const val STATE_PREFS = "DepitunWidgetState"
        private const val KEY_SOLDIERS = "widget_soldiers"
        private const val KEY_INDEX = "index"

        // Mirrors the palette baked into depitun_widget.xml and the iOS view.
        private const val COLOR_INK = 0xFF1E1B16.toInt()
        private const val COLOR_MUTED = 0xFF8A8276.toInt()
        private const val COLOR_ON_PHOTO = 0xFFFFFFFF.toInt()
        private const val COLOR_ON_PHOTO_MUTED = 0xD9FFFFFF.toInt()
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { renderWidget(context, appWidgetManager, it, widgetData) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_NEXT) return

        val data = context.getSharedPreferences(DATA_PREFS, Context.MODE_PRIVATE)
        val count = parseSoldiers(data).length()
        if (count > 1) {
            val state = context.getSharedPreferences(STATE_PREFS, Context.MODE_PRIVATE)
            val next = (state.getInt(KEY_INDEX, 0) + 1) % count
            state.edit().putInt(KEY_INDEX, next).apply()
        }

        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, DepitunWidgetProvider::class.java),
        )
        ids.forEach { renderWidget(context, manager, it, data) }
    }

    private fun renderWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val soldiers = parseSoldiers(widgetData)
        val count = soldiers.length()
        val state = context.getSharedPreferences(STATE_PREFS, Context.MODE_PRIVATE)
        var index = state.getInt(KEY_INDEX, 0)
        if (index >= count) {
            index = 0
            state.edit().putInt(KEY_INDEX, 0).apply()
        }

        val views = RemoteViews(context.packageName, R.layout.depitun_widget).apply {
            if (count == 0) {
                setTextViewText(R.id.widget_title, "Մնաց")
                setTextViewText(R.id.widget_days, "—")
                setTextViewText(R.id.widget_percent, "")
                setTextViewText(R.id.widget_discharge, "")
                setViewVisibility(R.id.widget_bg, View.GONE)
                setViewVisibility(R.id.widget_scrim, View.GONE)
                setViewVisibility(R.id.widget_next, View.GONE)
                applyTextColors(overPhoto = false)
            } else {
                val s = soldiers.getJSONObject(index)
                setTextViewText(R.id.widget_title, s.optString("title", "Մնաց"))
                setTextViewText(R.id.widget_days, s.optString("days", "—"))
                setTextViewText(R.id.widget_percent, s.optString("percent", ""))
                setTextViewText(R.id.widget_discharge, s.optString("discharge", ""))

                val bitmap = decodeBackground(s.optString("photoPath", ""))
                if (bitmap != null) {
                    setImageViewBitmap(R.id.widget_bg, bitmap)
                    setViewVisibility(R.id.widget_bg, View.VISIBLE)
                    setViewVisibility(R.id.widget_scrim, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_bg, View.GONE)
                    setViewVisibility(R.id.widget_scrim, View.GONE)
                }
                applyTextColors(overPhoto = bitmap != null)

                if (count > 1) {
                    setViewVisibility(R.id.widget_next, View.VISIBLE)
                    val nextIntent = Intent(context, DepitunWidgetProvider::class.java)
                        .apply { action = ACTION_NEXT }
                    val pendingNext = PendingIntent.getBroadcast(
                        context,
                        0,
                        nextIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    setOnClickPendingIntent(R.id.widget_next, pendingNext)
                } else {
                    setViewVisibility(R.id.widget_next, View.GONE)
                }
            }

            val openApp = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
            )
            setOnClickPendingIntent(R.id.widget_root, openApp)
        }
        manager.updateAppWidget(widgetId, views)
    }

    /**
     * Recolours the labels for what sits behind them. Every soldier now gets a
     * photo — their own or the app's default backdrop — and those are dark
     * enough that the card palette's ink would be unreadable on top, so the
     * text goes white over a photo and back to ink on the bare cream card.
     * The day count keeps the accent colour either way.
     */
    private fun RemoteViews.applyTextColors(overPhoto: Boolean) {
        val primary = if (overPhoto) COLOR_ON_PHOTO else COLOR_INK
        val secondary = if (overPhoto) COLOR_ON_PHOTO_MUTED else COLOR_MUTED
        setTextColor(R.id.widget_title, secondary)
        setTextColor(R.id.widget_days_unit, primary)
        setTextColor(R.id.widget_subtitle, primary)
        setTextColor(R.id.widget_percent, primary)
        setTextColor(R.id.widget_discharge, secondary)
    }

    private fun parseSoldiers(prefs: SharedPreferences): JSONArray {
        val raw = prefs.getString(KEY_SOLDIERS, "[]") ?: "[]"
        return try {
            JSONArray(raw)
        } catch (_: Throwable) {
            JSONArray()
        }
    }

    /**
     * Decodes the background photo at [path], downscaled so the bitmap stays
     * well under the RemoteViews transaction limit. Returns null when the path
     * is empty, the file is missing, or decoding fails.
     */
    private fun decodeBackground(path: String): Bitmap? {
        if (path.isEmpty()) return null
        val file = File(path)
        if (!file.exists()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0) return null

            // A RemoteViews update crosses Binder, which caps a transaction at
            // ~1 MB, and the bitmap travels inside it. 500px of ARGB_8888 came
            // to roughly 1.7 MB — over the limit, so the host gave up with
            // "Problem loading widget". 320px of RGB_565 is around 0.3 MB and
            // still sharper than any home-screen widget can show; the photo is
            // a full-bleed backdrop, so it has no alpha to lose.
            val target = 320
            var sample = 1
            var longest = maxOf(bounds.outWidth, bounds.outHeight)
            while (longest / 2 >= target) {
                sample *= 2
                longest /= 2
            }
            val opts = BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.RGB_565
            }
            BitmapFactory.decodeFile(path, opts)
        } catch (_: Throwable) {
            null
        }
    }
}
