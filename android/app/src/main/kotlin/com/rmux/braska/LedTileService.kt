package com.rmux.braska

import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import androidx.annotation.RequiresApi
import java.net.HttpURLConnection
import java.net.URL
import java.io.OutputStreamWriter
import kotlin.concurrent.thread

@RequiresApi(Build.VERSION_CODES.N)
class LedTileService : TileService() {
    
    private fun getPrefs(): SharedPreferences {
        return getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    override fun onStartListening() {
        super.onStartListening()
        updateTileUI()
    }

    override fun onClick() {
        super.onClick()
        val prefs = getPrefs()
        val profilesStr = prefs.getString("flutter.ps4_led_profiles", "white,blue,red,off") ?: "white,blue,red,off"
        val ledsLen = profilesStr.split(",").filter { it.isNotEmpty() }.size
        var idx = prefs.getLong("flutter.ps4_tile_led_idx", 0L).toInt()
        idx = (idx + 1) % (if (ledsLen > 0) ledsLen else 1)
        prefs.edit().putLong("flutter.ps4_tile_led_idx", idx.toLong()).apply()
        
        updateTileUI()

        // Capture the current index value to prevent race conditions in the background thread
        val currentIdx = idx
        
        thread {
            val urlStr = prefs.getString("flutter.ps4_addr", "") ?: ""
            val token = prefs.getString("flutter.ps4_token", "") ?: ""
            
            if (urlStr.isEmpty()) return@thread
            
            try {
                val fullUrl = if (urlStr.startsWith("http")) "$urlStr/api/led" else "http://$urlStr/api/led"
                val url = URL(fullUrl)
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Content-Type", "application/json")
                if (token.isNotEmpty()) {
                    conn.setRequestProperty("Authorization", "Bearer $token")
                }
                conn.doOutput = true
                
                val profilesStr = prefs.getString("flutter.ps4_led_profiles", "white,blue,red,white_pulsing,blue_pulsing,red_pulsing,green,pink,off") ?: "white,blue,red,off"
                val leds = profilesStr.split(",").filter { it.isNotEmpty() }.toTypedArray()
                // Use captured index and ensure it's within bounds
                val safeIdx = if (leds.isEmpty()) 0 else currentIdx.coerceIn(0, leds.size - 1)
                val led = leds[safeIdx]
                val json = """{"profile": "$led"}"""
                
                OutputStreamWriter(conn.outputStream).use { it.write(json) }
                val responseCode = conn.responseCode
                println("LedTileService: POST returned $responseCode for $led")
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun updateTileUI() {
        val tile = qsTile ?: return
        val prefs = getPrefs()
        val urlStr = prefs.getString("flutter.ps4_addr", "") ?: ""
        
        if (urlStr.isEmpty()) {
            tile.label = "PS4 LED"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = "App Setup Rqd"
            }
            tile.state = Tile.STATE_UNAVAILABLE
            tile.updateTile()
            return
        }

        val idx = prefs.getLong("flutter.ps4_tile_led_idx", 0L).toInt()
        val profilesStr = prefs.getString("flutter.ps4_led_profiles", "white,blue,red,off") ?: "white,blue,red,off"
        val leds = profilesStr.split(",").filter { it.isNotEmpty() }.toTypedArray()
        val realIdx = if (idx >= leds.size) 0 else idx
        val activeLed = leds[realIdx]
        
        tile.label = "LED: $activeLed"
        tile.state = if (activeLed == "off") Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        tile.updateTile()
    }
}
