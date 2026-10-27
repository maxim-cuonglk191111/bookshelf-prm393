import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/book.dart';

/// Thrown by [BooksRepository.update] when a rename would collide with another book.
class DuplicateBookException implements Exception {
  @override
  String toString() => 'A book with the same title and author is already saved.';
}

class BooksRepository {
  BooksRepository([FirebaseFirestore? db]) : _col = (db ?? FirebaseFirestore.instance).collection('books');

  final CollectionReference<Map<String, dynamic>> _col;

  Stream<List<Book>> watch(String uid) => _col
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Book.fromDoc(d.id, d.data())).toList()..sort(compareBooks));

  Map<String, dynamic> _data(String id, String uid, BookInput i, bool favorite, Object createdAt) => {
        'id': id,
        'userId': uid,
        'title': i.title,
        'author': i.author,
        'genre': i.genre,
        'status': i.status,
        'rating': i.rating,
        'favorite': favorite,
        'notes': i.notes,
        'createdAt': createdAt,
      };

  /// A transaction is used so nothing shows up locally before the server accepts the
  /// write. A duplicate title+author hits an existing document: the rules refuse it
  /// because createdAt would change.
  Future<void> add(String uid, BookInput i) {
    final id = bookKey(uid, i.title, i.author);
    return _col.firestore.runTransaction((tx) async {
      tx.set(_col.doc(id), _data(id, uid, i, false, FieldValue.serverTimestamp()));
    });
  }

  Future<void> setFavorite(Book b, bool value) => _col.doc(b.id).update({'favorite': value});

  Future<void> delete(Book b) => _col.doc(b.id).delete();

  /// Returns the id of the saved book (it changes when title/author change the key).
  Future<String> update(Book old, BookInput i) async {
    final newId = bookKey(old.userId, i.title, i.author);
    if (newId == old.id) {
      await _col.doc(old.id).update({
        'title': i.title,
        'author': i.author,
        'genre': i.genre,
        'status': i.status,
        'rating': i.rating,
        'notes': i.notes,
      });
      return old.id;
    }
    await _col.firestore.runTransaction((tx) async {
      final target = await tx.get(_col.doc(newId));
      if (target.exists) throw DuplicateBookException();
      tx.delete(_col.doc(old.id));
      tx.set(_col.doc(newId), _data(newId, old.userId, i, old.favorite, Timestamp.fromDate(old.createdAt!)));
    });
    return newId;
  }
}
