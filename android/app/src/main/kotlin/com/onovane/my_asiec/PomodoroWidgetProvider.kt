package com.onovane.my_asiec // Убедись, что пакет правильный!

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PomodoroWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: android.content.SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.pomodoro_widget_layout).apply {
                // Получаем данные, сохраненные из Flutter
                val sessionTitle = widgetData.getString("session_title", "Рабочий цикл")
                val time = widgetData.getString("time", "25:00")
                val status = widgetData.getString("status", "На паузе")

                // Устанавливаем текст в наши TextView
                setTextViewText(R.id.widget_session_title, sessionTitle)
                setTextViewText(R.id.widget_time, time)
                setTextViewText(R.id.widget_status, status)

                // Создаем Intent для запуска MainActivity
                val launchAppIntent = Intent(context, MainActivity::class.java)
                val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getActivity(context, 0, launchAppIntent, pendingIntentFlags)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
