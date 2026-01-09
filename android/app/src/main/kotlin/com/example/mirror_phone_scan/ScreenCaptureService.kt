package com.example.mirror_phone_scan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ScreenCaptureService : Service() {
    companion object {
        const val CHANNEL_ID = "ScreenCaptureChannel"
        const val NOTIFICATION_ID = 1
        const val ACTION_STOP_MIRRORING = "com.example.mirror_phone_scan.STOP_MIRRORING"
        const val BROADCAST_CLEANUP = "com.example.mirror_phone_scan.CLEANUP"
    }

    override fun onCreate() {
        super.onCreate()
        android.util.Log.d("ScreenCaptureService", "Service onCreate() called")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        android.util.Log.d("ScreenCaptureService", "Service onStartCommand() called")
        
        // Handle stop action from notification
        if (intent?.action == ACTION_STOP_MIRRORING) {
            android.util.Log.d("ScreenCaptureService", "Stop action received from notification")
            performCleanup()
            stopSelf()
            return START_NOT_STICKY
        }
        
        val notification = createNotification()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            android.util.Log.d("ScreenCaptureService", "Starting foreground with MEDIA_PROJECTION type")
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        
        android.util.Log.d("ScreenCaptureService", "✅ Service is now in foreground mode")
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    /**
     * Called when app is removed from recent apps (killed by user)
     * This is critical for proper cleanup when app is force-stopped
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        android.util.Log.d("ScreenCaptureService", "⚠️ App task removed - performing cleanup")
        performCleanup()
        stopSelf()
    }

    /**
     * Perform cleanup and notify Flutter side
     */
    private fun performCleanup() {
        try {
            android.util.Log.d("ScreenCaptureService", "🧹 Performing cleanup...")
            
            // Send broadcast to notify Flutter side to cleanup
            val cleanupIntent = Intent(BROADCAST_CLEANUP)
            sendBroadcast(cleanupIntent)
            
            android.util.Log.d("ScreenCaptureService", "✅ Cleanup broadcast sent")
        } catch (e: Exception) {
            android.util.Log.e("ScreenCaptureService", "❌ Error during cleanup: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Mirroring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Screen mirroring is active"
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        // Create stop action intent
        val stopIntent = Intent(this, ScreenCaptureService::class.java).apply {
            action = ACTION_STOP_MIRRORING
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Mirror Phone")
            .setContentText("Screen mirroring is active")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop Mirroring",
                stopPendingIntent
            )
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        android.util.Log.d("ScreenCaptureService", "Service onDestroy() called")
        super.onDestroy()
        stopForeground(STOP_FOREGROUND_REMOVE)
    }
}
