class Author {
  final String fio;
  final List<Book> books;

  Author({required this.fio, required this.books});

  factory Author.fromJson(Map<String, dynamic> json) {
    var list = json['books'] as List;
    return Author(
      fio: json['fio'],
      books: list.map((i) => Book.fromJson(i)).toList(),
    );
  }
}

class Book {
  final String title;
  final List<ContentItem> items;

  Book({required this.title, required this.items});

  factory Book.fromJson(Map<String, dynamic> json) {
    var list = json['content'] as List;
    return Book(
      title: json['book_title'],
      items: list.map((i) => ContentItem.fromJson(i)).toList(),
    );
  }
}

class ContentItem {
  final String title;
  final String text;
  bool read = false;

  ContentItem({required this.title, required this.text});

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(title: json['item_title'], text: json['text']);
  }
}
