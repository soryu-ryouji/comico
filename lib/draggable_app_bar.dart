import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class DraggableAppBar extends StatelessWidget {
  final bool showBackButton;
  final Color? backgroundColor;
  final double elevation;
  final bool visible;
  final List<Widget>? leftActions;
  final List<Widget>? centerActions;
  final List<Widget>? rightActions;

  const DraggableAppBar({
    super.key,
    this.showBackButton = true,
    this.backgroundColor,
    this.elevation = 4.0,
    this.visible = true,
    this.leftActions,
    this.centerActions,
    this.rightActions,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Material(
      elevation: elevation,
      color: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      child: SizedBox(
        height: kToolbarHeight,
        child: Stack(
          children: [
            // 可拖动区域
            Positioned.fill(
              child: DragToMoveArea(
                child: Container(color: Colors.transparent),
              ),
            ),
            // 内容区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(children: _buildAppBarContent(context)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarContent(BuildContext context) {
    return [
      // 左侧内容
      if (showBackButton || leftActions != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
            ...?leftActions,
          ],
        ),

      // 中间内容 - 使用Expanded确保居中
      Expanded(
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [...?centerActions],
          ),
        ),
      ),

      // 右侧内容
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [...?rightActions, ..._buildWindowControls()],
      ),
    ];
  }

  List<Widget> _buildWindowControls() {
    return [_WindowControls()];
  }
}

// 专门处理拖动的组件
class DragToMoveArea extends StatelessWidget {
  final Widget child;

  const DragToMoveArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.buttons == kPrimaryMouseButton) {
          windowManager.startDragging();
        }
      },
      child: MouseRegion(cursor: SystemMouseCursors.move, child: child),
    );
  }
}

class _WindowControls extends StatefulWidget {
  @override
  _WindowControlsState createState() => _WindowControlsState();
}

class _WindowControlsState extends State<_WindowControls> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _updateWindowState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _updateWindowState() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted && isMaximized != _isMaximized) {
      setState(() => _isMaximized = isMaximized);
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isMaximized ? Icons.fullscreen_exit : Icons.fullscreen),
          onPressed: () async {
            if (_isMaximized) {
              onWindowUnmaximize();
              await windowManager.unmaximize();
            } else {
              onWindowMaximize();
              await windowManager.maximize();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}
