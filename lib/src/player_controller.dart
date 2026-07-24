import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const MethodChannel _commands = MethodChannel('com.iskora.drive/media');
const EventChannel _events = EventChannel('com.iskora.drive/media_events');

class PlayerState {
  const PlayerState({
    this.connected = false,
    this.playing = false,
    this.title = 'Nothing playing',
    this.artist = 'Choose media on your phone',
    this.positionMs = 0,
    this.durationMs = 0,
    this.error,
  });

  final bool connected;
  final bool playing;
  final String title;
  final String artist;
  final int positionMs;
  final int durationMs;
  final String? error;

  PlayerState copyWith({
    bool? connected,
    bool? playing,
    String? title,
    String? artist,
    int? positionMs,
    int? durationMs,
    String? error,
    bool clearError = false,
  }) {
    return PlayerState(
      connected: connected ?? this.connected,
      playing: playing ?? this.playing,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final NotifierProvider<PlayerController, PlayerState> playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

class PlayerController extends Notifier<PlayerState> {
  StreamSubscription<dynamic>? _subscription;

  @override
  PlayerState build() {
    _subscription = _events.receiveBroadcastStream().listen(
      _handleNativeEvent,
      onError: (Object error, StackTrace stackTrace) {
        if (ref.mounted) {
          state = state.copyWith(error: error.toString());
        }
      },
    );
    ref.onDispose(() => _subscription?.cancel());
    unawaited(_initialize());
    return const PlayerState();
  }

  Future<void> _initialize() async {
    try {
      final Map<Object?, Object?>? payload =
          await _commands.invokeMapMethod<Object?, Object?>('getState');
      if (payload != null && ref.mounted) {
        _applyPayload(payload);
      }
    } on MissingPluginException {
      if (ref.mounted) {
        state = state.copyWith(
          error: 'Native media core is available on Android builds.',
        );
      }
    } on PlatformException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(error: error.message ?? error.code);
      }
    }
  }

  Future<void> togglePlayback() async {
    await _invoke(state.playing ? 'pause' : 'play');
  }

  Future<void> skipNext() async {
    await _invoke('skipNext');
  }

  Future<void> skipPrevious() async {
    await _invoke('skipPrevious');
  }

  Future<void> playUrl({
    required String url,
    required String title,
    String artist = 'ISKORA Drive',
  }) async {
    await _invoke(
      'playUrl',
      <String, Object>{'url': url, 'title': title, 'artist': artist},
    );
  }

  Future<void> _invoke(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    try {
      await _commands.invokeMethod<void>(method, arguments);
      if (ref.mounted) {
        state = state.copyWith(clearError: true);
      }
    } on PlatformException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(error: error.message ?? error.code);
      }
    }
  }

  void _handleNativeEvent(dynamic event) {
    if (event is Map<Object?, Object?> && ref.mounted) {
      _applyPayload(event);
    }
  }

  void _applyPayload(Map<Object?, Object?> payload) {
    state = state.copyWith(
      connected: payload['connected'] as bool? ?? false,
      playing: payload['playing'] as bool? ?? false,
      title: payload['title'] as String? ?? 'Nothing playing',
      artist: payload['artist'] as String? ?? 'Choose media on your phone',
      positionMs: (payload['positionMs'] as num?)?.toInt() ?? 0,
      durationMs: (payload['durationMs'] as num?)?.toInt() ?? 0,
      clearError: true,
    );
  }
}
