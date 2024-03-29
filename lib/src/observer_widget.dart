import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:obsobject/obsobject.dart';

///An observer of observables to update widget by an asynchronous processing
///after all changed done
class ObserverWidget<T> extends StatefulWidget {
  ///The function use to build widget
  final Widget Function(BuildContext context, T value) builder;

  ///Listening on an observable
  final ObservableBase<T> observable;

  ///Create an observer widget
  const ObserverWidget(
      {Key? key, required this.observable, required this.builder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ObserverWidgetState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('observable', observable.peek));
  }
}

class _ObserverWidgetState<T> extends State<ObserverWidget<T>> {
  Subscription? _subscription;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.observable.peek);

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant ObserverWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.observable != oldWidget.observable) _subscribe();
  }

  void _subscribe() {
    _subscription?.dispose();
    _subscription = widget.observable.changed(() => setState(() {}));
  }

  @override
  void dispose() {
    _subscription?.dispose();
    super.dispose();
  }
}
