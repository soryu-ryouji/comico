// lib/handler/context_menu_handler.dart
import 'package:flutter/material.dart';
import 'package:comico/widgets/context_menu.dart';
import 'package:comico/services/explorer_service.dart';

mixin ContextMenuHandler<T extends StatefulWidget> on State<T> {
  OverlayEntry? _contextMenuOverlayEntry;
  final ExplorerService _explorerService = ExplorerService();

  void showContextMenu(Offset position, String path) {
    removeContextMenu();

    _contextMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        const menuWidth = 200.0;
        const itemHeight = 48.0;
        const verticalPadding = 8.0;

        // 计算菜单总高度
        final menuHeight = ContextMenu.calculateTotalHeight(
          itemCount: 4, // 当前有4个菜单项
          itemHeight: itemHeight,
          verticalPadding: verticalPadding,
        );

        final screenSize = MediaQuery.of(context).size;

        // 调整位置确保不超出屏幕
        final adjustedPosition = Offset(
          position.dx > screenSize.width - menuWidth
              ? screenSize.width - menuWidth - 8
              : position.dx,
          position.dy > screenSize.height - menuHeight
              ? screenSize.height - menuHeight - 8
              : position.dy,
        );

        return Positioned(
          left: adjustedPosition.dx,
          top: adjustedPosition.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: removeContextMenu,
            child: MouseRegion(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: menuWidth,
                  height: menuHeight,
                  child: ContextMenu(
                    onOpenExplorer: () => _openInExplorer(path),
                    onClose: removeContextMenu,
                    itemHeight: itemHeight,
                    padding: verticalPadding,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_contextMenuOverlayEntry!);
  }

  void removeContextMenu() {
    _contextMenuOverlayEntry?.remove();
    _contextMenuOverlayEntry = null;
  }

  Future<void> _openInExplorer(String path) async {
    try {
      await _explorerService.openInExplorer(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('打开资源管理器失败: $e')));
      }
    }
  }
}
