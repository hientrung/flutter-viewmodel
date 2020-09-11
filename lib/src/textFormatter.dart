import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

abstract class TextFormatter<T> extends TextInputFormatter {
  ///Format value to text
  String format(T value);

  ///Parser text to value
  dynamic parse(String text);

  ///Check current text is valid to parse or not
  bool isValid(String text) => true;
}

///Process format number while typing
class NumberTextFormatter<T> extends TextFormatter<T> {
  ///Current locale
  final String locale;

  ///Number of fraction allowed
  final int fraction;

  ///Current number formatter
  NumberFormat numberFormat;
  String _last;
  String _decimal;
  String _thousand;
  RegExp _regex;

  ///Create number formatter used for TextInput
  NumberTextFormatter({@required this.fraction, this.locale}) {
    //format decimal number
    var s = '#,##0';
    if (fraction > 0) {
      s += '.'.padRight(fraction + 1, '#');
    }
    numberFormat = NumberFormat(s, locale);
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

///Handler format string by a masked text,
///used to parse to other value type of TextFormatter
class _StringFormat {
  final String mask;
  final Map<String, RegExp> keys;
  final String holder;
  final includeLiteral;
  _StringFormat({
    @required this.mask,
    @required this.keys,
    this.holder = '_',
    this.includeLiteral = false,
  })  : assert(holder != null),
        assert(keys != null);

  TextEditingValue formatEdit(TextEditingValue value) {
    if (value.text == null || value.text.isEmpty) {
      return value;
    }

    //override text if can
    var text = value.text.length <= mask.length
        ? value.text
        : value.text.substring(0, value.selection.end) +
            value.text.substring(
                value.text.length - mask.length + value.selection.end);
    //array regexp to check characters
    final arr = <RegExp>[];
    for (var i = 0; i < mask.length; i++) {
      if (keys.containsKey(mask[i])) {
        arr.add(keys[mask[i]]);
      }
    }

    //get raw text, position
    var raw = '';
    var ind = 0;
    var pos = 0;
    for (var i = 0; i < text.length && ind < arr.length; i++) {
      if (text[i].contains(arr[ind])) {
        ind++;
        raw += text[i];
        if (i < value.selection.end) {
          pos++;
        }
      }
    }

    //format text and current position
    text = format(raw);
    var cur = 0;
    ind = 0;
    for (var i = 0; i < mask.length && ind < pos; i++) {
      if (keys.containsKey(mask[i])) {
        ind++;
      }
      cur++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cur),
    );
  }

  ///Check current text editing is valid or not
  bool isValid(String text) {
    if (text == null || text.isEmpty || text == format('')) {
      return true;
    }
    if (text.length != mask.length) {
      return false;
    }
    for (var i = 0; i < mask.length; i++) {
      if (keys.containsKey(mask[i]) && !text[i].contains(keys[mask[i]])) {
        return false;
      }
    }
    return true;
  }

  ///Format raw text to masked text
  String format(String value) {
    var s = '';
    var c = 0;
    for (var i = 0; i < mask.length; i++) {
      if (keys.containsKey(mask[i])) {
        if (c > -1 && c < value.length) {
          if (value[c].contains(keys[mask[i]])) {
            s += value[c];
            c++;
          } else {
            s += holder;
            c = -1; //invalid mask
          }
        } else {
          s += holder;
        }
      } else {
        s += mask[i];
        if (includeLiteral) {
          c++;
        }
      }
    }
    return s;
  }

  ///Parse masked text to raw text
  String parse(String text) {
    if (text == null || text.isEmpty) {
      return '';
    }
    var s = '';
    for (var i = 0; i < mask.length; i++) {
      if (keys.containsKey(mask[i])) {
        if (i < text.length && text[i].contains(keys[mask[i]])) {
          s += text[i];
        } else {
          //invalid, maybe change mask
          return '';
        }
      } else {
        if (includeLiteral) {
          s += mask[i];
        }
      }
    }
    return s;
  }
}

///Process format masked text
///
///Default [keys] use the following wildcard characters
///- \* : any character
///- 0 : number only, 0-9
///- A : letter only, a-zA-Z
///- \# : number or letter
class MaskTextFormatter extends TextFormatter<String> {
  final _StringFormat _fm;
  MaskTextFormatter({
    @required String mask,
    Map<String, RegExp> keys,
    String holder = '_',
    bool includeLiteral = false,
  })  : assert(mask != null),
        _fm = _StringFormat(
          mask: mask,
          keys: keys ??
              <String, RegExp>{
                '*': RegExp(r'.'),
                '0': RegExp(r'[0-9]'),
                'A': RegExp(r'[a-zA-Z]'),
                '#': RegExp(r'[0-9a-zA-Z]')
              },
          holder: holder,
          includeLiteral: includeLiteral,
        );

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text == oldValue?.text) return newValue;
    return _fm.formatEdit(newValue);
  }

  @override
  String format(String value) => _fm.format(value);

  @override
  dynamic parse(String text) => _fm.parse(text);

  @override
  bool isValid(String text) => _fm.isValid(text);
}

///Used to handle DateTimeFormatter
enum DateTimeFormatterType { Date, DateShortTime, DateFullTime }

///Process format DateTime
class DateTimeFormatter extends TextFormatter<DateTime> {
  ///Type mask typing
  final DateTimeFormatterType type;

  ///Current Locale use to format
  final String locale;

  _StringFormat _fm;
  DateFormat _dateFormat;

  DateTimeFormatter({this.type = DateTimeFormatterType.Date, this.locale})
      : assert(type != null) {
    final d = DateFormat.yMd(locale);
    switch (type) {
      case DateTimeFormatterType.Date:
        _dateFormat = d;
        break;
      case DateTimeFormatterType.DateShortTime:
        _dateFormat = d.add_Hm();
        break;
      case DateTimeFormatterType.DateFullTime:
        _dateFormat = d.add_Hms();
        break;
    }
    var s = _dateFormat.pattern;
    //rewrite format use full digit
    s = s
        .replaceAll(RegExp(r'y+'), 'yyyy')
        .replaceAll(RegExp(r'M+'), 'MM')
        .replaceAll(RegExp(r'd+'), 'dd')
        .replaceAll(RegExp(r'H+'), 'HH')
        .replaceAll(RegExp(r'j+'), 'HH')
        .replaceAll(RegExp(r'm+'), 'mm')
        .replaceAll(RegExp(r's+'), 'ss');
    _dateFormat = DateFormat(s, locale);
    //rewrite masked text
    s = s
        .replaceAll(RegExp(r'y+'), '0000')
        .replaceAll(RegExp(r'M+'), '00')
        .replaceAll(RegExp(r'd+'), '00')
        .replaceAll(RegExp(r'H+'), '00')
        .replaceAll(RegExp(r'm+'), '00')
        .replaceAll(RegExp(r's+'), '00');
    _fm = _StringFormat(mask: s, keys: <String, RegExp>{'0': RegExp(r'[0-9]')});
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue?.text == newValue.text) {
      return newValue;
    }
    return _fm.formatEdit(newValue);
  }

  @override
  bool isValid(String text) {
    if (text == null || text.isEmpty || text == format(null)) {
      return true;
    }
    try {
      var d = _dateFormat.parse(text);
      return _dateFormat.format(d) == text;
    } on FormatException catch (_) {
      return false;
    }
  }

  @override
  String format(DateTime value) {
    if (value == null) {
      return _fm.format('');
    }
    return _dateFormat.format(value);
  }

  @override
  dynamic parse(String text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    try {
      return _dateFormat.parse(text);
    } catch (_) {
      return null;
    }
  }
}
