import 'package:flutter/material.dart';
import 'comic.dart';
import 'chapter_screen.dart';
import 'dart:io';
import 'draggable_app_bar.dart';

class ComicDetailScreen extends StatelessWidget {
  final Comic comic;

  const ComicDetailScreen({super.key, required this.comic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildDetailView(),
          DraggableAppBar(leftActions: [Text(comic.title)]),
        ],
      ),
    );
  }

  Padding _buildDetailView() {
    return Padding(
      padding: const EdgeInsets.only(
        top: kToolbarHeight,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          _ComicCover(coverImage: comic.coverImage),
          _ChapterList(chapters: comic.chapters),
        ],
      ),
    );
  }
}

class _ComicCover extends StatelessWidget {
  final File? coverImage;

  const _ComicCover({this.coverImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.all(16),
      child:
          coverImage != null
              ? Image.file(coverImage!, fit: BoxFit.contain)
              : const Center(child: Icon(Icons.image, size: 100)),
    );
  }
}

class _ChapterList extends StatelessWidget {
  final List<Chapter> chapters;

  const _ChapterList({required this.chapters});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('章节列表', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return _ChapterListItem(chapter: chapter);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterListItem extends StatelessWidget {
  final Chapter chapter;

  const _ChapterListItem({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(chapter.name),
      subtitle: Text('${chapter.pages.length} 页'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _navigateToChapterViewer(context, chapter),
    );
  }

  void _navigateToChapterViewer(BuildContext context, Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterViewerScreen(chapter: chapter),
      ),
    );
  }
}
