import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/puzzle_game.dart';
import '../services/preferences_service.dart';
import '../utils/puzzle_difficulty_calculator.dart';
import '../widgets/puzzle_board.dart';

/// Full-page game screen with a single central glassmorphism card.
///
/// Layout hierarchy:
///   Background gradient + decorative blobs
///     → Glass card (BackdropFilter blur)
///       → Title
///       → Stats bar (步數 | 時間 | 難度係數 badge)
///       → Puzzle board (left) + Controls panel (right) — stacked on narrow screens
///       → Primary restart CTA (full-width)
///
/// A [Stopwatch]-based timer starts on the first move and displays as MM:SS.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int _customSizeSentinel = -1;
  static const int _minGridSize = 2;
  static const int _maxGridSize = 10;

  late int _gridSize;
  late PuzzleGame _game;
  bool _loaded = false;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = '00:00';

  /// Notifies the controls panel of move-count changes without a full rebuild.
  final ValueNotifier<int> _moveCountNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _loadGridSize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _moveCountNotifier.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Persistence
  // ------------------------------------------------------------------

  Future<void> _loadGridSize() async {
    final size = await PreferencesService.getGridSize();
    setState(() {
      _gridSize = size;
      _game = PuzzleGame(size);
      _loaded = true;
    });
  }

  // ------------------------------------------------------------------
  // Grid size
  // ------------------------------------------------------------------

  void _changeGridSize(int newSize) {
    if (newSize == _customSizeSentinel) {
      _showCustomSizeDialog();
      return;
    }
    PreferencesService.setGridSize(newSize);
    _resetTimer();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(AppStrings.customSizeTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppStrings.gridSizeFieldLabel,
            hintText: AppStrings.gridSizeHint(_minGridSize, _maxGridSize),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
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

  // ------------------------------------------------------------------
  // Game lifecycle
  // ------------------------------------------------------------------

  void _newGame() {
    _resetTimer();
    setState(() {
      _game = PuzzleGame(_gridSize);
    });
    _moveCountNotifier.value = 0;
  }

  /// Called by [PuzzleBoard] after every valid move.
  void _onMoved(int moveCount, bool isSolved) {
    if (moveCount == 1) _startTimer();
    _moveCountNotifier.value = moveCount;
    if (isSolved) {
      _timer?.cancel();
      _showWinDialog(moveCount);
    }
  }

  // ------------------------------------------------------------------
  // Timer
  // ------------------------------------------------------------------

  void _startTimer() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _formattedTime = _formatTime(_stopwatch.elapsed);
          });
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _stopwatch..stop()..reset();
    if (mounted) {
      setState(() {
        _formattedTime = '00:00';
      });
    }
  }

  static String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ------------------------------------------------------------------
  // Win dialog
  // ------------------------------------------------------------------

  void _showWinDialog(int moves) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(AppStrings.winTitle),
        content: Text(AppStrings.winMessage(moves)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.continueViewing),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
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

  // ==================================================================
  // BUILD
  // ==================================================================

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF7C4DFF),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5F0FF),
                    Color(0xFFEDE7F6),
                    Color(0xFFE8EAF6),
                  ],
                ),
              ),
            ),
          ),
          // Decorative blobs (visible through the frosted card)
          Positioned(
            top: -120,
            left: -80,
            child: _buildDecorativeBlob(320, 320, const Color(0xFF7C4DFF)),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _buildDecorativeBlob(280, 280, const Color(0xFF536DFE)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -40,
            child: _buildDecorativeBlob(200, 200, const Color(0xFF448AFF)),
          ),
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth > 840;
                final double horizontalPadding =
                    constraints.maxWidth > 1200 ? 80 : 24;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 24,
                        ),
                        child: SizedBox(
                          width: isWide ? 960 : constraints.maxWidth,
                          child: _buildGlassCard(isWide),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeBlob(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha:0.12),
            color.withValues(alpha:0.06),
            color.withValues(alpha:0),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Glass card
  // ------------------------------------------------------------------

  Widget _buildGlassCard(bool isWide) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.78),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha:0.08),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stats bar
                _buildStatsBar(),
                const SizedBox(height: 28),
                // Content area
                isWide ? _buildWideLayout() : _buildNarrowLayout(),
                const SizedBox(height: 24),
                // Restart CTA
                _buildRestartButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Stats bar
  // ------------------------------------------------------------------

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3EFFF),
            Color(0xFFEEF0FF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C4DFF).withValues(alpha:0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 步數
          const Spacer(flex: 1),
          _buildStatColumn(
            label: AppStrings.moveCountLabel,
            valueWidget: ValueListenableBuilder<int>(
              valueListenable: _moveCountNotifier,
              builder: (context, count, _) => Text(
                '$count',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
          _buildStatDivider(),
          // 時間
          const Spacer(flex: 1),
          _buildStatColumn(
            label: AppStrings.timeLabel,
            valueWidget: Text(
              _formattedTime,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A237E),
                fontFamily: 'monospace',
              ),
            ),
          ),
          const Spacer(flex: 1),
          _buildStatDivider(),
          // 難度係數
          const Spacer(flex: 1),
          _buildStatColumn(
            label: AppStrings.difficultyLabel,
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_game.difficulty}（${PuzzleDifficultyCalculator.difficultyLevel(_game.difficulty)}）',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4527A0),
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required Widget valueWidget,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5C6BC0).withValues(alpha:0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget,
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF7C4DFF).withValues(alpha:0.15),
    );
  }

  // ------------------------------------------------------------------
  // Layout — wide (side-by-side)
  // ------------------------------------------------------------------

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: PuzzleBoard(
            game: _game,
            onMoved: _onMoved,
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 4,
          child: _buildControlsPanel(),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Layout — narrow (stacked)
  // ------------------------------------------------------------------

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        PuzzleBoard(
          game: _game,
          onMoved: _onMoved,
        ),
        const SizedBox(height: 24),
        _buildControlsPanel(),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Controls panel
  // ------------------------------------------------------------------

  Widget _buildControlsPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section label
        Text(
          AppStrings.gridSizeLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C6BC0),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Manual 3-column grid using Row — avoids creating a Scrollable
        // (GridView would render a scrollbar on desktop platforms).
        // Row 1: 3×3, 4×4, 5×5
        Row(
          children: [
            Expanded(child: _buildSizeButton(3)),
            const SizedBox(width: 8),
            Expanded(child: _buildSizeButton(4)),
            const SizedBox(width: 8),
            Expanded(child: _buildSizeButton(5)),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: 6×6, 7×7, 8×8
        Row(
          children: [
            Expanded(child: _buildSizeButton(6)),
            const SizedBox(width: 8),
            Expanded(child: _buildSizeButton(7)),
            const SizedBox(width: 8),
            Expanded(child: _buildSizeButton(8)),
          ],
        ),
        const SizedBox(height: 8),
        // Row 3: custom button (full width)
        SizedBox(
          width: double.infinity,
          child: _buildCustomButton(),
        ),
      ],
    );
  }

  Widget _buildSizeButton(int size) {
    final selected = _gridSize == size;
    return SizedBox(
      height: 48,
      child: Material(
        elevation: selected ? 3 : 0,
        borderRadius: BorderRadius.circular(12),
        shadowColor: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : const Color(0xFF7C4DFF).withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _changeGridSize(size),
            child: Center(
              child: Text(
                '$size×$size',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF1A237E),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton() {
    return SizedBox(
      height: 48,
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _showCustomSizeDialog,
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: Color(0xFF7C4DFF)),
                  SizedBox(width: 4),
                  Text(
                    AppStrings.custom,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Restart CTA
  // ------------------------------------------------------------------

  Widget _buildRestartButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(14),
        shadowColor: const Color(0xFF1565C0).withValues(alpha:0.3),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1565C0),
                Color(0xFF1976D2),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _newGame,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shuffle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.newGame,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}