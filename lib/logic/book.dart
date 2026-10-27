import 'package:cloud_firestore/cloud_firestore.dart';

const genres = ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
const statuses = ['To Read', 'Reading', 'Finished'];

class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.favorite = false,
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String notes;
  final DateTime? createdAt;

  /// Defensive read: a missing or odd field degrades instead of crashing.
  factory Book.fromDoc(String id, Map<String, dynamic> d) {
    final r = d['rating'];
    final c = d['createdAt'];
    return Book(
      id: id,
      userId: (d['userId'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      author: (d['author'] ?? '') as String,
      genre: (d['genre'] ?? '') as String,
      status: (d['status'] ?? '') as String,
      rating: r is num ? r.toInt() : null,
      favorite: d['favorite'] == true,
      notes: (d['notes'] ?? '') as String,
      createdAt: c is Timestamp ? c.toDate() : null,
    );
  }
}

/// What the Add / Edit form produces (already trimmed).
class BookInput {
  const BookInput({
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.notes = '',
  });

  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final String notes;
}

/// Document id: one book per (user, title, author), letter case ignored.
/// MUST stay identical to `bookKey` in firestore.rules. Security Rules `lower()` only
/// lower-cases ASCII letters and `size()` counts UTF-16 units, so this does the same
/// (verified against the live rules by docs/rules_check.py).
String bookKey(String userId, String title, String author) {
  String norm(String s) => s
      .trim()
      .replaceAllMapped(RegExp('[A-Z]'), (m) => m[0]!.toLowerCase())
      .replaceAll('/', '%2F');
  final t = norm(title);
  return '$userId|${t.length}|$t|${norm(author)}';
}

/// Title (case-insensitive), equal titles by author.
int compareBooks(Book a, Book b) {
  final c = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  return c != 0 ? c : a.author.toLowerCase().compareTo(b.author.toLowerCase());
}
