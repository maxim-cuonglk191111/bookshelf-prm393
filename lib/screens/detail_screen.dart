import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/books_controller.dart';
import '../logic/book.dart';
import '../ui/messenger.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'book_form.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.bookId});
  final String bookId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _id = widget.bookId;
  Book? _last; // keeps the screen steady while a rename swaps the document id
  var _editing = false;
  var _leaving = false; // deleting: do not react to the book disappearing

  Future<String?> _save(BooksController c, BookInput input) async {
    final old = _id;
    final newId = bookKey(c.uid!, input.title, input.author);
    setState(() => _id = newId);
    final err = await c.update(old, input);
    if (!mounted) return err;
    if (err != null) {
      setState(() => _id = old);
    } else {
      setState(() => _editing = false);
    }
    return err;
  }

  Future<void> _confirmDelete(BooksController c, Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this book?'),
        content: Text('"${book.title}" will be removed from your list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Palette.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _leaving = true);
    final err = await c.delete(book);
    if (!mounted) return;
    if (err != null) {
      setState(() => _leaving = false);
      showToast(err);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BooksController>();
    final book = c.byId(_id) ?? (_editing || _leaving ? _last : null);
    if (book == null) {
      // The book is gone (e.g. deleted elsewhere): go back to the list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_leaving) Navigator.maybePop(context);
      });
      return const LoadingView();
    }
    _last = book;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Book details')),
      body: PageBody(children: [
        if (_editing)
          BookForm(
            initial: book,
            submitLabel: 'Save',
            onSubmit: (i) => _save(c, i),
            onCancel: () => setState(() => _editing = false),
          )
        else ...[
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(book.title, style: t.headlineMedium?.copyWith(fontSize: 22))),
                IconButton(
                  tooltip: book.favorite ? 'Remove from favorites' : 'Add to favorites',
                  icon: Icon(book.favorite ? Icons.star : Icons.star_border, color: Palette.star),
                  onPressed: () async {
                    final err = await c.setFavorite(book);
                    if (err != null) showToast(err);
                  },
                ),
              ]),
              const Divider(),
              _Field('Author', book.author),
              _Field('Genre', book.genre),
              _Field('Status', book.status),
              _Field('Rating', book.rating?.toString() ?? '-'),
              _Field('Notes', book.notes.isEmpty ? '-' : book.notes),
            ]),
          ),
          vGap,
          Row(children: [
            Expanded(child: AppButton('Edit', onPressed: () => setState(() => _editing = true))),
            const SizedBox(width: Gap.sm),
            Expanded(child: AppButton('Delete', outlined: true, onPressed: () => _confirmDelete(c, book))),
          ]),
        ],
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: t.bodySmall),
        Text(value, style: t.bodyMedium),
      ]),
    );
  }
}
