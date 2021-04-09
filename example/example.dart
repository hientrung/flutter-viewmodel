import 'package:flutter/material.dart';
import 'package:vmobject/vmobject.dart';

void main() {
  runApp(MaterialApp(home: HomeView()));
}

class HomeModel extends ViewModel {
  final Observable<int> count = Observable<int>(1);
  final Observable<int> a = Observable(0);
  final Observable<double> b = Observable(0);
  final Observable<double?> c = Observable(null);
  final Observable<String> d = Observable('');
  final Observable<DateTime> e = Observable(DateTime(2021, 1, 4));
  final Observable<DateTime?> f = Observable(null);
  final Observable<String> g = Observable('');
  final Observable<DateTime> h = Observable(DateTime.now());
  final Observable<int?> i = Observable(null)
    ..isValid.validator = ValidatorRequired();

  @override
  void activate() {
    super.activate();
    a.changed(() => print('int: $a'));
    b.changed(() => print('double: $b'));
    c.changed(() => print('double?: $c'));
    d.changed(() => print('string: $d'));
    e.changed(() => print('DateTime: $e'));
    f.changed(() => print('DateTime?: $f'));
    g.changed(() => print('Mask: $g'));
    h.changed(() => print('Mask: $h'));
  }

  void add() {
    count.value++;
  }
}

class HomeView extends ViewWidget<HomeModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  HomeModel initModel() => HomeModel();

  @override
  Widget builder(BuildContext context, HomeModel model) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            ObserverWidget(
                observable: model.count,
                builder: (context, int value) => Text(
                      '$value',
                      style: Theme.of(context).textTheme.headline4,
                    )),
            ObserverFormField(
              observable: model.a,
              decoration: InputDecoration(labelText: 'Int'),
            ),
            ObserverFormField(
              observable: model.b,
              decoration: InputDecoration(labelText: 'Double'),
            ),
            ObserverFormField(
              observable: model.c,
              decoration: InputDecoration(labelText: 'Double?'),
            ),
            ObserverFormField(
              observable: model.d,
              decoration: InputDecoration(labelText: 'String'),
            ),
            ObserverFormField(
              observable: model.e,
              decoration: InputDecoration(labelText: 'DateTime'),
            ),
            ObserverFormField(
              observable: model.f,
              decoration: InputDecoration(labelText: 'DateTime?'),
            ),
            ObserverFormField(
              observable: model.g,
              decoration: InputDecoration(labelText: 'Mask'),
              formatter: MaskTextFormatter(mask: '0000-####-####'),
            ),
            ObserverFormField(
              observable: model.h,
              decoration: InputDecoration(labelText: 'Full DateTime'),
              formatter: DateTimeFormatter<DateTime>(
                  type: DateTimeFormatterType.dateFullTime),
            ),
            ObserverFormField(
              observable: model.i,
              decoration: InputDecoration(labelText: 'Required'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          model.add();
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
