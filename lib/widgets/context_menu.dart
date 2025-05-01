// lib/widgets/context_menu.dart
import 'package:flutter/material.dart';

class ContextMenu extends StatelessWidget {
  final VoidCallback onOpenExplorer;
  final VoidCallback onClose;
  final double itemHeight;
  final double padding;

  static double calculateTotalHeight({
    required int itemCount,
    required double itemHeight,
    required double verticalPadding,
  }) {
    return verticalPadding * 2 + (itemHeight * itemCount);
  }

  const ContextMenu({
    super.key,
    required this.onOpenExplorer,
    required this.onClose,
    required this.itemHeight,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            icon: Icons.folder_open,
            text: '在资源管理器中打开',
            onTap: onOpenExplorer,
          ),
          _buildMenuItem(
            icon: Icons.refresh,
            text: '刷新',
            onTap: () {
              // 重新加载漫画列表逻辑
              onClose();
            },
          ),
          _buildMenuItem(icon: Icons.close, text: '关闭菜单', onTap: onClose),
          _buildMenuItem(
            icon: Icons.info,
            text: '查看详情',
            onTap: () {}, // 实际详情逻辑
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: itemHeight,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
