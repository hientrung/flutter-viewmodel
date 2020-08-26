import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart';

abstract class TextFormatter<T> extends TextInputFormatter {
  ///Format value to text
  String format(T value);

  ///Parser text to value
  dynamic parse(String text);
}

///Process format number while typing
class NumberTextFormatter<T> extends TextFormatter<T> {
  ///Current locale
  final Locale locale;

  ///Number of fraction allowed
  final int fraction;

  ///Current number formatter
  NumberFormat numberFormat;
  String _last;
  String _decimal;
  String _thousand;
  RegExp _regex;

  ///Create number formatter used for TextInput
  NumberTextFormatter({@required this.fraction, @required this.locale}) {
    //format decimal number
    final l = locale.toLanguageTag();
    final code =
        Intl.verifiedLocale(l, (l) => numberFormatSymbols.containsKey(l));
    final pt = numberFormatSymbols[code].DECIMAL_PATTERN as String;
    final arr = pt.split('.');
    var s = arr[0];
    if (fraction > 0) {
      s += '.'.padRight(fraction + 1, '#');
    }
    numberFormat = NumberFormat(s, code);
    _decimal = numberFormat.symbols.DECIMAL_SEP;
    _thousand = numberFormat.symbols.GROUP_SEP;
    if (fraction > 0) {
      _regex = RegExp('^\\d+(?:\\.\\d{0,$fraction})?\$');
    } else {
      _regex = RegExp(r'^\d+$');
    }
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text == _last) {
      return oldValue;
    }
    if (newValue.text == null || newValue.text.isEmpty) {
      _last = newValue.text;
      return newValue;
    }

    var text = newValue.text.replaceAll(_thousand, '');
    if (_decimal != '.') {
      text = text.replaceAll(_decimal, '.');
    }
    if (!_regex.hasMatch(text)) {
      return oldValue;
    }

    //convert to number
    num number = 0;
    switch (T) {
      case int:
        number = int.tryParse(text) ?? 0;
        break;
      case double:
        number = double.tryParse(text) ?? 0;
        break;
    }
    text = numberFormat.format(number).trim();
    if (newValue.text.endsWith(_decimal) && !text.contains(_decimal)) {
      text += _decimal;
    }

    //current cursor
    final m = RegExp('[\\d\\$_decimal]');
    var old = 0;
    for (var i = 0; i < newValue.selection.end; i++) {
      if (m.hasMatch(newValue.text[i])) {
        old++;
      }
    }

    var ind = 0;
    var cur = 0;
    for (var i = 0; i < text.length && ind < old; i++) {
      if (m.hasMatch(text[i])) ind++;
      cur++;
    }

    _last = text;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cur),
    );
  }

  @override
  String format(T value) {
    if (value == null) {
      return '';
    }
    return numberFormat.format(value);
  }

  @override
  dynamic parse(String text) {
    var t = text;
    if (t == null || t.isEmpty) {
      t = '0';
    }
    final v = numberFormat.parse(t);
    switch (T) {
      case int:
        return v.toInt();
      case double:
        return v.toDouble();
      default:
        return null;
    }
  }
}
