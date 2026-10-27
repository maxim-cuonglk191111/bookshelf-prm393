import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../logic/book.dart';
import '../logic/book_filters.dart';
import 'books_repository.dart';

/// Single source of truth for the signed-in user's books and the list filters.
class BooksController extends ChangeNotifier {
  BooksController([BooksRepository? repo]) : _repo = repo ?? BooksRepository();

  final BooksRepository _repo;
  StreamSubscription<List<Book>>? _sub;
  String? _uid;

  List<Book> _all = const [];
  bool loading = false;
  String? loadError;
  BookFilters filters = const BookFilters();

  String? get uid => _uid;
  List<Book> get all => _all;
  List<Book> get shown => _all.where(filters.matches).toList();
  Summary get summary => summarize(shown);
  Book? byId(String id) {
    for (final b in _all) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Called when the signed-in user changes; drops everything of the previous user.
  void bind(String? uid) {
    if (uid == _uid) return;
    _sub?.cancel();
    _sub = null;
    _uid = uid;
    _all = const [];
    filters = const BookFilters();
    loadError = null;
    loading = uid != null;
    if (uid != null) {
      _sub = _repo.watch(uid).listen((books) {
        _all = books;
        loading = false;
        loadError = null;
        notifyListeners();
      }, onError: (Object e) {
        loading = false;
        loadError = _message(e);
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void setFilters(BookFilters f) {
    filters = f;
    notifyListeners();
  }

  void clearFilters() => setFilters(const BookFilters());

  /// Returns null on success, otherwise the error message to show on the form.
  Future<String?> add(BookInput input) => _run(() => _repo.add(_uid!, input));

  Future<String?> update(String id, BookInput input) {
    final old = byId(id);
    if (old == null) return Future.value('This book no longer exists.');
    return _run(() => _repo.update(old, input));
  }

  Future<String?> setFavorite(Book b) => _run(() => _repo.setFavorite(b, !b.favorite));

  Future<String?> delete(Book b) => _run(() => _repo.delete(b));

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  static String _message(Object e) =>
      e is FirebaseException ? (e.message ?? e.code) : e.toString();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
