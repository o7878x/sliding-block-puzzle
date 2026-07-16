import 'package:flutter/material.dart';
import '../models/puzzle_game.dart';
import 'puzzle_tile.dart';

/// Renders the N×N puzzle grid from a [PuzzleGame] state.
///
/// Uses a [Stack] + [AnimatedPositioned] layout so that tiles smoothly slide
/// into their new position after every move.  Each tile widget is keyed by its
/// number value so that Flutter knows which tile is which across rebuilds.
/// Theme colours are resolved once and passed down, avoiding repeated
/// O(depth) `Theme.of(context)` calls per tile.
class PuzzleBoard extends StatefulWidget {
  final PuzzleGame game;
  final void Function(int moveCount, bool isSolved) onMoved;

  const PuzzleBoard({
    super.key,
    required this.game,
    required this.onMoved,
  });

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard> {
  void _handleTap(int index) {
    widget.game.move(index);
    setState(() {});
    widget.onMoved(widget.game.moveCount, widget.game.isSolved());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final containerColor = theme.colorScheme.primaryContainer;
    final textColor = theme.colorScheme.onPrimaryContainer;

    return AspectRatio(
      aspectRatio: 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / widget.game.size;
            final fontSize = (cellSize * 0.45).clamp(10.0, 56.0);

            return Stack(
              children: [
                for (int i = 0; i < widget.game.gridCount; i++)
                  if (widget.game.tiles[i] != 0)
                    AnimatedPositioned(
                      key: ValueKey(widget.game.tiles[i]),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      left: (i % widget.game.size) * cellSize,
                      top: (i ~/ widget.game.size) * cellSize,
                      width: cellSize,
                      height: cellSize,
                      child: PuzzleTile(
                        number: widget.game.tiles[i],
                        onTap: () => _handleTap(i),
                        containerColor: containerColor,
                        textColor: textColor,
                        fontSize: fontSize,
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
