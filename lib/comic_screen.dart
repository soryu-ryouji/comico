import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'comic.dart';
import 'chapter_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ComicListScreen extends StatefulWidget {
  final String comicsDirectory;

  const ComicListScreen({super.key, required this.comicsDirectory});

  @override
  _ComicListScreenState createState() => _ComicListScreenState();
}

class _ComicListScreenState extends State<ComicListScreen> {
  List<Comic> comics = [];
  bool isGridView = true;
  bool isLoading = true;
  double gridItemWidth = 150.0;

  @override
  void initState() {
    super.initState();
    _loadComics();
    _loadGridSettings();
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
            pages: pages..sort((a, b) => a.path.compareTo(b.path)),
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
      isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('comico'),
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
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth / gridItemWidth)
            .floor()
            .clamp(2, 10);

        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              final keys = RawKeyboard.instance.keysPressed;
              final isCtrlPressed =
                  keys.contains(LogicalKeyboardKey.controlLeft) ||
                  keys.contains(LogicalKeyboardKey.controlRight);

              if (isCtrlPressed) {
                // 阻止滚动
                return;
              }
            }
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemCount: comics.length,
            itemBuilder: (context, index) {
              final comic = comics[index];
              return GestureDetector(
                onTap: () => _navigateToComicDetail(comic),
                child: Card(
                  child: Column(
                    children: [
                      Expanded(
                        child:
                            comic.coverImage != null
                                ? Image.file(
                                  comic.coverImage!,
                                  fit: BoxFit.cover,
                                )
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
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: comics.length,
      itemBuilder: (context, index) {
        final comic = comics[index];
        return ListTile(
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
          onTap: () => _navigateToComicDetail(comic),
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
