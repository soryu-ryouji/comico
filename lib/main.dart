import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'comic_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final initialPath = prefs.getString('comicsDirectory') ?? 'D:\\Comics';

  runApp(MyApp(initialDirectory: initialPath));
}

class MyApp extends StatelessWidget {
  final String initialDirectory;

  const MyApp({super.key, required this.initialDirectory});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'comico',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ComicListScreen(comicsDirectory: initialDirectory),
    );
  }
}
