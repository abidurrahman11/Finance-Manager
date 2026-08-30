import 'package:finance_manager/presentation/screens/profile/profile_screen.dart';
import 'package:finance_manager/presentation/providers/auth_provider.dart';
import 'package:finance_manager/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('profile renders the local offline user', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Local User'), findsOneWidget);
    expect(find.text('offline@finance.manager'), findsOneWidget);
    expect(find.text('Finance Manager'), findsOneWidget);
  });
}

class _FakeAuthRepository extends AuthRepository {
  @override
  Future<bool> isLoggedIn() async => false;
}
