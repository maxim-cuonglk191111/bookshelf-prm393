import 'package:flutter/material.dart';

import '../logic/book.dart';
import '../logic/validators.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// The one book form: used by "Add a book" on List and by Edit on Detail,
/// so both share the same fields, rules and messages.
class BookForm extends StatefulWidget {
  const BookForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
    this.onCancel,
    this.successMessage,
    this.clearOnSuccess = false,
  });

  final Book? initial;
  final String submitLabel;

  /// Returns null on success, otherwise the error message to show on the form.
  final Future<String?> Function(BookInput input) onSubmit;
  final VoidCallback? onCancel;
  final String? successMessage;
  final bool clearOnSuccess;

  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _author = TextEditingController(text: widget.initial?.author ?? '');
  late final _rating = TextEditingController(text: widget.initial?.rating?.toString() ?? '');
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  late var _genre = widget.initial?.genre ?? '';
  late var _status = widget.initial?.status ?? '';
  var _mode = AutovalidateMode.disabled; // validation starts at the first submit
  var _resets = 0;
  var _busy = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    for (final c in [_title, _author, _rating, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _mode = AutovalidateMode.onUserInteraction;
      _error = null;
      _success = null;
    });
    if (!_form.currentState!.validate()) return;
    final rating = _rating.text.trim();
    final input = BookInput(
      title: _title.text.trim(),
      author: _author.text.trim(),
      genre: _genre,
      status: _status,
      rating: rating.isEmpty ? null : int.parse(rating),
      notes: _notes.text.trim(),
    );
    setState(() => _busy = true);
    final error = await widget.onSubmit(input);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      if (error == null && widget.clearOnSuccess) {
        for (final c in [_title, _author, _rating, _notes]) {
          c.clear();
        }
        _genre = '';
        _status = '';
        _mode = AutovalidateMode.disabled;
        _resets++; // rebuilds the dropdowns with the empty choice
        _success = widget.successMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        autovalidateMode: _mode,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppTextField(label: 'Title', controller: _title, validator: validateTitle),
          vGap,
          AppTextField(label: 'Author', controller: _author, validator: validateAuthor),
          vGap,
          AppDropdown(
            key: ValueKey('genre$_resets'),
            label: 'Genre',
            placeholder: 'Choose genre',
            options: genres,
            value: _genre,
            validator: validateGenre,
            onChanged: (v) => _genre = v,
          ),
          vGap,
          AppDropdown(
            key: ValueKey('status$_resets'),
            label: 'Status',
            placeholder: 'Choose status',
            options: statuses,
            value: _status,
            validator: validateStatus,
            onChanged: (v) => _status = v,
          ),
          vGap,
          AppTextField(
            label: 'Rating (0-5, optional)',
            controller: _rating,
            keyboardType: TextInputType.number,
            validator: validateRating,
          ),
          vGap,
          AppTextField(label: 'Notes (optional)', controller: _notes, maxLines: 3, validator: validateNotes),
          vGap,
          if (widget.onCancel == null)
            AppButton(widget.submitLabel, onPressed: _submit, busy: _busy)
          else
            Row(children: [
              Expanded(child: AppButton(widget.submitLabel, onPressed: _submit, busy: _busy)),
              const SizedBox(width: Gap.sm),
              Expanded(child: AppButton('Cancel', outlined: true, onPressed: _busy ? null : widget.onCancel)),
            ]),
          if (_error != null) ...[vGap, MessageBanner(_error!)],
          if (_success != null) ...[vGap, MessageBanner(_success!, isError: false)],
        ]),
      );
}
