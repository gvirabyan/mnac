package com.virabyan.mnac

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget showing days remaining until discharge.
 *
 * Data is written from Flutter via `home_widget` (see HomeWidgetService) and
 * read here from the shared preferences. Tapping the widget opens the app.
 */
class DepitunWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.depitun_widget).apply {
                val title = widgetData.getString("widget_title", "Մնաց")
                    ?: "Մնաց"
                val days = widgetData.getString("widget_days", "—") ?: "—"
                val discharge = widgetData.getString("widget_discharge", "") ?: ""

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_days, days)
                setTextViewText(R.id.widget_discharge, discharge)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
