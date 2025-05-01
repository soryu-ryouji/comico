// lib/screens/comic_screen.dart
import 'dart:io';

import 'package:comico/handler/context_menu_handler.dart';
import 'package:comico/screen/comic_detail_screen.dart';
import 'package:comico/screen/settings_screen.dart';
import 'package:comico/widgets/comic.dart';
import 'package:comico/widgets/comic_grid_view.dart';
import 'package:comico/widgets/comic_list_view.dart';
import 'package:comico/widgets/comic_search_bar.dart';
import 'package:comico/widgets/draggable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comico/services/comic_loader_service.dart';

class ComicScreen extends StatefulWidget {
  final String comicsDirectory;

  const ComicScreen({super.key, required this.comicsDirectory});

  @override
  State<ComicScreen> createState() => _ComicScreenState();
}

class _ComicScreenState extends State<ComicScreen>
    with ContextMenuHandler<ComicScreen> {
  final List<Comic> _comics = [];
  final List<Comic> _filteredComics = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ComicLoaderService _comicLoader = ComicLoaderService();

  bool _isGridView = true;
  bool _isLoading = true;
  bool _showSearchBar = false;
  double _gridItemWidth = 150.0;

  static const _prefsGridWidthKey = 'gridItemWidth';
  static const _prefsComicsDirKey = 'comicsDirectory';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadGridSettings();
    await _loadComics();
    _searchController.addListener(_filterComics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    removeContextMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildComicView(),
          _buildDraggableAppBar(),
          _buildSearchBar(_showSearchBar),
        ],
      ),
    );
  }

  Widget _buildDraggableAppBar() {
    return DraggableAppBar(
      showBackButton: false,
      leftActions: [
        IconButton(icon: const Icon(Icons.search), onPressed: _toggleSearchBar),
      ],
      rightActions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: _toggleViewMode,
        ),
        IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings),
      ],
    );
  }

  Widget _buildSearchBar(bool isVisible) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      top: kToolbarHeight + 8,
      left: 16,
      right: 16,
      child: ComicSearchBar(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onClose: _toggleSearchBar,
      ),
    );
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _filterComics();
      }
    });
  }

  Future<void> _loadGridSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gridItemWidth = prefs.getDouble(_prefsGridWidthKey) ?? 150.0;
    });
  }

  Future<void> _loadComics() async {
    setState(() => _isLoading = true);

    try {
      final comicsDir = Directory(widget.comicsDirectory);
      if (!await comicsDir.exists()) {
        _showErrorSnackbar('漫画目录 ${widget.comicsDirectory} 不存在');
        return;
      }

      final loadedComics = await _comicLoader.loadComicsFromDirectory(
        comicsDir,
      );

      setState(() {
        _comics
          ..clear()
          ..addAll(loadedComics)
          ..sort((a, b) => a.title.compareTo(b.title));
        _filteredComics.clear();
        _filteredComics.addAll(_comics);
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar('加载漫画失败: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterComics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredComics.clear();
      if (query.isEmpty) {
        _filteredComics.addAll(_comics);
      } else {
        _filteredComics.addAll(
          _comics.where((comic) => comic.title.toLowerCase().contains(query)),
        );
      }
    });
  }

  void _toggleViewMode() => setState(() => _isGridView = !_isGridView);

  Future<void> _openSettings() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(
              initialDirectory: widget.comicsDirectory,
              initialGridItemWidth: _gridItemWidth,
              onSave: (String directory, double gridItemWidth) {
                setState(() {
                  _gridItemWidth = gridItemWidth;
                });
              },
            ),
      ),
    );

    if (result != null && mounted) {
      await _handleSettingsResult(result);
    }
  }

  Future<void> _handleSettingsResult(Map<String, dynamic> result) async {
    final newDirectory = result['directory'] as String;
    final newWidth = result['gridItemWidth'] as double;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_prefsComicsDirKey, newDirectory),
      prefs.setDouble(_prefsGridWidthKey, newWidth),
    ]);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ComicScreen(comicsDirectory: newDirectory),
        ),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildComicView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final topPadding = _showSearchBar ? kToolbarHeight + 70.0 : kToolbarHeight;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child:
          _isGridView
              ? ComicGridView(
                comics: _filteredComics,
                comicsDirectory: widget.comicsDirectory,
                itemWidth: _gridItemWidth,
                onComicTap: _navigateToComicDetail,
                onContextMenu:
                    (position, path) => showContextMenu(position, path),
              )
              : ComicListView(
                comics: _filteredComics,
                comicsDirectory: widget.comicsDirectory,
                onComicTap: _navigateToComicDetail,
                onContextMenu:
                    (position, path) => showContextMenu(position, path),
              ),
    );
  }

  void _navigateToComicDetail(Comic comic) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComicDetailScreen(comic: comic)),
    );
  }
}
