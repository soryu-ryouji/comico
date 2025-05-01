// lib/services/explorer_service.dart
import 'dart:io';

class ExplorerService {
  Future<void> openInExplorer(String path) async {
    try {
      final command = _getPlatformCommand(path);
      await Process.run(command[0], command.sublist(1));
    } catch (e) {
      throw Exception('打开资源管理器失败: $e');
    }
  }

  List<String> _getPlatformCommand(String path) {
    if (Platform.isWindows) {
      return ['explorer', path.replaceAll('/', '\\')];
    } else if (Platform.isMacOS) {
      return ['open', path];
    } else {
      return ['xdg-open', path];
    }
  }
}
