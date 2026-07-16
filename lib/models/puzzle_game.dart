import 'dart:math';

/// Core game logic for an N×N sliding-block puzzle.
///
/// The board is represented as a flat list where 0 = empty cell and
/// 1 … N²−1 = numbered tiles.  Puzzle generation guarantees solvability
/// via inversion-count parity and never produces the solved state.
class PuzzleGame {
  final int size;
  late List<int> _tiles;
  late int emptyIndex;
  int moveCount = 0;

  /// How many tiles are currently in their correct (solved) position.
  /// Updated incrementally by [move] so that [isSolved] is O(1).
  int _correctCount = 0;

  /// The flat tile array (0 = empty cell, 1 … N²−1 = numbered tiles).
  ///
  /// Setting this triggers a full recount of [_correctCount].
  List<int> get tiles => _tiles;
  set tiles(List<int> value) {
    _tiles = value;
    _recomputeCorrectCount();
  }

  PuzzleGame(this.size) {
    _initSolved();
    shuffle();
  }

  int get gridCount => size * size;

  // ------------------------------------------------------------------
  // Initialisation & shuffle
  // ------------------------------------------------------------------

  void _initSolved() {
    _tiles = List.generate(gridCount - 1, (i) => i + 1) + [0];
    emptyIndex = gridCount - 1;
    _correctCount = gridCount;
  }

  /// Randomly shuffles the board until the result is solvable and not the
  /// solved state.
  void shuffle() {
    final random = Random();
    do {
      _tiles.shuffle(random);
      emptyIndex = _tiles.indexOf(0);
      // Rebuild correct-count inside the loop so that isSolved() (now O(1)
      // via [_correctCount]) returns the correct answer for this iteration.
      _recomputeCorrectCount();
    } while (!_isSolvable() || isSolved());
    moveCount = 0;
  }

  /// Full scan to rebuild [_correctCount] from scratch.
  /// Called from the [shuffle] retry loop and any other time tiles are
  /// bulk-reordered; the normal [move] path updates it incrementally.
  void _recomputeCorrectCount() {
    int count = 0;
    for (int i = 0; i < gridCount; i++) {
      if (_isTileCorrect(i)) count++;
    }
    _correctCount = count;
  }

  /// Whether the tile at [index] is in its solved position.
  bool _isTileCorrect(int index) {
    final value = _tiles[index];
    // The empty tile (0) belongs at the last position.
    if (value == 0) return index == gridCount - 1;
    // Numbered tile (1 … gridCount−1) belongs at index value−1.
    return value == index + 1;
  }

  // ------------------------------------------------------------------
  // Solvability  (inversion-count parity)
  // ------------------------------------------------------------------

  /// Returns true iff the current tile permutation is solvable.
  ///
  /// For odd N the puzzle is solvable when the inversion count is even.
  /// For even N it must also account for the blank's row from the bottom.
  bool _isSolvable() {
    int inversions = 0;
    for (int i = 0; i < gridCount; i++) {
      for (int j = i + 1; j < gridCount; j++) {
        if (_tiles[i] != 0 && _tiles[j] != 0 && _tiles[i] > _tiles[j]) {
          inversions++;
        }
      }
    }

    if (size.isOdd) {
      return inversions.isEven;
    } else {
      // Row of the blank counting from the bottom (1-indexed).
      final int blankRowFromBottom = size - (emptyIndex ~/ size);
      return (inversions + blankRowFromBottom).isEven;
    }
  }

  // ------------------------------------------------------------------
  // Moves
  // ------------------------------------------------------------------

  /// Whether the tile at [index] is adjacent to the empty cell.
  bool canMove(int index) {
    if (index < 0 || index >= gridCount) return false;

    final int row = index ~/ size;
    final int col = index % size;
    final int emptyRow = emptyIndex ~/ size;
    final int emptyCol = emptyIndex % size;

    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  /// Moves the tile at [index] into the empty cell if adjacent.
  /// Returns true if the move was performed.
  bool move(int index) {
    if (!canMove(index)) return false;

    final int from = index;
    final int to = emptyIndex;

    // Decrement for positions whose values are about to change.
    if (_isTileCorrect(to)) _correctCount--;
    if (_isTileCorrect(from)) _correctCount--;

    _tiles[to] = _tiles[from];
    _tiles[from] = 0;
    emptyIndex = from;

    // Increment for positions after the swap.
    if (_isTileCorrect(to)) _correctCount++;
    if (_isTileCorrect(from)) _correctCount++;

    moveCount++;
    return true;
  }

  // ------------------------------------------------------------------
  // Win detection
  // ------------------------------------------------------------------

  /// Returns true iff every tile is in its correct (solved) position.
  ///
  /// O(1) thanks to the incrementally-maintained [_correctCount].
  bool isSolved() => _correctCount == gridCount;
}
