import 'package:test/test.dart';
import 'package:storey/storey.dart';

class FooState {
}

class FooAction extends Action {
}

class BarAction extends Action {
}

class DummyAction extends Action {
}

void main() {
  List<String> logs = [];

  setUp(() {
    logs.clear();
  });

  group('typed reducer', () {
    FooState fooReducer(FooState fooState, FooAction action) {
      logs.add('foo');
      return fooState;
    }

    FooState foobarReducer(FooState fooState, BarAction action) {
      logs.add('foobar');
      return fooState;
    }

    TypedReducer<FooState> typedFooReducer = new ProxyTypedReducer<FooState, FooAction>(fooReducer);

    test('reducer is called for matching action', () {
      FooState fooState = new FooState();

      typedFooReducer(fooState, new FooAction());

      expect(logs, ['foo']);
    });

    test('reducer is not called for mismatched action', () {
      FooState fooState = new FooState();

      typedFooReducer(fooState, new BarAction());

      expect(logs, []);
    });


    Reducer<FooState> mergedFooReducer = new MergedTypedReducer<FooState>(<TypedReducer<FooState>>[
      typedFooReducer,
      new ProxyTypedReducer<FooState, BarAction>(foobarReducer),
    ]);

    test('only matching reducer in merged reducers is called', () {
      FooState fooState = new FooState();

      mergedFooReducer(fooState, new FooAction());

      expect(logs, ['foo']);
    });

    test('only matching reducer in merged reducers is called', () {
      FooState fooState = new FooState();

      mergedFooReducer(fooState, new BarAction());

      expect(logs, ['foobar']);
    });

    test('only matching reducer in merged reducers is called', () {
      FooState fooState = new FooState();

      mergedFooReducer(fooState, new DummyAction());

      expect(logs, []);
    });

  });
}
