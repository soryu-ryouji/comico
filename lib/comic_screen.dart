import 'dart:io';
import 'package:flutter/material.dart';
import 'comic.dart';
import 'chapter_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComicListScreen extends StatefulWidget {
  final String comicsDirectory;

  const ComicListScreen({super.key, required this.comicsDirectory});

  @override
  _ComicListScreenState createState() => _ComicListScreenState();
}

class _ComicListScreenState extends State<ComicListScreen> {
  List<Comic> comics = [];
  List<Comic> filteredComics = [];
  bool isGridView = true;
  bool isLoading = true;
  double gridItemWidth = 150.0;
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _contextMenuOverlayEntry;

  @override
  void initState() {
    super.initState();
    _loadComics();
    _loadGridSettings();
    _searchController.addListener(_filterComics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeContextMenu();
    super.dispose();
  }

  void _filterComics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredComics =
          comics.where((comic) {
            return comic.title.toLowerCase().contains(query);
          }).toList();
    });
  }

  Future<void> _loadGridSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      gridItemWidth = prefs.getDouble('gridItemWidth') ?? 150.0;
    });
  }

  Future<void> _loadComics() async {
    setState(() => isLoading = true);

    final comicsDir = Directory(widget.comicsDirectory);
    if (!await comicsDir.exists()) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('漫画目录 ${widget.comicsDirectory} 不存在')),
      );
      return;
    }

    final comicDirs =
        await comicsDir.list().where((entity) => entity is Directory).toList();

    final loadedComics = <Comic>[];

    for (var dir in comicDirs) {
      final comicDir = dir as Directory;
      final comicName = comicDir.path.split(Platform.pathSeparator).last;

      File? coverImage;
      final coverFiles =
          await comicDir
              .list()
              .where(
                (entity) =>
                    entity is File &&
                    entity.path.toLowerCase().contains('cover') &&
                    (entity.path.toLowerCase().endsWith('.jpg') ||
                        entity.path.toLowerCase().endsWith('.png') ||
                        entity.path.toLowerCase().endsWith('.jpeg')),
              )
              .toList();

      if (coverFiles.isNotEmpty) {
        coverImage = File(coverFiles.first.path);
      }

      final chapterDirs =
          await comicDir.list().where((entity) => entity is Directory).toList();

      chapterDirs.sort((a, b) => a.path.compareTo(b.path));

      final chapters = <Chapter>[];

      for (var chapterDir in chapterDirs) {
        final chapterName = chapterDir.path.split(Platform.pathSeparator).last;
        final pages =
            await (chapterDir as Directory)
                .list()
                .where(
                  (entity) =>
                      entity is File &&
                      (entity.path.toLowerCase().endsWith('.jpg') ||
                          entity.path.toLowerCase().endsWith('.png') ||
                          entity.path.toLowerCase().endsWith('.jpeg')),
                )
                .map((e) => File(e.path))
                .toList();

        chapters.add(
          Chapter(
            name: chapterName,
            directory: chapterDir,
            pages: pages..sort((a, b) => _naturalCompare(a.path, b.path)),
          ),
        );
      }

      loadedComics.add(
        Comic(
          title: comicName,
          coverImage: coverImage,
          chapters: chapters..sort((a, b) => a.name.compareTo(b.name)),
        ),
      );
    }

    setState(() {
      comics = loadedComics..sort((a, b) => a.title.compareTo(b.title));
      filteredComics = comics;
      isLoading = false;
    });
  }

  int _naturalCompare(String a, String b) {
    final reg = RegExp(r'(\d+)|(\D+)');
    final ma = reg.allMatches(a);
    final mb = reg.allMatches(b);

    final len = ma.length < mb.length ? ma.length : mb.length;
    for (var i = 0; i < len; i++) {
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

  void _toggleViewMode() {
    setState(() => isGridView = !isGridView);
  }

  void _openSettings() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(
              initialDirectory: widget.comicsDirectory,
              initialGridItemWidth: gridItemWidth,
              onSave: (newPath, newItemWidth) {
                Navigator.pop(context, {
                  'directory': newPath,
                  'gridItemWidth': newItemWidth,
                });
              },
            ),
      ),
    );

    if (result != null) {
      final newDirectory = result['directory'] as String;
      final newWidth = result['gridItemWidth'] as double;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('comicsDirectory', newDirectory);
      await prefs.setDouble('gridItemWidth', newWidth);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ComicListScreen(comicsDirectory: newDirectory),
        ),
      );
    }
  }

  void _navigateToComicDetail(Comic comic) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ComicDetailScreen(comic: comic)),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset globalPosition,
    String path,
  ) {
    _removeContextMenu();

    final overlayState = Overlay.of(context);

    _contextMenuOverlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _removeContextMenu,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              Positioned(
                left: globalPosition.dx,
                top: globalPosition.dy,
                child: Material(
                  elevation: 8,
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuItem(
                          icon: Icons.folder_open,
                          text: '在资源管理器中打开',
                          onTap: () {
                            _removeContextMenu();
                            _openInExplorer(path);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );

    overlayState.insert(_contextMenuOverlayEntry!);
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [Icon(icon, size: 20), SizedBox(width: 8), Text(text)],
        ),
      ),
    );
  }

  void _removeContextMenu() {
    _contextMenuOverlayEntry?.remove();
    _contextMenuOverlayEntry = null;
  }

  void _openInExplorer(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [path.replaceAll('/', '\\')]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打开资源管理器失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _removeContextMenu,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索漫画...',
              border: InputBorder.none,
              icon: Icon(Icons.search),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(isGridView ? Icons.list : Icons.grid_view),
              onPressed: _toggleViewMode,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
          ],
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : isGridView
                ? _buildGridView()
                : _buildListView(),
      ),
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth / gridItemWidth)
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
          itemCount: filteredComics.length,
          itemBuilder: (context, index) {
            final comic = filteredComics[index];
            final comicDir =
                comic.chapters.isNotEmpty
                    ? comic.chapters.first.directory.parent.path
                    : widget.comicsDirectory;

            return GestureDetector(
              onTap: () => _navigateToComicDetail(comic),
              onSecondaryTapDown: (details) {
                _showContextMenu(context, details.globalPosition, comicDir);
              },
              child: Card(
                child: Column(
                  children: [
                    Expanded(
                      child:
                          comic.coverImage != null
                              ? Image.file(comic.coverImage!, fit: BoxFit.cover)
                              : const Center(
                                child: Icon(Icons.image, size: 50),
                              ),
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
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: filteredComics.length,
      itemBuilder: (context, index) {
        final comic = filteredComics[index];
        final comicDir =
            comic.chapters.isNotEmpty
                ? comic.chapters.first.directory.parent.path
                : widget.comicsDirectory;

        return GestureDetector(
          onTap: () => _navigateToComicDetail(comic),
          onSecondaryTapDown: (details) {
            _showContextMenu(context, details.localPosition, comicDir);
          },
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
      },
    );
  }
}

class ComicDetailScreen extends StatelessWidget {
  final Comic comic;

  const ComicDetailScreen({super.key, required this.comic});

  void _navigateToChapterViewer(BuildContext context, Chapter chapter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterViewerScreen(chapter: chapter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(comic.title)),
      body: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.all(16),
            child:
                comic.coverImage != null
                    ? Image.file(comic.coverImage!, fit: BoxFit.contain)
                    : const Center(child: Icon(Icons.image, size: 100)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('章节列表', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: comic.chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = comic.chapters[index];
                        return ListTile(
                          title: Text(chapter.name),
                          subtitle: Text('${chapter.pages.length} 页'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap:
                              () => _navigateToChapterViewer(context, chapter),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
