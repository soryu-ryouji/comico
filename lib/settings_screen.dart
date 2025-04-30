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
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _directoryController;
  double _gridItemWidth = 150;

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _directoryController,
              decoration: const InputDecoration(
                labelText: '漫画目录路径',
                hintText: '请输入漫画文件夹完整路径',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Grid 元素宽度:'),
                Expanded(
                  child: Slider(
                    value: _gridItemWidth,
                    min: 80,
                    max: 300,
                    divisions: 22,
                    label: '${_gridItemWidth.toInt()} px',
                    onChanged: (value) {
                      setState(() {
                        _gridItemWidth = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            // 设置白天/夜间模式
            Row(
              children: [
                const Text('主题模式:'),
                const SizedBox(width: 10),
                DropdownButtonHideUnderline(
                  // 移除默认的下划线
                  child: DropdownButton<String>(
                    value:
                        themeProvider.themeMode == ThemeMode.dark
                            ? 'dark'
                            : 'light',
                    items: const [
                      DropdownMenuItem(value: 'light', child: Text('白天模式')),
                      DropdownMenuItem(value: 'dark', child: Text('夜间模式')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.toggleTheme(value == 'dark');
                      }
                    },
                    focusColor: Colors.transparent, // 移除焦点时的半透明背景
                    dropdownColor: Theme.of(context).cardColor, // 使用主题卡片颜色
                    elevation: 0, // 完全移除阴影
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium, // 使用主题文本样式
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onSave(_directoryController.text, _gridItemWidth);
              },
              child: const Text('保存设置'),
            ),
          ],
        ),
      ),
    );
  }
}
