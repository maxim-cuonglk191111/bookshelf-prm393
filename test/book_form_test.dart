import 'package:bookshelf/logic/book.dart';
import 'package:bookshelf/screens/book_form.dart';
import 'package:bookshelf/screens/home_screen.dart';
import 'package:bookshelf/ui/theme.dart';
import 'package:bookshelf/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpForm(
  WidgetTester t, {
  required Future<String?> Function(BookInput) onSubmit,
  Book? initial,
  VoidCallback? onCancel,
  double textScale = 1.0,
  Size size = const Size(390, 844),
}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(),
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
    home: Scaffold(
      body: PageBody(children: [
        BookForm(
          initial: initial,
          submitLabel: initial == null ? 'Add book' : 'Save',
          successMessage: 'Book added',
          clearOnSuccess: initial == null,
          onSubmit: onSubmit,
          onCancel: onCancel,
        ),
      ]),
    ),
  ));
}

Future<void> choose(WidgetTester t, String from, String item) async {
  await t.tap(find.text(from));
  await t.pumpAndSettle();
  await t.tap(find.text(item).last);
  await t.pumpAndSettle();
}

Future<void> type(WidgetTester t, String label, String text) async {
  await t.enterText(find.widgetWithText(TextFormField, label), text);
  await t.pump();
}

Future<void> tapButton(WidgetTester t, String label) async {
  await t.ensureVisible(find.text(label));
  await t.tap(find.text(label));
  await t.pumpAndSettle();
}

const errors = [
  'Title is required',
  'Title must be at most 100 characters',
  'Author is required',
  'Author must be at most 60 characters',
  'Please choose a genre',
  'Please choose a status',
  'Rating must be a whole number from 0 to 5',
  'Notes must be at most 300 characters',
];

void main() {
  testWidgets('first load shows no error and the dropdowns start on the empty choice', (t) async {
    await pumpForm(t, onSubmit: (_) async => null);
    for (final e in errors) {
      expect(find.text(e), findsNothing);
    }
    expect(find.text('Choose genre'), findsOneWidget);
    expect(find.text('Choose status'), findsOneWidget);
  });

  testWidgets('empty submit shows title, author, genre, status messages only; they clear as fields become valid', (t) async {
    var calls = 0;
    await pumpForm(t, onSubmit: (_) async {
      calls++;
      return null;
    });
    await tapButton(t, 'Add book');
    expect(calls, 0);
    for (final e in ['Title is required', 'Author is required', 'Please choose a genre', 'Please choose a status']) {
      expect(find.text(e), findsOneWidget, reason: e);
    }
    expect(find.text('Rating must be a whole number from 0 to 5'), findsNothing);
    expect(find.text('Notes must be at most 300 characters'), findsNothing);

    await type(t, 'Title', 'Dune');
    expect(find.text('Title is required'), findsNothing);
    expect(find.text('Author is required'), findsOneWidget);
    await choose(t, 'Choose genre', 'Fiction');
    expect(find.text('Please choose a genre'), findsNothing);
    expect(find.text('Please choose a status'), findsOneWidget);
  });

  testWidgets('spaces only counts as empty; length and rating rules', (t) async {
    await pumpForm(t, onSubmit: (_) async => null);
    await type(t, 'Title', '    ');
    await type(t, 'Author', ' ' * 5);
    await tapButton(t, 'Add book');
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Author is required'), findsOneWidget);

    await type(t, 'Title', 'a' * 101);
    await type(t, 'Author', 'b' * 61);
    await type(t, 'Rating (0-5, optional)', '2.5');
    await type(t, 'Notes (optional)', 'n' * 301);
    await tapButton(t, 'Add book');
    expect(find.text('Title must be at most 100 characters'), findsOneWidget);
    expect(find.text('Author must be at most 60 characters'), findsOneWidget);
    expect(find.text('Rating must be a whole number from 0 to 5'), findsOneWidget);
    expect(find.text('Notes must be at most 300 characters'), findsOneWidget);

    await type(t, 'Title', 'a' * 100);
    await type(t, 'Author', 'b' * 60);
    await type(t, 'Rating (0-5, optional)', '5');
    await type(t, 'Notes (optional)', 'n' * 300);
    for (final e in errors.where((e) => !e.contains('choose'))) {
      expect(find.text(e), findsNothing, reason: e);
    }
  });

  testWidgets('valid submit sends trimmed values, clears the form, shows Book added and no errors', (t) async {
    BookInput? got;
    await pumpForm(t, onSubmit: (i) async {
      got = i;
      return null;
    });
    await type(t, 'Title', '  The Hobbit ');
    await type(t, 'Author', ' Tolkien');
    await choose(t, 'Choose genre', 'Fiction');
    await choose(t, 'Choose status', 'To Read');
    await type(t, 'Rating (0-5, optional)', '4');
    await type(t, 'Notes (optional)', ' prequel ');
    await tapButton(t, 'Add book');

    expect(got, isNotNull);
    expect([got!.title, got!.author, got!.genre, got!.status, got!.rating, got!.notes],
        ['The Hobbit', 'Tolkien', 'Fiction', 'To Read', 4, 'prequel']);
    expect(find.text('Book added'), findsOneWidget);
    expect(find.text('Choose genre'), findsOneWidget);
    expect(find.text('Choose status'), findsOneWidget);
    for (final e in errors) {
      expect(find.text(e), findsNothing);
    }
    expect(find.text('The Hobbit'), findsNothing); // fields were cleared
  });

  testWidgets('a Firestore error is shown on the form and nothing is cleared', (t) async {
    await pumpForm(t, onSubmit: (_) async => 'Missing or insufficient permissions.');
    await type(t, 'Title', 'Dune');
    await type(t, 'Author', 'Herbert');
    await choose(t, 'Choose genre', 'Fiction');
    await choose(t, 'Choose status', 'Reading');
    await tapButton(t, 'Add book');
    expect(find.text('Missing or insufficient permissions.'), findsOneWidget);
    expect(find.text('Book added'), findsNothing);
    expect(find.text('Dune'), findsOneWidget);
  });

  testWidgets('edit mode starts from the book, validates the same way, and Cancel works', (t) async {
    var cancelled = false;
    const book = Book(
        id: 'x', userId: 'u', title: 'Dune', author: 'Herbert', genre: 'Fiction', status: 'Reading', rating: 5, notes: 'Epic');
    await pumpForm(t, initial: book, onSubmit: (_) async => null, onCancel: () => cancelled = true);
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Fiction'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    await type(t, 'Title', '');
    await type(t, 'Rating (0-5, optional)', '9');
    await tapButton(t, 'Save');
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Rating must be a whole number from 0 to 5'), findsOneWidget);
    await tapButton(t, 'Cancel');
    expect(cancelled, isTrue);
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('no overflow: form with errors at $size and ${scale}x text', (t) async {
        await pumpForm(t, onSubmit: (_) async => null, textScale: scale, size: size);
        await tapButton(t, 'Add book');
        expect(t.takeException(), isNull);
      });

      testWidgets('no overflow: Home at $size and ${scale}x text', (t) async {
        t.view.physicalSize = size * 2;
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        await t.pumpWidget(MaterialApp(
          theme: buildTheme(),
          builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
          home: const HomeScreen(),
        ));
        expect(t.takeException(), isNull);
        expect(find.text('BookShelf'), findsWidgets);
        expect(find.text('Login'), findsOneWidget);
        expect(find.text('Register'), findsOneWidget);
      });
    }
  }
}
