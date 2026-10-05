import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m18_residences_shared/m18_residences_shared.dart';

Widget app(Widget home, {void Function(BuildContext)? onLogout}) {
  final material = MaterialApp(theme: AppTheme.lightTheme, home: home);
  return onLogout == null ? material : LogoutScope(onLogout: onLogout, child: material);
}

void main() {
  group('CustomTextFormField', () {
    testWidgets('shows the validator message', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextFormField(
                controller: TextEditingController(),
                labelText: 'Room Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Room Name'), findsOneWidget);
    });

    testWidgets('wraps the field in a Semantics identifier only when semanticsId is set', (tester) async {
      Finder semanticsWithId(String id) => find.byWidgetPredicate((w) => w is Semantics && w.properties.identifier == id);

      await tester.pumpWidget(
        app(
          Scaffold(
            body: Column(
              children: [
                CustomTextFormField(controller: TextEditingController(), labelText: 'Username', semanticsId: 'admin-username'),
                CustomTextFormField(controller: TextEditingController(), labelText: 'Password'),
              ],
            ),
          ),
        ),
      );

      expect(semanticsWithId('admin-username'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.identifier != null), findsOneWidget);
    });
  });

  testWidgets('CustomDropdownForm reports the picked value', (tester) async {
    int? picked;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: CustomDropdownForm<int>(
            label: 'Room',
            items: const [
              DropdownMenuItem(value: 1, child: Text('Room 101')),
              DropdownMenuItem(value: 2, child: Text('Room 102')),
            ],
            value: null,
            onChanged: (v) => picked = v,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Room'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Room 102').last);
    await tester.pumpAndSettle();

    expect(picked, 2);
  });

  group('CustomAppBar', () {
    testWidgets('logout button runs the LogoutScope action', (tester) async {
      var loggedOut = 0;
      await tester.pumpWidget(
        app(
          Scaffold(appBar: CustomAppBar(title: 'Welcome Admin!', logoutOnBack: true)),
          onLogout: (_) => loggedOut++,
        ),
      );

      await tester.tap(find.byTooltip('Logout'));
      expect(loggedOut, 1);
    });

    testWidgets('logout without a LogoutScope fails loudly', (tester) async {
      await tester.pumpWidget(app(Scaffold(appBar: CustomAppBar(title: 'Home', logoutOnBack: true))));

      await tester.tap(find.byTooltip('Logout'));
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('back button pops the route; subtitle and refresh are shown', (tester) async {
      var refreshed = 0;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: CustomAppBar(title: 'Billing', subtitle: 'ANA', showRefresh: true, onRefresh: () => refreshed++, centerTitle: true),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('ANA'), findsOneWidget);
      await tester.tap(find.byTooltip('Refresh'));
      expect(refreshed, 1);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('ErrorView', () {
    testWidgets('Refresh runs onRetry when given', (tester) async {
      var retried = 0;
      var loggedOut = 0;
      await tester.pumpWidget(
        app(
          ErrorView(message: 'Failed to load rooms', onRetry: () => retried++),
          onLogout: (_) => loggedOut++,
        ),
      );

      await tester.tap(find.text('Refresh'));
      expect((retried, loggedOut), (1, 0));
      expect(find.text('Failed to load rooms'), findsOneWidget);
    });

    testWidgets('Refresh logs out when there is nothing to retry', (tester) async {
      var loggedOut = 0;
      await tester.pumpWidget(app(const ErrorView(message: 'Session has expired'), onLogout: (_) => loggedOut++));

      await tester.tap(find.text('Refresh'));
      expect(loggedOut, 1);
    });
  });

  testWidgets('LoadingOverlay reveals the slow-server message after 5 seconds', (tester) async {
    await tester.pumpWidget(app(const Scaffold(body: LoadingOverlay())));

    double opacity() => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
    expect(opacity(), 0.0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 600));
    expect(opacity(), 1.0);
    expect(find.textContaining('Server taking too long to respond'), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // dispose the repeating animation
  });

  group('ReceiptLink', () {
    Future<SignedFile> neverCalled(String _, String _) => throw StateError('should not fetch');

    testWidgets('renders nothing without a receipt (null or empty URL) or tenant name', (tester) async {
      for (final (name, url) in [('ANA', null), ('ANA', ''), (null, '1727000000-r3')]) {
        await tester.pumpWidget(
          app(
            Scaffold(
              body: ReceiptLink(tenantName: name, receiptUrl: url, fetchSignedFile: neverCalled),
            ),
          ),
        );
        expect(find.byType(InkWell), findsNothing);
      }
    });

    testWidgets('shows the file name and opens a dialog with the fetch error', (tester) async {
      final requested = <(String, String)>[];
      final completer = Completer<SignedFile>();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ReceiptLink(
              tenantName: 'ANA',
              receiptUrl: '1727000000-r3',
              fetchSignedFile: (name, file) {
                requested.add((name, file));
                return completer.future;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('1727000000-r3'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(requested, [('ANA', '1727000000-r3')]);

      completer.completeError(const ApiException(404, '{"error":"Receipt not found"}'));
      await tester.pump();
      expect(find.text('Error loading receipt: Receipt not found'), findsOneWidget);
    });

    testWidgets('showFullName shows the whole storage key', (tester) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ReceiptLink(tenantName: 'ANA', receiptUrl: '1727000000-r3', fetchSignedFile: neverCalled, showFullName: true),
          ),
        ),
      );
      expect(find.text('receipts/ANA/1727000000-r3'), findsOneWidget);
    });
  });

  testWidgets('SignedImageDialog fetches its URL only once across rebuilds', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => SignedImageDialog.show(
              context,
              fetchFile: () async {
                calls++;
                throw const ApiException(500, 'down');
              },
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(calls, 1);
    expect(find.text('Error loading image: down'), findsOneWidget);
  });

  testWidgets('SignedImageDialog offers PDFs in a new tab instead of showing them', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => SignedImageDialog.show(
              context,
              subject: 'receipt',
              fetchFile: () async => const SignedFile(url: 'https://api.test/api/files/r.pdf', contentType: 'application/pdf'),
              openUrl: opened.add,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('This receipt is a PDF.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(opened, isEmpty, reason: 'only a tap opens the tab');

    await tester.tap(find.text('Open PDF'));
    expect(opened, ['https://api.test/api/files/r.pdf']);
  });

  testWidgets('SignedImageDialog saves under its save name, reports failures and closes', (tester) async {
    const pdf = SignedFile(url: 'https://api.test/api/files/r.pdf', contentType: 'application/pdf');
    final saved = <(SignedFile, String)>[];
    var fail = false;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => SignedImageDialog.show(
              context,
              subject: 'receipt',
              fileName: 'receipts/ANA/1727000000-r3',
              saveName: 'receipt-ANA-1727000000-r3',
              fetchFile: () async => pdf,
              saveFile: (file, name) async {
                if (fail) throw Exception('offline');
                saved.add((file, name));
              },
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('receipts/ANA/1727000000-r3'), findsOneWidget);

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(saved, [(pdf, 'receipt-ANA-1727000000-r3')]);

    fail = true;
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saving the receipt failed: Exception: offline'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('SignedImageDialog disables Save until the file is fetched, and when fetching failed', (tester) async {
    final completer = Completer<SignedFile>();
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => SignedImageDialog.show(context, fetchFile: () => completer.future),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    IconButton save() => tester.widget<IconButton>(find.ancestor(of: find.byIcon(Icons.download), matching: find.byType(IconButton)));
    expect(save().onPressed, isNull);
    expect(find.text('Image'), findsOneWidget, reason: 'the capitalized subject when there is no file name');

    completer.completeError(const ApiException(500, 'down'));
    await tester.pump();
    expect(save().onPressed, isNull);
  });

  testWidgets('pages and dialogs each get their own selection area', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => showSelectableDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(content: Text('Account 1234')),
                      ),
                      child: const Text('open dialog'),
                    ),
                  ),
                ),
              ),
              child: const Text('open page'),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(SelectionArea), findsOneWidget, reason: 'the first page');

    await tester.tap(find.text('open page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();
    // The dialog's text belongs to the dialog's own area, not to one shared with the hidden pages below.
    final dialogArea = find.ancestor(of: find.text('Account 1234'), matching: find.byType(SelectionArea));
    expect(dialogArea, findsOneWidget);
    expect(find.descendant(of: dialogArea, matching: find.text('open page', skipOffstage: false)), findsNothing);

    await tester.longPress(find.text('Account 1234'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Copy'), findsOneWidget);
  });

  group('responsive', () {
    test('WindowSize.fromWidth uses the 600 / 1024 breakpoints', () {
      expect(WindowSize.fromWidth(360), WindowSize.compact);
      expect(WindowSize.fromWidth(599), WindowSize.compact);
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(1023), WindowSize.medium);
      expect(WindowSize.fromWidth(1024), WindowSize.expanded);
    });

    Future<void> pumpAt(WidgetTester tester, double width, Widget child) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(child));
    }

    for (final (width, expected) in [(360.0, 'compact'), (800.0, 'medium'), (1440.0, 'expanded')]) {
      testWidgets('ResponsiveBuilder and context.windowSize pick $expected at $width px', (tester) async {
        await pumpAt(
          tester,
          width,
          Builder(
            builder: (context) => Column(
              children: [
                Text('window: ${context.windowSize.name}'),
                ResponsiveBuilder(
                  compact: (_) => const Text('compact'),
                  medium: (_) => const Text('medium'),
                  expanded: (_) => const Text('expanded'),
                ),
              ],
            ),
          ),
        );
        expect(find.text('window: $expected'), findsOneWidget);
        expect(find.text(expected), findsOneWidget);
      });
    }

    testWidgets('ResponsiveBuilder falls back expanded -> medium -> compact', (tester) async {
      await pumpAt(tester, 1440, ResponsiveBuilder(compact: (_) => const Text('compact')));
      expect(find.text('compact'), findsOneWidget);
    });

    testWidgets('ResponsiveCenter caps the content width', (tester) async {
      await pumpAt(
        tester,
        1440,
        const ResponsiveCenter(
          child: SizedBox(key: Key('content'), width: double.infinity, height: 10),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('content'))).width, WindowSize.maxContentWidth);
    });
  });
}
