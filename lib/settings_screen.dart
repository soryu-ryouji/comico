import 'package:flutter/material.dart';

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
