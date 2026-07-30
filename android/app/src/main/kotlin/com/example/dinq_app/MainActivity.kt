package me.dinq.app

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.webkit.CookieManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicInteger

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "me.dinq.app/github_oauth"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "clearGitHubCookies" -> clearGitHubCookies(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun clearGitHubCookies(result: MethodChannel.Result) {
        val cookieManager = CookieManager.getInstance()
        val cookieNames = cookieManager.getCookie("https://github.com/")
            .orEmpty()
            .split(';')
            .mapNotNull { cookie ->
                cookie.trim().substringBefore('=').takeIf { it.isNotBlank() }
            }
            .distinct()

        if (cookieNames.isEmpty()) {
            result.success(null)
            return
        }

        val expiredCookies = cookieNames.flatMap { name ->
            listOf(
                "$name=; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Path=/; Secure",
                "$name=; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Domain=github.com; Path=/; Secure",
                "$name=; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Domain=.github.com; Path=/; Secure",
            )
        }
        val remaining = AtomicInteger(expiredCookies.size)
        expiredCookies.forEach { expiredCookie ->
            cookieManager.setCookie("https://github.com/", expiredCookie) {
                if (remaining.decrementAndGet() == 0) {
                    cookieManager.flush()
                    result.success(null)
                }
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
