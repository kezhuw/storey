import 'package:test/test.dart';
import 'package:storey/storey.dart';

class ParentState {
}

class ParentAction extends Action {
}

class ChildAction extends Action {
}

class DummyAction extends Action {
}

void main() {
  List<String> logs = [];

  setUp(() {
    logs.clear();
  });

  group('typed reducer', () {
    ParentState parentReducer(ParentState parentState, ParentAction action) {
      logs.add('parent');
      return parentState;
    }

    ParentState mixedReducer(ParentState parentState, ChildAction action) {
      logs.add('mixed');
      return parentState;
    }

    TypedReducer<ParentState> typedParentReducer = new ProxyTypedReducer<ParentState, ParentAction>(parentReducer);

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

      mergedParentReducer(parentState, new DummyAction());

      expect(logs, []);
    });

    test('throw error if multiple (proxy) typed reducer can accept dispatching action', () {
      Reducer<ParentState> parentReducer = new MergedTypedReducer<ParentState>(<TypedReducer<ParentState>>[
        typedParentReducer,
        typedParentReducer,
      ]);

      expect(() => parentReducer(new ParentState(), new ParentAction()), throwsStateError);
    });

    test('throw error if multiple (merged) typed reducer can accept dispatching action', () {
      Reducer<ParentState> parentReducer = new MergedTypedReducer<ParentState>(<TypedReducer<ParentState>>[
        mergedParentReducer,
        mergedParentReducer,
      ]);

      expect(() => parentReducer(new ParentState(), new ParentAction()), throwsStateError);
    });

  });
}
