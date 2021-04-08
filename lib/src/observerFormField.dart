import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obsobject/obsobject.dart';

import 'observerWidget.dart';
import 'textFormatter.dart';

///An input to enter value for observable string or number or datetime.
///
///Validation on lost focus or instant validate if it already validated
class ObserverFormField<T> extends FormField<T> {
  ///Current observable value
  final ObservableBase<T> observable;

  ///Text input type, if null it will use default type base on value type
  final TextInputType? keyboardType;

  ///Handler format display value
  final TextFormatter<T>? formatter;

  ///Create new form field for an observable
  ObserverFormField({
    required this.observable,
    this.formatter,
    Key? key,
    InputDecoration decoration = const InputDecoration(),
    this.keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.none,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextDirection textDirection = TextDirection.ltr,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    bool autofocus = false,
    bool readOnly = false,
    ToolbarOptions? toolbarOptions,
    bool showCursor = true,
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    int? maxLength,
    ValueChanged<T>? onChanged,
    GestureTapCallback? onTap,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
    FormFieldSetter<T>? onSaved,
    bool enabled = true,
    double cursorWidth = 2.0,
    Radius? cursorRadius,
    Color? cursorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool enableInteractiveSelection = true,
    InputCounterWidgetBuilder? buildCounter,
    ScrollPhysics? scrollPhysics,
  }) : super(
          key: key,
          initialValue: observable.value,
          onSaved: onSaved,
          enabled: enabled,
          builder: (field) {
            final state = field as _ObserverFormFieldState<T>;
            final effectiveDecoration = (decoration)
                .applyDefaults(Theme.of(state.context).inputDecorationTheme);
            state._controller.text = state._getText(observable.value);
            return ObserverWidget<String>(
                observable: Computed(() {
                  //it should redraw if change valid status
                  if (!observable.hasValidator) {
                    return '';
                  }
                  observable.isValid.value; //depend
                  if (!state._mustValidate) {
                    return '';
                  } else {
                    return observable.isValid.message;
                  }
                }),
                builder: (context, _) => TextField(
                      controller: state._controller,
                      focusNode: state._node,
                      decoration: effectiveDecoration.copyWith(
                          errorText: state.errorText),
                      keyboardType: state._keyboardType,
                      textInputAction: textInputAction,
                      style: style,
                      strutStyle: strutStyle,
                      textAlign: textAlign,
                      textAlignVertical: textAlignVertical,
                      textDirection: textDirection,
                      textCapitalization: textCapitalization,
                      autofocus: autofocus,
                      toolbarOptions: toolbarOptions,
                      readOnly: readOnly && observable is ObservableWritable,
                      showCursor: showCursor,
                      obscureText: obscureText,
                      autocorrect: autocorrect,
                      smartDashesType: smartDashesType ??
                          (obscureText
                              ? SmartDashesType.disabled
                              : SmartDashesType.enabled),
                      smartQuotesType: smartQuotesType ??
                          (obscureText
                              ? SmartQuotesType.disabled
                              : SmartQuotesType.enabled),
                      enableSuggestions: enableSuggestions,
                      maxLines: maxLines,
                      minLines: minLines,
                      expands: expands,
                      maxLength: maxLength,
                      onChanged: (val) {
                        if (state._formatter.isValid(val)) {
                          final v = state._getValue(val);
                          if (observable is ObservableWritable<T> && v is T) {
                            state._updating = true;
                            observable.value = v;
                          }
                          onChanged?.call(v);
                        }
                      },
                      onTap: onTap,
                      onEditingComplete: onEditingComplete,
                      onSubmitted: onFieldSubmitted,
                      inputFormatters: <TextInputFormatter>[state._formatter],
                      enabled: enabled,
                      cursorWidth: cursorWidth,
                      cursorRadius: cursorRadius,
                      cursorColor: cursorColor,
                      scrollPadding: scrollPadding,
                      scrollPhysics: scrollPhysics,
                      keyboardAppearance: keyboardAppearance,
                      enableInteractiveSelection: enableInteractiveSelection,
                      buildCounter: buildCounter,
                    ));
          },
        );

  @override
  FormFieldState<T> createState() => _ObserverFormFieldState<T>();
}

class _ObserverFormFieldState<T> extends FormFieldState<T> {
  ///handle focus
  late FocusNode _node;

  ///should validate value or not
  var _mustValidate = false;

  ///listen on observable value changed
  Subscription? _subChanged;

  ///handle text of text field
  late TextEditingController _controller;

  ///Set current update observable is internally to avoid rebuild widget
  bool _updating = false;

  ///set default input type
  TextInputType? _keyboardType;

  ///current formatter
  late TextFormatter _formatter;

  @override
  void initState() {
    super.initState();
    //current formatter
    if (widget.formatter != null) {
      _formatter = widget.formatter!;
    } else {
      switch (T) {
        case int:
          _formatter = NumberTextFormatter<int?>(
            fraction: 0,
          );
          break;
        case double:
          _formatter = NumberTextFormatter<double?>(
            fraction: 2,
          );
          break;
        case String:
          _formatter = StringTextFormatter();
          break;
        default:
          throw UnimplementedError('Should provide formatter for text input');
      }
    }
    //current text controller
    _controller =
        TextEditingController(text: _getText(widget.observable.value));

    //default input type
    if (widget.keyboardType != null) {
      _keyboardType = widget.keyboardType;
    } else {
      switch (T) {
        case int:
          _keyboardType = TextInputType.number;
          break;
        case double:
          _keyboardType = TextInputType.numberWithOptions(decimal: true);
          break;
        case DateTime:
          _keyboardType = TextInputType.datetime;
          break;
      }
    }

    _node = FocusNode();
    _node.addListener(() {
      //reset if formatter invalid
      if (!_node.hasFocus && !_formatter.isValid(_controller.text)) {
        _controller.text = _getText(widget.observable.value);
      }
      //validate on lost focus
      if (widget.observable.hasValidator && !_node.hasFocus && !_mustValidate) {
        setState(() {
          _mustValidate = true;
        });
      }
    });

    //if observable has validate, setup handlers
    if (widget.observable.hasValidator) {
      //changed outside
      _subChanged = widget.observable.changed(() {
        if (!_updating) {
          setState(() {
            _controller.text = _getText(widget.observable.value);
          });
        } else {
          _updating = false;
        }
      });
    }
  }

  @override
  void reset() {
    //already call rebuild
    if (widget.observable is ObservableWritable) {
      _updating = true;
      (widget.observable as ObservableWritable).value = widget.initialValue;
    }
    _mustValidate = false;
    _controller.text = _getText(widget.observable.value);
  }

  @override
  ObserverFormField<T> get widget => super.widget as ObserverFormField<T>;

  @override
  bool validate() {
    //already call rebuild
    _mustValidate = true;
    return widget.observable.hasValidator
        ? widget.observable.isValid.value
        : true;
  }

  @override
  String? get errorText => hasError ? widget.observable.isValid.message : null;

  @override
  T get value => widget.observable.value;

  @override
  bool get hasError => widget.observable.hasValidator && _mustValidate
      ? !widget.observable.isValid.value
      : false;

  @override
  bool get isValid => widget.observable.hasValidator
      ? widget.observable.isValid.validator!.validate(value) != null
      : true;

  @override
  void dispose() {
    _node.dispose();
    _subChanged?.dispose();
    _controller.dispose();
    super.dispose();
  }

  ///Convert value to string
  String _getText(dynamic value) {
    return _formatter.format(value);
  }

  ///Parse string to value
  dynamic _getValue(String text) {
    return _formatter.parse(text);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', widget.observable.peek));
  }
}
