import 'package:test/test.dart';
import 'package:storey/storey.dart';

class FooState {
}

class BarState {
}

class FoobarState {
}

class ValueAction extends Action {
  const ValueAction({this.value = 'ValueAction', this.logging = true});

  final dynamic value;
  final bool logging;
}

class SkipAction extends ValueAction {
  const SkipAction({String value = 'SkipAction'}) : super(value: value);
}

class TransformSkipAction extends SkipAction {
  const TransformSkipAction({String value = 'TransformSkipAction'}) : super(value: value);
}

void main() {
  List<String> logs = [];

  setUp(() {
    logs.clear();
  });

  void loggingMiddleware(Store<dynamic> store, Action action, Dispatcher next) {
    if (action is ValueAction && action.logging) {
      logs.add('logging');
      logs.add(action.value);
    }
    next(action);
  }

  void skipMiddleware(Store<dynamic> store, Action action, Dispatcher next) {
    assert(action != null);
    if (action is SkipAction) {
      return;
    }
    next(action);
  }

  void transformSkipActionMiddleware(Store<dynamic> store, Action action, Dispatcher next) {
    if (action is TransformSkipAction) {
      ValueAction valueAction = action;
      action = new ValueAction(value: valueAction.value);
    }
    next(action);
  }

  group('Store.dispatch', () {
    Store<FooState> fooStore;
    Store<BarState> barStore;
    Store<FoobarState> foobarStore;

    setUp(() {
      foobarStore = new Store<FoobarState>(
        name: 'foobar',
        initialState: null,
        reducer: (FoobarState state, Action action) {
          if (action is ValueAction) {
            logs.add('foobar');
            logs.add(action.value);
          }
          return state;
        },
      );

      barStore = new Store<BarState>(
        name: 'bar',
        initialState: null,
        reducer: (BarState state, Action action) {
          if (action is ValueAction) {
            logs.add('bar');
            logs.add(action.value);
          }
          return state;
        },
        children: [foobarStore],
        middlewares: [skipMiddleware, loggingMiddleware],
      );

      fooStore = new Store<FooState>(
        name: 'foo',
        initialState: null,
        reducer: (FooState state, Action action) {
          if (action is ValueAction) {
            logs.add('foo');
            logs.add(action.value);
          }
          return state;
        },
        children: [barStore],
        middlewares: [transformSkipActionMiddleware],
      );
    });

    test('dispatch reach reducer', () {
      foobarStore.dispatch(const ValueAction(value: 'hello', logging: false));
      expect(logs, ['foobar', 'hello']);
    });

    test('middlewares are called before reducer', () {
      barStore.dispatch(const ValueAction(value: 'hello'));
      expect(logs, ['logging', 'hello', 'bar', 'hello']);
    });

    test('middlewares from ancestors are called', () {
      foobarStore.dispatch(const ValueAction(value: 'hello'));
      expect(logs, ['logging', 'hello', 'foobar', 'hello']);
    });

    test('middlewares from descendants are not called', () {
      fooStore.dispatch(const ValueAction(value: 'hello'));
      expect(logs, ['foo', 'hello']);
    });

    test('middlewares are chained from left to right', () {
      barStore.dispatch(const SkipAction());
      expect(logs, []);

      barStore.dispatch(const ValueAction(value: 'hello'));
      expect(logs, ['logging', 'hello', 'bar', 'hello']);
    });

    test('middlewares are chained from parent to child', () {
      barStore.dispatch(new SkipAction());
      expect(logs, []);

      barStore.dispatch(const TransformSkipAction());
      expect(logs, ['logging', 'TransformSkipAction', 'bar', 'TransformSkipAction']);
    });
  });
}
