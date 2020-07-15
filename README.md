Base classes used to build Flutter project follow pattern MVVM

![structure](/assets/structure.png)

## Classes

### ObserverWidget

A widget auto rebuild every time the observable changed

```dart
//define observable in viewmodel
final count = Observable(0);
//used in build context
ObserverWidget(
    observable: count,
    builder: (context, int value) => Text('$value')
)

```

Dependency on library [obsobject](https://github.com/hientrung/dart-observable)

### ViewModel

Base class for viewmodel layer

```dart
class HomeModel extends ViewModel {
    //somethings...
}
```

In somewhere, you can use `ViewModel.of` to get created objects already

```dart
final home = ViewModel.of<HomeModel>();
```

Lifecycle events call below functions, you can overwrite these functions to handle something (subscribe, create computed objects, fetch data,...)

- `activate`: called before render widget
- `dispose`: called after widget removed

### ViewWidget

Base class for view layer. There are 2 methods should override `initModel` and `builder`

By default, the viewmodel for view is initialized only once and cached. You can override property `cacheModel` to `false` to ignore use cache viewmodel (eg: login view).

```dart
class HomeView extends ViewWidget<HomeModel> {
    @override
    HomeModel initModel() => HomeModel();

    @override
    Widget builder(BuildContext context, HomeModel model) {
        //return widget
    }
}
```
