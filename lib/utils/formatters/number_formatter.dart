import 'package:decima/domain/enums/decimal_separator.dart';

class NumberFormatter {
  NumberFormatter._();

  static String format(
    int cents, {
    required DecimalSeparator separator,
    bool useThousandsSeparator = false,
  }) {
    final isNegative = cents < 0;
    final absCents = cents.abs();
    final wholePart = absCents ~/ 100;
    final decimalPart = absCents % 100;
    final sign = isNegative ? '-' : '';

    final wholeStr = useThousandsSeparator
        ? _addThousandsSeparator(wholePart.toString(), separator)
        : wholePart.toString();

    final decimalStr = decimalPart.toString().padLeft(2, '0');

    return '$sign$wholeStr${separator.character}$decimalStr';
  }

  static String formatDouble(
    double value, {
    required DecimalSeparator separator,
    bool useThousandsSeparator = false,
  }) {
    final cents = (value * 100).round();

    return format(
      cents,
      separator: separator,
      useThousandsSeparator: useThousandsSeparator,
    );
  }

  static String _addThousandsSeparator(
    String wholeStr,
    DecimalSeparator decimalSeparator,
  ) {
    final thousandsSep = decimalSeparator == DecimalSeparator.dot ? ',' : '.';

    if (wholeStr.length <= 3) return wholeStr;

    final buffer = StringBuffer();
    final start = wholeStr.length % 3;

    if (start > 0) {
      buffer.write(wholeStr.substring(0, start));
    }

    for (var i = start; i < wholeStr.length; i += 3) {
      if (buffer.isNotEmpty) buffer.write(thousandsSep);
      buffer.write(wholeStr.substring(i, i + 3));
    }

    return buffer.toString();
  }
}
