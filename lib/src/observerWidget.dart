import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:obsobject/obsobject.dart';

///An observer of observable to update widget
class ObserverWidget<T> extends StatefulWidget {
  ///The function use to build widget
  final Widget Function(BuildContext context, T value) builder;

  ///Listening on an observable
  final ObservableBase<T> observable;

  ///Create an observer widget
  const ObserverWidget(
      {Key key, @required this.observable, @required this.builder})
      : assert(observable != null),
        assert(builder != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _ObserverWidgetState<T>();
}

class _ObserverWidgetState<T> extends State<ObserverWidget<T>> {
  Subscription _subscription;
  T _value;

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(ObserverWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observable != widget.observable) {
      _subscribe();
    } else {
      _value = widget.observable.peek;
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _unsubscribe();
    _value = widget.observable.peek;
    _subscription = widget.observable.changed((T v) {
      setState(() {
        _value = v;
      });
    });
  }

  void _unsubscribe() {
    _subscription?.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', _value));
  }
}
