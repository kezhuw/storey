import 'package:test/test.dart';
import 'package:storey/storey.dart';

class FooState {
}

class BarState {
}

class FooAction extends Action {
}

class BarAction extends Action {
}

void main() {
  List<String> logs = [];

  setUp(() {
    logs.clear();
  });

  group('typed middleware', () {
    Reducer nopReducer = (dynamic state, Action action) => state;

    void fooMiddleware(Store<FooState> store, FooAction action, Dispatcher next) {
      logs.add('foo');
      next(action);
    }

    void nextDispatcher(Action store) {
      logs.add('next');
    }

    Middleware typedMiddleware = new TypedMiddlewareBinding<FooState, FooAction>(fooMiddleware);

    test('middleware is called for matching state and action', () {
      Store<FooState> fooStore = new Store<FooState>(reducer: nopReducer, initialState: new FooState());

      typedMiddleware(fooStore, new FooAction(), nextDispatcher);

      expect(logs, <String>['foo', 'next']);
    });

    test('middleware is skipped for mismatched state', () {
      Store<BarState> barStore = new Store<BarState>(reducer: nopReducer, initialState: new BarState());

      typedMiddleware(barStore, new FooAction(), nextDispatcher);

      expect(logs, <String>['next']);
    });

    test('middleware is skipped for mismatched action', () {
      Store<FooState> fooStore = new Store<FooState>(reducer: nopReducer, initialState: new FooState());

      typedMiddleware(fooStore, new BarAction(), nextDispatcher);

      expect(logs, <String>['next']);
    });
  });
}
