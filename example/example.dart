import 'package:flutter/material.dart';
import 'package:vmobject/vmobject.dart';

class HomeModel extends ViewModel {
  final Observable<int> count = Observable<int>(1);

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
