import 'package:flutter/material.dart';
import '../models/puzzle_game.dart';
import 'puzzle_tile.dart';

/// Renders the N×N puzzle grid from a [PuzzleGame] state.
///
/// Uses a [Stack] + [AnimatedPositioned] layout so that tiles smoothly slide
/// into their new position after every move.  Each tile widget is keyed by its
/// number value so that Flutter knows which tile is which across rebuilds.
///
/// An inset padding inside the clip boundary ensures tile shadows are visible.
/// Empty cells render as subtle outline indicators for spatial awareness.
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha:0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C4DFF).withValues(alpha:0.08),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / widget.game.size;
            final fontSize = (cellSize * 0.45).clamp(10.0, 56.0);

            return Stack(
              children: [
                // Background — empty cell indicators
                for (int i = 0; i < widget.game.gridCount; i++)
                  if (widget.game.tiles[i] == 0)
                    Positioned(
                      left: (i % widget.game.size) * cellSize,
                      top: (i ~/ widget.game.size) * cellSize,
                      width: cellSize,
                      height: cellSize,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF7C4DFF).withValues(alpha:0.15),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                // Actual numbered tiles
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