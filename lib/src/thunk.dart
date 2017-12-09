import 'dart:async';

import 'package:meta/meta.dart';

import 'store.dart';

typedef Future<R> Thunk<S, R>(Store<S> store);

@immutable
class ThunkAction<S, R> extends RequestAction<Future<R>> {
  ThunkAction(this.thunk);

  final Thunk<S, R> thunk;

  void call(Store<dynamic> store) {
    if (store.state is! S) {
      return;
    }
    result = thunk(store as Store<S>);
  }
}

void _handleThunkAction(Store<dynamic> store, ThunkAction<dynamic, dynamic> action, Dispatcher next) {
  action(store);
}

Middleware thunkMiddleware = new ProxyTypedMiddleware<dynamic, ThunkAction>(_handleThunkAction);
