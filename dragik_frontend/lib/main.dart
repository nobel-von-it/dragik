import 'dart:convert';

import 'package:dragik_frontend/models.dart';
import 'package:flutter/material.dart';

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

  void _changeTheme(bool? isDark) {
    setState(() {
      _themeMode = switch (isDark) {
        true => ThemeMode.dark,
        false => ThemeMode.light,
        null => ThemeMode.system,
      };
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
      home: MyHomePage(onThemeChanged: _changeTheme),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Function(bool?) onThemeChanged;
  const MyHomePage({super.key, required this.onThemeChanged});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController _scrollController = ScrollController();

  List<Book> _books = [];
  ContentItem? _currentTitle;

  @override
  initState() {
    super.initState();
    _loadBookFromJson();
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
              setState(() {
                _currentTitle = ci;
              });
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
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
          PopupMenuButton(
            onSelected: widget.onThemeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(value: true, child: Text('Dark')),
              const PopupMenuItem(value: false, child: Text('Light')),
              const PopupMenuItem(value: null, child: Text('System')),
            ],
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
            ? Text('PICK SOME TITLE', style: TextStyle(fontSize: 36))
            : SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    _currentTitle!.text,
                    style: TextStyle(fontSize: 18, height: 1.5),
                  ),
                ),
              ),
      ),
    );
  }
}
