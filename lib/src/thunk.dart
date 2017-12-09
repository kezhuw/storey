import 'dart:async';

import 'package:meta/meta.dart';

import 'store.dart';

typedef Future<Result> Thunk<State, Result>(Store<State> store);

@immutable
class ThunkAction<State, Result> extends RequestAction<Future<Result>> {
  ThunkAction(this.thunk);

  final Thunk<State, Result> thunk;

  void call(Store<dynamic> store) {
    if (store.state is! State) {
      return;
    }
    result = thunk(store as Store<State>);
  }
}

void _handleThunkAction(Store<dynamic> store, ThunkAction<dynamic, dynamic> action, Dispatcher next) {
  action(store);
}

Middleware thunkMiddleware = new ProxyTypedMiddleware<dynamic, ThunkAction>(_handleThunkAction);
