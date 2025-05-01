import 'package:flutter/material.dart';
import 'package:comico/widgets/comic.dart';

class ComicGridView extends StatelessWidget {
  final List<Comic> comics;
  final String comicsDirectory;
  final double itemWidth;
  final Function(Comic) onComicTap;
  final Function(Offset, String) onContextMenu;

  const ComicGridView({
    super.key,
    required this.comics,
    required this.comicsDirectory,
    required this.itemWidth,
    required this.onComicTap,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / itemWidth).floor().clamp(
          2,
          10,
        );

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: comics.length,
          itemBuilder: (context, index) {
            final comic = comics[index];
            return _ComicGridItem(
              comic: comic,
              comicsDirectory: comicsDirectory,
              onTap: () => onComicTap(comic),
              onContextMenu: onContextMenu,
            );
          },
        );
      },
    );
  }
}

class _ComicGridItem extends StatefulWidget {
  final Comic comic;
  final String comicsDirectory;
  final VoidCallback onTap;
  final Function(Offset, String) onContextMenu;

  const _ComicGridItem({
    required this.comic,
    required this.comicsDirectory,
    required this.onTap,
    required this.onContextMenu,
  });

  @override
  State<_ComicGridItem> createState() => _ComicGridItemState();
}

class _ComicGridItemState extends State<_ComicGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final comicDir =
        widget.comic.chapters.isNotEmpty
            ? widget.comic.chapters.first.directory.parent.path
            : widget.comicsDirectory;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown:
            (details) => widget.onContextMenu(details.globalPosition, comicDir),
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final hoverColor = Theme.of(context).hoverColor;

    return Card(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildCoverImage(),
                _buildHoverOverlay(_isHovered, hoverColor),
              ],
            ),
          ),
          _buildTitle(),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    return widget.comic.coverImage != null
        ? Image.file(
          widget.comic.coverImage!,
          fit: BoxFit.cover,
          width: double.infinity,
        )
        : const Center(child: Icon(Icons.image, size: 50));
  }

  Widget _buildHoverOverlay(bool isHovered, hoverColor) {
    if (!isHovered) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: hoverColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        widget.comic.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
