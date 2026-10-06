import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m18_residences_shared/m18_residences_shared.dart';

Widget app(Widget home, {void Function(BuildContext)? onLogout}) {
  final material = MaterialApp(theme: AppTheme.light, home: home);
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

  group('BillFileButton', () {
    Future<SignedFile> neverCalled(String _, String _) => throw StateError('should not fetch');

    testWidgets('renders nothing without a file (null or empty URL) or tenant name', (tester) async {
      for (final (name, url) in [('ANA', null), ('ANA', ''), (null, '1727000000-r3')]) {
        await tester.pumpWidget(
          app(
            Scaffold(
              body: BillFileButton(kind: BillFileKind.receipt, tenantName: name, fileUrl: url, fetchSignedFile: neverCalled),
            ),
          ),
        );
        expect(find.byType(OutlinedButton), findsNothing);
      }
    });

    testWidgets('shows a View button, no file name, and opens a dialog with the fetch error', (tester) async {
      final requested = <(String, String)>[];
      final completer = Completer<SignedFile>();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: BillFileButton(
              kind: BillFileKind.payment,
              tenantName: 'ANA',
              fileUrl: '1727000000-r3',
              fetchSignedFile: (name, file) {
                requested.add((name, file));
                return completer.future;
              },
            ),
          ),
        ),
      );
      expect(find.textContaining('1727000000'), findsNothing);
      expect(tester.getSize(find.byType(OutlinedButton)).height, greaterThanOrEqualTo(48));

      await tester.tap(find.text('View payment'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(requested, [('ANA', '1727000000-r3')]);
      expect(find.text('Payment · ANA'), findsOneWidget);

      completer.completeError(const ApiException(404, '{"error":"Payment image not found"}'));
      await tester.pump();
      expect(find.text('Error loading payment: Payment image not found'), findsOneWidget);
    });

    testWidgets('the receipt kind says View receipt', (tester) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: BillFileButton(kind: BillFileKind.receipt, tenantName: 'ANA', fileUrl: '1-r3', fetchSignedFile: neverCalled),
          ),
        ),
      );
      expect(find.text('View receipt'), findsOneWidget);
    });
  });

  testWidgets('BillStatusChip shows the status label', (tester) async {
    for (final status in BillStatus.values) {
      await tester.pumpWidget(app(Scaffold(body: BillStatusChip(status))));
      expect(find.text(status.label), findsOneWidget);
    }
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
        theme: AppTheme.light,
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

  group('AppTheme', () {
    test('light and dark carry their status colors', () {
      expect(AppTheme.light.extension<StatusColors>(), StatusColors.light);
      expect(AppTheme.dark.extension<StatusColors>(), StatusColors.dark);
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
      expect(AppTheme.light.colorScheme.primary, AppTheme.brand);
    });

    testWidgets('BillStatusChip takes its colors from the theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: BillStatusChip(BillStatus.paid)),
        ),
      );
      final label = tester.widget<Text>(find.text('Paid'));
      expect(label.style?.color, StatusColors.dark.onPaid);
    });
  });

  group('money', () {
    test('formatPeso shows whole pesos with separators', () {
      expect(formatPeso(6050), '₱6,050');
      expect(formatPeso(0), '₱0');
      expect(formatCount(1234), '1,234');
    });

    testWidgets('MoneyText uses tabular figures', (tester) async {
      await tester.pumpWidget(app(const Scaffold(body: MoneyText(7386))));
      final text = tester.widget<Text>(find.text('₱7,386'));
      expect(text.style?.fontFeatures, AppTheme.tabularFigures);
    });
  });

  group('AdaptiveScaffold', () {
    const destinations = [
      AdaptiveDestination(label: 'Dashboard', icon: Icons.dashboard_outlined),
      AdaptiveDestination(label: 'Verify', icon: Icons.fact_check_outlined, badgeCount: 2),
      AdaptiveDestination(label: 'Billing', icon: Icons.receipt_long_outlined),
      AdaptiveDestination(label: 'Readings', icon: Icons.bolt_outlined),
      AdaptiveDestination(label: 'Tenants', icon: Icons.people_outline),
      AdaptiveDestination(label: 'Rooms', icon: Icons.meeting_room_outlined),
    ];

    Future<List<int>> pumpAt(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final selected = <int>[];
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => AdaptiveScaffold(
              destinations: destinations,
              selectedIndex: selected.isEmpty ? 0 : selected.last,
              onDestinationSelected: (i) => setState(() => selected.add(i)),
              moreSheetFooter: (_) => [const ListTile(title: Text('Logout'))],
              body: const Text('page'),
            ),
          ),
        ),
      );
      return selected;
    }

    testWidgets('compact: a bottom bar with the first four and a More sheet for the rest', (tester) async {
      final selected = await pumpAt(tester, 390);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Tenants'), findsNothing);
      expect(find.text('2'), findsOneWidget); // the Verify badge

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Logout'), findsOneWidget);
      await tester.tap(find.text('Rooms'));
      await tester.pumpAndSettle();
      expect(selected, [5]);
      expect(find.text('Logout'), findsNothing);
    });

    testWidgets('medium: a rail with labels; expanded: an extended rail', (tester) async {
      final selected = await pumpAt(tester, 800);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isFalse);
      await tester.tap(find.text('Rooms'));
      await tester.pumpAndSettle();
      expect(selected, [5]);

      await pumpAt(tester, 1440);
      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isTrue);
    });
  });

  testWidgets('EmptyState shows its title, message and action', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: EmptyState(
            icon: Icons.check,
            title: 'All payments verified',
            message: 'Nothing to check.',
            action: TextButton(onPressed: () {}, child: const Text('Refresh')),
          ),
        ),
      ),
    );
    expect(find.text('All payments verified'), findsOneWidget);
    expect(find.text('Nothing to check.'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });

  testWidgets('SelectablePage: a hidden page of an IndexedStack is not in the visible page\'s selection area', (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: IndexedStack(
            index: 1,
            children: [
              SelectablePage(child: Text('hidden')),
              SelectablePage(child: Text('shown')),
            ],
          ),
        ),
      ),
    );
    final shownArea = find.ancestor(of: find.text('shown'), matching: find.byType(SelectionArea)).first;
    expect(find.descendant(of: shownArea, matching: find.text('hidden', skipOffstage: false)), findsNothing);
    // The hidden page has an area of its own.
    expect(find.ancestor(of: find.text('hidden', skipOffstage: false), matching: find.byType(SelectionArea)), findsWidgets);
  });

  testWidgets('BrandMark paints the logo and shows its label', (tester) async {
    await tester.pumpWidget(app(const Scaffold(body: BrandMark(label: 'M18 Admin', size: 40))));
    expect(find.text('M18 Admin'), findsOneWidget);
    expect(find.bySemanticsLabel('M18 Residences logo'), findsOneWidget);
    final paint = find.descendant(of: find.byType(BrandMark), matching: find.byType(CustomPaint)).first;
    expect(tester.getSize(paint), const Size(40, 40));
  });
}
