import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'comico',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ImageBrowserScreen(),
    );
  }
}

class ImageBrowserScreen extends StatefulWidget {
  const ImageBrowserScreen({super.key});

  @override
  _ImageBrowserScreenState createState() => _ImageBrowserScreenState();
}

class _ImageBrowserScreenState extends State<ImageBrowserScreen> {
  final String directoryPath = 'D:\\OneDrive\\Pictures\\wallpaper';
  List<File> imageFiles = [];
  int currentIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadImages();
    _focusNode.requestFocus();
  }

  Future<void> _loadImages() async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      final files = await directory.list().toList();
      final images =
          files
              .where((file) {
                final path = file.path.toLowerCase();
                return path.endsWith('.jpg') ||
                    path.endsWith('.jpeg') ||
                    path.endsWith('.png') ||
                    path.endsWith('.gif');
              })
              .cast<File>()
              .toList();

      setState(() {
        imageFiles = images;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('文件夹 $directoryPath 不存在')));
    }
  }

  void _nextImage() {
    if (imageFiles.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex + 1) % imageFiles.length;
      });
    }
  }

  void _previousImage() {
    if (imageFiles.isNotEmpty) {
      setState(() {
        currentIndex =
            (currentIndex - 1 + imageFiles.length) % imageFiles.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _nextImage();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _previousImage();
            }
          }
        },
        child: Stack(
          children: [
            if (imageFiles.isNotEmpty)
              Center(
                child: PhotoView(
                  imageProvider: FileImage(imageFiles[currentIndex]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: GestureDetector(
                onTap: _previousImage,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: GestureDetector(
                onTap: _nextImage,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  imageFiles.isNotEmpty
                      ? '${currentIndex + 1}/${imageFiles.length}'
                      : '0/0',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
