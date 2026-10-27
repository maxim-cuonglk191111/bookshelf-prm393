import 'book.dart';

class BookFilters {
  const BookFilters({
    this.genre,
    this.status,
    this.favoritesOnly = false,
    this.query = '',
  });

  /// null = All.
  final String? genre;
  final String? status;
  final bool favoritesOnly;
  final String query;

  BookFilters copyWith({
    String? genre,
    String? status,
    bool? favoritesOnly,
    String? query,
    bool clearGenre = false,
    bool clearStatus = false,
  }) =>
      BookFilters(
        genre: clearGenre ? null : (genre ?? this.genre),
        status: clearStatus ? null : (status ?? this.status),
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        query: query ?? this.query,
      );

  bool matches(Book b) {
    if (genre != null && b.genre != genre) return false;
    if (status != null && b.status != status) return false;
    if (favoritesOnly && !b.favorite) return false;
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !b.title.toLowerCase().contains(q) &&
        !b.author.toLowerCase().contains(q)) {
      return false;
    }
    return true;
  }
}

class Summary {
  const Summary(this.total, this.favorites, this.byStatus);
  final int total;
  final int favorites;

  /// One entry per status that appears; most books first, ties in
  /// To Read, Reading, Finished order.
  final List<MapEntry<String, int>> byStatus;
}

Summary summarize(List<Book> shown) {
  final counts = <String, int>{};
  for (final b in shown) {
    counts[b.status] = (counts[b.status] ?? 0) + 1;
  }
  final rows = counts.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : statuses.indexOf(a.key).compareTo(statuses.indexOf(b.key));
    });
  return Summary(shown.length, shown.where((b) => b.favorite).length, rows);
}
