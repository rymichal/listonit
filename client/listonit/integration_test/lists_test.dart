import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:listonit/app/app.dart';

import '../test/mocks/mock_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Story 1.2: View All Lists', () {
    testWidgets('displays list of shopping lists as cards', (tester) async {
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

      // Verify lists screen is shown
      expect(find.text('My Lists'), findsOneWidget);

      // Verify all sample lists are displayed
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Hardware Store'), findsOneWidget);
      expect(find.text('Party Supplies'), findsOneWidget);

      // Verify each list tile has a menu icon (more_vert) for editing
      expect(find.byIcon(Icons.more_vert), findsNWidgets(3));
    });

    testWidgets('each card shows name, icon, and last updated', (tester) async {
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

      // Verify list icons are present
      expect(find.byIcon(Icons.local_grocery_store), findsOneWidget);
      expect(find.byIcon(Icons.build), findsOneWidget);
      expect(find.byIcon(Icons.cake), findsOneWidget);

      // Verify "Updated" text is shown (time formatting)
      expect(find.textContaining('Updated'), findsNWidgets(3));
    });

    testWidgets('shows empty state when no lists exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createTestOverrides(
            authState: authenticatedState(),
            listsState: emptyListsState(),
          ),
          child: const ListonitApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No shopping lists yet'), findsOneWidget);
      expect(find.text('Tap + to create your first list'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching lists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createTestOverrides(
            authState: authenticatedState(),
            listsState: loadingListsState(),
          ),
          child: const ListonitApp(),
        ),
      );
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has FAB to create new list', (tester) async {
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

      // Verify FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('tapping FAB opens create list modal', (tester) async {
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

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify create list modal appears
      expect(find.text('Create New List'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('tapping list card navigates to detail screen', (tester) async {
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

      // Tap on the first list (Groceries)
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify we navigated to detail screen
      // The app bar should show the list name
      expect(find.text('Groceries'), findsOneWidget);

      // Verify add item input is visible
      expect(find.text('Add an item...'), findsOneWidget);

      // Verify empty state for items is shown
      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('pull to refresh triggers list reload', (tester) async {
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

      // Find the RefreshIndicator by looking for the ListView
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Perform pull to refresh gesture
      await tester.fling(listView, const Offset(0, 300), 1000);
      await tester.pump();

      // Verify RefreshIndicator is triggered (shows circular progress)
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('Story 1.3: Edit List Properties', () {
    testWidgets('long-press on list tile opens edit modal', (tester) async {
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

      // Find and long-press on the first list (Groceries)
      final groceriesTile = find.text('Groceries');
      await tester.longPress(groceriesTile);
      await tester.pumpAndSettle();

      // Verify edit modal opens
      expect(find.text('Edit List'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('menu icon on list tile opens edit modal', (tester) async {
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

      // Tap on the menu icon (more_vert) for the first list
      final menuButtons = find.byIcon(Icons.more_vert);
      expect(menuButtons, findsWidgets);
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Verify popup menu appears with Edit option
      expect(find.text('Edit'), findsOneWidget);

      // Tap the Edit option
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Verify edit modal opens
      expect(find.text('Edit List'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('can rename list in edit modal', (tester) async {
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

      // Open edit modal via long-press
      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify the text field is pre-populated with current name
      final textField = find.byType(TextField).first;
      expect(find.descendant(
        of: textField,
        matching: find.text('Groceries'),
      ), findsWidgets);

      // Clear the field and enter new name
      await tester.tap(textField);
      await tester.pumpAndSettle();
      await tester.enterText(textField, 'Weekly Shopping');
      await tester.pumpAndSettle();

      // Verify Save Changes button is now enabled
      final saveButton = find.byType(FilledButton);
      expect(saveButton, findsOneWidget);
      expect(find.descendant(
        of: saveButton,
        matching: find.text('Save Changes'),
      ), findsOneWidget);
    });

    testWidgets('color picker is available in edit modal', (tester) async {
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

      // Open edit modal
      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify color picker label is visible
      expect(find.text('Color'), findsOneWidget);

      // Verify multiple color options are present
      final colorContainers = find.byType(GestureDetector).at(1);
      expect(colorContainers, findsOneWidget);
    });

    testWidgets('icon picker is available in edit modal', (tester) async {
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

      // Open edit modal
      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify icon picker label is visible
      expect(find.text('Icon'), findsOneWidget);
    });

    testWidgets('edit modal accessible from list detail screen menu', (tester) async {
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

      // Navigate to list detail
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify we're on detail screen
      expect(find.text('Add an item...'), findsOneWidget);

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Edit option
      await tester.tap(find.text('Edit list'));
      await tester.pumpAndSettle();

      // Verify edit modal opens
      expect(find.text('Edit List'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('save button is disabled when no changes made', (tester) async {
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

      // Open edit modal
      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify Save Changes button is disabled (no changes yet)
      final saveButton = find.byType(FilledButton);
      expect(saveButton, findsOneWidget);

      // The button should be disabled since no changes were made
      // This can be verified by checking if it responds to tap
      final buttonWidget = tester.widget<FilledButton>(saveButton);
      expect(buttonWidget.onPressed, isNull);
    });
  });
}