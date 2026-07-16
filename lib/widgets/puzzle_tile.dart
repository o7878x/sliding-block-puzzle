import 'package:flutter/material.dart';

/// A single numbered tile rendered inside the puzzle board's [Stack].
///
/// [fontSize] is pre-computed by the parent based on the cell size so the
/// tile does not need a [FittedBox] or a second layout pass.
class PuzzleTile extends StatelessWidget {
  final int number;
  final VoidCallback? onTap;
  final Color containerColor;
  final Color textColor;
  final double fontSize;

  const PuzzleTile({
    super.key,
    required this.number,
    this.onTap,
    required this.containerColor,
    required this.textColor,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
