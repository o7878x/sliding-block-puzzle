/// All UI strings for the sliding-block puzzle, in Traditional Chinese.
///
/// Centralising strings here makes it easy to audit, review, and later
/// integrate with Flutter's official l10n framework.
class AppStrings {
  AppStrings._();

  // ──────────────────────────────────────────────────────────────
  // App-level
  // ──────────────────────────────────────────────────────────────
  static const String appTitle = '數字華容道';

  // ──────────────────────────────────────────────────────────────
  // Game screen — app bar
  // ──────────────────────────────────────────────────────────────
  static const String gameTitle = '數字華容道';

  // ──────────────────────────────────────────────────────────────
  // Game screen — controls card
  // ──────────────────────────────────────────────────────────────
  static const String moveCountLabel = '步數';
  static const String timeLabel = '時間';
  // ──────────────────────────────────────────────────────────────
  // Game screen — difficulty
  // ──────────────────────────────────────────────────────────────
  static const String difficultyLabel = '難度係數';
  static const String difficultyEasy = '簡單';
  static const String difficultyMedium = '普通';
  static const String difficultyHard = '困難';
  static const String difficultyExpert = '極難';
  static const String gridSizeLabel = '階數';
  static const String custom = '自訂';
  static const String newGame = '重新開始';

  // ──────────────────────────────────────────────────────────────
  // Custom-size dialog
  // ──────────────────────────────────────────────────────────────
  static const String customSizeTitle = '自訂階數';
  static const String gridSizeFieldLabel = '階數';
  static String gridSizeHint(int min, int max) =>
      '輸入 $min~$max 之間的數字';
  static const String cancel = '取消';
  static const String confirm = '確認';
  static const String invalidInput = '請輸入有效數字';

  // ──────────────────────────────────────────────────────────────
  // Win dialog
  // ──────────────────────────────────────────────────────────────
  static const String winTitle = '恭喜過關！';
  static String winMessage(int moves) => '你用了 $moves 步完成了拼圖。';
  static const String continueViewing = '繼續查看';
  static const String newRound = '新一局';
}
