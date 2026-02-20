import 'dart:convert';

import 'package:dragik_frontend/models.dart';
import 'package:dragik_frontend/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(
    ChangeNotifierProvider(
      create: (_) => settingsProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Читалка по ДРАГОМОЩЕНКО БАЗА',
      themeMode: settings.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: MyHomePage(),
    );
  }
}

class MySettingsPage extends StatelessWidget {
  const MySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Тема', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text('Выбор темы'),
            trailing: DropdownButton(
              value: settings.themeMode,
              onChanged: (val) {
                if (val != null) settings.setTheme(val);
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Светлая'),
                ),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Темная')),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Системная'),
                ),
              ],
            ),
          ),
          const Divider(),
          const Text(
            'Размер шрифта',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              const Icon(Icons.text_fields, size: 16),
              Expanded(
                child: Slider(
                  value: settings.fontSize,
                  min: 12,
                  max: 40,
                  divisions: 14,
                  label: settings.fontSize.round().toString(),
                  onChanged: settings.setFontSize,
                ),
              ),
              const Icon(Icons.text_fields, size: 30),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.height, size: 16),
              Expanded(
                child: Slider(
                  value: settings.fontHeight,
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  label: settings.fontHeight.toString(),
                  onChanged: settings.setFontHeight,
                ),
              ),
              const Icon(Icons.height, size: 30),
            ],
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _scrollController = ScrollController();

  List<Author> _authors = [];
  ContentItem? _currentTitle;
  String? _currentBookTitle;
  SharedPreferences? _prefs;

  @override
  initState() {
    super.initState();
    _loadBookFromJson();
    _initPrefs();

    _scrollController.addListener(_saveScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_saveScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _getStorageKey() {
    return 'scroll_${_currentBookTitle}_${_currentTitle?.title}';
  }

  void _saveScroll() {
    if (_currentTitle != null && _prefs != null) {
      _prefs?.setDouble(_getStorageKey(), _scrollController.offset);
    }
  }

  void _loadScroll() {
    if (_currentTitle != null && _prefs != null) {
      double savedOffset = _prefs!.getDouble(_getStorageKey()) ?? 0.0;
      WidgetsBinding.instance.addPostFrameCallback((s) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            savedOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadBookFromJson() async {
    String jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString("assets/dragomoshchenko.json");

    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    // read dir with all json assets
    final author = Author.fromJson(jsonMap);
    // do it in loop but now is constant
    final authors = [author];

    // books.forEach((b) {
    //   print(b.title);
    // });

    setState(() {
      _authors = authors;
    });
  }

  List<ExpansionTile> _prepareExpansionTiles() {
    return _authors.map((a) {
      return ExpansionTile(
        title: Text(a.fio),
        children: a.books.map((b) {
          return ExpansionTile(
            title: Text(b.title),
            children: b.items.map((ci) {
              return ListTile(
                title: ci.read
                    ? Row(
                        children: [
                          Icon(Icons.check),
                          Divider(indent: 5.0),
                          Expanded(child: Text(ci.title)),
                        ],
                      )
                    : Text(ci.title),
                onTap: () {
                  _saveScroll();

                  setState(() {
                    _currentTitle = ci;
                    _currentBookTitle = b.title;
                  });

                  _loadScroll();

                  Navigator.pop(context);
                },
                onLongPress: () {
                  setState(() {
                    ci.read = !ci.read;
                  });
                },
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Аркадий ДРАГОМОЩЕНКО'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MySettingsPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("Аркадий Драгомощенко")),
            ..._prepareExpansionTiles(),
          ],
        ),
      ),
      body: Center(
        child: _currentTitle == null
            ? Text(
                'PICK SOME TITLE',
                style: TextStyle(fontSize: settings.fontSize * 2),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    _currentTitle!.text,
                    style: TextStyle(
                      fontSize: settings.fontSize,
                      height: settings.fontHeight,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
