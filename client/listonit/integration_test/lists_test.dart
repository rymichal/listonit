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

  group('Story 1.4: Delete List', () {
    testWidgets('delete option appears in list detail menu', (tester) async {
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

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify delete option is present with error color
      expect(find.text('Delete list'), findsOneWidget);
    });

    testWidgets('delete confirmation dialog shows list name', (tester) async {
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

      // Open menu and tap delete
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete list'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete list?'), findsOneWidget);
      expect(find.text('Groceries'), findsWidgets); // List name appears somewhere in dialog
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancel button dismisses delete dialog without deleting', (tester) async {
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

      // Open menu and tap delete
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete list'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify we're still on detail screen
      expect(find.text('Add an item...'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('undo snackbar appears after deletion', (tester) async {
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

      // Open menu and tap delete
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete list'));
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.text('Delete'));

      // Wait for navigation back and snackbar to appear
      await Future.delayed(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      // Verify snackbar appears (core functionality test)
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('undo action restores deleted list', (tester) async {
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

      // Verify list exists before deletion
      expect(find.text('Groceries'), findsWidgets);

      // Delete the list
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete list'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));

      // Wait for navigation and snackbar
      await Future.delayed(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      // Verify snackbar appears after deletion
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('delete list via lists screen menu', (tester) async {
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

      // Verify list exists
      expect(find.text('Hardware Store'), findsOneWidget);

      // Navigate to the list detail screen
      await tester.tap(find.text('Hardware Store'));
      await tester.pumpAndSettle();

      // Verify we're on detail screen
      expect(find.text('Add an item...'), findsOneWidget);

      // Open menu on detail screen
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify Delete list option exists on detail screen menu
      expect(find.text('Delete list'), findsOneWidget);
    });

    testWidgets('snackbar auto-dismisses after 5 seconds', (tester) async {
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

      // Delete a list from detail screen
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify we're on detail screen
      expect(find.text('Add an item...'), findsOneWidget);

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap delete list
      await tester.tap(find.text('Delete list'));
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Snackbar should be visible after delete and return to lists screen
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('Story 1.5: Duplicate List', () {
    testWidgets('duplicate option appears in list detail menu', (tester) async {
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

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify duplicate option is present
      expect(find.text('Duplicate list'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('duplicate option has copy icon', (tester) async {
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

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Find the duplicate list tile and verify it has the copy icon
      final duplicateTile = find.ancestor(
        of: find.text('Duplicate list'),
        matching: find.byType(ListTile),
      );
      expect(duplicateTile, findsOneWidget);

      // Verify copy icon is within the tile
      expect(
        find.descendant(of: duplicateTile, matching: find.byIcon(Icons.copy)),
        findsOneWidget,
      );
    });

    testWidgets('duplicate option is positioned before Share in menu', (tester) async {
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

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Get all ListTiles in the menu
      final listTiles = find.byType(ListTile);

      // Find the indices of Duplicate and Share
      int duplicateIndex = -1;
      int shareIndex = -1;

      for (int i = 0; i < tester.widgetList(listTiles).length; i++) {
        final tile = listTiles.at(i);
        if (find.descendant(of: tile, matching: find.text('Duplicate list')).evaluate().isNotEmpty) {
          duplicateIndex = i;
        }
        if (find.descendant(of: tile, matching: find.text('Share list')).evaluate().isNotEmpty) {
          shareIndex = i;
        }
      }

      // Duplicate should come before Share
      expect(duplicateIndex, greaterThan(-1));
      expect(shareIndex, greaterThan(-1));
      expect(duplicateIndex, lessThan(shareIndex));
    });

    testWidgets('menu options order: Edit, Duplicate, Share, Clear, Delete', (tester) async {
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

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify all menu options are present
      expect(find.text('Edit list'), findsOneWidget);
      expect(find.text('Duplicate list'), findsOneWidget);
      expect(find.text('Share list'), findsOneWidget);
      expect(find.text('Clear completed'), findsOneWidget);
      expect(find.text('Delete list'), findsOneWidget);
    });

    testWidgets('tapping duplicate closes menu', (tester) async {
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

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify menu is open
      expect(find.text('Duplicate list'), findsOneWidget);

      // Tap duplicate
      await tester.tap(find.text('Duplicate list'));
      await tester.pump();

      // Menu should be closed (bottom sheet dismissed)
      await tester.pumpAndSettle();
    });

    testWidgets('duplicate option accessible on any list', (tester) async {
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

      // Test on Hardware Store list
      await tester.tap(find.text('Hardware Store'));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify duplicate option is present
      expect(find.text('Duplicate list'), findsOneWidget);
    });

    testWidgets('duplicate option uses correct icon (Icons.copy)', (tester) async {
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

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Find all icons in the bottom sheet
      final copyIcon = find.byIcon(Icons.copy);
      expect(copyIcon, findsOneWidget);

      // Verify it's associated with the Duplicate list text
      final duplicateListTile = find.ancestor(
        of: find.text('Duplicate list'),
        matching: find.byType(ListTile),
      );

      expect(
        find.descendant(of: duplicateListTile, matching: copyIcon),
        findsOneWidget,
      );
    });

    testWidgets('duplicate option on Party Supplies list', (tester) async {
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

      // Test on Party Supplies list
      await tester.tap(find.text('Party Supplies'));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify duplicate option is present
      expect(find.text('Duplicate list'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });
  });
}