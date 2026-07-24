import 'package:flutter_test/flutter_test.dart';
import 'package:iskora_drive/src/player_controller.dart';

void main() {
  test('PlayerState copyWith preserves unspecified values', () {
    const PlayerState initial = PlayerState(
      connected: true,
      title: 'Track',
      artist: 'Artist',
    );

    final PlayerState updated = initial.copyWith(playing: true);

    expect(updated.connected, isTrue);
    expect(updated.playing, isTrue);
    expect(updated.title, 'Track');
    expect(updated.artist, 'Artist');
  });
}
