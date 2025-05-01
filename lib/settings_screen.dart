import 'package:comico/draggable_app_bar.dart';
import 'package:comico/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  final String initialDirectory;
  final double initialGridItemWidth;
  final Function(String, double) onSave;

  const SettingsScreen({
    super.key,
    required this.initialDirectory,
    required this.initialGridItemWidth,
    required this.onSave,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _directoryController;
  late double _gridItemWidth;

  @override
  void initState() {
    super.initState();
    _directoryController = TextEditingController(text: widget.initialDirectory);
    _gridItemWidth = widget.initialGridItemWidth;
  }

  @override
  void dispose() {
    _directoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildSettingsView(),
          DraggableAppBar(
            leftActions: [Text('设置')],
            showBackButton: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            visible: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: kToolbarHeight,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDirectorySetting(),
          const SizedBox(height: 24),
          _buildGridWidthSetting(),
          const SizedBox(height: 24),
          _buildThemeSetting(themeProvider, theme),
          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildDirectorySetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('漫画目录路径', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _directoryController,
          decoration: const InputDecoration(
            hintText: '请输入漫画文件夹完整路径',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildGridWidthSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('网格项宽度', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _gridItemWidth,
                min: 80,
                max: 300,
                divisions: 22,
                label: '${_gridItemWidth.toInt()} px',
                onChanged: _updateGridWidth,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${_gridItemWidth.toInt()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeSetting(ThemeProvider themeProvider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('主题模式', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value:
                    themeProvider.themeMode == ThemeMode.dark
                        ? 'dark'
                        : 'light',
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'light', child: Text('白天模式')),
                  DropdownMenuItem(value: 'dark', child: Text('夜间模式')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.toggleTheme(value == 'dark');
                  }
                },
                dropdownColor: theme.cardColor,
                icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _saveSettings,
        child: const Text('保存设置'),
      ),
    );
  }

  void _updateGridWidth(double value) {
    setState(() => _gridItemWidth = value);
  }

  void _saveSettings() {
    widget.onSave(_directoryController.text, _gridItemWidth);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('设置已保存')));
  }
}
