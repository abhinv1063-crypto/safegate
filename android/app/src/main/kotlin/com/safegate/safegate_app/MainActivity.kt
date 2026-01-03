package com.safegate.safegate_app

import io.flutter.embedding.android.FlutterActivity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.content.Context

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        // Create notification channels
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Panic alerts channel (for guard alerts to residents)
            val panicChannel = NotificationChannel(
                "panic_channel",
                "Panic Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for panic alerts"
                setSound(android.net.Uri.parse("android.resource://" + packageName + "/" + R.raw.siren), null)
            }

            // Resident emergency alerts channel (for resident alerts to guard)
            val residentPanicChannel = NotificationChannel(
                "resident_panic_channel",
                "Resident Emergency Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Emergency alerts from residents"
                setSound(android.net.Uri.parse("android.resource://" + packageName + "/" + R.raw.siren), null)
            }

            notificationManager.createNotificationChannel(panicChannel)
            notificationManager.createNotificationChannel(residentPanicChannel)
        }
    }
}
