import 'dart:async';

import 'package:test/test.dart';
import 'package:storey/storey.dart';

class FooState {
}

class FooAction extends Action {
  FooAction(this.state);

  final FooState state;
}

class BarState {
}


void main() {
  group('Store.teardown', () {
    Store<FooState> fooStore;
    Store<BarState> barStore;

    setUp(() {
      barStore = new Store<BarState>(
        name: 'bar',
        initialState: null,
        reducer: null,
      );

      fooStore = new Store<FooState>(
        name: 'foo',
        initialState: null,
        reducer: (FooState state, Action action) => (action as FooAction).state,
        children: [barStore],
      );
    });

    test('Store.stream is closed if this store is teardown', () async {
      Completer<String> completer = new Completer<String>();
      fooStore.stream.listen(null, onDone: () => completer.complete('closed'));

      fooStore.teardown();

      expect(await completer.future, 'closed');
    });

    test('Store.stream is closed if ancestor store is teardown', () async {
      Completer<String> completer = new Completer<String>();
      barStore.stream.listen(null, onDone: () => completer.complete('closed'));

      fooStore.teardown();

      expect(await completer.future, 'closed');
    });

    test('Store.stream is not closed if descendant store is teardown', () async {
      Future<FooState> future = fooStore.stream.first;

      barStore.teardown();

      FooAction action = new FooAction(new FooState());
      fooStore.dispatch(action);

      expect(await future, action.state);
    });
  });
}
