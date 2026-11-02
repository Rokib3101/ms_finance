library core_utils;

class BanglaUtils {
  static const Map<String, String> _enToBn = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  static const Map<String, String> _bnToEn = {
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };

  static String toBangla(dynamic input) {
    String inputStr = input.toString();

    // Check if the input is a pure number (possibly with decimal point)
    // We avoid formatting strings that look like dates (e.g., 2024-05-15) or have letters
    final numberRegex = RegExp(r'^-?\d+(\.\d+)?$');
    if (numberRegex.hasMatch(inputStr)) {
      inputStr = _addIndianCommas(inputStr);
    }

    String output = '';
    for (int i = 0; i < inputStr.length; i++) {
      output += _enToBn[inputStr[i]] ?? inputStr[i];
    }
    return output;
  }

  static String _addIndianCommas(String input) {
    List<String> parts = input.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    bool isNegative = integerPart.startsWith('-');
    if (isNegative) {
      integerPart = integerPart.substring(1);
    }

    if (integerPart.length <= 3) {
      return (isNegative ? '-' : '') + integerPart + decimalPart;
    }

    // Last 3 digits
    String lastThree = integerPart.substring(integerPart.length - 3);
    String remaining = integerPart.substring(0, integerPart.length - 3);

    // Add commas every 2 digits for the remaining part
    String formattedRemaining = '';
    while (remaining.length > 2) {
      formattedRemaining =
          ',${remaining.substring(remaining.length - 2)}$formattedRemaining';
      remaining = remaining.substring(0, remaining.length - 2);
    }

    formattedRemaining = remaining + formattedRemaining;

    return '${isNegative ? '-' : ''}$formattedRemaining,$lastThree$decimalPart';
  }

  static String toEnglish(String input) {
    String output = '';
    for (int i = 0; i < input.length; i++) {
      output += _bnToEn[input[i]] ?? input[i];
    }
    return output;
  }

  static double parse(String input) {
    String english = toEnglish(input);
    return double.tryParse(english.replaceAll(',', '')) ?? 0.0;
  }
}
