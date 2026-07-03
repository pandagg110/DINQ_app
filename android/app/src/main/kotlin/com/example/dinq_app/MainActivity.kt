package me.dinq.app

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var neteasePlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dinq/netease_audio"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val url = call.argument<String>("url").orEmpty()
                    @Suppress("UNCHECKED_CAST")
                    val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
                    playNeteasePreview(url, headers, result)
                }
                "pause" -> {
                    pauseNeteasePreview()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playNeteasePreview(
        url: String,
        headers: Map<String, String>,
        result: MethodChannel.Result,
    ) {
        if (url.isBlank()) {
            result.error("EMPTY_URL", "Netease preview URL is empty", null)
            return
        }

        releaseNeteasePlayer()

        val player = MediaPlayer()
        neteasePlayer = player
        var responded = false

        fun successOnce() {
            if (responded) return
            responded = true
            result.success(null)
        }

        fun errorOnce(code: String, message: String?) {
            if (responded) return
            responded = true
            result.error(code, message, null)
        }

        try {
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            player.setOnPreparedListener {
                it.start()
                successOnce()
            }
            player.setOnCompletionListener {
                releaseNeteasePlayer()
            }
            player.setOnErrorListener { _, what, extra ->
                releaseNeteasePlayer()
                errorOnce("PLAYBACK_ERROR", "MediaPlayer error: what=$what extra=$extra")
                true
            }
            player.setDataSource(this, Uri.parse(url), headers)
            player.prepareAsync()
        } catch (error: Exception) {
            releaseNeteasePlayer()
            errorOnce("PLAYBACK_EXCEPTION", error.message)
        }
    }

    private fun pauseNeteasePreview() {
        neteasePlayer?.pause()
    }

    private fun releaseNeteasePlayer() {
        neteasePlayer?.run {
            try {
                stop()
            } catch (_: Exception) {
            }
            release()
        }
        neteasePlayer = null
    }

    override fun onDestroy() {
        releaseNeteasePlayer()
        super.onDestroy()
    }
}
