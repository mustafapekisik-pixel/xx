import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskora_drive/src/player_controller.dart';

const String _demoAudioUrl =
    'https://storage.googleapis.com/exoplayer-test-media-0/play.mp3';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final PlayerState player = ref.watch(playerControllerProvider);
    final double width = MediaQuery.sizeOf(context).width;
    final bool wide = width >= 840;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ISKORA Drive',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: player.connected
                  ? 'Native medya çekirdeği hazır'
                  : 'Medya çekirdeğine bağlanılıyor',
              child: Icon(
                player.connected ? Icons.link_rounded : Icons.link_off_rounded,
                color: player.connected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: <Widget>[
            if (wide)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectDestination,
                labelType: NavigationRailLabelType.all,
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Ana sayfa'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music_rounded),
                    label: Text('Kütüphane'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite_outline_rounded),
                    selectedIcon: Icon(Icons.favorite_rounded),
                    label: Text('Favoriler'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: Text('Ayarlar'),
                  ),
                ],
              ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildPage(player),
                    ),
                  ),
                  _NowPlayingBar(player: player),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Ana sayfa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music_rounded),
                  label: 'Kütüphane',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Favoriler',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Ayarlar',
                ),
              ],
            ),
    );
  }

  Widget _buildPage(PlayerState player) {
    return switch (_selectedIndex) {
      0 => _HomePage(
          key: const ValueKey<String>('home'),
          player: player,
          onPlayDemo: _playDemo,
          onOpenStream: _showStreamSheet,
        ),
      1 => _LibraryPage(
          key: const ValueKey<String>('library'),
          onPlayDemo: _playDemo,
          onOpenStream: _showStreamSheet,
        ),
      2 => const _InformationPage(
          key: ValueKey<String>('favorites'),
          icon: Icons.favorite_rounded,
          title: 'Favoriler',
          message:
              'Favori parça ve akışların kalıcı olarak saklanacağı bölüm hazırlanıyor.',
        ),
      _ => const _InformationPage(
          key: ValueKey<String>('settings'),
          icon: Icons.tune_rounded,
          title: 'Ayarlar',
          message:
              'Tema, oynatma, depolama ve araç ayarları burada yönetilecek.',
        ),
    };
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _playDemo() async {
    await ref.read(playerControllerProvider.notifier).playUrl(
          url: _demoAudioUrl,
          title: 'ISKORA Test Sesi',
          artist: 'Google ExoPlayer test medyası',
        );
  }

  Future<void> _showStreamSheet() async {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController titleController =
        TextEditingController(text: 'İnternet akışı');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'HTTPS medya akışı aç',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'HTTPS medya adresi',
                    hintText: 'https://example.com/audio.mp3',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final String url = urlController.text.trim();
                    final Uri? uri = Uri.tryParse(url);
                    if (uri == null || !uri.isAbsolute || uri.scheme != 'https') {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text('Geçerli bir HTTPS adresi gir.'),
                        ),
                      );
                      return;
                    }

                    await ref.read(playerControllerProvider.notifier).playUrl(
                          url: url,
                          title: titleController.text.trim().isEmpty
                              ? 'İnternet akışı'
                              : titleController.text.trim(),
                        );
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Oynat'),
                ),
              ],
            ),
          ),
        );
      },
    );

    urlController.dispose();
    titleController.dispose();
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.player,
    required this.onPlayDemo,
    required this.onOpenStream,
    super.key,
  });

  final PlayerState player;
  final Future<void> Function() onPlayDemo;
  final Future<void> Function() onOpenStream;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: <Widget>[
        Text(
          'Medyan. Yolculuğun.',
          style: textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Flutter arayüzü, native Kotlin Media3 oynatma çekirdeğiyle çalışıyor.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      player.connected
                          ? Icons.check_circle_rounded
                          : Icons.sync_rounded,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        player.connected
                            ? 'Native medya çekirdeği hazır'
                            : 'Native medya çekirdeğine bağlanılıyor',
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: player.connected ? onPlayDemo : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Test sesini çal'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: player.connected ? onOpenStream : null,
                  icon: const Icon(Icons.add_link_rounded),
                  label: const Text('Kendi HTTPS akışını aç'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _FeatureTile(
          icon: Icons.library_music_rounded,
          title: 'Çalışan medya oynatma',
          subtitle: 'Test sesi veya HTTPS ses akışı oynatır.',
        ),
        const _FeatureTile(
          icon: Icons.notifications_active_rounded,
          title: 'Arka plan ve sistem kontrolleri',
          subtitle: 'Media3 oturumu üzerinden oynat/duraklat kontrolü sağlar.',
        ),
        const _FeatureTile(
          icon: Icons.directions_car_filled_rounded,
          title: 'Android Auto kataloğu',
          subtitle: 'Araç ekranına sürücü güvenli medya ağacı sunar.',
        ),
      ],
    );
  }
}

class _LibraryPage extends StatelessWidget {
  const _LibraryPage({
    required this.onPlayDemo,
    required this.onOpenStream,
    super.key,
  });

  final Future<void> Function() onPlayDemo;
  final Future<void> Function() onOpenStream;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Text('Kütüphane', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.music_note_rounded),
            ),
            title: const Text('ISKORA Test Sesi'),
            subtitle: const Text('Bağlantı ve Android Auto oynatma testi'),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: onPlayDemo,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.link_rounded),
            ),
            title: const Text('HTTPS akışı ekle'),
            subtitle: const Text('Doğrudan MP3, AAC veya HLS ses adresi aç'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenStream,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Yerel klasör tarama ve kalıcı oynatma listeleri sonraki geliştirme katmanıdır.',
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _InformationPage extends StatelessWidget {
  const _InformationPage({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 64),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _NowPlayingBar extends ConsumerWidget {
  const _NowPlayingBar({required this.player});

  final PlayerState player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int duration = player.durationMs <= 0 ? 1 : player.durationMs;
    final double progress =
        (player.positionMs / duration).clamp(0.0, 1.0).toDouble();

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LinearProgressIndicator(value: progress, minHeight: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 390;
                  return Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.graphic_eq_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              player.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              player.error ?? player.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!compact)
                        IconButton(
                          tooltip: 'Önceki',
                          onPressed: player.connected
                              ? () => ref
                                  .read(playerControllerProvider.notifier)
                                  .skipPrevious()
                              : null,
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                      FilledButton(
                        onPressed: player.connected
                            ? () => ref
                                .read(playerControllerProvider.notifier)
                                .togglePlayback()
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                        ),
                        child: Icon(
                          player.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      if (!compact)
                        IconButton(
                          tooltip: 'Sonraki',
                          onPressed: player.connected
                              ? () => ref
                                  .read(playerControllerProvider.notifier)
                                  .skipNext()
                              : null,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
