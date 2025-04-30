import 'dart:io';
import 'package:flutter/material.dart';
import 'comic.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'comic_detail_screen.dart';

class ComicScreen extends StatefulWidget {
  final String comicsDirectory;

  const ComicScreen({super.key, required this.comicsDirectory});

  @override
  State<ComicScreen> createState() => _ComicScreenState();
}

class _ComicScreenState extends State<ComicScreen> {
  final List<Comic> _comics = [];
  final List<Comic> _filteredComics = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isGridView = true;
  bool _isLoading = true;
  double _gridItemWidth = 150.0;
  OverlayEntry? _contextMenuOverlayEntry;

  static const _imageExtensions = ['.jpg', '.jpeg', '.png'];
  static const _prefsGridWidthKey = 'gridItemWidth';
  static const _prefsComicsDirKey = 'comicsDirectory';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadGridSettings();
    await _loadComics();
    _searchController.addListener(_filterComics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeContextMenu();
    super.dispose();
  }

  Future<void> _loadGridSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gridItemWidth = prefs.getDouble(_prefsGridWidthKey) ?? 150.0;
    });
  }

  Future<void> _loadComics() async {
    setState(() => _isLoading = true);

    try {
      final comicsDir = Directory(widget.comicsDirectory);
      if (!await comicsDir.exists()) {
        _showErrorSnackbar('漫画目录 ${widget.comicsDirectory} 不存在');
        return;
      }

      final comicDirs = await _getSubDirectories(comicsDir);
      final loadedComics = await Future.wait(
        comicDirs.map(_createComicFromDir),
      );

      setState(() {
        _comics
          ..clear()
          ..addAll(loadedComics)
          ..sort((a, b) => a.title.compareTo(b.title));
        _filteredComics.clear();
        _filteredComics.addAll(_comics);
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar('加载漫画失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Directory>> _getSubDirectories(Directory dir) async {
    return await dir
        .list()
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();
  }

  Future<Comic> _createComicFromDir(Directory comicDir) async {
    final comicName = _getLastPathSegment(comicDir.path);
    final coverImage = await _findCoverImage(comicDir);
    final chapters = await _getChapters(comicDir);

    return Comic(
      title: comicName,
      coverImage: coverImage,
      chapters: chapters..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  Future<File?> _findCoverImage(Directory dir) async {
    try {
      final files =
          await dir
              .list()
              .where((entity) {
                if (entity is! File) return false;
                final path = entity.path.toLowerCase();
                return path.contains('cover') &&
                    _imageExtensions.any((ext) => path.endsWith(ext));
              })
              .cast<File>()
              .toList();

      return files.isNotEmpty ? files.first : null;
    } catch (e) {
      debugPrint('查找封面图片失败: $e');
      return null;
    }
  }

  Future<List<Chapter>> _getChapters(Directory comicDir) async {
    final chapterDirs = await _getSubDirectories(comicDir);
    final chapters = <Chapter>[];

    for (final chapterDir in chapterDirs) {
      final chapterName = _getLastPathSegment(chapterDir.path);
      final pages = await _getChapterPages(chapterDir);

      chapters.add(
        Chapter(
          name: chapterName,
          directory: chapterDir,
          pages: pages..sort((a, b) => _naturalCompare(a.path, b.path)),
        ),
      );
    }

    return chapters;
  }

  Future<List<File>> _getChapterPages(Directory chapterDir) async {
    try {
      return await chapterDir
          .list()
          .where(
            (entity) =>
                entity is File &&
                _imageExtensions.any(
                  (ext) => entity.path.toLowerCase().endsWith(ext),
                ),
          )
          .cast<File>()
          .toList();
    } catch (e) {
      debugPrint('获取章节页面失败: $e');
      return [];
    }
  }

  String _getLastPathSegment(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  int _naturalCompare(String a, String b) {
    final reg = RegExp(r'(\d+)|(\D+)');
    final ma = reg.allMatches(a);
    final mb = reg.allMatches(b);

    for (var i = 0; i < ma.length && i < mb.length; i++) {
      final am = ma.elementAt(i).group(0)!;
      final bm = mb.elementAt(i).group(0)!;

      final an = int.tryParse(am);
      final bn = int.tryParse(bm);

      if (an != null && bn != null) {
        final diff = an - bn;
        if (diff != 0) return diff;
      } else {
        final diff = am.compareTo(bm);
        if (diff != 0) return diff;
      }
    }

    return a.length.compareTo(b.length);
  }

  void _filterComics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredComics.clear();
      if (query.isEmpty) {
        _filteredComics.addAll(_comics);
      } else {
        _filteredComics.addAll(
          _comics.where((comic) => comic.title.toLowerCase().contains(query)),
        );
      }
    });
  }

  void _toggleViewMode() => setState(() => _isGridView = !_isGridView);

  Future<void> _openSettings() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(
              initialDirectory: widget.comicsDirectory,
              initialGridItemWidth: _gridItemWidth,
              onSave: (String directory, double gridItemWidth) {
                setState(() {
                  _gridItemWidth = gridItemWidth;
                });
              },
            ),
      ),
    );

    if (result != null && mounted) {
      await _handleSettingsResult(result);
    }
  }

  Future<void> _handleSettingsResult(Map<String, dynamic> result) async {
    final newDirectory = result['directory'] as String;
    final newWidth = result['gridItemWidth'] as double;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_prefsComicsDirKey, newDirectory),
      prefs.setDouble(_prefsGridWidthKey, newWidth),
    ]);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ComicScreen(comicsDirectory: newDirectory),
        ),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showContextMenu(BuildContext context, Offset position, String path) {
    _removeContextMenu();

    _contextMenuOverlayEntry = OverlayEntry(
      builder:
          (context) => _ContextMenu(
            position: position,
            onOpenExplorer: () => _openInExplorer(path),
            onClose: _removeContextMenu,
          ),
    );

    Overlay.of(context).insert(_contextMenuOverlayEntry!);
  }

  void _removeContextMenu() {
    _contextMenuOverlayEntry?.remove();
    _contextMenuOverlayEntry = null;
  }

  Future<void> _openInExplorer(String path) async {
    try {
      final command =
          Platform.isWindows
              ? ['explorer', path.replaceAll('/', '\\')]
              : Platform.isMacOS
              ? ['open', path]
              : ['xdg-open', path];

      await Process.run(command[0], command.sublist(1));
    } catch (e) {
      _showErrorSnackbar('打开资源管理器失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _removeContextMenu,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(appBar: _buildComicAppBar(), body: _buildBody()),
    );
  }

  AppBar _buildComicAppBar() {
    return AppBar(
      title: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: '搜索漫画...',
          border: InputBorder.none,
          icon: Icon(Icons.search),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: _toggleViewMode,
        ),
        IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildComicView();
  }

  Widget _buildComicView() {
    return _isGridView ? _buildGridView() : _buildListView();
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / _gridItemWidth)
            .floor()
            .clamp(2, 10);

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: _filteredComics.length,
          itemBuilder: (context, index) {
            final comic = _filteredComics[index];
            return _ComicGridItem(
              comic: comic,
              comicsDirectory: widget.comicsDirectory,
              onTap: () => _navigateToComicDetail(comic),
              onContextMenu:
                  (position, path) => _showContextMenu(context, position, path),
            );
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredComics.length,
      itemBuilder: (context, index) {
        final comic = _filteredComics[index];
        return _ComicListItem(
          comic: comic,
          comicsDirectory: widget.comicsDirectory,
          onTap: () => _navigateToComicDetail(comic),
          onContextMenu:
              (position, path) => _showContextMenu(context, position, path),
        );
      },
    );
  }

  void _navigateToComicDetail(Comic comic) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComicDetailScreen(comic: comic)),
    );
  }
}

class _ComicGridItem extends StatelessWidget {
  final Comic comic;
  final String comicsDirectory;
  final VoidCallback onTap;
  final Function(Offset, String) onContextMenu;

  const _ComicGridItem({
    required this.comic,
    required this.comicsDirectory,
    required this.onTap,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final comicDir =
        comic.chapters.isNotEmpty
            ? comic.chapters.first.directory.parent.path
            : comicsDirectory;

    return GestureDetector(
      onTap: onTap,
      onSecondaryTapDown:
          (details) => onContextMenu(details.globalPosition, comicDir),
      child: Card(
        child: Column(
          children: [
            Expanded(
              child:
                  comic.coverImage != null
                      ? Image.file(comic.coverImage!, fit: BoxFit.cover)
                      : const Center(child: Icon(Icons.image, size: 50)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                comic.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComicListItem extends StatelessWidget {
  final Comic comic;
  final String comicsDirectory;
  final VoidCallback onTap;
  final Function(Offset, String) onContextMenu;

  const _ComicListItem({
    required this.comic,
    required this.comicsDirectory,
    required this.onTap,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final comicDir =
        comic.chapters.isNotEmpty
            ? comic.chapters.first.directory.parent.path
            : comicsDirectory;

    return GestureDetector(
      onTap: onTap,
      onSecondaryTapDown:
          (details) => onContextMenu(details.globalPosition, comicDir),
      child: ListTile(
        leading:
            comic.coverImage != null
                ? Image.file(
                  comic.coverImage!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                : const Icon(Icons.image),
        title: Text(comic.title),
        subtitle: Text('${comic.chapters.length} 章'),
      ),
    );
  }
}

class _ContextMenu extends StatelessWidget {
  final Offset position;
  final VoidCallback onOpenExplorer;
  final VoidCallback onClose;

  const _ContextMenu({
    required this.position,
    required this.onOpenExplorer,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Positioned(
          left: position.dx,
          top: position.dy,
          child: Material(
            elevation: 8,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ContextMenuItem(
                    icon: Icons.folder_open,
                    text: '在资源管理器中打开',
                    onTap: onOpenExplorer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ContextMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}
