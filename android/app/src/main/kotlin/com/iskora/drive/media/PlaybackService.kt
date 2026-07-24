package com.iskora.drive.media

import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.LibraryResult
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.MediaLibraryService.LibraryParams
import androidx.media3.session.MediaLibraryService.MediaLibrarySession
import androidx.media3.session.MediaSession
import androidx.media3.session.SessionError
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

class PlaybackService : MediaLibraryService() {
    private var mediaLibrarySession: MediaLibrarySession? = null

    private val rootItem: MediaItem = MediaItem.Builder()
        .setMediaId(ROOT_ID)
        .setMediaMetadata(
            MediaMetadata.Builder()
                .setTitle("ISKORA Drive")
                .setSubtitle("Araç medya kütüphanesi")
                .setIsBrowsable(true)
                .setIsPlayable(false)
                .build(),
        )
        .build()

    private val demoItem: MediaItem = MediaItem.Builder()
        .setMediaId(DEMO_ID)
        .setUri(DEMO_URL)
        .setMediaMetadata(
            MediaMetadata.Builder()
                .setTitle("ISKORA Test Sesi")
                .setArtist("Google ExoPlayer test medyası")
                .setIsBrowsable(false)
                .setIsPlayable(true)
                .setMediaType(MediaMetadata.MEDIA_TYPE_MUSIC)
                .build(),
        )
        .build()

    private val libraryCallback = object : MediaLibrarySession.Callback {
        override fun onGetLibraryRoot(
            session: MediaLibrarySession,
            browser: MediaSession.ControllerInfo,
            params: LibraryParams?,
        ): ListenableFuture<LibraryResult<MediaItem>> =
            Futures.immediateFuture(LibraryResult.ofItem(rootItem, params))

        override fun onGetItem(
            session: MediaLibrarySession,
            browser: MediaSession.ControllerInfo,
            mediaId: String,
        ): ListenableFuture<LibraryResult<MediaItem>> {
            val item = when (mediaId) {
                ROOT_ID -> rootItem
                DEMO_ID -> demoItem
                else -> null
            }

            return if (item != null) {
                Futures.immediateFuture(LibraryResult.ofItem(item, null))
            } else {
                Futures.immediateFuture(
                    LibraryResult.ofError(SessionError.ERROR_BAD_VALUE),
                )
            }
        }

        override fun onGetChildren(
            session: MediaLibrarySession,
            browser: MediaSession.ControllerInfo,
            parentId: String,
            page: Int,
            pageSize: Int,
            params: LibraryParams?,
        ): ListenableFuture<LibraryResult<ImmutableList<MediaItem>>> {
            val children = if (parentId == ROOT_ID && page == 0) {
                ImmutableList.of(demoItem)
            } else {
                ImmutableList.of()
            }

            return Futures.immediateFuture(
                LibraryResult.ofItemList(children, params),
            )
        }

        override fun onAddMediaItems(
            mediaSession: MediaSession,
            controller: MediaSession.ControllerInfo,
            mediaItems: List<MediaItem>,
        ): ListenableFuture<List<MediaItem>> {
            val resolvedItems = mediaItems.mapNotNull { requestedItem ->
                when {
                    requestedItem.localConfiguration != null -> requestedItem
                    requestedItem.mediaId == DEMO_ID -> demoItem
                    requestedItem.requestMetadata.mediaUri != null -> requestedItem.buildUpon()
                        .setUri(requestedItem.requestMetadata.mediaUri)
                        .build()
                    else -> null
                }
            }
            return Futures.immediateFuture(resolvedItems)
        }
    }

    override fun onCreate() {
        super.onCreate()

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
            .build()

        val player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(audioAttributes, true)
            setHandleAudioBecomingNoisy(true)
        }

        mediaLibrarySession = MediaLibrarySession.Builder(
            this,
            player,
            libraryCallback,
        ).build()
    }

    override fun onGetSession(
        controllerInfo: MediaSession.ControllerInfo,
    ): MediaLibrarySession? = mediaLibrarySession

    override fun onDestroy() {
        mediaLibrarySession?.run {
            player.release()
            release()
        }
        mediaLibrarySession = null
        super.onDestroy()
    }

    private companion object {
        const val ROOT_ID = "iskora_root"
        const val DEMO_ID = "iskora_demo_audio"
        const val DEMO_URL =
            "https://storage.googleapis.com/exoplayer-test-media-0/play.mp3"
    }
}
