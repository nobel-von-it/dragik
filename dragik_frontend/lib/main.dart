import 'dart:convert';

import 'package:dragik_frontend/models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 18.0;

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _changeFontSize(double size) {
    setState(() {
      _fontSize = size;
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Читалка по ДРАГОМОЩЕНКО БАЗА',
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: MyHomePage(
        currentThemeMode: _themeMode,
        currentFontSize: _fontSize,
        onThemeChanged: _changeTheme,
        onFontSizeChanged: _changeFontSize,
      ),
    );
  }
}

class MySettingsPage extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final double currentFontSize;
  final Function(ThemeMode) onThemeChanged;
  final Function(double) onFontSizeChanged;

  const MySettingsPage({
    super.key,
    required this.currentThemeMode,
    required this.currentFontSize,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Тема', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text('Выбор темы'),
            trailing: DropdownButton(
              value: currentThemeMode,
              onChanged: (val) {
                if (val != null) onThemeChanged(val);
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
                  value: currentFontSize,
                  min: 12,
                  max: 40,
                  divisions: 14,
                  label: currentFontSize.round().toString(),
                  onChanged: onFontSizeChanged,
                ),
              ),
              const Icon(Icons.text_fields, size: 30),
            ],
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final double currentFontSize;
  final Function(ThemeMode) onThemeChanged;
  final Function(double) onFontSizeChanged;

  const MyHomePage({
    super.key,
    required this.currentThemeMode,
    required this.currentFontSize,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _scrollController = ScrollController();

  List<Book> _books = [];
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

    final jsonBooks = jsonMap['books'] as List<dynamic>;
    final books = jsonBooks.map((b) {
      return Book.fromJson(b as Map<String, dynamic>);
    }).toList();

    // books.forEach((b) {
    //   print(b.title);
    // });

    setState(() {
      _books = books;
    });
  }

  List<ExpansionTile> _prepareExpansionTiles() {
    return _books.map((b) {
      return ExpansionTile(
        title: Text(b.title),
        children: b.items.map((ci) {
          return ListTile(
            title: Text(ci.title),
            onTap: () {
              _saveScroll();

              setState(() {
                _currentTitle = ci;
                _currentBookTitle = b.title;
              });

              _loadScroll();

              Navigator.pop(context);
            },
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                MaterialPageRoute(
                  builder: (context) => MySettingsPage(
                    currentThemeMode: widget.currentThemeMode,
                    currentFontSize: widget.currentFontSize,
                    onThemeChanged: widget.onThemeChanged,
                    onFontSizeChanged: widget.onFontSizeChanged,
                  ),
                ),
              );
            },
          ),
          // PopupMenuButton(
          //   onSelected: widget.onThemeChanged,
          //   itemBuilder: (context) => [
          //     const PopupMenuItem(value: true, child: Text('Dark')),
          //     const PopupMenuItem(value: false, child: Text('Light')),
          //     const PopupMenuItem(value: null, child: Text('System')),
          //   ],
          // ),
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
                style: TextStyle(fontSize: widget.currentFontSize * 2),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    _currentTitle!.text,
                    style: TextStyle(
                      fontSize: widget.currentFontSize,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
