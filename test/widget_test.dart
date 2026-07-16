import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sliding_block_puzzle/l10n/strings.dart';
import 'package:sliding_block_puzzle/main.dart';
import 'package:sliding_block_puzzle/widgets/puzzle_board.dart';

void main() {
  testWidgets('Puzzle app renders board and controls',
      (WidgetTester tester) async {
    // Mock SharedPreferences for the widget test.
    SharedPreferences.setMockInitialValues({});

    // Web-sized logical viewport so the board + side card both fit.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const PuzzleApp());
    await tester.pumpAndSettle();

    // The app bar should show the puzzle title.
    expect(find.text(AppStrings.gameTitle), findsOneWidget);

    // The puzzle board should exist.
    expect(find.byType(PuzzleBoard), findsOneWidget);

    // Numbered tiles should be present (e.g., the tile "1").
    expect(find.text('1'), findsWidgets);

    // The controls card should contain the grid-size label.
    expect(find.text(AppStrings.gridSizeLabel), findsOneWidget);

    // The "custom" button should be present.
    expect(find.text(AppStrings.custom), findsOneWidget);

    // The "new game" button should be present.
    expect(find.text(AppStrings.newGame), findsOneWidget);
  });
}
