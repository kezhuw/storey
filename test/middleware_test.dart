import 'package:test/test.dart';
import 'package:storey/storey.dart';

class ParentState {
}

class ChildState {
}

class ParentAction extends Action {
}

class ChildAction extends Action {
}

void main() {
  List<String> logs = [];

  setUp(() {
    logs.clear();
  });

  group('typed middleware', () {
    Reducer nopReducer = (dynamic state, Action action) => state;

    void parentMiddleware(Store<ParentState> store, ParentAction action, Dispatcher next) {
      logs.add('parent');
      next(action);
    }

    void nextDispatcher(Action store) {
      logs.add('next');
    }

    Middleware typedMiddleware = new ProxyTypedMiddleware<ParentState, ParentAction>(parentMiddleware);

    test('middleware is called for matching store and action', () {
      Store<ParentState> parentStore = new Store<ParentState>(name: 'parent', reducer: nopReducer, initialState: new ParentState());

      typedMiddleware(parentStore, new ParentAction(), nextDispatcher);

      expect(logs, <String>['parent', 'next']);
    });

    test('middleware is called for matching store, with null state, and action', () {
      Store<ParentState> parentStore = new Store<ParentState>(name: 'parent', reducer: nopReducer, initialState: null);

      typedMiddleware(parentStore, new ParentAction(), nextDispatcher);

      expect(logs, <String>['parent', 'next']);
    });

    test('middleware is skipped for mismatched state', () {
      Store<ChildState> childStore = new Store<ChildState>(name: 'child', reducer: nopReducer, initialState: new ChildState());

      typedMiddleware(childStore, new ParentAction(), nextDispatcher);

      expect(logs, <String>['next']);
    });

    test('middleware is skipped for mismatched action', () {
      Store<ParentState> parentStore = new Store<ParentState>(name: 'parent', reducer: nopReducer, initialState: new ParentState());

      typedMiddleware(parentStore, new ChildAction(), nextDispatcher);

      expect(logs, <String>['next']);
    });
  });
}
