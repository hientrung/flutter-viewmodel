import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obsobject/obsobject.dart';

import 'observer_widget.dart';
import 'text_formatter.dart';

///An input to enter value for observable string or number or datetime.
///
///Validation on lost focus or instant validate if it already validated
class ObserverFormField<T> extends FormField<T> {
  ///Current observable value
  final ObservableBase<T> observable;

  ///Handler format display value, if null it will use default format base on value type
  final TextFormatter<T>? formatter;

  ///Text input type, if null it will use default type base on value type
  final TextInputType? keyboardType;

  ///Create new form field for an observable
  ///
  ///For documentation about the various parameters, see the [TextField] class
  ///and [new TextField], the constructor.
  ObserverFormField({
    required this.observable,
    this.formatter,
    this.keyboardType,
    Key? key,
    //copy from constructor TextField
    InputDecoration decoration = const InputDecoration(),
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign textAlign = TextAlign.start,
    TextAlignVertical? textAlignVertical,
    TextDirection textDirection = TextDirection.ltr,
    bool readOnly = false,
    ToolbarOptions? toolbarOptions,
    bool showCursor = true,
    bool autofocus = false,
    String obscuringCharacter = '•',
    bool obscureText = false,
    bool autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    bool enableSuggestions = true,
    int? maxLines = 1,
    int? minLines,
    bool expands = false,
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
    ValueChanged<T>? onChanged,
    VoidCallback? onEditingComplete,
    bool enabled = true,
    double cursorWidth = 2.0,
    double? cursorHeight,
    Radius? cursorRadius,
    Color? cursorColor,
    Brightness? keyboardAppearance,
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
    bool enableInteractiveSelection = true,
    TextSelectionControls? selectionControls,
    VoidCallback? onTap,
    MouseCursor? mouseCursor,
    InputCounterWidgetBuilder? buildCounter,
    ScrollController? scrollController,
    ScrollPhysics? scrollPhysics,
    Iterable<String>? autofillHints,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool enableIMEPersonalizedLearning = true,
    AppPrivateCommandCallback? onAppPrivateCommand,
    BoxHeightStyle selectionHeightStyle = BoxHeightStyle.tight,
    BoxWidthStyle selectionWidthStyle = BoxWidthStyle.tight,
    ValueChanged<T>? onSubmitted,
    String? restorationId,
  }) : super(
          key: key,
          initialValue: observable.value,
          enabled: enabled,
          builder: (field) {
            final state = field as _ObserverFormFieldState<T>;
            return ObserverWidget(
              observable: state._err!,
              builder: (context, String? err) => TextField(
                controller: state._controller,
                decoration: decoration
                    .applyDefaults(Theme.of(context).inputDecorationTheme)
                    .copyWith(errorText: err),
                keyboardType: state._keyboardType,
                focusNode: state._focusNode,
                textInputAction: textInputAction,
                textCapitalization: textCapitalization,
                style: style,
                strutStyle: strutStyle,
                textAlign: textAlign,
                textAlignVertical: textAlignVertical,
                textDirection: textDirection,
                readOnly: readOnly && observable is ObservableWritable,
                toolbarOptions: toolbarOptions,
                showCursor: showCursor,
                autofocus: autofocus,
                obscuringCharacter: obscuringCharacter,
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
                  if (state._formatter!.isValid(val)) {
                    final v = state._getValue(val);
                    if (observable is ObservableWritable<T> && v is T) {
                      observable.value = v;
                    }
                    onChanged?.call(v);
                  }
                },
                onEditingComplete: onEditingComplete,
                inputFormatters: <TextInputFormatter>[state._formatter!],
                enabled: enabled,
                cursorWidth: cursorWidth,
                cursorHeight: cursorHeight,
                cursorRadius: cursorRadius,
                cursorColor: cursorColor,
                keyboardAppearance: keyboardAppearance,
                scrollPadding: scrollPadding,
                enableInteractiveSelection: enableInteractiveSelection,
                selectionControls: selectionControls,
                onTap: onTap,
                mouseCursor: mouseCursor,
                buildCounter: buildCounter,
                scrollController: scrollController,
                scrollPhysics: scrollPhysics,
                autofillHints: autofillHints,
                dragStartBehavior: dragStartBehavior,
                enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
                maxLengthEnforcement: maxLengthEnforcement,
                onAppPrivateCommand: onAppPrivateCommand,
                selectionHeightStyle: selectionHeightStyle,
                selectionWidthStyle: selectionWidthStyle,
                onSubmitted: onSubmitted != null
                    ? (_) => onSubmitted.call(observable.peek)
                    : null,
                restorationId: restorationId,
              ),
            );
          },
        );

  @override
  FormFieldState<T> createState() => _ObserverFormFieldState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', observable.peek));
  }
}

class _ObserverFormFieldState<T> extends FormFieldState<T> {
  ///handle text of text field
  TextEditingController? _controller;

  ///set default input type
  TextInputType? _keyboardType;

  ///current formatter
  TextFormatter<T>? _formatter;

  ///current focus node
  FocusNode? _focusNode;

  ///Should show validate error
  final _mustValidate = Observable(false);

  ///Listen on error
  Computed<String?>? _err;

  void _subscribe([ObserverFormField<T>? old]) {
    if (old == null || widget.observable != old.observable) {
      //current error computed
      _err?.dispose();
      _err = Computed(() {
        if (!_mustValidate.value) return null;
        return widget.observable.error;
      });
    }
    if (old == null || widget.formatter != old.formatter) {
      //current formatter
      if (widget.formatter != null) {
        _formatter = widget.formatter!;
      } else {
        switch (T.toString()) {
          case 'int':
            _formatter = NumberTextFormatter<int>() as TextFormatter<T>;
            break;
          case 'int?':
            _formatter = NumberTextFormatter<int?>() as TextFormatter<T>;
            break;
          case 'double':
            _formatter = NumberTextFormatter<double>(
              fraction: 2,
            ) as TextFormatter<T>;
            break;
          case 'double?':
            _formatter = NumberTextFormatter<double?>(
              fraction: 2,
            ) as TextFormatter<T>;
            break;
          case 'String':
            _formatter = StringTextFormatter() as TextFormatter<T>;
            break;
          case 'DateTime':
            _formatter = DateTimeFormatter<DateTime>() as TextFormatter<T>;
            break;
          case 'DateTime?':
            _formatter = DateTimeFormatter<DateTime?>() as TextFormatter<T>;
            break;
          default:
            throw UnimplementedError('Should provide formatter for text input');
        }
      }
    }
    if (old == null ||
        widget.observable != old.observable ||
        widget.formatter != old.formatter) {
      //current text controller
      _controller?.dispose();
      _controller =
          TextEditingController(text: _getText(widget.observable.value));
    }
    if (old == null || widget.keyboardType != old.keyboardType) {
      //default input type
      if (widget.keyboardType != null) {
        _keyboardType = widget.keyboardType;
      } else {
        switch (T.toString()) {
          case 'int':
          case 'int?':
            _keyboardType = TextInputType.number;
            break;
          case 'double':
          case 'double?':
            _keyboardType =
                const TextInputType.numberWithOptions(decimal: true);
            break;
          case 'DateTime':
          case 'DateTime?':
            _keyboardType = TextInputType.datetime;
            break;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    //handle focus
    _focusNode?.dispose();
    _focusNode = FocusNode();
    _focusNode!.addListener(() {
      if (!_focusNode!.hasFocus) {
        _mustValidate.value = true;
        _controller!.text = _getText(widget.observable.peek);
      }
    });
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant ObserverFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribe(oldWidget);
  }

  @override
  void reset() {
    if (widget.observable is ObservableWritable) {
      _mustValidate.value = false;
      (widget.observable as ObservableWritable).value = widget.initialValue;
    }
  }

  @override
  ObserverFormField<T> get widget => super.widget as ObserverFormField<T>;

  @override
  bool validate() {
    _mustValidate.value = true;
    return widget.observable.valid;
  }

  @override
  String? get errorText => widget.observable.error;

  @override
  T get value => widget.observable.peek;

  @override
  bool get hasError => !widget.observable.valid;

  @override
  bool get isValid => widget.observable.valid;

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode?.dispose();
    _err?.dispose();
    super.dispose();
  }

  ///Convert value to string
  String _getText(dynamic value) {
    return _formatter!.format(value);
  }

  ///Parse string to value
  T _getValue(String text) {
    return _formatter!.parse(text);
  }
}
