import 'package:math_expressions/math_expressions.dart';
import 'core_utils.dart';

class MathEvaluator {
  /// Evaluates a string expression like "100+50", "1000-200", "+500", "-200", "50*2", "১০+২০".
  /// If [baseValue] is provided and [input] starts with '+' or '-',
  /// [baseValue] is prepended to perform relative addition/subtraction.
  static double? evaluate(String input, {double? baseValue}) {
    String clean = input.trim();
    if (clean.isEmpty) return 0.0;

    // Convert Bangla digits to English
    clean = BanglaUtils.toEnglish(clean);
    clean = clean
        .replaceAll(',', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('–', '-');

    // Handle relative expression starting with + or -
    if (baseValue != null) {
      final noSpaces = clean.replaceAll(' ', '');
      if (noSpaces.startsWith('+') || noSpaces.startsWith('-')) {
        clean = '${formatNumber(baseValue)}$noSpaces';
      }
    }

    try {
      // If simple double
      final simpleVal = double.tryParse(clean);
      if (simpleVal != null) {
        return simpleVal;
      }

      // Parse with math_expressions
      final p = Parser();
      Expression exp = p.parse(clean);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);
      if (result.isNaN || result.isInfinite) return null;
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Checks if the input contains math operators or starts with +/-
  static bool isExpression(String input) {
    final clean = BanglaUtils.toEnglish(input.trim());
    return clean.contains('+') ||
        clean.contains('-') ||
        clean.contains('*') ||
        clean.contains('/') ||
        clean.contains('×') ||
        clean.contains('÷');
  }

  /// Formats a double value cleanly without trailing .0 or unnecessary decimal places.
  static String formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      String str = value.toStringAsFixed(2);
      if (str.endsWith('.00')) {
        return str.substring(0, str.length - 3);
      }
      if (str.endsWith('0')) {
        return str.substring(0, str.length - 1);
      }
      return str;
    }
  }
}
