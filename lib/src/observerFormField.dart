import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vmobject/vmobject.dart';

///An input to enter value for observable string or number or datetime.
///
///Validation on lost focus or instant validate if it already validated
class ObserverFormField<T> extends FormField<T> {
  ///Current observable value
  final ObservableBase<T> observable;

  ///Text input type, if null it will use default type base on value type
  final TextInputType keyboardType;

  ///Create new form field for an observable
  ObserverFormField({
    @required this.observable,
    Key key,
    InputDecoration decoration = const InputDecoration(),
    this.keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction,
    TextStyle style,
    StrutStyle strutStyle,
    TextDirection textDirection,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical textAlignVertical,
    bool autofocus = false,
    bool readOnly = false,
    ToolbarOptions toolbarOptions,
    bool showCursor,
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType smartDashesType,
    SmartQuotesType smartQuotesType,
    bool enableSuggestions = true,
    bool maxLengthEnforced = true,
    int maxLines = 1,
    int minLines,
    bool expands = false,
    int maxLength,
    ValueChanged<T> onChanged,
    GestureTapCallback onTap,
    VoidCallback onEditingComplete,
    ValueChanged<String> onFieldSubmitted,
    FormFieldSetter<T> onSaved,
    List<TextInputFormatter> inputFormatters,
    bool enabled = true,
    double cursorWidth = 2.0,
    Radius cursorRadius,
    Color cursorColor,
    Brightness keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool enableInteractiveSelection = true,
    InputCounterWidgetBuilder buildCounter,
    ScrollPhysics scrollPhysics,
  })  : assert(T == String || T == int || T == double || T == DateTime),
        super(
          key: key,
          initialValue: observable.value,
          onSaved: onSaved,
          enabled: enabled,
          builder: (field) {
            final state = field as _ObserverFormFieldState;
            final effectiveDecoration = (decoration ?? const InputDecoration())
                .applyDefaults(Theme.of(field.context).inputDecorationTheme);
            return TextField(
              controller: state._controller,
              focusNode: state._node,
              decoration:
                  effectiveDecoration.copyWith(errorText: state.errorText),
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
              readOnly: readOnly,
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
              maxLengthEnforced: maxLengthEnforced,
              maxLines: maxLines,
              minLines: minLines,
              expands: expands,
              maxLength: maxLength,
              onChanged: (val) {
                final v = _ObserverFormFieldState.getValue<T>(val);
                if (observable is ObservableWritable<T>) {
                  state._updating = true;
                  (observable as ObservableWritable<T>).value = v;
                }
                onChanged?.call(v);
              },
              onTap: onTap,
              onEditingComplete: onEditingComplete,
              onSubmitted: onFieldSubmitted,
              inputFormatters: inputFormatters,
              enabled: enabled,
              cursorWidth: cursorWidth,
              cursorRadius: cursorRadius,
              cursorColor: cursorColor,
              scrollPadding: scrollPadding,
              scrollPhysics: scrollPhysics,
              keyboardAppearance: keyboardAppearance,
              enableInteractiveSelection: enableInteractiveSelection,
              buildCounter: buildCounter,
            );
          },
        );

  @override
  FormFieldState<T> createState() => _ObserverFormFieldState<T>();
}

class _ObserverFormFieldState<T> extends FormFieldState<T> {
  ///handle focus
  FocusNode _node;

  ///should validate value or not
  var _mustValidate = false;

  ///listen on status value is valid or not
  Subscription _subValid;

  ///listen on observable value changed
  Subscription _subChanged;

  ///handle text of text field
  TextEditingController _controller;

  ///Set current update observable is internally to avoid rebuild widget
  bool _updating = false;

  ///set default input type
  TextInputType _keyboardType;

  @override
  void initState() {
    super.initState();
    //current text controller
    _controller = TextEditingController(text: getText(widget.observable.value));

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

    //if observable has validate, setup handlers
    if (widget.observable.hasValidator) {
      //validate on lost focus
      _node = FocusNode();
      _node.addListener(() {
        if (!_node.hasFocus && !_mustValidate) {
          setState(() {
            _mustValidate = true;
          });
        }
      });
      //instant validate
      _subValid = widget.observable.isValid.changed(() {
        if (_mustValidate) {
          setState(() {});
        }
      });
      //changed outside
      _subChanged = widget.observable.changed(() {
        if (!_updating) {
          setState(() {
            _controller.text = getText(widget.observable.value);
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
    _controller.text = getText(widget.observable.value);
  }

  @override
  ObserverFormField<T> get widget => super.widget as ObserverFormField;

  @override
  bool validate() {
    //already call rebuild
    _mustValidate = true;
    return widget.observable.hasValidator
        ? widget.observable.isValid.value
        : true;
  }

  @override
  String get errorText => hasError ? widget.observable.isValid.message : null;

  @override
  T get value => widget.observable.value;

  @override
  bool get hasError => widget.observable.hasValidator && _mustValidate
      ? !widget.observable.isValid.value
      : false;

  @override
  bool get isValid => widget.observable.hasValidator
      ? widget.observable.isValid.validator.validate(value)
      : true;

  @override
  void dispose() {
    _node?.dispose();
    _subValid?.dispose();
    _subChanged?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  ///convert value to String
  static String getText(dynamic val) {
    return val?.toString() ?? '';
  }

  ///convert a String to value
  static S getValue<S>(String val) {
    dynamic v;
    try {
      switch (S) {
        case int:
          v = int.parse(val);
          break;
        case double:
          v = double.parse(val);
          break;
        case String:
          v = val;
          break;
        case DateTime:
          v = DateTime.parse(val);
          break;
        default:
          v = null;
      }
    } catch (ex) {
      v = null;
    }

    return v;
  }
}
