import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String initialDirectory;
  final Function(String) onSave;

  const SettingsScreen({
    super.key,
    required this.initialDirectory,
    required this.onSave,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _directoryController;

  @override
  void initState() {
    super.initState();
    _directoryController = TextEditingController(text: widget.initialDirectory);
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
            ElevatedButton(
              onPressed: () {
                widget.onSave(_directoryController.text);
              },
              child: const Text('保存设置'),
            ),
          ],
        ),
      ),
    );
  }
}
