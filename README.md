# storey
[![Travis Build](https://img.shields.io/travis/kezhuw/storey/master.svg)]()
[![CircleCI Build](https://img.shields.io/circleci/project/github/kezhuw/storey/master.svg)]()
[![Codecov Test Coverage](https://img.shields.io/codecov/c/github/kezhuw/storey/master.svg)]()

Redux like store but hierarchical.

## Usage

A simple usage example:

```dart
import 'dart:async';

import 'package:storey/storey.dart';

class StringState {
  StringState(this.str);
  String str;
}

class OverwriteAction extends Action {
  const OverwriteAction(this.str);

  final String str;
}

StringState _handleOverwriteAction(StringState state, OverwriteAction action) {
  return state..str = action.str;
}

class ExchangeAction extends RequestAction<String> {
  ExchangeAction(this.str);
  final String str;
}

StringState _handleExchangeAction(StringState state, ExchangeAction action) {
  action.result = state.str;
  return state..str = action.str;
}

Reducer<StringState> _reducer = new MergedTypedReducer<StringState>(
    [
      new ProxyTypedReducer<StringState, OverwriteAction>(_handleOverwriteAction),
      new ProxyTypedReducer<StringState, ExchangeAction>(_handleExchangeAction),
    ]
);

Store<StringState> createStore(String initialStr) {
  return new Store<StringState>(
    initialState: new StringState(initialStr),
    reducer: _reducer,
    middlewares: <Middleware>[thunkMiddleware],
  );
}

Future<Null> main() async {
  Store<StringState> store = createStore('foo');
  assert(store.state.str == 'foo');

  store.dispatch(const OverwriteAction('bar'));
  assert(store.state.str == 'bar');

  ExchangeAction request = new ExchangeAction('foobar');
  store.dispatch(request);
  assert(store.state.str == 'foobar');
  assert(request.result == 'bar');
}
```

## License
Released under The MIT License (MIT). See [LICENSE](LICENSE) for the full license text.

## Clients

* [readhub_flutter][] A mobile app client for [Readhub][] using [flutter][].

[readhub_flutter]: https://github.com/kezhuw/readhub_flutter
[Readhub]: https://readhub.me
[flutter]: https://flutter.io
