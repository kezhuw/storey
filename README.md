# storey
[![Pub](https://img.shields.io/pub/v/storey.svg)](https://pub.dartlang.org/packages/storey)
[![Travis CI](https://travis-ci.org/kezhuw/storey.svg?branch=master)](https://travis-ci.org/kezhuw/storey)
[![CircleCI](https://circleci.com/gh/kezhuw/storey.svg?style=svg)](https://circleci.com/gh/kezhuw/storey)
[![codecov](https://codecov.io/gh/kezhuw/storey/branch/master/graph/badge.svg)](https://codecov.io/gh/kezhuw/storey)

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

## View Bindings

* [flutter_storey][] Flutter binding to storey.

## Clients

* [readhub_flutter][] A mobile app client for [Readhub][] using [flutter][].

## Recommendations

* [redux.dart][] and [flutter_redux][], a redux porting in dart and its flutter binding.
* [greencat][] and [flutter_greencat][], another redux porting and its flutter binding.

[readhub_flutter]: https://github.com/kezhuw/readhub_flutter
[Readhub]: https://readhub.me
[flutter]: https://flutter.io
[flutter_storey]: https://github.com/kezhuw/flutter_storey

[redux.dart]: https://github.com/johnpryan/redux.dart
[flutter_redux]: https://github.com/brianegan/flutter_redux

[greencat]: https://github.com/alexeieleusis/greencat
[flutter_greencat]: https://gitlab.com/brianegan/flutter_greencat
