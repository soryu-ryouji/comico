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
  int currentPageIndex = 0;
  final FocusNode _focusNode = FocusNode();
  final Map<int, ImageProvider> _imageCache = {}; // 存储已加载的图片
  static const int _precacheCount = 3; // 预缓存前后各3页

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
    final start = (currentPageIndex - _precacheCount).clamp(
      0,
      widget.chapter.pages.length - 1,
    );
    final end = (currentPageIndex + _precacheCount).clamp(
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
    if (currentPageIndex < widget.chapter.pages.length - 1) {
      setState(() {
        currentPageIndex++;
        _precacheImages(); // 翻页时预缓存新页
      });
    }
  }

  void _previousPage() {
    if (currentPageIndex > 0) {
      setState(() {
        currentPageIndex--;
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

  @override
  Widget build(BuildContext context) {
    final title =
        '${widget.chapter.name} - ${currentPageIndex + 1}/${widget.chapter.pages.length}';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                  imageProvider: tryGetImage(currentPageIndex),
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
