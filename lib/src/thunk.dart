import 'dart:async';

import 'package:meta/meta.dart';

import 'store.dart';

/// Thunk is a function that accepts a store and returns a value.
typedef R Thunk<S, R>(Store<S> store);

/// VoidThunk is a special [Thunk] that returns nothing.
typedef void VoidThunk<S> (Store<S> store);

/// AsyncThunk is a special [Thunk] that returns a [Future].
typedef Future<R> AsyncThunk<S, R>(Store<S> store);

/// ThunkAction is an action type for [Thunk]. It restrict thunk to store with
/// specified state type [S], and store the result in field [result].
@immutable
class ThunkAction<S, R> extends RequestAction<R> {
  ThunkAction(this.thunk);

  final Thunk<S, R> thunk;

  void call(Store<dynamic> store) {
    if (store.state is! S) {
      return;
    }
    result = thunk(store as Store<S>);
  }
}

/// VoidThunkAction is an action type for [VoidThunk]. It restrict thunk to store
/// with specified state type [S].
///
/// Due to type system limitation, it actually extends from ThunkAction<S, Null>,
/// not ThunkAction<S, void>. The [result] value is always null.
///
/// See: https://github.com/dart-lang/sdk/issues/28943 for void as generic type
/// argument.
@immutable
class VoidThunkAction<S> extends ThunkAction<S, Null> {
  VoidThunkAction(VoidThunk<S> thunk) : super((Store<S> store) {
    thunk(store);
    return null;
  });
}

/// AsyncThunkAction is an action type for [AsyncThunk]. It restrict thunk to
/// store with specified state type [S]. The [result] is a [Future] with [R] as
/// its type argument.
@immutable
class AsyncThunkAction<S, R> extends ThunkAction<S, Future<R>> {
  AsyncThunkAction(AsyncThunk<S, R> thunk) : super(thunk);
}

/// A middleware that intercepts [Function] like actions, call that function
/// instead of passing control to next [Dispatcher].
///
/// See [ThunkAction], [VoidThunkAction] and [AsyncThunkAction] for predefined
/// thunk action types, clients are free to create custom thunk action types as
/// long as those types are [Function] like.
///
/// Client can restrict this middleware to more concrete state type by wrap it
/// in [ProxyTypedMiddleware].
void thunkMiddleware(Store<dynamic> store, Action action, Dispatcher next) {
  if (action is Function) {
    Function f = action as Function;
    f(store);
    return;
  }
  next(action);
}
