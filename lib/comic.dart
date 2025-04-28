import 'dart:io';

class Comic {
  final String title;
  final File? coverImage;
  final List<Chapter> chapters;

  Comic({
    required this.title,
    required this.coverImage,
    required this.chapters,
  });
}

class Chapter {
  final String name;
  final Directory directory;
  final List<File> pages;

  Chapter({required this.name, required this.directory, required this.pages});
}
