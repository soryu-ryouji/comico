import 'package:flutter/material.dart';
import 'package:comico/widgets/comic.dart';

class ComicListView extends StatelessWidget {
  final List<Comic> comics;
  final String comicsDirectory;
  final Function(Comic) onComicTap;
  final Function(Offset, String) onContextMenu;

  const ComicListView({
    super.key,
    required this.comics,
    required this.comicsDirectory,
    required this.onComicTap,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: comics.length,
      itemBuilder: (context, index) {
        final comic = comics[index];
        return _ComicListItem(
          comic: comic,
          comicsDirectory: comicsDirectory,
          onTap: () => onComicTap(comic),
          onContextMenu: onContextMenu,
        );
      },
    );
  }
}

class _ComicListItem extends StatelessWidget {
  final Comic comic;
  final String comicsDirectory;
  final VoidCallback onTap;
  final Function(Offset, String) onContextMenu;

  const _ComicListItem({
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
      child: ListTile(
        leading:
            comic.coverImage != null
                ? Image.file(
                  comic.coverImage!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                : const Icon(Icons.image),
        title: Text(comic.title),
        subtitle: Text('${comic.chapters.length} 章'),
      ),
    );
  }
}
