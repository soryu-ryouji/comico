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
      body: Column(
        children: [
          DraggableAppBar(
            leftActions: [const Text('设置')],
            showBackButton: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            visible: true,
          ),
          Expanded(child: _buildSettingsView()),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDirectorySetting(),
              const SizedBox(height: 24),
              _buildGridWidthSetting(),
              const SizedBox(height: 24),
              _buildThemeSetting(themeProvider),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectorySetting() {
    return _buildSettingRow(
      label: '漫画目录路径',
      description: '设置漫画文件夹的存储路径',
      control: TextField(
        controller: _directoryController,
        decoration: const InputDecoration(
          hintText: '请输入漫画文件夹完整路径',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        onChanged: (_) => _saveSettings(),
      ),
    );
  }

  Widget _buildGridWidthSetting() {
    return _buildSettingRow(
      label: '网格项宽度',
      description: '设置漫画列表中每个网格项的宽度',
      control: Row(
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
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${_gridItemWidth.toInt()}',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSetting(ThemeProvider themeProvider) {
    return _buildSettingRow(
      label: '主题模式',
      description: '切换白天/夜间主题',
      control: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(minWidth: 150), // 设置最小宽度
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildThemeDropdownButton(themeProvider),
        ),
      ),
    );
  }

  Widget _buildThemeDropdownButton(ThemeProvider themeProvider) {
    final theme = Theme.of(context);

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: themeProvider.themeMode == ThemeMode.dark ? 'dark' : 'light',
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
        isDense: true, // 保持紧凑但通过外层约束控制大小
        focusColor: Colors.transparent,
        iconSize: 24,
        borderRadius: BorderRadius.circular(8),
        alignment: Alignment.centerRight,
        selectedItemBuilder: (BuildContext context) {
          return [
            Container(alignment: Alignment.centerRight, child: Text('白天模式')),
            Container(alignment: Alignment.centerRight, child: Text('夜间模式')),
          ];
        },
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String description,
    required Widget control,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(flex: 3, child: control),
      ],
    );
  }

  void _updateGridWidth(double value) {
    setState(() => _gridItemWidth = value);
    _saveSettings();
  }

  void _saveSettings() {
    widget.onSave(_directoryController.text, _gridItemWidth);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('设置已保存')));
  }
}
