package com.kmart.kmart_customer

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.Executor
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kmart/location"
    private var pendingLocationResult: MethodChannel.Result? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val PERMISSION_REQUEST_CODE = 2001
    private val bgExecutor: Executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
}
