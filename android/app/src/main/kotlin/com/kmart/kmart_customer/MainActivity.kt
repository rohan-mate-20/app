package com.kmart.kmart_customer

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.Executor
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kmart/location"
    private val PLATFORM_CHANNEL = "kmart/platform"
    private var pendingLocationResult: MethodChannel.Result? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val PERMISSION_REQUEST_CODE = 2001
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 2002
    private val bgExecutor: Executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Platform Utilities Channel (Play Store, Phone Dialer, SMS, Notifications)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openPlayStore" -> {
                    val pkg = call.argument<String>("packageName") ?: packageName
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$pkg")).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$pkg")).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(webIntent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PLAY_STORE_ERROR", e.message, null)
                        }
                    }
                }
                "makePhoneCall" -> {
                    val phone = call.argument<String>("phoneNumber") ?: ""
                    try {
                        // Uses ACTION_DIAL which opens phone dialer safely without sensitive CALL_PHONE permission
                        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phone")).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DIAL_ERROR", e.message, null)
                    }
                }
                "openSms" -> {
                    val phone = call.argument<String>("phoneNumber") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("sms:$phone")).apply {
                            putExtra("sms_body", message)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SMS_ERROR", e.message, null)
                    }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                        if (!granted) {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                NOTIFICATION_PERMISSION_REQUEST_CODE
                            )
                        }
                        result.success(granted)
                    } else {
                        result.success(true)
                    }
                }
                "checkNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    } else {
                        result.success(true)
                    }
                }
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "K-Mart"
                    val body = call.argument<String>("body") ?: ""
                    val notificationId = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                    try {
                        createNotificationChannel()
                        val intent = Intent(this, MainActivity::class.java).apply {
                            action = Intent.ACTION_MAIN
                            addCategory(Intent.CATEGORY_LAUNCHER)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }
                        val pendingIntent = PendingIntent.getActivity(this, notificationId, intent, flags)

                        val smallIconResId = resources.getIdentifier("ic_stat_kmart", "drawable", packageName).let {
                            if (it != 0) it else applicationInfo.icon
                        }
                        val largeIcon = getAppIconBitmap()

                        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                            .setSmallIcon(smallIconResId)
                            .setColor(0xFFE53935.toInt())
                            .setContentTitle(title)
                            .setContentText(body)
                            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                            .setPriority(NotificationCompat.PRIORITY_HIGH)
                            .setDefaults(NotificationCompat.DEFAULT_ALL)
                            .setContentIntent(pendingIntent)
                            .setAutoCancel(true)

                        if (largeIcon != null) {
                            builder.setLargeIcon(largeIcon)
                        }

                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        notificationManager.notify(notificationId, builder.build())
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(hasLocationPermission())
                }
                "requestPermission" -> {
                    if (hasLocationPermission()) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            PERMISSION_REQUEST_CODE
                        )
                    }
                }
                "isLocationServiceEnabled" -> {
                    result.success(isLocationServiceEnabled())
                }
                "getCurrentLocation" -> {
                    handleGetCurrentLocation(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
        val coarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
        return fine == PackageManager.PERMISSION_GRANTED || coarse == PackageManager.PERMISSION_GRANTED
    }

    private fun isLocationServiceEnabled(): Boolean {
        val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
        val gps = try { lm.isProviderEnabled(LocationManager.GPS_PROVIDER) } catch (_: Exception) { false }
        val net = try { lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) } catch (_: Exception) { false }
        return gps || net
    }

    private fun handleGetCurrentLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            pendingLocationResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ),
                PERMISSION_REQUEST_CODE
            )
            return
        }

        if (!isLocationServiceEnabled()) {
            result.error("LOCATION_SERVICES_DISABLED", "Location services (GPS) are turned off.", null)
            return
        }

        fetchDeviceLocation(result)
    }

    private fun fetchDeviceLocation(result: MethodChannel.Result) {
        val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        if (lm == null) {
            result.error("UNAVAILABLE", "Location manager service is not available on this device.", null)
            return
        }

        var bestLocation: Location? = null
        val providers = lm.getProviders(true)
        for (provider in providers) {
            try {
                val l = lm.getLastKnownLocation(provider) ?: continue
                if (bestLocation == null || l.accuracy < bestLocation.accuracy) {
                    bestLocation = l
                }
            } catch (_: SecurityException) {
            }
        }

        if (bestLocation != null) {
            resolveLocationResult(bestLocation, result)
            return
        }

        val listener = object : LocationListener {
            override fun onLocationChanged(loc: Location) {
                try {
                    lm.removeUpdates(this)
                } catch (_: Exception) {}
                resolveLocationResult(loc, result)
            }
            override fun onProviderEnabled(p: String) {}
            override fun onProviderDisabled(p: String) {}
            @Deprecated("Deprecated in Java")
            override fun onStatusChanged(p: String?, s: Int, e: Bundle?) {}
        }

        var listenerRegistered = false
        val handler = Handler(Looper.getMainLooper())
        val timeoutRunnable = Runnable {
            try {
                lm.removeUpdates(listener)
            } catch (_: Exception) {}
            result.error("TIMEOUT", "Location request timed out. Please enter your address manually.", null)
        }

        for (provider in arrayOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER, LocationManager.PASSIVE_PROVIDER)) {
            try {
                if (lm.isProviderEnabled(provider)) {
                    lm.requestSingleUpdate(provider, listener, Looper.getMainLooper())
                    listenerRegistered = true
                    break
                }
            } catch (_: Exception) {}
        }

        if (listenerRegistered) {
            handler.postDelayed(timeoutRunnable, 10000)
        } else {
            result.error("UNAVAILABLE", "No location provider is available.", null)
        }
    }

    private fun resolveLocationResult(loc: Location, result: MethodChannel.Result) {
        val lat = loc.latitude
        val lng = loc.longitude

        bgExecutor.execute {
            var house: String? = null
            var area: String? = null
            var city: String? = null
            var state: String? = null
            var pincode: String? = null
            var addressLine: String? = null

            try {
                if (Geocoder.isPresent()) {
                    val geocoder = Geocoder(this@MainActivity, Locale.getDefault())
                    val addresses = geocoder.getFromLocation(lat, lng, 1)
                    if (!addresses.isNullOrEmpty()) {
                        val addr = addresses[0]
                        addressLine = addr.getAddressLine(0)
                        house = addr.featureName
                        area = addr.subLocality ?: addr.locality ?: addr.subAdminArea
                        city = addr.locality ?: addr.subAdminArea
                        state = addr.adminArea
                        pincode = addr.postalCode
                    }
                }
            } catch (_: Exception) {
            }

            Handler(Looper.getMainLooper()).post {
                val map = HashMap<String, Any?>()
                map["latitude"] = lat
                map["longitude"] = lng
                map["house"] = house
                map["area"] = area
                map["city"] = city
                map["state"] = state
                map["pincode"] = pincode
                map["addressLine"] = addressLine
                result.success(map)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (pendingPermissionResult != null) {
                pendingPermissionResult?.success(granted)
                pendingPermissionResult = null
            } else if (pendingLocationResult != null) {
                val res = pendingLocationResult
                pendingLocationResult = null
                if (granted) {
                    if (isLocationServiceEnabled()) {
                        fetchDeviceLocation(res!!)
                    } else {
                        res?.error("LOCATION_SERVICES_DISABLED", "Location services (GPS) are turned off.", null)
                    }
                } else {
                    res?.error("PERMISSION_DENIED", "Location permission was denied.", null)
                }
            }
        }
    }

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "kmart_orders_channel"
    }

    private fun getAppIconBitmap(): Bitmap? {
        return try {
            val drawable = ContextCompat.getDrawable(this, R.mipmap.ic_launcher) ?: return null
            if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 192
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 192
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bitmap
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "K-Mart Notifications"
            val descriptionText = "Order updates, status alerts and offers"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableLights(true)
                enableVibration(true)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
