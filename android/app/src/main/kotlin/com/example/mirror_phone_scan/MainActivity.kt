package com.example.mirror_phone_scan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mirror_phone_scan/screen_capture"
    private var methodChannel: MethodChannel? = null
    private var cleanupReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    try {
                        startScreenCaptureService()
                        // Give the service time to call startForeground()
                        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                            result.success(true)
                        }, 1000)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "stopForegroundService" -> {
                    stopScreenCaptureService()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Register broadcast receiver for cleanup signals
        setupCleanupReceiver()
    }

    private fun setupCleanupReceiver() {
        cleanupReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == ScreenCaptureService.BROADCAST_CLEANUP) {
                    android.util.Log.d("MainActivity", "Received cleanup broadcast from service")
                    // Notify Flutter side to cleanup
                    methodChannel?.invokeMethod("onCleanup", null)
                }
            }
        }

        val filter = IntentFilter(ScreenCaptureService.BROADCAST_CLEANUP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(cleanupReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(cleanupReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Unregister broadcast receiver
        cleanupReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Error unregistering receiver: ${e.message}")
            }
        }
    }

    private fun startScreenCaptureService() {
        val serviceIntent = Intent(this, ScreenCaptureService::class.java)
        androidx.core.content.ContextCompat.startForegroundService(this, serviceIntent)
    }

    private fun stopScreenCaptureService() {
        val serviceIntent = Intent(this, ScreenCaptureService::class.java)
        stopService(serviceIntent)
    }
}
