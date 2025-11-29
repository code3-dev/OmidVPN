package com.pira.omid

import android.app.AlertDialog
import android.content.BroadcastReceiver
import android.content.Context
import android.content.DialogInterface
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "vpn_notification"
    private lateinit var disconnectReceiver: BroadcastReceiver
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationPermission" -> {
                    result.success(checkNotificationPermission())
                }
                "requestNotificationPermissionInApp" -> {
                    result.success(requestNotificationPermissionInApp())
                }
                "openAppSettingsForNotifications" -> {
                    openAppSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Register the AppList method channel
        AppListMethodChannel.registerWith(flutterEngine, this)
        
        // Register broadcast receiver for VPN disconnect
        disconnectReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "vpn_disconnect_action") {
                    // Send a message back to Flutter to handle the disconnection
                    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("disconnectVpn", null)
                }
            }
        }
        
        val filter = IntentFilter("vpn_disconnect_action")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(disconnectReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(disconnectReceiver, filter)
        }
    }
    
    // Check if notification permission is granted
    private fun checkNotificationPermission(): Boolean {
        return NotificationManagerCompat.from(this).areNotificationsEnabled()
    }
    
    // Request notification permission in app (returns true if already granted or if requested successfully)
    private fun requestNotificationPermissionInApp(): Boolean {
        if (checkNotificationPermission()) {
            return true
        }
        
        // For Android 13+ (Tiramisu), we need to request the permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // We can't request permission directly, need to open settings
            return false
        } else {
            // For older versions, permission is usually granted by default
            return true
        }
    }
    
    // Open app settings
    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        val uri = Uri.fromParts("package", packageName, null)
        intent.data = uri
        startActivity(intent)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(disconnectReceiver)
        } catch (e: Exception) {
            // Receiver not registered
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        OpenVPNFlutterPlugin.connectWhileGranted(requestCode == 24 && resultCode == RESULT_OK)
        super.onActivityResult(requestCode, resultCode, data)
    }
}