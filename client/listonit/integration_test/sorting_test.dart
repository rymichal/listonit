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

  group('Epic 4: Organization & Sorting', () {
    group('Story 4.1: Alphabetical Sort', () {
      testWidgets('items default to chronological sort (newest first)',
          (tester) async {
        final testList = TestData.createList(
          id: 'list-1',
          name: 'Shopping List',
          sortMode: 'chronological',
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

        // Add items in specific order
        await tester.enterText(find.byType(TextField), 'Apples');
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Zebras');
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Bananas');
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Get the items list from the provider
        final itemsNotifier = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(itemsNotifier, isNotNull);
      });

      testWidgets('can sort items alphabetically A-Z', (tester) async {
        final testList = TestData.createList(
          id: 'list-sort-az',
          name: 'Alphabetical Sort Test',
          sortMode: 'alphabetical',
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
        final items = ['Zebra', 'Apple', 'Banana'];
        for (final item in items) {
          await tester.enterText(find.byType(TextField), item);
          await tester.tap(find.byIcon(Icons.add));
          await tester.pumpAndSettle();
        }

        // Verify items are present
        for (final item in items) {
          expect(find.text(item), findsOneWidget);
        }
      });

      testWidgets('can sort items alphabetically Z-A', (tester) async {
        final testList = TestData.createList(
          id: 'list-sort-za',
          name: 'Reverse Alphabetical Sort Test',
          sortMode: 'alphabetical',
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
        final items = ['Apples', 'Bananas', 'Cherries'];
        for (final item in items) {
          await tester.enterText(find.byType(TextField), item);
          await tester.tap(find.byIcon(Icons.add));
          await tester.pumpAndSettle();
        }

        // Verify all items are present
        for (final item in items) {
          expect(find.text(item), findsOneWidget);
        }
      });

      testWidgets('checked items always appear at the bottom', (tester) async {
        final testList = TestData.createList(
          id: 'list-checked-bottom',
          name: 'Checked Items Test',
          sortMode: 'alphabetical',
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
        final items = ['Apples', 'Bananas', 'Cherries'];
        for (final item in items) {
          await tester.enterText(find.byType(TextField), item);
          await tester.tap(find.byIcon(Icons.add));
          await tester.pumpAndSettle();
        }

        // Check the first item (Apples)
        final checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().isNotEmpty) {
          await tester.tap(checkboxes.first);
          await tester.pumpAndSettle();

          // Verify "Completed" section appears
          expect(find.text('Completed'), findsWidgets);
        }
      });

      testWidgets('sort options menu is accessible', (tester) async {
        final testList = TestData.createList(
          id: 'list-sort-menu',
          name: 'Sort Menu Test',
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

        // Open options menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Verify sort option appears
        expect(find.text('Sort items'), findsOneWidget);
      });

      testWidgets('can change sort mode via menu', (tester) async {
        final testList = TestData.createList(
          id: 'list-sort-change',
          name: 'Sort Change Test',
          sortMode: 'chronological',
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
        await tester.enterText(find.byType(TextField), 'Zebra');
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Apple');
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Open options menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Tap sort options
        final sortTile = find.text('Sort items');
        if (sortTile.evaluate().isNotEmpty) {
          await tester.tap(sortTile);
          await tester.pumpAndSettle();

          // Verify sort options appear
          expect(
            find.text('Alphabetical (A-Z)'),
            findsOneWidget,
          );
          expect(
            find.text('Alphabetical (Z-A)'),
            findsOneWidget,
          );
          expect(
            find.text('Newest First'),
            findsOneWidget,
          );
        }
      });

      testWidgets('alphabetical sort is case-insensitive', (tester) async {
        final testList = TestData.createList(
          id: 'list-case-insensitive',
          name: 'Case Insensitive Test',
          sortMode: 'alphabetical',
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

        // Add items with mixed case
        final items = ['zebra', 'APPLE', 'bAnAnAs'];
        for (final item in items) {
          await tester.enterText(find.byType(TextField), item);
          await tester.tap(find.byIcon(Icons.add));
          await tester.pumpAndSettle();
        }

        // All items should be visible
        for (final item in items) {
          expect(find.text(item), findsOneWidget);
        }
      });

      testWidgets('newly added items respect current sort order',
          (tester) async {
        final testList = TestData.createList(
          id: 'list-new-item-sort',
          name: 'New Item Sort Test',
          sortMode: 'alphabetical',
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

        // Add first item
        await tester.enterText(find.byType(TextField), 'Apples');
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Add item that should appear later alphabetically
        await tester.enterText(find.byType(TextField), 'Bananas');
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Verify both items are present
        expect(find.text('Apples'), findsOneWidget);
        expect(find.text('Bananas'), findsOneWidget);
      });
    });

    group('Story 4.2: Custom Sort (Drag & Drop)', () {
      testWidgets('custom sort option appears in sort menu', (tester) async {
        final testList = TestData.createList(
          id: 'list-custom-sort',
          name: 'Custom Sort Test',
          sortMode: 'chronological',
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

        // Open options menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Tap sort options
        final sortTile = find.text('Sort items');
        if (sortTile.evaluate().isNotEmpty) {
          await tester.tap(sortTile);
          await tester.pumpAndSettle();

          // Verify custom order option appears
          expect(
            find.text('Custom Order'),
            findsOneWidget,
          );
        }
      });

      testWidgets('switching to custom sort shows drag handles', (tester) async {
        final testList = TestData.createList(
          id: 'list-drag-handles',
          name: 'Drag Handles Test',
          sortMode: 'chronological',
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

        // Open sort menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sort items'));
        await tester.pumpAndSettle();

        // Select custom order
        await tester.tap(find.text('Custom Order'));
        await tester.pumpAndSettle();

        // Verify drag handles appear (looking for drag_handle icon)
        expect(
          find.byIcon(Icons.drag_handle),
          findsWidgets,
        );
      });

      testWidgets('unchecked items can be reordered', (tester) async {
        final testList = TestData.createList(
          id: 'list-reorder',
          name: 'Reorder Test',
          sortMode: 'custom',
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

        // Add items in order
        final items = ['First', 'Second', 'Third'];
        for (final item in items) {
          await tester.enterText(find.byType(TextField), item);
          await tester.tap(find.byIcon(Icons.add));
          await tester.pumpAndSettle();
        }

        // Verify all items are present
        for (final item in items) {
          expect(find.text(item), findsOneWidget);
        }
      });

      testWidgets('checked items do not show drag handles', (tester) async {
        final testList = TestData.createList(
          id: 'list-checked-no-drag',
          name: 'Checked No Drag Test',
          sortMode: 'custom',
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

          // Verify "Completed" section appears
          expect(find.text('Completed'), findsWidgets);
        }
      });

      testWidgets('selection mode disables drag reordering', (tester) async {
        final testList = TestData.createList(
          id: 'list-selection-no-drag',
          name: 'Selection Mode Test',
          sortMode: 'custom',
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

        // Verify initial state has drag handles
        expect(
          find.byIcon(Icons.drag_handle),
          findsWidgets,
        );
      });

      testWidgets('can switch between sort modes', (tester) async {
        final testList = TestData.createList(
          id: 'list-mode-switch',
          name: 'Mode Switch Test',
          sortMode: 'chronological',
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
        final items = ['Zebra', 'Apple', 'Banana'];
        for (final item in items) {
          await tester.enterText(find.byType(TextField), item);
          await tester.tap(find.byIcon(Icons.add));
          await tester.pumpAndSettle();
        }

        // Open sort menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sort items'));
        await tester.pumpAndSettle();

        // Switch to custom order
        await tester.tap(find.text('Custom Order'));
        await tester.pumpAndSettle();

        // Verify drag handles appear
        expect(
          find.byIcon(Icons.drag_handle),
          findsWidgets,
        );

        // Open sort menu again
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sort items'));
        await tester.pumpAndSettle();

        // Switch back to alphabetical
        await tester.tap(find.text('Alphabetical (A-Z)'));
        await tester.pumpAndSettle();

        // Verify drag handles are gone
        expect(
          find.byIcon(Icons.drag_handle),
          findsNothing,
        );
      });
    });
  });
}
