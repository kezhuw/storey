import 'package:test/test.dart';
import 'package:storey/storey.dart';

class ParentState {
}

class ChildState {
}

class GrandsonState {
}

void main() {
  group('Store.find', () {
    Store<ParentState> parentStore;
    Store<ChildState> childStore;
    Store<GrandsonState> grandsonStore;

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
}
