import 'dart:async';

import 'package:test/test.dart';
import 'package:storey/storey.dart';

class ParentState {
}

class ParentAction extends Action {
  ParentAction(this.state);

  final ParentState state;
}

class ChildState {
}


void main() {
  group('Store.teardown', () {
    Store<ParentState> parentStore;
    Store<ChildState> childStore;

    setUp(() {
      childStore = new Store<ChildState>(
        name: 'child',
        initialState: null,
        reducer: null,
      );

      parentStore = new Store<ParentState>(
        name: 'parent',
        initialState: null,
        reducer: (ParentState state, Action action) => (action as ParentAction).state,
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
}
