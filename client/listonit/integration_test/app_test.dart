// Main integration test entry point.
//
// Run all integration tests with:
//   flutter test integration_test
//
// Or run individual test files:
//   flutter test integration_test/lists_test.dart
//   flutter test integration_test/list_detail_test.dart
//
// Run on a specific device:
//   flutter test integration_test -d macos
//   flutter test integration_test -d chrome

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:listonit/app/app.dart';

import '../test/mocks/mock_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Story 1.2: Complete Integration Tests', () {
    testWidgets('full flow: view lists, navigate to detail, add items',
        (tester) async {
      // Start the app with authenticated user and sample lists
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

      // Step 1: Verify lists screen displays all lists
      expect(find.text('My Lists'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Hardware Store'), findsOneWidget);
      expect(find.text('Party Supplies'), findsOneWidget);

      // Step 2: Navigate to list detail
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Step 3: Verify detail screen
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);

      // Step 4: Add an item
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsOneWidget);

      // Step 5: Add another item
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Bread'), findsOneWidget);

      // Step 6: Check off an item
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();
      expect(find.text('Completed (1)'), findsOneWidget);

      // Step 7: Navigate back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Step 8: Verify we're back on lists screen
      expect(find.text('My Lists'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
    });
  });
}
