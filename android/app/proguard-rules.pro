# Media3 and Flutter publish the consumer rules they require.
# Keep Flutter method channel entry points and the native playback service explicit.
-keep class com.iskora.drive.MainActivity { *; }
-keep class com.iskora.drive.media.PlaybackService { *; }
