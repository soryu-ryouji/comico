import 'dart:io';
import 'package:comico/widgets/comic.dart';
import 'package:comico/services/image_service.dart';

class ComicLoaderService {
  final ImageService _imageService = ImageService();

  Future<List<Comic>> loadComicsFromDirectory(Directory comicsDir) async {
    final comicDirs = await _getSubDirectories(comicsDir);
    return await Future.wait(comicDirs.map(_createComicFromDir));
  }

  Future<List<Directory>> _getSubDirectories(Directory dir) async {
    return await dir
        .list()
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();
  }

  Future<Comic> _createComicFromDir(Directory comicDir) async {
    final comicName = _getLastPathSegment(comicDir.path);
    final coverImage = await _imageService.findCoverImage(comicDir);
    final chapters = await _getChapters(comicDir);

    return Comic(
      title: comicName,
      coverImage: coverImage,
      chapters: chapters..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  Future<List<Chapter>> _getChapters(Directory comicDir) async {
    final chapterDirs = await _getSubDirectories(comicDir);
    final chapters = <Chapter>[];

    for (final chapterDir in chapterDirs) {
      final chapterName = _getLastPathSegment(chapterDir.path);
      final pages = await _imageService.getChapterPages(chapterDir);

      chapters.add(
        Chapter(
          name: chapterName,
          directory: chapterDir,
          pages: pages..sort((a, b) => _naturalCompare(a.path, b.path)),
        ),
      );
    }

    return chapters;
  }

  String _getLastPathSegment(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  int _naturalCompare(String a, String b) {
    final reg = RegExp(r'(\d+)|(\D+)');
    final ma = reg.allMatches(a);
    final mb = reg.allMatches(b);

    for (var i = 0; i < ma.length && i < mb.length; i++) {
      final am = ma.elementAt(i).group(0)!;
      final bm = mb.elementAt(i).group(0)!;

      final an = int.tryParse(am);
      final bn = int.tryParse(bm);

      if (an != null && bn != null) {
        final diff = an - bn;
        if (diff != 0) return diff;
      } else {
        final diff = am.compareTo(bm);
        if (diff != 0) return diff;
      }
    }

    return a.length.compareTo(b.length);
  }
}
