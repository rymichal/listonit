import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:listonit/app/app.dart';

import '../test/mocks/mock_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Story 1.2: List Detail Screen', () {
    Future<void> navigateToListDetail(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createTestOverrides(
            authState: authenticatedState(),
            listsState: listsStateWithData(),
          ),
          child: const ListonitApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to first list (Groceries)
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
    }

    testWidgets('displays list name and icon in app bar', (tester) async {
      await navigateToListDetail(tester);

      // Verify list name is in app bar
      expect(find.text('Groceries'), findsOneWidget);

      // Verify list icon is shown
      expect(find.byIcon(Icons.local_grocery_store), findsOneWidget);
    });

    testWidgets('shows empty state when no items', (tester) async {
      await navigateToListDetail(tester);

      // Verify empty state
      expect(find.text('No items yet'), findsOneWidget);
      expect(find.text('Add your first item above'), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets('has text input to add items', (tester) async {
      await navigateToListDetail(tester);

      // Verify add item input exists
      expect(find.text('Add an item...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify add button exists
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsOneWidget);
    });

    testWidgets('can add new item to list', (tester) async {
      await navigateToListDetail(tester);

      // Enter item text
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.pumpAndSettle();

      // Tap add button (FilledButton containing add icon)
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Verify item is added
      expect(find.text('Milk'), findsOneWidget);

      // Verify empty state is gone
      expect(find.text('No items yet'), findsNothing);
    });

    testWidgets('can check off item', (tester) async {
      await navigateToListDetail(tester);

      // Add an item first
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Find and tap the checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Verify completed section appears
      expect(find.text('Completed (1)'), findsOneWidget);
    });

    testWidgets('can uncheck completed item', (tester) async {
      await navigateToListDetail(tester);

      // Add and check an item
      await tester.enterText(find.byType(TextField), 'Eggs');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Verify it's in completed section
      expect(find.text('Completed (1)'), findsOneWidget);

      // Uncheck the item
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Verify completed section is gone
      expect(find.text('Completed (1)'), findsNothing);
    });

    testWidgets('can swipe to delete item', (tester) async {
      await navigateToListDetail(tester);

      // Add an item
      await tester.enterText(find.byType(TextField), 'Cheese');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Verify item exists
      expect(find.text('Cheese'), findsOneWidget);

      // Swipe to delete
      await tester.drag(find.text('Cheese'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verify item is deleted
      expect(find.text('Cheese'), findsNothing);

      // Verify empty state returns
      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('can add multiple items', (tester) async {
      await navigateToListDetail(tester);

      // Add multiple items
      final items = ['Apples', 'Bananas', 'Oranges'];
      for (final item in items) {
        await tester.enterText(find.byType(TextField), item);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      }

      // Verify all items are shown
      for (final item in items) {
        expect(find.text(item), findsOneWidget);
      }

      // Verify we have 3 checkboxes
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('has options menu in app bar', (tester) async {
      await navigateToListDetail(tester);

      // Verify more options button exists
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('options menu shows available actions', (tester) async {
      await navigateToListDetail(tester);

      // Tap more options
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify menu options
      expect(find.text('Edit list'), findsOneWidget);
      expect(find.text('Share list'), findsOneWidget);
      expect(find.text('Clear completed'), findsOneWidget);
      expect(find.text('Delete list'), findsOneWidget);
    });

    testWidgets('can navigate back to lists screen', (tester) async {
      await navigateToListDetail(tester);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify we're back on lists screen
      expect(find.text('My Lists'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Hardware Store'), findsOneWidget);
    });

    testWidgets('clear completed removes checked items', (tester) async {
      await navigateToListDetail(tester);

      // Add items
      await tester.enterText(find.byType(TextField), 'Item 1');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Item 2');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Check first item
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Open options menu and clear completed
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear completed'));
      await tester.pumpAndSettle();

      // Verify only unchecked item remains
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Completed'), findsNothing);
    });

    testWidgets('pressing enter in text field adds item', (tester) async {
      await navigateToListDetail(tester);

      // Enter text and press enter
      await tester.enterText(find.byType(TextField), 'Yogurt');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify item is added
      expect(find.text('Yogurt'), findsOneWidget);
    });
  });
}
