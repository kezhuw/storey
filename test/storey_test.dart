import 'dart:async';

import 'package:test/test.dart';
import 'package:storey/storey.dart';

class ParentState {
}

class ChildState {
}

class GrandsonState {
}

class ParentAction extends Action {
  ParentAction([this.state]);

  final ParentState state;
}

class ChildAction extends Action {
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

  ParentState parentReducer(ParentState parentState, ParentAction action) {
    logs.add('parent');
    return action.state ?? parentState;
  }

  ParentState mixedReducer(ParentState parentState, ChildAction action) {
    logs.add('mixed');
    return parentState;
  }

  TypedReducer<ParentState> typedParentReducer = new ProxyTypedReducer<ParentState, ParentAction>(parentReducer);

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

  Store<ParentState> parentStore;
  Store<ChildState> childStore;
  Store<GrandsonState> grandsonStore;

  group('Store.find', () {
    setUp(() {
      grandsonStore = new Store<GrandsonState>(
        name: 'grandson',
        initialState: null,
        reducer: null,
      );

      childStore = new Store<ChildState>(
        name: 'child',
        initialState: null,
        reducer: null,
        children: [grandsonStore],
      );

      parentStore = new Store<ParentState>(
        name: 'parent',
        initialState: null,
        reducer: null,
        children: [childStore],
      );
    });

    test('empty path to find this store', () {
      expect(identical(parentStore.find(path: const Iterable.empty()), parentStore), true);

      expect(identical(childStore.find(path: const Iterable.empty()), childStore), true);
    });

    test('use path to find descendant store', () {
      expect(identical(childStore, parentStore.find(path: ['child'])), true);

      expect(identical(grandsonStore, childStore.find(path: ['grandson'])), true);

      expect(identical(grandsonStore, parentStore.find(path: ['child', 'grandson'])), true);
    });
  });

  group('typed reducer', () {
    test('reducer is called for matching action', () {
      ParentState parentState = new ParentState();

      typedParentReducer(parentState, new ParentAction());

      expect(logs, ['parent']);
    });

    test('reducer is not called for mismatched action', () {
      ParentState parentState = new ParentState();

      typedParentReducer(parentState, new ChildAction());

      expect(logs, []);
    });


    TypedReducer<ParentState> mergedParentReducer = new MergedTypedReducer<ParentState>(<TypedReducer<ParentState>>[
      typedParentReducer,
      new ProxyTypedReducer<ParentState, ChildAction>(mixedReducer),
    ]);

    test('only matching reducer in merged reducers is called', () {
      ParentState parentState = new ParentState();

      mergedParentReducer(parentState, new ParentAction());

      expect(logs, ['parent']);
    });

    test('only matching reducer in merged reducers is called', () {
      ParentState parentState = new ParentState();

      mergedParentReducer(parentState, new ChildAction());

      expect(logs, ['mixed']);
    });

    test('only matching reducer in merged reducers is called', () {
      ParentState parentState = new ParentState();

      mergedParentReducer(parentState, new Action.empty());

      expect(logs, []);
    });

    test('throw error if multiple (proxy) typed reducer can accept dispatching action', () {
      Reducer<ParentState> reducer = new MergedTypedReducer<ParentState>(<TypedReducer<ParentState>>[
        typedParentReducer,
        typedParentReducer,
      ]);

      expect(() => reducer(new ParentState(), new ParentAction()), throwsStateError);
    });

    test('throw error if multiple (merged) typed reducer can accept dispatching action', () {
      Reducer<ParentState> reducer = new MergedTypedReducer<ParentState>(<TypedReducer<ParentState>>[
        mergedParentReducer,
        mergedParentReducer,
      ]);

      expect(() => reducer(new ParentState(), new ParentAction()), throwsStateError);
    });

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

  group('Store.teardown', () {
    setUp(() {
      childStore = new Store<ChildState>(
        name: 'child',
        initialState: null,
        reducer: null,
      );

      parentStore = new Store<ParentState>(
        name: 'parent',
        initialState: null,
        reducer: typedParentReducer,
        children: [childStore],
      );
    });

    test('Store.stream is closed if this store is teardown', () async {
      Completer<String> completer = new Completer<String>();
      parentStore.stream.listen(null, onDone: () => completer.complete('closed'));

      parentStore.teardown();

      expect(await completer.future, 'closed');
    });

    test('Store.stream is closed if ancestor store is teardown', () async {
      Completer<String> completer = new Completer<String>();
      childStore.stream.listen(null, onDone: () => completer.complete('closed'));

      parentStore.teardown();

      expect(await completer.future, 'closed');
    });

    test('Store.stream is not closed if descendant store is teardown', () async {
      Future<ParentState> future = parentStore.stream.first;

      childStore.teardown();

      ParentAction action = new ParentAction(new ParentState());
      parentStore.dispatch(action);

      expect(await future, action.state);
    });
  });

  group('Thunk actions', () {
    setUp(() {
      parentStore = new Store<ParentState>(
        name: 'parent',
        initialState: new ParentState(),
        reducer: (ParentState state, Action action) {
          logs.add('parent non thunk action');
          return state;
        },
        middlewares: [thunkMiddleware],
      );

      childStore = new Store<ChildState>(
        name: 'parent',
        initialState: new ChildState(),
        reducer: null,
        middlewares: [thunkMiddleware],
      );
    });

    void voidParentThunk(Store<ParentState> store) {
      logs.add('void parent thunk');
    }

    String syncParentThunk(Store<ParentState> store) {
      logs.add('sync parent thunk');
      return 'syncParentThunk';
    }

    Future<String> asyncParentThunk(Store<ParentState> store) async {
      logs.add('async parent thunk');
      return await new Future<String>.value('parent thunk result');
    }

    test('non thunk action reach reducer', () {
      parentStore.dispatch(new Action.empty());
      expect(logs, ['parent non thunk action']);
    });

    test('thunk action is called for matching state', () {
      ThunkAction<ParentState, String> action = new ThunkAction<ParentState, String>(syncParentThunk);

      parentStore.dispatch(action);

      expect(logs, ['sync parent thunk']);
      expect(action.result, 'syncParentThunk');
    });

    test('thunk action is skipped for mismatched state', () {
      ThunkAction<ParentState, String> action = new ThunkAction<ParentState, String>(syncParentThunk);

      childStore.dispatch(action);

      expect(logs, []);
      expect(action.result, isNull);
    });

    test('void thunk action is called for matching state', () {
      VoidThunkAction<ParentState> action = new VoidThunkAction<ParentState>(voidParentThunk);

      parentStore.dispatch(action);

      expect(logs, ['void parent thunk']);
      expect(action.result, isNull);
    });

    test('void thunk action is skipped for mismatched state', () {
      ThunkAction<ParentState, Null> action = new VoidThunkAction<ParentState>(voidParentThunk);

      childStore.dispatch(action);

      expect(logs, []);
      expect(action.result, isNull);
    });

    test('async thunk action is called for matching state', () async {
      AsyncThunkAction<ParentState, String> action = new AsyncThunkAction<ParentState, String>(asyncParentThunk);

      expect(action.result, isNull);

      parentStore.dispatch(action);

      expect(action.result, isNotNull);
      expect(action.result, const isInstanceOf<Future<String>>());

      String s = await action.result;

      expect(s, 'parent thunk result');

      expect(logs, ['async parent thunk']);
    });

    test('async thunk action is skipped for mismatched state', () async {
      Future<String> childThunk(Store<ChildState> store) async {
        return await new Future<String>.value('child thunk result');
      }

      ThunkAction<ChildState, Future<String>> action = new AsyncThunkAction<ChildState, String>(childThunk);

      expect(action.result, isNull);

      parentStore.dispatch(action);

      expect(action.result, isNull);

      expect(logs, []);
    });
  });

  group('Store.dispatch', () {
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
