import 'package:flutter/material.dart';

class ContextMenu extends StatelessWidget {
  final Offset position;
  final VoidCallback onOpenExplorer;
  final VoidCallback onClose;

  const ContextMenu({
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
