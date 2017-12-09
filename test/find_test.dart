import 'package:test/test.dart';
import 'package:storey/storey.dart';

class FooState {
}

class BarState {
}

class FoobarState {
}

void main() {
  group('Store.find', () {
    Store<FooState> fooStore;
    Store<BarState> barStore;
    Store<FoobarState> foobarStore;

    setUp(() {
      foobarStore = new Store<FoobarState>(
        name: 'foobar',
        initialState: null,
        reducer: null,
      );

      barStore = new Store<BarState>(
        name: 'bar',
        initialState: null,
        reducer: null,
        children: [foobarStore],
      );

      fooStore = new Store<FooState>(
        name: 'foo',
        initialState: null,
        reducer: null,
        children: [barStore],
      );
    });

    test('empty path to find this store', () {
      expect(identical(fooStore.find(path: const Iterable.empty()), fooStore), true);

      expect(identical(barStore.find(path: const Iterable.empty()), barStore), true);
    });

    test('use path to find descendant store', () {
      expect(identical(barStore, fooStore.find(path: ['bar'])), true);

      expect(identical(foobarStore, barStore.find(path: ['foobar'])), true);

      expect(identical(foobarStore, fooStore.find(path: ['bar', 'foobar'])), true);
    });
  });
}
