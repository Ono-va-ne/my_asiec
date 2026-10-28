package com.onovane.my_asiec

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ScheduleWidgetProvider : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ScheduleWidget()
}

private data class WidgetScheduleEntry(
    val startTime: String,
    val endTime: String,
    val discipline: String,
    val room: String = "",
)

private class ScheduleWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val widgetData = context.getSharedPreferences(
                "HomeWidgetPreferences",
                Context.MODE_PRIVATE,
            )
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val dataDate = widgetData.getString("schedule_widget_date", "")
            val title = widgetData.getString("schedule_widget_title", "Расписание") ?: "Расписание"
            val entries = if (dataDate == today) {
                formatEntries(widgetData.getString("schedule_widget_entries", "[]") ?: "[]")
            } else {
                listOf(
                    WidgetScheduleEntry(
                        startTime = "",
                        endTime = "",
                        discipline = "Откройте приложение, чтобы обновить расписание.",
                    ),
                )
            }
            ScheduleContent(title, entries, context)
        }
    }

    @Composable
    private fun ScheduleContent(
        title: String,
        entries: List<WidgetScheduleEntry>,
        context: Context,
    ) {
        val background = ColorProvider(
            day = themeColor(context, com.google.android.material.R.attr.colorSurface, 0xFFF6F3FA.toInt()),
            night = themeColor(context, com.google.android.material.R.attr.colorSurface, 0xFF211F26.toInt()),
        )
        val primary = ColorProvider(
            day = themeColor(context, com.google.android.material.R.attr.colorPrimary, 0xFF5E4B7A.toInt()),
            night = themeColor(context, com.google.android.material.R.attr.colorPrimary, 0xFFD7BAFF.toInt()),
        )
        val onSurface = ColorProvider(
            day = themeColor(context, com.google.android.material.R.attr.colorOnSurface, 0xFF1D1B20.toInt()),
            night = themeColor(context, com.google.android.material.R.attr.colorOnSurface, 0xFFE8E0E9.toInt()),
        )
        val cardBackground = ColorProvider(
            day = themeColor(context, com.google.android.material.R.attr.colorSurface, 0xFFFFFFFF.toInt()),
            night = themeColor(context, com.google.android.material.R.attr.colorSurface, 0xFF302D35.toInt()),
        )
        val currentCardBackground = ColorProvider(
            day = themeColor(context, com.google.android.material.R.attr.colorPrimaryContainer, 0xFFEFE6FF.toInt()),
            night = themeColor(context, com.google.android.material.R.attr.colorPrimaryContainer, 0xFF3B2F47.toInt()),
        )

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(background)
                .padding(16.dp)
                .clickable(actionStartActivity(Intent(context, MainActivity::class.java))),
        ) {
            Text(
                text = "СЕГОДНЯ",
                style = TextStyle(
                    color = primary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
            Text(
                text = title,
                maxLines = 1,
                style = TextStyle(
                    color = onSurface,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
            LazyColumn(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(top = 10.dp),
            ) {
                items(entries) { entry ->
                    val isCurrent = isCurrentEntry(entry)
                    val progress = if (isCurrent) calculateProgress(entry) else 0f

                    Column(
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp)
                            .background(if (isCurrent) currentCardBackground else cardBackground)
                            .padding(10.dp),
                    ) {
                        if (isCurrent) {
                            Box(
                                modifier = GlanceModifier
                                    .fillMaxWidth()
                                    .height(4.dp)
                                    .background(primary),
                                content = {
                                    Box(
                                        modifier = GlanceModifier
                                            .width((progress * 100f).coerceIn(0f, 100f).dp)
                                            .fillMaxSize()
                                            .background(primary),
                                        content = {},
                                    )
                                },
                            )
                        }

                        Row(
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .padding(top = if (isCurrent) 8.dp else 0.dp),
                        ) {
                            Text(
                                text = buildString {
                                    if (entry.startTime.isNotBlank() && entry.endTime.isNotBlank()) {
                                        append(entry.startTime)
                                        append("–")
                                        append(entry.endTime)
                                    }
                                },
                                style = TextStyle(
                                    color = onSurface,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                ),
                            )
                        }

                        Text(
                            text = entry.discipline,
                            style = TextStyle(
                                color = onSurface,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium,
                            ),
                        )

                        if (entry.room.isNotBlank()) {
                            Text(
                                text = entry.room,
                                style = TextStyle(
                                    color = primary,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Medium,
                                ),
                            )
                        }
                    }
                }
            }
        }
    }

    private fun themeColor(context: Context, colorAttribute: Int, fallback: Int): Color {
        return try {
            val resolved = com.google.android.material.color.MaterialColors.getColor(
                context,
                colorAttribute,
                fallback,
            )
            Color(resolved)
        } catch (_: Exception) {
            Color(fallback)
        }
    }

    private fun formatEntries(rawEntries: String): List<WidgetScheduleEntry> {
        return try {
            val entries = JSONArray(rawEntries)
            if (entries.length() == 0) return listOf(
                WidgetScheduleEntry(
                    startTime = "",
                    endTime = "",
                    discipline = "Сегодня занятий нет",
                ),
            )

            buildList {
                for (index in 0 until entries.length()) {
                    val entry = entries.getJSONObject(index)
                    add(
                        WidgetScheduleEntry(
                            startTime = entry.optString("startTime"),
                            endTime = entry.optString("endTime"),
                            discipline = entry.optString("discipline"),
                            room = entry.optString("room"),
                        ),
                    )
                }
            }
        } catch (_: Exception) {
            listOf(
                WidgetScheduleEntry(
                    startTime = "",
                    endTime = "",
                    discipline = "Откройте приложение, чтобы обновить расписание.",
                ),
            )
        }
    }

    private fun isCurrentEntry(entry: WidgetScheduleEntry): Boolean {
        val startTime = parseTime(entry.startTime) ?: return false
        val endTime = parseTime(entry.endTime) ?: return false
        val now = System.currentTimeMillis()

        return now in startTime..endTime
    }

    private fun calculateProgress(entry: WidgetScheduleEntry): Float {
        val startTime = parseTime(entry.startTime) ?: return 0f
        val endTime = parseTime(entry.endTime) ?: return 0f
        val now = System.currentTimeMillis()
        if (endTime <= startTime) return 0f

        val elapsed = (now - startTime).coerceAtLeast(0L)
        val duration = endTime - startTime
        return if (duration <= 0L) 0f else (elapsed.toFloat() / duration.toFloat()).coerceIn(0f, 1f)
    }

    private fun parseTime(time: String): Long? {
        if (time.isBlank()) return null

        return try {
            val formatter = SimpleDateFormat("HH:mm", Locale.getDefault())
            val parsed = formatter.parse(time) ?: return null
            val calendar = java.util.Calendar.getInstance()
            calendar.time = parsed
            val now = java.util.Calendar.getInstance()
            now.set(java.util.Calendar.HOUR_OF_DAY, calendar.get(java.util.Calendar.HOUR_OF_DAY))
            now.set(java.util.Calendar.MINUTE, calendar.get(java.util.Calendar.MINUTE))
            now.set(java.util.Calendar.SECOND, 0)
            now.set(java.util.Calendar.MILLISECOND, 0)
            now.timeInMillis
        } catch (_: Exception) {
            null
        }
    }
}
