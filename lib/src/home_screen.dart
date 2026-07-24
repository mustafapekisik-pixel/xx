import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskora_drive/src/player_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const List<String> _titles = <String>[
    'Home',
    'Library',
    'Favorites',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final PlayerState player = ref.watch(playerControllerProvider);
    final bool wide = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: wide ? 32 : 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('ISKORA Drive'),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                player.connected ? Icons.link_rounded : Icons.link_off_rounded,
                size: 18,
              ),
              label: Text(player.connected ? 'Media core ready' : 'Connecting'),
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
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music_rounded),
                    label: Text('Library'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite_outline_rounded),
                    selectedIcon: Icon(Icons.favorite_rounded),
                    label: Text('Favorites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: Text('Settings'),
                  ),
                ],
              ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: _buildPage(
                        context,
                        index: _selectedIndex,
                        title: _titles[_selectedIndex],
                      ),
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
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music_rounded),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Favorites',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showStreamSheet(context),
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Open stream'),
            )
          : null,
    );
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildPage(
    BuildContext context, {
    required int index,
    required String title,
  }) {
    return switch (index) {
      0 => _Dashboard(key: const ValueKey<String>('dashboard')),
      1 => _EmptyPage(
          key: const ValueKey<String>('library'),
          icon: Icons.library_music_rounded,
          title: title,
          message: 'Local folders, playlists and network sources will live here.',
        ),
      2 => _EmptyPage(
          key: const ValueKey<String>('favorites'),
          icon: Icons.favorite_rounded,
          title: title,
          message: 'Pinned albums, streams and tracks will appear here.',
        ),
      _ => _EmptyPage(
          key: const ValueKey<String>('settings'),
          icon: Icons.tune_rounded,
          title: title,
          message: 'Playback, appearance, storage and car settings will live here.',
        ),
    };
  }

  Future<void> _showStreamSheet(BuildContext context) async {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController titleController =
        TextEditingController(text: 'Internet stream');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Open media stream',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'HTTPS media URL',
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
                      const SnackBar(content: Text('Enter a valid HTTPS URL.')),
                    );
                    return;
                  }
                  await ref.read(playerControllerProvider.notifier).playUrl(
                        url: url,
                        title: titleController.text.trim().isEmpty
                            ? 'Internet stream'
                            : titleController.text.trim(),
                      );
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play'),
              ),
            ],
          ),
        );
      },
    );

    urlController.dispose();
    titleController.dispose();
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      children: <Widget>[
        Text('Your media, one place.', style: textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          'A modern phone experience backed by a native Android media service.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns = constraints.maxWidth >= 920
                ? 4
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: columns == 1 ? 3.2 : 1.7,
              children: const <Widget>[
                _FeatureCard(
                  icon: Icons.folder_copy_rounded,
                  title: 'Folders',
                  subtitle: 'Browse local media safely',
                ),
                _FeatureCard(
                  icon: Icons.queue_music_rounded,
                  title: 'Playlists',
                  subtitle: 'Keep listening across devices',
                ),
                _FeatureCard(
                  icon: Icons.podcasts_rounded,
                  title: 'Streams',
                  subtitle: 'Open HTTPS audio sources',
                ),
                _FeatureCard(
                  icon: Icons.directions_car_filled_rounded,
                  title: 'Car ready',
                  subtitle: 'Native Media3 session controls',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.shield_outlined, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Driver-safe architecture',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Android Auto uses its own approved media interface. The Flutter UI remains on the phone, while Kotlin and Media3 handle background playback and vehicle controls.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 32),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _EmptyPage extends StatelessWidget {
  const _EmptyPage({
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
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded),
                  ),
                  const SizedBox(width: 12),
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
                  IconButton(
                    tooltip: 'Previous',
                    onPressed: () => ref
                        .read(playerControllerProvider.notifier)
                        .skipPrevious(),
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  FilledButton(
                    onPressed: player.connected
                        ? () => ref
                            .read(playerControllerProvider.notifier)
                            .togglePlayback()
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(
                      player.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next',
                    onPressed: () => ref
                        .read(playerControllerProvider.notifier)
                        .skipNext(),
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
