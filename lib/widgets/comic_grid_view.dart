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

class _ComicGridItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final comicDir =
        comic.chapters.isNotEmpty
            ? comic.chapters.first.directory.parent.path
            : comicsDirectory;

    return GestureDetector(
      onTap: onTap,
      onSecondaryTapDown:
          (details) => onContextMenu(details.globalPosition, comicDir),
      child: Card(
        child: Column(
          children: [
            Expanded(
              child:
                  comic.coverImage != null
                      ? Image.file(comic.coverImage!, fit: BoxFit.cover)
                      : const Center(child: Icon(Icons.image, size: 50)),
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
  }
}
