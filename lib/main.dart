import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'comic_screen.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final initialPath = prefs.getString('comicsDirectory') ?? 'D:\\Comics';
  final themeProvider = ThemeProvider();

  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: MyApp(initialDirectory: initialPath),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialDirectory;

  const MyApp({super.key, required this.initialDirectory});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'comico',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: ComicScreen(comicsDirectory: initialDirectory),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
