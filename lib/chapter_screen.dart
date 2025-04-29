import 'comic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

class ChapterViewerScreen extends StatefulWidget {
  final Chapter chapter;

  const ChapterViewerScreen({super.key, required this.chapter});

  @override
  _ChapterViewerScreenState createState() => _ChapterViewerScreenState();
}

class _ChapterViewerScreenState extends State<ChapterViewerScreen> {
  int curPageIndex = 0;
  final FocusNode _focusNode = FocusNode();
  final Map<int, ImageProvider> _imageCache = {}; // 存储已加载的图片
  static const int _precacheCount = 3; // 预缓存前后各3页

  bool _showAppBar = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _precacheImages(); // 初始时预加载图片
  }

  @override
  void didUpdateWidget(ChapterViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter != widget.chapter) {
      _imageCache.clear(); // 切换章节时清空缓存
      _precacheImages(); // 重新预加载图片
    }
  }

  FileImage tryGetImage(int index) {
    if (_imageCache.containsKey(index)) {
      return _imageCache[index] as FileImage;
    } else {
      final file = widget.chapter.pages[index];
      final provider = FileImage(file);
      _imageCache[index] = provider;
      return provider;
    }
  }

  // 预缓存图片：同时缓存当前页和前后几页
  void _precacheImages() async {
    final start = (curPageIndex - _precacheCount).clamp(
      0,
      widget.chapter.pages.length - 1,
    );
    final end = (curPageIndex + _precacheCount).clamp(
      0,
      widget.chapter.pages.length - 1,
    );

    for (int i = start; i <= end; i++) {
      if (_imageCache.containsKey(i)) return;

      final file = widget.chapter.pages[i];
      final provider = FileImage(file);
      _imageCache[i] = provider;

      try {
        await precacheImage(provider, context);
      } catch (e) {
        debugPrint('预缓存图片失败: ${file.path}');
      }
    }
  }

  void _nextPage() {
    if (curPageIndex < widget.chapter.pages.length - 1) {
      setState(() {
        curPageIndex++;
        _precacheImages();
      });
    }
  }

  void _previousPage() {
    if (curPageIndex > 0) {
      setState(() {
        curPageIndex--;
        _precacheImages();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _imageCache.clear();
    super.dispose();
  }

  void _handlePointerHover(PointerHoverEvent event) {
    debugPrint('Pointer moved: ${event.position}');
    if (event.position.dy < 50) {
      setState(() {
        _showAppBar = true;
      });
    } else {
      setState(() {
        _showAppBar = false;
      });
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy > 0) {
        _nextPage();
      } else if (event.scrollDelta.dy < 0) {
        _previousPage();
      }
    }
  }

  void _handleKeyDown(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextPage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousPage();
      }
    }
  }

  AppBar? _updateAppbar() {
    if (!_showAppBar) return null;

    final progress = '${curPageIndex + 1}/${widget.chapter.pages.length}';
    final title = '${widget.chapter.name} - $progress';

    return AppBar(title: Text(title));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _updateAppbar(),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyDown,
        child: Listener(
          onPointerHover: _handlePointerHover,
          onPointerSignal: _handlePointerSignal,
          child: Stack(
            children: [
              Center(
                child: PhotoView(
                  imageProvider: tryGetImage(curPageIndex),
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
