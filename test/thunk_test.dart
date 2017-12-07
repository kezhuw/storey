import 'dart:async';

import 'package:test/test.dart';
import 'package:storey/storey.dart';

class FooState {
}

class BarState {
}

void main() {
  group('Thunk actions', () {
    Store<FooState> store = new Store<FooState>(
      initialState: new FooState(),
      reducer: null,
      middlewares: [thunkMiddleware],
    );

    Future<String> thunk(Store<FooState> store) async {
      return await new Future<String>.value('foo thunk result');
    }

    test('thunk action is called for matching state', () async {
      ThunkAction<FooState, String> action = new ThunkAction<FooState, String>(thunk);

      expect(action.result, isNull);

      store.dispatch(action);

      expect(action.result, isNotNull);

      expect(action.result, const isInstanceOf<Future<String>>());

      String s = await action.result;

      expect(s, 'foo thunk result');
    });

    test('thunk action is skipped for mismatched state', () async {
      Future<String> barThunk(Store<BarState> store) async {
        return await new Future<String>.value('bar thunk result');
      }

      ThunkAction<BarState, String> action = new ThunkAction<BarState, String>(barThunk);

      expect(action.result, isNull);

      store.dispatch(action);

      expect(action.result, isNull);
    });
  });
}