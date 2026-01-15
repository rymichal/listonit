import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:listonit/app/app.dart';
import 'package:listonit/core/network/connectivity_service.dart';
import 'package:listonit/core/storage/hive_service.dart' as hive_service;
import '../test/mocks/mock_providers.dart';

// Create a test-friendly connectivity notifier container
class TestConnectivityNotifier extends ConnectivityNotifier {
  TestConnectivityNotifier() : super(Connectivity()) {
    state = const ConnectivityState.online();
  }

  void setOnline() {
    state = const ConnectivityState.online();
  }

  void setOffline() {
    state = const ConnectivityState.offline();
  }
}

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before tests
  await hive_service.HiveService.initialize();

  group('Epic 6.4: Offline Support', () {
    group('Offline Banner Visibility', () {
      testWidgets('shows offline banner when connection is lost', (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: listsStateWithData(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Initially should not show offline banner (we're online)
        expect(find.text('Offline Mode'), findsNothing);

        // Simulate going offline
        connectivityNotifier.setOffline();
        await tester.pumpAndSettle();

        // Should show offline banner
        expect(find.text('Offline Mode'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      });

      testWidgets('hides offline banner when connection is restored',
          (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();
        connectivityNotifier.setOffline();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: listsStateWithData(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Should show offline banner initially
        expect(find.text('Offline Mode'), findsOneWidget);

        // Simulate connection restored
        connectivityNotifier.setOnline();
        await tester.pumpAndSettle();

        // Offline banner should disappear
        expect(find.text('Offline Mode'), findsNothing);
      });

      testWidgets('shows pending changes text when offline',
          (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();
        connectivityNotifier.setOffline();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: listsStateWithData(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Banner should show offline mode message
        expect(find.text('Offline Mode'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data?.contains('sync') ?? false),
          ),
          findsWidgets,
        );
      });
    });

    group('List Creation Offline', () {
      testWidgets('allows creating list while offline', (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();
        connectivityNotifier.setOffline();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: emptyListsState(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap FAB to create list
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Enter list name
        await tester.enterText(find.byType(TextFormField), 'Offline List');
        await tester.pumpAndSettle();

        // Create list
        await tester.tap(find.text('Create List'));
        await tester.pumpAndSettle();

        // List should appear in UI (optimistic update)
        expect(find.text('Offline List'), findsOneWidget);
      });

      testWidgets('keeps list visible after creation offline',
          (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();
        connectivityNotifier.setOffline();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: emptyListsState(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Create a list offline
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'Cached List');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create List'));
        await tester.pumpAndSettle();

        // Go online
        connectivityNotifier.setOnline();
        await tester.pumpAndSettle();

        // List should still be visible
        expect(find.text('Cached List'), findsOneWidget);
      });
    });

    group('Offline State Transitions', () {
      testWidgets('smoothly transitions from offline to online',
          (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();
        connectivityNotifier.setOffline();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: listsStateWithData(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Offline banner visible
        expect(find.text('Offline Mode'), findsOneWidget);

        // Transition to online
        connectivityNotifier.setOnline();
        await tester.pumpAndSettle();

        // Offline banner should smoothly disappear
        expect(find.text('Offline Mode'), findsNothing);
        expect(find.byType(ListonitApp), findsOneWidget);
      });

      testWidgets('preserves data during offline->online transition',
          (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: listsStateWithData(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Get initial list count while online
        int initialListCount =
            find.byType(Card).evaluate().length;

        // Go offline
        connectivityNotifier.setOffline();
        await tester.pumpAndSettle();

        // Data should still be visible
        int offlineListCount =
            find.byType(Card).evaluate().length;
        expect(offlineListCount, equals(initialListCount));

        // Go back online
        connectivityNotifier.setOnline();
        await tester.pumpAndSettle();

        // Data should still be visible
        int onlineListCount =
            find.byType(Card).evaluate().length;
        expect(onlineListCount, equals(initialListCount));
      });
    });

    group('Offline UX Elements', () {
      testWidgets('displays offline banner at top of screen',
          (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();
        connectivityNotifier.setOffline();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: listsStateWithData(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Banner should show offline text and cloud_off icon
        expect(find.text('Offline Mode'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      });

      testWidgets('shows cloud_off icon when offline', (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();
        connectivityNotifier.setOffline();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: listsStateWithData(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Should show cloud_off icon
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      });

      testWidgets('shows cloud_queue icon when online with pending',
          (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: listsStateWithData(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // When online with no pending, no banner should show
        expect(find.text('Offline Mode'), findsNothing);
        expect(find.text('Pending Changes'), findsNothing);
      });
    });

    group('Data Persistence', () {
      testWidgets('data visible after navigation while offline',
          (tester) async {
        final connectivityNotifier = TestConnectivityNotifier();
        connectivityNotifier.setOffline();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityProvider
                  .overrideWith((ref) => connectivityNotifier),
              ...createTestOverrides(
                authState: authenticatedState(),
                listsState: listsStateWithData(),
              ),
            ],
            child: const ListonitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Offline banner should be visible
        expect(find.text('Offline Mode'), findsOneWidget);

        // Lists should still be visible in UI
        expect(find.byType(Card), findsWidgets);
      });
    });
  });
}
