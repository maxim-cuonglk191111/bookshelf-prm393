import 'package:bookshelf/logic/book.dart';
import 'package:bookshelf/logic/book_filters.dart';
import 'package:bookshelf/logic/validators.dart';
import 'package:flutter_test/flutter_test.dart';

Book b(String t, String a, {String g = 'Fiction', String s = 'To Read', bool fav = false}) =>
    Book(id: '$t|$a', userId: 'u', title: t, author: a, genre: g, status: s, favorite: fav);

void main() {
  test('title / author / notes limits', () {
    expect(validateTitle('  '), 'Title is required');
    expect(validateTitle('a' * 100), isNull);
    expect(validateTitle('a' * 101), 'Title must be at most 100 characters');
    expect(validateAuthor('a' * 60), isNull);
    expect(validateAuthor('a' * 61), 'Author must be at most 60 characters');
    expect(validateNotes('a' * 300), isNull);
    expect(validateNotes('a' * 301), 'Notes must be at most 300 characters');
  });

  test('rating', () {
    for (final ok in ['', ' ', '0', '5', '3']) {
      expect(validateRating(ok), isNull, reason: ok);
    }
    for (final bad in ['-1', '6', '2.5', 'abc', '10']) {
      expect(validateRating(bad), ratingError, reason: bad);
    }
  });

  test('auth messages', () {
    expect(validateEmail(''), 'Email is required');
    expect(validateEmail('abc'), 'Please enter a valid email address');
    expect(validateEmail('a@b.co'), isNull);
    expect(validatePassword(''), 'Password is required');
    expect(validatePassword('123'), isNull);
    expect(validatePassword('123', requireMinLength: true), 'Password must be at least 6 characters');
    expect(validateConfirmPassword('', 'x'), 'Confirm password is required');
    expect(validateConfirmPassword('y', 'x'), 'Passwords do not match');
    expect(validateGenre(''), 'Please choose a genre');
    expect(validateStatus(''), 'Please choose a status');
  });

  test('sort: case-insensitive title, then author', () {
    final l = [b('dune', 'Z'), b('Dune', 'A'), b('Alpha', 'Q')]..sort(compareBooks);
    expect(l.map((e) => e.author), ['Q', 'A', 'Z']);
  });

  test('book key ignores case, trims, and is unambiguous', () {
    expect(bookKey('u', 'Dune', 'Herbert'), bookKey('u', ' dune ', 'HERBERT'));
    expect(bookKey('u', 'Dune', 'H'), isNot(bookKey('v', 'Dune', 'H')));
    expect(bookKey('u', 'a', 'b|c'), isNot(bookKey('u', 'a|b', 'c')));
    expect(bookKey('u', 'a/b', 'c').contains('/'), isFalse);
    expect(bookKey('u', 'Đ📚', 'x'), 'u|3|Đ📚|x'); // UTF-16 length, ASCII-only lower-casing
  });

  test('filters combine, search trims and ignores case', () {
    final books = [
      b('Dune', 'Herbert', g: 'Fiction', s: 'Reading', fav: true),
      b('Sapiens', 'Harari', g: 'Non-Fiction', s: 'Finished'),
      b('Emma', 'Austen', g: 'Fiction', s: 'To Read'),
    ];
    List<String> run(BookFilters f) => books.where(f.matches).map((e) => e.title).toList();
    expect(run(const BookFilters(genre: 'Fiction')), ['Dune', 'Emma']);
    expect(run(const BookFilters(genre: 'Fiction', status: 'Reading')), ['Dune']);
    expect(run(const BookFilters(favoritesOnly: true)), ['Dune']);
    expect(run(const BookFilters(query: '  HARA ')), ['Sapiens']);
    expect(run(const BookFilters(query: 'dun', favoritesOnly: true, genre: 'Non-Fiction')), isEmpty);
  });

  test('summary: counts and status order (ties: To Read, Reading, Finished)', () {
    final s = summarize([
      b('a', '1', s: 'Finished', fav: true),
      b('b', '2', s: 'Reading'),
      b('c', '3', s: 'To Read'),
      b('d', '4', s: 'Finished'),
    ]);
    expect(s.total, 4);
    expect(s.favorites, 1);
    expect(s.byStatus.map((e) => '${e.key}:${e.value}'), ['Finished:2', 'To Read:1', 'Reading:1']);
    expect(summarize([]).byStatus, isEmpty);
  });
}
