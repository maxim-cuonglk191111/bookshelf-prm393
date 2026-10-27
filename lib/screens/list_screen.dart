import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/books_controller.dart';
import '../logic/book.dart';
import '../ui/messenger.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'book_form.dart';
import 'detail_screen.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BooksController>();
    final shown = c.shown;
    return Scaffold(
      appBar: AppBar(
        title: Text(user.email ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('Logout')),
          const SizedBox(width: Gap.xs),
        ],
      ),
      body: PageBody(children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              maintainState: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: Gap.md),
              childrenPadding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
              title: Text('Add a book', style: Theme.of(context).textTheme.titleMedium),
              children: [
                BookForm(
                  submitLabel: 'Add book',
                  successMessage: 'Book added',
                  clearOnSuccess: true,
                  onSubmit: c.add,
                ),
              ],
            ),
          ),
        ),
        vGap,
        _Filters(controller: c),
        vGap,
        _SummaryCard(controller: c),
        vGap,
        if (c.loadError != null) MessageBanner(c.loadError!),
        if (c.loading)
          const Padding(padding: EdgeInsets.all(Gap.lg), child: Center(child: CircularProgressIndicator()))
        else if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Center(child: Text('No books found', style: Theme.of(context).textTheme.titleMedium)),
          )
        else
          for (final b in shown) ...[_BookTile(book: b, controller: c), vGapSm],
      ]),
    );
  }
}

class _Filters extends StatefulWidget {
  const _Filters({required this.controller});
  final BooksController controller;

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final f = c.filters;
    if (f.query.isEmpty && _search.text.isNotEmpty) _search.clear(); // reset by Clear / account switch
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: AppDropdown(
              key: ValueKey('fg${f.genre}'),
              label: 'Genre',
              placeholder: 'All',
              options: genres,
              value: f.genre ?? '',
              onChanged: (v) => c.setFilters(v.isEmpty ? f.copyWith(clearGenre: true) : f.copyWith(genre: v)),
            ),
          ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: AppDropdown(
              key: ValueKey('fs${f.status}'),
              label: 'Status',
              placeholder: 'All',
              options: statuses,
              value: f.status ?? '',
              onChanged: (v) => c.setFilters(v.isEmpty ? f.copyWith(clearStatus: true) : f.copyWith(status: v)),
            ),
          ),
        ]),
        vGapSm,
        AppTextField(
          label: 'Search title or author',
          controller: _search,
          onChanged: (v) => c.setFilters(f.copyWith(query: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Favorites only'),
          value: f.favoritesOnly,
          onChanged: (v) => c.setFilters(f.copyWith(favoritesOnly: v)),
        ),
        AppButton('Clear', outlined: true, onPressed: c.clearFilters),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});
  final BooksController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.summary;
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Books: ${s.total}', style: t.titleMedium),
        const SizedBox(height: Gap.xs),
        Text('Favorites: ${s.favorites}', style: t.titleMedium),
        if (s.byStatus.isNotEmpty) ...[
          vGapSm,
          const Divider(),
          vGapSm,
          for (final e in s.byStatus)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(child: Text(e.key, style: t.bodyMedium)),
                Text('${e.value}', style: t.bodyMedium),
              ]),
            ),
        ],
      ]),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book, required this.controller});
  final Book book;
  final BooksController controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.xs, Gap.sm),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(bookId: book.id))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(book.title, style: t.titleMedium),
            Text(book.author, style: t.bodyMedium),
            const SizedBox(height: Gap.xs),
            Text('${book.genre} · ${book.status}', style: t.bodySmall),
          ]),
        ),
        IconButton(
          tooltip: book.favorite ? 'Remove from favorites' : 'Add to favorites',
          icon: Icon(book.favorite ? Icons.star : Icons.star_border, color: Palette.star),
          onPressed: () async {
            final err = await controller.setFavorite(book);
            if (err != null) showToast(err);
          },
        ),
        const Icon(Icons.chevron_right, color: Palette.inkSoft),
        const SizedBox(width: Gap.xs),
      ]),
    );
  }
}
