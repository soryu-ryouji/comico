import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final initialPath = prefs.getString('comicsDirectory') ?? 'D:\\Comics';

  runApp(MyApp(initialDirectory: initialPath));
}

class MyApp extends StatelessWidget {
  final String initialDirectory;

  const MyApp({super.key, required this.initialDirectory});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'comico',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ComicListScreen(comicsDirectory: initialDirectory),
    );
  }
}

class Comic {
  final String title;
  final File? coverImage;
  final List<Chapter> chapters;

  Comic({
    required this.title,
    required this.coverImage,
    required this.chapters,
  });
}

class Chapter {
  final String name;
  final Directory directory;
  final List<File> pages;

  Chapter({required this.name, required this.directory, required this.pages});
}

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

  @override
  void initState() {
    super.initState();
    _loadComics();
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

      // 按名字排序（支持中日韩 Unicode 排序）
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
    final newDirectory = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(
              initialDirectory: widget.comicsDirectory,
              onSave: (newPath) {
                Navigator.pop(context, newPath); // 返回新路径
              },
            ),
      ),
    );

    if (newDirectory != null && newDirectory.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('comicsDirectory', newDirectory);

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
        title: const Text('漫画列表'),
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
        // 设定每个格子最小宽度
        const double minItemWidth = 150;
        int crossAxisCount = (constraints.maxWidth / minItemWidth).floor();
        crossAxisCount = crossAxisCount.clamp(2, 8); // 最少2个，最多8个（可根据需要调整）

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7, // 图片比例
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
              padding: const EdgeInsets.all(16), // 加点内边距
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('章节列表', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Expanded(
                    // 一定要加 Expanded 包住 ListView，不然溢出
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

class ChapterViewerScreen extends StatefulWidget {
  final Chapter chapter;

  const ChapterViewerScreen({super.key, required this.chapter});

  @override
  _ChapterViewerScreenState createState() => _ChapterViewerScreenState();
}

class _ChapterViewerScreenState extends State<ChapterViewerScreen> {
  int currentPageIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  void _nextPage() {
    if (currentPageIndex < widget.chapter.pages.length - 1) {
      setState(() => currentPageIndex++);
    }
  }

  void _previousPage() {
    if (currentPageIndex > 0) {
      setState(() => currentPageIndex--);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.chapter.name} - ${currentPageIndex + 1}/${widget.chapter.pages.length}',
        ),
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _nextPage();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _previousPage();
            }
          }
        },
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              if (event.scrollDelta.dy > 0) {
                _nextPage();
              } else if (event.scrollDelta.dy < 0) {
                _previousPage();
              }
            }
          },
          child: Stack(
            children: [
              Center(
                child: PhotoView(
                  imageProvider: FileImage(
                    widget.chapter.pages[currentPageIndex],
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.3,
                child: GestureDetector(
                  onTap: _previousPage,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.3,
                child: GestureDetector(
                  onTap: _nextPage,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final String initialDirectory;
  final Function(String) onSave;

  const SettingsScreen({
    super.key,
    required this.initialDirectory,
    required this.onSave,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _directoryController;

  @override
  void initState() {
    super.initState();
    _directoryController = TextEditingController(text: widget.initialDirectory);
  }

  @override
  void dispose() {
    _directoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _directoryController,
              decoration: const InputDecoration(
                labelText: '漫画目录路径',
                hintText: '请输入漫画文件夹完整路径',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onSave(_directoryController.text);
              },
              child: const Text('保存设置'),
            ),
          ],
        ),
      ),
    );
  }
}
