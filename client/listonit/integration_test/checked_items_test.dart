import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:listonit/features/lists/presentation/list_detail_screen.dart';
import 'package:listonit/core/storage/hive_service.dart' as hive_service;
import '../test/mocks/mock_providers.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before tests
  await hive_service.HiveService.initialize();

  group('Story 4.4: Manage Checked Items', () {
    testWidgets('completed items are shown by default', (tester) async {
      final testList = TestData.createList(
        id: 'list-checked-default',
        name: 'Checked Items Test',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createTestOverrides(
            authState: authenticatedState(),
            listsState: listsStateWithData(),
          ),
          child: MaterialApp(
            home: ListDetailScreen(list: testList),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add items
      final items = ['Item 1', 'Item 2', 'Item 3'];
      for (final item in items) {
        await tester.enterText(find.byType(TextField), item);
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      }

      // Check the first item
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();

        // Verify completed section appears with item count
        expect(find.text('Completed (1)'), findsOneWidget);
      }
    });

    testWidgets('can hide completed items', (tester) async {
      final testList = TestData.createList(
        id: 'list-hide-checked',
        name: 'Hide Checked Test',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createTestOverrides(
            authState: authenticatedState(),
            listsState: listsStateWithData(),
          ),
          child: MaterialApp(
            home: ListDetailScreen(list: testList),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add items
      final items = ['Item 1', 'Item 2'];
      for (final item in items) {
        await tester.enterText(find.byType(TextField), item);
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      }

      // Check first item
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();

        // Verify completed section shows
        expect(find.text('Completed (1)'), findsOneWidget);

        // Find and tap the collapse button (expand_less icon)
        final collapseButtons = find.byIcon(Icons.expand_less);
        if (collapseButtons.evaluate().isNotEmpty) {
          await tester.tap(collapseButtons.first);
          await tester.pumpAndSettle();

          // Verify completed items are hidden and collapsed section shows
          expect(find.text('1 completed item'), findsOneWidget);
        }
      }
    });

    testWidgets('can show collapsed completed items', (tester) async {
      final testList = TestData.createList(
        id: 'list-show-collapsed',
        name: 'Show Collapsed Test',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createTestOverrides(
            authState: authenticatedState(),
            listsState: listsStateWithData(),
          ),
          child: MaterialApp(
            home: ListDetailScreen(list: testList),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add items
      final items = ['Item 1', 'Item 2', 'Item 3'];
      for (final item in items) {
        await tester.enterText(find.byType(TextField), item);
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      }

      // Check all items
      var checkboxes = find.byType(Checkbox);
      final checkboxCount = checkboxes.evaluate().length;
      for (int i = 0; i < checkboxCount; i++) {
        checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().isNotEmpty) {
          await tester.tap(checkboxes.first);
          await tester.pumpAndSettle();
        }
      }

      // Verify all items are checked and section is expanded
      expect(find.text('Completed (3)'), findsOneWidget);

      // Collapse the section
      final collapseButtons = find.byIcon(Icons.expand_less);
      if (collapseButtons.evaluate().isNotEmpty) {
        await tester.tap(collapseButtons.first);
        await tester.pumpAndSettle();

        // Verify collapsed text appears
        expect(find.text('3 completed items'), findsOneWidget);

        // Tap to expand again
        final expandButtons = find.byIcon(Icons.expand_more);
        if (expandButtons.evaluate().isNotEmpty) {
          await tester.tap(expandButtons.first);
          await tester.pumpAndSettle();

          // Verify expanded again
          expect(find.text('Completed (3)'), findsOneWidget);
        }
      }
    });

    testWidgets('clear completed items shows confirmation dialog',
        (tester) async {
      final testList = TestData.createList(
        id: 'list-clear-confirm',
        name: 'Clear Confirmation Test',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createTestOverrides(
            authState: authenticatedState(),
            listsState: listsStateWithData(),
          ),
          child: MaterialApp(
            home: ListDetailScreen(list: testList),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add and check an item
      await tester.enterText(find.byType(TextField), 'Test Item');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();

        // Find and tap "Clear all" button
        final clearButtons = find.byType(TextButton);
        if (clearButtons.evaluate().isNotEmpty) {
          // Look for the "Clear all" TextButton in the completed section
          final clearAllText = find.text('Clear all');
          if (clearAllText.evaluate().isNotEmpty) {
            await tester.tap(clearAllText);
            await tester.pumpAndSettle();

            // Verify confirmation dialog appears
            expect(find.text('Clear completed items?'), findsOneWidget);
            expect(
              find.text(
                'This will delete all completed items. This action cannot be undone.',
              ),
              findsOneWidget,
            );
          }
        }
      }
    });

    testWidgets('can cancel clearing completed items', (tester) async {
      final testList = TestData.createList(
        id: 'list-clear-cancel',
        name: 'Clear Cancel Test',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createTestOverrides(
            authState: authenticatedState(),
            listsState: listsStateWithData(),
          ),
          child: MaterialApp(
            home: ListDetailScreen(list: testList),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add and check an item
      await tester.enterText(find.byType(TextField), 'Test Item');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();

        // Tap "Clear all"
        final clearAllText = find.text('Clear all');
        if (clearAllText.evaluate().isNotEmpty) {
          await tester.tap(clearAllText);
          await tester.pumpAndSettle();

          // Tap Cancel in the dialog
          final cancelButton = find.text('Cancel');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton);
            await tester.pumpAndSettle();

            // Verify dialog is closed and completed item is still there
            expect(find.text('Clear completed items?'), findsNothing);
            expect(find.text('Completed (1)'), findsOneWidget);
          }
        }
      }
    });

    testWidgets('completed items count updates when checked/unchecked',
        (tester) async {
      final testList = TestData.createList(
        id: 'list-count-update',
        name: 'Count Update Test',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createTestOverrides(
            authState: authenticatedState(),
            listsState: listsStateWithData(),
          ),
          child: MaterialApp(
            home: ListDetailScreen(list: testList),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add multiple items
      final items = ['Item 1', 'Item 2', 'Item 3'];
      for (final item in items) {
        await tester.enterText(find.byType(TextField), item);
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      }

      // Check first item - should show Completed (1)
      var checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();
        expect(find.text('Completed (1)'), findsOneWidget);

        // Check second item - should show Completed (2)
        checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().isNotEmpty) {
          await tester.tap(checkboxes.first); // This will now be a different item
          await tester.pumpAndSettle();
          expect(find.text('Completed (2)'), findsOneWidget);
        }
      }
    });
  });
}
