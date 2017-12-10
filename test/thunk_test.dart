import 'dart:async';

import 'package:test/test.dart';
import 'package:storey/storey.dart';

class ParentState {
}

class ChildState {
}

void main() {
  group('Thunk actions', () {
    List<String> logs = [];
    Store<ParentState> parentStore;
    Store<ChildState> childStore;

    setUp(() {
      logs.clear();

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
}
