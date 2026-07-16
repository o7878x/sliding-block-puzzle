import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/puzzle_game.dart';
import '../services/preferences_service.dart';
import '../widgets/puzzle_board.dart';

/// Main game screen: puzzle board, move counter, grid-size selector,
/// and a "new game" button.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const List<int> _gridSizes = [3, 4, 5, 6, 7, 8];
  static const int _customSizeSentinel = -1;
  static const int _minGridSize = 2;
  static const int _maxGridSize = 10;

  late int _gridSize;
  late PuzzleGame _game;
  bool _loaded = false;

  /// Notifies the controls panel of move-count changes without rebuilding the
  /// entire screen or the puzzle board.
  final ValueNotifier<int> _moveCountNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _loadGridSize();
  }

  @override
  void dispose() {
    _moveCountNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadGridSize() async {
    final size = await PreferencesService.getGridSize();
    setState(() {
      _gridSize = size;
      _game = PuzzleGame(size);
      _loaded = true;
    });
  }

  void _changeGridSize(int newSize) {
    if (newSize == _customSizeSentinel) {
      _showCustomSizeDialog();
      return;
    }
    PreferencesService.setGridSize(newSize);
    setState(() {
      _gridSize = newSize;
      _game = PuzzleGame(newSize);
    });
    _moveCountNotifier.value = 0;
  }

  Future<void> _showCustomSizeDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.customSizeTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppStrings.gridSizeFieldLabel,
            hintText: AppStrings.gridSizeHint(_minGridSize, _maxGridSize),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              final size = int.tryParse(text);
              if (size == null || size < _minGridSize || size > _maxGridSize) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.invalidInput)),
                );
                return;
              }
              Navigator.of(context).pop(size);
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      _changeGridSize(result);
    }
  }

  void _newGame() {
    setState(() {
      _game = PuzzleGame(_gridSize);
    });
    _moveCountNotifier.value = 0;
  }

  /// Called by [PuzzleBoard] after every valid move.  Updates the move count
  /// via the lightweight [ValueNotifier] and shows the win dialog if needed.
  /// Does NOT call `setState` — the board and controls rebuild independently.
  void _onMoved(int moveCount, bool isSolved) {
    _moveCountNotifier.value = moveCount;
    if (isSolved) {
      _showWinDialog(moveCount);
    }
  }

  void _showWinDialog(int moves) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.winTitle),
        content: Text(AppStrings.winMessage(moves)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.continueViewing),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _newGame();
            },
            child: const Text(AppStrings.newRound),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.gameTitle),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Left: puzzle board ----
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: PuzzleBoard(
                      game: _game,
                      onMoved: _onMoved,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // ---- Right: controls card ----
            SizedBox(
              width: 200,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status: step count & current grid size
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(AppStrings.moveCountLabel,
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                              const SizedBox(height: 4),
                              ValueListenableBuilder<int>(
                                valueListenable: _moveCountNotifier,
                                builder: (context, count, _) => Text(
                                  '$count',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('$_gridSize×$_gridSize',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Grid size selector
                        Text(AppStrings.gridSizeLabel, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _gridSizes.map((size) {
                            final selected = _gridSize == size;
                            return ChoiceChip(
                              label: Text('$size×$size'),
                              selected: selected,
                              onSelected: (_) => _changeGridSize(size),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _showCustomSizeDialog,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(AppStrings.custom),
                        ),
                        const Divider(height: 32),
                        FilledButton.icon(
                          onPressed: _newGame,
                          icon: const Icon(Icons.shuffle),
                          label: const Text(AppStrings.newGame),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
