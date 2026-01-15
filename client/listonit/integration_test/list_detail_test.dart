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

  group('List Detail Screen', () {
    group('Empty State', () {
      testWidgets('shows empty state when no items', (tester) async {
        // Create a test list with no items
        final testList = TestData.createList(
          id: 'empty-list',
          name: 'Empty Shopping List',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: createTestOverrides(
              authState: authenticatedState(),
            ),
            child: MaterialApp(
              home: ListDetailScreen(list: testList),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify empty state UI elements are displayed
        expect(find.byIcon(Icons.checklist), findsOneWidget);
        expect(find.text('No items yet'), findsOneWidget);
        expect(find.text('Add your first item above'), findsOneWidget);
      });
    });

    group('Item Management', () {
      testWidgets('can add new item to list', (tester) async {
        final testList = TestData.createList(
          id: 'list-1',
          name: 'Shopping List',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: createTestOverrides(
              authState: authenticatedState(),
            ),
            child: MaterialApp(
              home: ListDetailScreen(list: testList),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify empty state is shown initially
        expect(find.text('No items yet'), findsOneWidget);

        // Enter item name in the text field
        await tester.enterText(find.byType(TextField), 'Milk');
        await tester.pumpAndSettle();

        // Tap the add button
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Verify item was added to the list
        expect(find.text('Milk'), findsOneWidget);
        expect(find.text('No items yet'), findsNothing);
      });

      testWidgets('can check off item', (tester) async {
        final testList = TestData.createList(
          id: 'list-2',
          name: 'Shopping List',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: createTestOverrides(
              authState: authenticatedState(),
            ),
            child: MaterialApp(
              home: ListDetailScreen(list: testList),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Add an item
        await tester.enterText(find.byType(TextField), 'Bread');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Verify item is in unchecked state
        expect(find.text('Bread'), findsOneWidget);
        expect(find.text('Completed'), findsNothing);

        // The checkbox is in the leading of ListTile, wrapped in a Container
        // We need to tap on the animated checkbox specifically
        // Find the first GestureDetector that's inside the ListTile leading
        // Use a more targeted approach: find Container with width 24 (the checkbox)
        final checkboxFinder = find.byWidgetPredicate(
          (widget) => widget is Container &&
                      widget.constraints?.maxWidth == 24 &&
                      widget.constraints?.maxHeight == 24,
        );

        if (checkboxFinder.evaluate().isNotEmpty) {
          await tester.tap(checkboxFinder.first);
        } else {
          // Fallback: tap left side of the Card where checkbox is
          // Get the Card and calculate the left edge
          final card = find.byType(Card).first;
          final cardCenter = tester.getCenter(card);
          await tester.tapAt(Offset(cardCenter.dx - 30, cardCenter.dy));
        }

        await tester.pumpAndSettle();

        // Verify item moved to completed section
        expect(find.text('Completed (1)'), findsOneWidget);
      });

      testWidgets('can uncheck completed item', (tester) async {
        final testList = TestData.createList(
          id: 'list-3',
          name: 'Shopping List',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: createTestOverrides(
              authState: authenticatedState(),
            ),
            child: MaterialApp(
              home: ListDetailScreen(list: testList),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Add an item
        await tester.enterText(find.byType(TextField), 'Eggs');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Check the item by tapping the checkbox (left side of card)
        final checkboxFinder = find.byWidgetPredicate(
          (widget) => widget is Container &&
                      widget.constraints?.maxWidth == 24 &&
                      widget.constraints?.maxHeight == 24,
        );

        if (checkboxFinder.evaluate().isNotEmpty) {
          await tester.tap(checkboxFinder.first);
        } else {
          final card = find.byType(Card).first;
          final cardCenter = tester.getCenter(card);
          await tester.tapAt(Offset(cardCenter.dx - 30, cardCenter.dy));
        }

        await tester.pumpAndSettle();

        // Verify item is in completed section
        expect(find.text('Completed (1)'), findsOneWidget);

        // Uncheck by tapping the checkbox again
        // After toggle, the item moves to completed section, find it again
        final checkboxFinder2 = find.byWidgetPredicate(
          (widget) => widget is Container &&
                      widget.constraints?.maxWidth == 24 &&
                      widget.constraints?.maxHeight == 24,
        );

        if (checkboxFinder2.evaluate().isNotEmpty) {
          await tester.tap(checkboxFinder2.first);
        } else {
          final card = find.byType(Card).first;
          final cardCenter = tester.getCenter(card);
          await tester.tapAt(Offset(cardCenter.dx - 30, cardCenter.dy));
        }

        await tester.pumpAndSettle();

        // Verify item moved back to unchecked section
        expect(find.text('Completed'), findsNothing);
        expect(find.text('Eggs'), findsOneWidget);
      });

      testWidgets('can add multiple items - Tests adding and displaying multiple items in the list', (tester) async {
        final testList = TestData.createList(
          id: 'list-4',
          name: 'Shopping List',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: createTestOverrides(
              authState: authenticatedState(),
            ),
            child: MaterialApp(
              home: ListDetailScreen(list: testList),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify empty state is shown initially
        expect(find.text('No items yet'), findsOneWidget);

        // Add first item
        await tester.enterText(find.byType(TextField), 'Milk');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Verify first item was added
        expect(find.text('Milk'), findsOneWidget);
        expect(find.text('No items yet'), findsNothing);

        // Add second item
        await tester.enterText(find.byType(TextField), 'Bread');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Verify second item was added
        expect(find.text('Bread'), findsOneWidget);
        expect(find.text('Milk'), findsOneWidget);

        // Add third item
        await tester.enterText(find.byType(TextField), 'Cheese');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Verify all three items are displayed
        expect(find.text('Milk'), findsOneWidget);
        expect(find.text('Bread'), findsOneWidget);
        expect(find.text('Cheese'), findsOneWidget);
      });
    });
  });
}
