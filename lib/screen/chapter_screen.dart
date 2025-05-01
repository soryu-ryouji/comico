import 'package:comico/widgets/comic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:comico/widgets/draggable_app_bar.dart';

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

  Widget _buildPageContent() {
    return Center(
      child: PhotoView(
        imageProvider: tryGetImage(curPageIndex),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }

  Widget _buildPageNavigationAreas() {
    return Row(
      children: [
        // 左侧翻页区域
        Expanded(
          child: GestureDetector(
            onTap: _previousPage,
            child: Container(color: Colors.transparent),
          ),
        ),
        // 中间内容区域（实际由PhotoView占据）
        const Expanded(flex: 2, child: SizedBox.shrink()),
        // 右侧翻页区域
        Expanded(
          child: GestureDetector(
            onTap: _nextPage,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = '${curPageIndex + 1} / ${widget.chapter.pages.length}';
    final title = '${widget.chapter.name}  -  $progress';
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyDown,
        child: Listener(
          onPointerHover: _handlePointerHover,
          onPointerSignal: _handlePointerSignal,
          child: Stack(
            children: [
              _buildPageContent(),
              _buildPageNavigationAreas(),
              DraggableAppBar(leftActions: [Text(title)], visible: _showAppBar),
            ],
          ),
        ),
      ),
    );
  }
}
