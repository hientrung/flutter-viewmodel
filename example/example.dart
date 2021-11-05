// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:vmobject/vmobject.dart';

void main() {
  runApp(const MaterialApp(home: HomeView()));
}

class HomeModel extends ViewModel {
  final Observable<int> count = Observable<int>(1);
  final Observable<int> a = Observable(0);
  final Observable<double> b = Observable(0);
  final Observable<double?> c = Observable(null);
  final Observable<String> d = Observable(
    '',
    validator: ValidatorLeast([ValidatorRequired(), ValidatorEmail()]),
  );
  final Observable<DateTime> e = Observable(DateTime(2021, 1, 4));
  final Observable<DateTime?> f = Observable(null);
  final Observable<String> g = Observable('');
  final Observable<DateTime> h = Observable(DateTime.now());
  final Observable<int?> i = Observable(null, validator: ValidatorRequired());

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
        title: const Text('My App'),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            ObserverWidget(
              observable: model.count,
              builder: (context, int value) => Text(
                '$value',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
            ObserverFormField(
              observable: model.a,
              decoration: const InputDecoration(labelText: 'Int'),
            ),
            ObserverFormField(
              observable: model.b,
              decoration: const InputDecoration(labelText: 'Double'),
            ),
            ObserverFormField(
              observable: model.c,
              decoration: const InputDecoration(labelText: 'Double?'),
            ),
            ObserverFormField(
              observable: model.d,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            ObserverFormField(
              observable: model.e,
              decoration: const InputDecoration(labelText: 'DateTime'),
            ),
            ObserverFormField(
              observable: model.f,
              decoration: const InputDecoration(labelText: 'DateTime?'),
            ),
            ObserverFormField(
              observable: model.g,
              decoration: const InputDecoration(labelText: 'Mask'),
              formatter: MaskTextFormatter(mask: '0000-####-####'),
            ),
            ObserverFormField(
              observable: model.h,
              decoration: const InputDecoration(labelText: 'Full DateTime'),
              formatter: DateTimeFormatter<DateTime>(
                  type: DateTimeFormatterType.dateFullTime),
            ),
            ObserverFormField(
              observable: model.i,
              decoration: const InputDecoration(labelText: 'Required number'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          model.add();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
