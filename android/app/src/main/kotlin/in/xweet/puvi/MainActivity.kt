package `in`.xweet.puvi

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val soundUri = Uri.parse(
                "${ContentResolver.SCHEME_ANDROID_RESOURCE}://${packageName}/raw/music"
            )

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            val notificationManager = getSystemService(NotificationManager::class.java) ?: return

            // 1. Primary custom sound channel explicitly mapped to R.raw.music
            val customSoundChannel = NotificationChannel(
                "custom_sound_channel",
                "Puvi Love Melody",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Intimate alerts and love pings with our melody"
                setSound(soundUri, audioAttributes)
                enableVibration(true)
                enableLights(true)
            }

            // 2. Main love notifications channel (v2 ensures Android creates/refreshes sound)
            val loveChannel = NotificationChannel(
                "puvi_love_channel_v2",
                "Puvi Love Notes & Pings",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Instant love showers, sweet pings and mood updates"
                setSound(soundUri, audioAttributes)
                enableVibration(true)
                enableLights(true)
            }

            // 3. Couple chat channel
            val chatChannel = NotificationChannel(
                "puvi_chat_v2",
                "Puvi Couple Chat",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Private love messages, photos, hugs and kisses"
                setSound(soundUri, audioAttributes)
                enableVibration(true)
                enableLights(true)
            }

            notificationManager.createNotificationChannel(customSoundChannel)
            notificationManager.createNotificationChannel(loveChannel)
            notificationManager.createNotificationChannel(chatChannel)
        }
    }
}
