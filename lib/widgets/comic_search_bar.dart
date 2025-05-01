import 'package:flutter/material.dart';

class ComicSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClose;
  final ValueChanged<String>? onSubmitted;

  const ComicSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onClose,
    this.onSubmitted,
  });

  @override
  State<ComicSearchBar> createState() => _ComicSearchBarState();
}

class _ComicSearchBarState extends State<ComicSearchBar> {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                decoration: const InputDecoration(
                  hintText: '搜索漫画...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: widget.onSubmitted,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              padding: EdgeInsets.zero,
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}
