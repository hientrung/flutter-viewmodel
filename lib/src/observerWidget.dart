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

  ///Listening on computation of some observables
  final T Function() computation;

  ///Create an observer widget
  const ObserverWidget(
      {Key key, this.observable, this.computation, @required this.builder})
      : assert(observable != null || computation != null),
        assert(builder != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _ObserverWidgetState<T>();
}

class _ObserverWidgetState<T> extends State<ObserverWidget<T>> {
  Computed<T> _computed;

  @override
  Widget build(BuildContext context) => widget.builder(context, _computed.peek);

  @override
  void initState() {
    super.initState();
    _computed =
        Computed(() => widget.observable?.value ?? widget.computation?.call());
    _computed.changed(() => setState(() {}));
  }

  @override
  void dispose() {
    _computed?.dispose();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', _computed.peek));
  }
}
