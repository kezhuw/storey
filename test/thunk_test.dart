import 'dart:async';

import 'package:test/test.dart';
import 'package:storey/storey.dart';

class FooState {
}

class BarState {
}

void main() {
  group('Thunk actions', () {
    List<String> logs = [];
    Store<FooState> fooStore;
    Store<BarState> barStore;

    setUp(() {
      logs.clear();

      fooStore = new Store<FooState>(
        name: 'foo',
        initialState: new FooState(),
        reducer: null,
        middlewares: [thunkMiddleware],
      );

      barStore = new Store<BarState>(
        name: 'foo',
        initialState: new BarState(),
        reducer: null,
        middlewares: [thunkMiddleware],
      );
    });

    void voidFooThunk(Store<FooState> store) {
      logs.add('void foo thunk');
    }

    String syncFooThunk(Store<FooState> store) {
      logs.add('sync foo thunk');
      return 'syncFooThunk';
    }

    Future<String> asyncFooThunk(Store<FooState> store) async {
      logs.add('async foo thunk');
      return await new Future<String>.value('foo thunk result');
    }

    test('thunk action is called for matching state', () {
      ThunkAction<FooState, String> action = new ThunkAction<FooState, String>(syncFooThunk);

      fooStore.dispatch(action);

      expect(logs, ['sync foo thunk']);
      expect(action.result, 'syncFooThunk');
    });

    test('thunk action is skipped for mismatched state', () {
      ThunkAction<FooState, String> action = new ThunkAction<FooState, String>(syncFooThunk);

      barStore.dispatch(action);

      expect(logs, []);
      expect(action.result, isNull);
    });

    test('void thunk action is called for matching state', () {
      VoidThunkAction<FooState> action = new VoidThunkAction<FooState>(voidFooThunk);

      fooStore.dispatch(action);

      expect(logs, ['void foo thunk']);
      expect(action.result, isNull);
    });

    test('void thunk action is skipped for mismatched state', () {
      ThunkAction<FooState, Null> action = new VoidThunkAction<FooState>(voidFooThunk);

      barStore.dispatch(action);

      expect(logs, []);
      expect(action.result, isNull);
    });

    test('async thunk action is called for matching state', () async {
      AsyncThunkAction<FooState, String> action = new AsyncThunkAction<FooState, String>(asyncFooThunk);

      expect(action.result, isNull);

      fooStore.dispatch(action);

      expect(action.result, isNotNull);
      expect(action.result, const isInstanceOf<Future<String>>());

      String s = await action.result;

      expect(s, 'foo thunk result');

      expect(logs, ['async foo thunk']);
    });

    test('async thunk action is skipped for mismatched state', () async {
      Future<String> barThunk(Store<BarState> store) async {
        return await new Future<String>.value('bar thunk result');
      }

      ThunkAction<BarState, Future<String>> action = new AsyncThunkAction<BarState, String>(barThunk);

      expect(action.result, isNull);

      fooStore.dispatch(action);

      expect(action.result, isNull);

      expect(logs, []);
    });
  });
}
