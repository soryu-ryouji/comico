// image_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class ImageService {
  static const _imageExtensions = ['.jpg', '.jpeg', '.png'];

  Future<File?> findCoverImage(Directory dir) async {
    try {
      final files =
          await dir
              .list()
              .where((entity) {
                if (entity is! File) return false;
                final path = entity.path.toLowerCase();
                return path.contains('cover') &&
                    _imageExtensions.any((ext) => path.endsWith(ext));
              })
              .cast<File>()
              .toList();

      return files.isNotEmpty ? files.first : null;
    } catch (e) {
      debugPrint('查找封面图片失败: $e');
      return null;
    }
  }

  Future<List<File>> getChapterPages(Directory chapterDir) async {
    try {
      return await chapterDir
          .list()
          .where(
            (entity) =>
                entity is File &&
                _imageExtensions.any(
                  (ext) => entity.path.toLowerCase().endsWith(ext),
                ),
          )
          .cast<File>()
          .toList();
    } catch (e) {
      debugPrint('获取章节页面失败: $e');
      return [];
    }
  }
}
