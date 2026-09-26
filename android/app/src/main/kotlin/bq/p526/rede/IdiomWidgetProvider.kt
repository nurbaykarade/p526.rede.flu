package bq.p526.rede

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Startbildschirm-Widget mit der Redewendung des Tages.
 *
 * Die App legt unter "days" die Redewendungen der nächsten Tage ab
 * ({"2026-09-27": {"id": 1, "text": "…", "meaning": "…"}, …}), damit das
 * Widget auch nach Mitternacht ohne geöffnete App weiterläuft.
 */
class IdiomWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    val entry =
        try {
          JSONObject(widgetData.getString("days", null) ?: "{}").optJSONObject(today)
        } catch (e: Exception) {
          null
        }

    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.idiom_widget).apply {
            if (entry != null) {
              setTextViewText(R.id.widget_text, "„${entry.optString("text")}“")
              setTextViewText(R.id.widget_meaning, entry.optString("meaning"))
            } else {
              setTextViewText(R.id.widget_text, "Redewendix")
              setTextViewText(R.id.widget_meaning, "Öffne die App für neue Redewendungen.")
            }
            val uri = entry?.let { Uri.parse("redewendix://idiom/${it.optInt("id")}") }
            setOnClickPendingIntent(
                R.id.widget_container,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri),
            )
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
