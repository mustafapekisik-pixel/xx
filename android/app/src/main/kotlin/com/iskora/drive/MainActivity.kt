package com.iskora.drive

import android.content.ComponentName
import androidx.core.content.ContextCompat
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.ListenableFuture
import com.iskora.drive.media.PlaybackService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var controllerFuture: ListenableFuture<MediaController>
    private var mediaController: MediaController? = null
    private var eventSink: EventChannel.EventSink? = null

    private val playerListener = object : Player.Listener {
        override fun onEvents(player: Player, events: Player.Events) {
            emitState()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler(::handleMethodCall)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                eventSink = events
                emitState()
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        connectMediaController()
    }

    private fun connectMediaController() {
        val sessionToken = SessionToken(
            this,
            ComponentName(this, PlaybackService::class.java),
        )

        controllerFuture = MediaController.Builder(this, sessionToken).buildAsync()
        controllerFuture.addListener(
            {
                runCatching { controllerFuture.get() }
                    .onSuccess { controller ->
                        mediaController?.removeListener(playerListener)
                        mediaController = controller
                        controller.addListener(playerListener)
                        emitState()
                    }
                    .onFailure { error ->
                        eventSink?.error(
                            "MEDIA_CONNECTION_FAILED",
                            error.message,
                            null,
                        )
                    }
            },
            ContextCompat.getMainExecutor(this),
        )
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "getState") {
            result.success(buildStatePayload())
            return
        }

        val controller = mediaController
        if (controller == null) {
            result.error(
                "MEDIA_NOT_READY",
                "The native media service is still connecting.",
                null,
            )
            return
        }

        when (call.method) {
            "play" -> {
                controller.play()
                result.success(null)
            }

            "pause" -> {
                controller.pause()
                result.success(null)
            }

            "skipNext" -> {
                controller.seekToNextMediaItem()
                result.success(null)
            }

            "skipPrevious" -> {
                controller.seekToPreviousMediaItem()
                result.success(null)
            }

            "playUrl" -> playUrl(call, controller, result)
            else -> result.notImplemented()
        }
    }

    private fun playUrl(
        call: MethodCall,
        controller: MediaController,
        result: MethodChannel.Result,
    ) {
        val url = call.argument<String>("url")?.trim().orEmpty()
        if (!url.startsWith("https://")) {
            result.error(
                "INVALID_MEDIA_URL",
                "Only HTTPS media URLs are accepted.",
                null,
            )
            return
        }

        val title = call.argument<String>("title")?.trim().orEmpty()
            .ifBlank { "Internet stream" }
        val artist = call.argument<String>("artist")?.trim().orEmpty()
            .ifBlank { "ISKORA Drive" }

        val mediaItem = MediaItem.Builder()
            .setUri(url)
            .setMediaId(url)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle(title)
                    .setArtist(artist)
                    .setIsPlayable(true)
                    .build(),
            )
            .build()

        controller.setMediaItem(mediaItem)
        controller.prepare()
        controller.play()
        result.success(null)
    }

    private fun emitState() {
        runOnUiThread {
            eventSink?.success(buildStatePayload())
        }
    }

    private fun buildStatePayload(): Map<String, Any> {
        val controller = mediaController
        val metadata = controller?.currentMediaItem?.mediaMetadata
        val duration = controller?.duration
            ?.takeUnless { it == C.TIME_UNSET || it < 0 }
            ?: 0L

        return mapOf(
            "connected" to (controller != null),
            "playing" to (controller?.isPlaying == true),
            "title" to (metadata?.title?.toString() ?: "Nothing playing"),
            "artist" to (metadata?.artist?.toString() ?: "Choose media on your phone"),
            "positionMs" to (controller?.currentPosition ?: 0L),
            "durationMs" to duration,
        )
    }

    override fun onDestroy() {
        mediaController?.removeListener(playerListener)
        mediaController = null
        if (::controllerFuture.isInitialized) {
            MediaController.releaseFuture(controllerFuture)
        }
        super.onDestroy()
    }

    private companion object {
        const val METHOD_CHANNEL = "com.iskora.drive/media"
        const val EVENT_CHANNEL = "com.iskora.drive/media_events"
    }
}
