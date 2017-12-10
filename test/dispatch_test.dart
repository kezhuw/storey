import 'package:test/test.dart';
import 'package:storey/storey.dart';

class ParentState {
}

class ChildState {
}

class GrandsonState {
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
    Store<ParentState> parentStore;
    Store<ChildState> childStore;
    Store<GrandsonState> grandsonStore;

    setUp(() {
      grandsonStore = new Store<GrandsonState>(
        name: 'grandson',
        initialState: null,
        reducer: (GrandsonState state, Action action) {
          if (action is ValueAction) {
            logs.add('grandson');
            logs.add(action.value);
          }
          return state;
        },
      );

      childStore = new Store<ChildState>(
        name: 'child',
        initialState: null,
        reducer: (ChildState state, Action action) {
          if (action is ValueAction) {
            logs.add('child');
            logs.add(action.value);
          }
          return state;
        },
        children: [grandsonStore],
        middlewares: [skipMiddleware, loggingMiddleware],
      );

      parentStore = new Store<ParentState>(
        name: 'parent',
        initialState: null,
        reducer: (ParentState state, Action action) {
          if (action is ValueAction) {
            logs.add('parent');
            logs.add(action.value);
          }
          return state;
        },
        children: [childStore],
        middlewares: [transformSkipActionMiddleware],
      );
    });

    test('dispatch reach reducer', () {
      grandsonStore.dispatch(const ValueAction(value: 'hello', logging: false));
      expect(logs, ['grandson', 'hello']);
    });

    test('middlewares are called before reducer', () {
      childStore.dispatch(const ValueAction(value: 'hello'));
      expect(logs, ['logging', 'hello', 'child', 'hello']);
    });

    test('middlewares from ancestors are called', () {
      grandsonStore.dispatch(const ValueAction(value: 'hello'));
      expect(logs, ['logging', 'hello', 'grandson', 'hello']);
    });

    test('middlewares from descendants are not called', () {
      parentStore.dispatch(const ValueAction(value: 'hello'));
      expect(logs, ['parent', 'hello']);
    });

    test('middlewares are chained from left to right', () {
      childStore.dispatch(const SkipAction());
      expect(logs, []);

      childStore.dispatch(const ValueAction(value: 'hello'));
      expect(logs, ['logging', 'hello', 'child', 'hello']);
    });

    test('middlewares are chained from parent to child', () {
      childStore.dispatch(new SkipAction());
      expect(logs, []);

      childStore.dispatch(const TransformSkipAction());
      expect(logs, ['logging', 'TransformSkipAction', 'child', 'TransformSkipAction']);
    });
  });
}
