import 'package:flutter/material.dart';

/// A single numbered tile with a blue-to-purple gradient, elevated shadow,
/// and a press animation (scale + shadow change) for a 3D relief feel.
class PuzzleTile extends StatefulWidget {
  final int number;
  final VoidCallback? onTap;
  final double fontSize;

  const PuzzleTile({
    super.key,
    required this.number,
    this.onTap,
    required this.fontSize,
  });

  @override
  State<PuzzleTile> createState() => _PuzzleTileState();
}

class _PuzzleTileState extends State<PuzzleTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7C4DFF), // Purple
                  Color(0xFF536DFE), // Indigo-blue
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withValues(alpha:0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withValues(alpha:0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: const Color(0xFF536DFE).withValues(alpha:0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                '${widget.number}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  letterSpacing: -0.5,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}