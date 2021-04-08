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
}

class _ObserverWidgetState<T> extends State<ObserverWidget<T>> {
  late Subscription _subscription;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.observable.peek);

  @override
  void initState() {
    super.initState();
    _subscription = widget.observable.changed(() => setState(() {}));
  }

  @override
  void dispose() {
    _subscription.dispose();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', widget.observable.peek));
  }
}
