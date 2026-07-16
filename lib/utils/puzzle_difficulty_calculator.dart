import '../l10n/strings.dart';

/// A utility class to calculate the difficulty score of an N-Puzzle game.
/// The difficulty score is calculated using Manhattan Distance and Linear Conflict,
/// which correlates highly with the minimum number of moves required to solve the puzzle.
class PuzzleDifficultyCalculator {
  final int size; // Grid size (e.g., 3 for 3x3, 4 for 4x4)
  final List<int>
  tiles; // 1D array representing the puzzle state, where 0 is the empty space

  PuzzleDifficultyCalculator({required this.size, required this.tiles});

  /// Returns the difficulty level label for a given [score].
  static String difficultyLevel(int score) {
    if (score < 15) return AppStrings.difficultyEasy;
    if (score <= 30) return AppStrings.difficultyMedium;
    if (score <= 45) return AppStrings.difficultyHard;
    return AppStrings.difficultyExpert;
  }

  /// Calculates and returns the difficulty score.
  /// The higher the score, the more difficult the puzzle layout.
  int calculateDifficulty() {
    int manhattan = _getManhattanDistance();
    int linearConflict = _getLinearConflict();

    // Difficulty score formula = Manhattan Distance + 2 * Linear Conflict
    return manhattan + (2 * linearConflict);
  }

  /// 1. Calculates the total Manhattan Distance of all tiles to their goal positions.
  int _getManhattanDistance() {
    int distance = 0;
    for (int i = 0; i < tiles.length; i++) {
      int value = tiles[i];
      if (value == 0) continue; // Ignore the empty space

      // Current coordinates (row, col)
      int currRow = i ~/ size;
      int currCol = i % size;

      // Target coordinates (targetRow, targetCol)
      // Assuming the goal state is [1, 2, 3, ..., 0]
      int targetIndex = value - 1;
      int targetRow = targetIndex ~/ size;
      int targetCol = targetIndex % size;

      distance += (currRow - targetRow).abs() + (currCol - targetCol).abs();
    }
    return distance;
  }

  /// 2. Calculates the number of Linear Conflicts.
  /// A conflict occurs when two tiles are in their goal row/column, but in the reversed order.
  int _getLinearConflict() {
    int conflicts = 0;

    // Detect horizontal (row) conflicts
    for (int row = 0; row < size; row++) {
      conflicts += _checkLineConflict(row, isRow: true);
    }

    // Detect vertical (column) conflicts
    for (int col = 0; col < size; col++) {
      conflicts += _checkLineConflict(col, isRow: false);
    }

    return conflicts;
  }

  int _checkLineConflict(int line, {required bool isRow}) {
    int conflicts = 0;
    List<int> lineTiles = [];

    // Extract all tiles in the current row or column
    for (int i = 0; i < size; i++) {
      int index = isRow ? (line * size + i) : (i * size + line);
      lineTiles.add(tiles[index]);
    }

    // Double loop to detect if any two tiles are in their goal line but their relative order is reversed
    for (int i = 0; i < size; i++) {
      int tileA = lineTiles[i];
      if (tileA == 0) continue;

      // Goal position of tile A
      int targetIndexA = tileA - 1;
      int targetRowA = targetIndexA ~/ size;
      int targetColA = targetIndexA % size;

      // Ensure A's goal position is indeed on this line (row or column)
      if (isRow && targetRowA != line) continue;
      if (!isRow && targetColA != line) continue;

      for (int j = i + 1; j < size; j++) {
        int tileB = lineTiles[j];
        if (tileB == 0) continue;

        // Goal position of tile B
        int targetIndexB = tileB - 1;
        int targetRowB = targetIndexB ~/ size;
        int targetColB = targetIndexB % size;

        // Ensure B's goal position is indeed on this line
        if (isRow && targetRowB != line) continue;
        if (!isRow && targetColB != line) continue;

        // If A is to the left (or above) B, but A's goal is to the right (or below) B, a conflict occurs
        if (isRow && targetColA > targetColB) {
          conflicts++;
        } else if (!isRow && targetRowA > targetRowB) {
          conflicts++;
        }
      }
    }

    return conflicts;
  }
}
