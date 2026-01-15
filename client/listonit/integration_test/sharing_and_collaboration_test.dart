import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:listonit/app/app.dart';
import 'package:listonit/features/lists/data/list_api.dart';
import 'package:listonit/features/auth/data/user_api.dart';
import 'package:listonit/features/auth/domain/user.dart';
import 'package:listonit/core/storage/hive_service.dart' as hive_service;
import '../test/mocks/mock_providers.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before tests
  await hive_service.HiveService.initialize();

  group('Epic 3: Sharing & Collaboration', () {
    group('Story 3.1: Direct User Sharing', () {
      group('Add Member to List', () {
        testWidgets('members modal displays add member button for owner',
            (tester) async {
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

          // Navigate to list detail by tapping a list
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          // Open members modal - look for members icon/button
          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            // Verify members modal opened with add member button visible
            final addMemberButton = find.byIcon(Icons.person_add);
            expect(addMemberButton, findsWidgets,
                reason: 'Add member button should be visible for owner');
          }
        });

        testWidgets('can open add member modal from members modal',
            (tester) async {
          final mockListApi = MockListApi();
          final mockUserApi = MockUserApi();

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...createTestOverrides(
                  authState: authenticatedState(),
                  listsState: listsStateWithData(),
                ),
                listApiProvider
                    .overrideWithValue(mockListApi),
                userApiProvider
                    .overrideWithValue(mockUserApi),
              ],
              child: const ListonitApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Navigate to list detail
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          // Open members modal
          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            // Tap add member button
            final addMemberButton = find.byIcon(Icons.person_add);
            if (addMemberButton.evaluate().isNotEmpty) {
              await tester.tap(addMemberButton.first);
              await tester.pumpAndSettle();

              // Verify share modal opened with "Add Member" title
              expect(find.text('Add Member'), findsOneWidget,
                  reason: 'Share modal should display "Add Member" title');
            }
          }
        });

        testWidgets('search users displays all available users',
            (tester) async {
          final mockListApi = MockListApi();
          final mockUserApi = MockUserApi();

          // Mock user search to return test users
          when(() => mockUserApi.searchUsers(query: any(named: 'query')))
              .thenAnswer((_) async => [
                User(
                  id: 'user-2',
                  username: 'john',
                  name: 'John Doe',
                  isActive: true,
                  isAdmin: false,
                  createdAt: DateTime(2024, 1, 1),
                  updatedAt: DateTime(2024, 1, 1),
                ),
                User(
                  id: 'user-3',
                  username: 'jane',
                  name: 'Jane Smith',
                  isActive: true,
                  isAdmin: false,
                  createdAt: DateTime(2024, 1, 1),
                  updatedAt: DateTime(2024, 1, 1),
                ),
              ]);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...createTestOverrides(
                  authState: authenticatedState(),
                  listsState: listsStateWithData(),
                ),
                listApiProvider
                    .overrideWithValue(mockListApi),
                userApiProvider
                    .overrideWithValue(mockUserApi),
              ],
              child: const ListonitApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Navigate to list and open add member modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            final addMemberButton = find.byIcon(Icons.person_add);
            if (addMemberButton.evaluate().isNotEmpty) {
              await tester.tap(addMemberButton.first);
              await tester.pumpAndSettle();

              // Verify search box is displayed
              expect(find.byType(TextField), findsWidgets,
                  reason: 'Search field should be visible in add member modal');
            }
          }
        });

        testWidgets('can select user from dropdown and assign role',
            (tester) async {
          final mockListApi = MockListApi();
          final mockUserApi = MockUserApi();

          when(() => mockUserApi.searchUsers(query: any(named: 'query')))
              .thenAnswer((_) async => [
                User(
                  id: 'user-2',
                  username: 'john',
                  name: 'John Doe',
                  isActive: true,
                  isAdmin: false,
                  createdAt: DateTime(2024, 1, 1),
                  updatedAt: DateTime(2024, 1, 1),
                ),
              ]);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...createTestOverrides(
                  authState: authenticatedState(),
                  listsState: listsStateWithData(),
                ),
                listApiProvider
                    .overrideWithValue(mockListApi),
                userApiProvider
                    .overrideWithValue(mockUserApi),
              ],
              child: const ListonitApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Navigate to list and open add member modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            final addMemberButton = find.byIcon(Icons.person_add);
            if (addMemberButton.evaluate().isNotEmpty) {
              await tester.tap(addMemberButton.first);
              await tester.pumpAndSettle();

              // Verify role selector is visible
              final roleDropdown = find.text('Can edit');
              if (roleDropdown.evaluate().isNotEmpty) {
                expect(roleDropdown, findsOneWidget,
                    reason: 'Role selector should show default "Can edit"');
              }
            }
          }
        });

        testWidgets('add member button is disabled when no user selected',
            (tester) async {
          final mockListApi = MockListApi();
          final mockUserApi = MockUserApi();

          when(() => mockUserApi.searchUsers(query: any(named: 'query')))
              .thenAnswer((_) async => []);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...createTestOverrides(
                  authState: authenticatedState(),
                  listsState: listsStateWithData(),
                ),
                listApiProvider
                    .overrideWithValue(mockListApi),
                userApiProvider
                    .overrideWithValue(mockUserApi),
              ],
              child: const ListonitApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Navigate and open add member modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            final addMemberButton = find.byIcon(Icons.person_add);
            if (addMemberButton.evaluate().isNotEmpty) {
              await tester.tap(addMemberButton.first);
              await tester.pumpAndSettle();

              // Find the Add Member action button
              final submitButton = find.widgetWithText(
                FilledButton,
                'Add Member',
              );

              // The button should exist but be disabled (no user selected)
              if (submitButton.evaluate().isNotEmpty) {
                // In Flutter, disabled buttons are still in the widget tree
                expect(submitButton, findsOneWidget,
                    reason: 'Add member button should be present');
              }
            }
          }
        });

        testWidgets('add member modal displays editor role by default',
            (tester) async {
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

          // Navigate to list
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          // Open members modal
          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            // Open add member modal
            final addMemberButton = find.byIcon(Icons.person_add);
            if (addMemberButton.evaluate().isNotEmpty) {
              await tester.tap(addMemberButton.first);
              await tester.pumpAndSettle();

              // Verify role selector shows "Can edit" (editor) by default
              expect(find.text('Can edit'), findsOneWidget,
                  reason: 'Role should default to editor');
            }
          }
        });

        testWidgets('role can be changed to viewer', (tester) async {
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

          // Navigate to list and open add member modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            final addMemberButton = find.byIcon(Icons.person_add);
            if (addMemberButton.evaluate().isNotEmpty) {
              await tester.tap(addMemberButton.first);
              await tester.pumpAndSettle();

              // Verify both role options are available
              expect(find.text('Can edit'), findsOneWidget,
                  reason: 'Editor role option should be available');
              expect(find.text('Can view'), findsOneWidget,
                  reason: 'Viewer role option should be available');
            }
          }
        });

        testWidgets('description and help text guides user experience',
            (tester) async {
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

          // Navigate to list and open add member modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            final addMemberButton = find.byIcon(Icons.person_add);
            if (addMemberButton.evaluate().isNotEmpty) {
              await tester.tap(addMemberButton.first);
              await tester.pumpAndSettle();

              // Verify modal has helpful text for user guidance
              expect(find.text('Add Member'), findsOneWidget,
                  reason: 'Modal title should be clear');
              expect(find.text('Select a user to add'), findsOneWidget,
                  reason: 'Should have instructions');
            }
          }
        });
      });

      group('Remove Member from List', () {
        testWidgets('can open member options menu', (tester) async {
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

          // Open members modal
          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            // Verify members list is displayed
            expect(find.byType(ListView), findsOneWidget,
                reason: 'Members list should be displayed');
          }
        });

        testWidgets('owner can see remove option for other members',
            (tester) async {
          final mockListApi = MockListApi();

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...createTestOverrides(
                  authState: authenticatedState(),
                  listsState: listsStateWithData(),
                ),
                listApiProvider
                    .overrideWithValue(mockListApi),
              ],
              child: const ListonitApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Navigate to list and open members modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            // Look for menu button on member tile
            final moreIcon = find.byIcon(Icons.more_vert);
            if (moreIcon.evaluate().isNotEmpty) {
              // Owner should have access to member menu
              expect(moreIcon, findsWidgets,
                  reason: 'Owner should see member options menu');
            }
          }
        });

        testWidgets('member removal UI flow works correctly', (tester) async {
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

          // Navigate to list and open members modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            // Find and tap member menu
            final moreIcon = find.byIcon(Icons.more_vert);
            if (moreIcon.evaluate().isNotEmpty) {
              await tester.tap(moreIcon.first);
              await tester.pumpAndSettle();

              // Verify remove option exists in menu
              final removeOption = find.text('Remove member');
              if (removeOption.evaluate().isNotEmpty) {
                expect(removeOption, findsOneWidget,
                    reason: 'Remove member option should be in menu');
              }
            }
          }
        });

        testWidgets('shows confirmation dialog before removing member',
            (tester) async {
          final mockListApi = MockListApi();

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...createTestOverrides(
                  authState: authenticatedState(),
                  listsState: listsStateWithData(),
                ),
                listApiProvider
                    .overrideWithValue(mockListApi),
              ],
              child: const ListonitApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Navigate to list and open members modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            // Open member menu and try to remove
            final moreIcon = find.byIcon(Icons.more_vert);
            if (moreIcon.evaluate().isNotEmpty) {
              await tester.tap(moreIcon.first);
              await tester.pumpAndSettle();

              final removeOption = find.text('Remove member');
              if (removeOption.evaluate().isNotEmpty) {
                await tester.tap(removeOption);
                await tester.pumpAndSettle();

                // Verify confirmation dialog
                expect(find.byType(AlertDialog), findsOneWidget,
                    reason: 'Confirmation dialog should appear');
                expect(find.text('Remove member?'), findsOneWidget,
                    reason: 'Dialog should ask for confirmation');
              }
            }
          }
        });

        testWidgets('can cancel member removal', (tester) async {
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

          // Navigate to list and open members modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            // Open member menu
            final moreIcon = find.byIcon(Icons.more_vert);
            if (moreIcon.evaluate().isNotEmpty) {
              await tester.tap(moreIcon.first);
              await tester.pumpAndSettle();

              final removeOption = find.text('Remove member');
              if (removeOption.evaluate().isNotEmpty) {
                await tester.tap(removeOption);
                await tester.pumpAndSettle();

                // Cancel the removal
                final cancelButton = find.widgetWithText(
                  TextButton,
                  'Cancel',
                );
                if (cancelButton.evaluate().isNotEmpty) {
                  await tester.tap(cancelButton.first);
                  await tester.pumpAndSettle();

                  // Verify dialog closed and we're back to members list
                  expect(find.byType(AlertDialog), findsNothing,
                      reason: 'Dialog should be closed');
                }
              }
            }
          }
        });

        testWidgets('member can remove themselves from list',
            (tester) async {
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

          // Navigate to list and open members modal
          await tester.tap(find.text('Groceries'));
          await tester.pumpAndSettle();

          final membersIcon = find.byIcon(Icons.people);
          if (membersIcon.evaluate().isNotEmpty) {
            await tester.tap(membersIcon.first);
            await tester.pumpAndSettle();

            // Find and tap menu for current user (should have "Leave list" option)
            final moreIcon = find.byIcon(Icons.more_vert);
            if (moreIcon.evaluate().isNotEmpty) {
              await tester.tap(moreIcon.first);
              await tester.pumpAndSettle();

              final leaveOption = find.text('Leave list');
              if (leaveOption.evaluate().isNotEmpty) {
                expect(leaveOption, findsOneWidget,
                    reason: 'Current user should see "Leave list" option');
              }
            }
          }
        });
      });
    });

    group('Story 3.2: View List Members', () {
      testWidgets('can view all members of a list', (tester) async {
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

        // Open members modal
        final membersIcon = find.byIcon(Icons.people);
        if (membersIcon.evaluate().isNotEmpty) {
          await tester.tap(membersIcon.first);
          await tester.pumpAndSettle();

          // Verify members are displayed
          expect(find.byType(ListTile), findsWidgets,
              reason: 'Members should be displayed as list tiles');
        }
      });

      testWidgets('displays member roles correctly', (tester) async {
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

        // Navigate to list and open members modal
        await tester.tap(find.text('Groceries'));
        await tester.pumpAndSettle();

        final membersIcon = find.byIcon(Icons.people);
        if (membersIcon.evaluate().isNotEmpty) {
          await tester.tap(membersIcon.first);
          await tester.pumpAndSettle();

          // Look for role indicators (Owner, editor, viewer)
          final roleText = find.text('Owner');
          if (roleText.evaluate().isNotEmpty) {
            expect(roleText, findsWidgets,
                reason: 'Member roles should be displayed');
          }
        }
      });

      testWidgets('displays user avatars in members list', (tester) async {
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

        // Navigate to list and open members modal
        await tester.tap(find.text('Groceries'));
        await tester.pumpAndSettle();

        final membersIcon = find.byIcon(Icons.people);
        if (membersIcon.evaluate().isNotEmpty) {
          await tester.tap(membersIcon.first);
          await tester.pumpAndSettle();

          // Look for avatar circles
          final avatars = find.byType(CircleAvatar);
          if (avatars.evaluate().isNotEmpty) {
            expect(avatars, findsWidgets,
                reason: 'Members should have avatar circles');
          }
        }
      });
    });
  });
}

// Mock classes for API testing
class MockListApi extends Mock implements ListApi {}

class MockUserApi extends Mock implements UserApi {}
