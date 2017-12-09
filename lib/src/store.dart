import 'dart:async';

import 'package:meta/meta.dart';

@immutable
abstract class Action {
  const Action();
}

class _ActionResult<Response> {
  Response value;
}

@immutable
abstract class RequestAction<R> extends Action {
  RequestAction();

  final _ActionResult<R> _result = new _ActionResult<R>();

  R get result => _result.value;
  void set result(R newValue) {
    _result.value = newValue;
  }
}

typedef void Dispatcher(Action action);
typedef void Middleware(Store<dynamic> store, Action action, Dispatcher next);

typedef void TypedMiddleware<S, A extends Action>(Store<S> store, A action, Dispatcher next);

// I wound like to export a static function instead of concrete class, but it won't work.
//
// Middleware createTypedMiddleware<S, A extends Action>(TypedMiddleware<S, A> typedMiddleware) {
//   return new ProxyTypedMiddleware<S, A>(typedMiddleware);
// }
//
// See: https://github.com/dart-lang/sdk/issues/31466 for more details.
class ProxyTypedMiddleware<S, A extends Action> {
  ProxyTypedMiddleware(this.middleware);

  final TypedMiddleware<S, A> middleware;

  bool _handlesAction(dynamic state, Action action) {
    return state is S && action is A;
  }

  void call(Store<dynamic> store, Action action, Dispatcher next) {
    if (_handlesAction(store.state, action)) {
      return middleware(store, action, next);
    }
    return next(action);
  }
}

typedef S Reducer<S>(S state, Action action);

typedef S ActionReducer<S, A extends Action>(S state, A action);

abstract class TypedReducer<S> {
  bool _handlesAction(Action action);

  S call(S state, Action action);
}

class ProxyTypedReducer<S, A extends Action> implements TypedReducer<S> {
  const ProxyTypedReducer(this.reducer);

  final ActionReducer<S, A> reducer;

  @protected
  bool _handlesAction(Action action) => action is A;

  S call(S state, Action action) {
    if (_handlesAction(action)) {
      return reducer(state, action);
    }
    return state;
  }
}

class MergedTypedReducer<S> implements TypedReducer<S> {
  const MergedTypedReducer(this.reducers);

  final Iterable<TypedReducer<S>> reducers;

  bool _handlesAction(Action action) {
    assert(reducers.where((TypedReducer<S> reducer) => reducer._handlesAction(action)).length <= 1);
    return reducers.any((TypedReducer<S> reducer) => reducer._handlesAction(action));
  }

  S call(S state, Action action) {
    assert(reducers.where((TypedReducer<S> reducer) => reducer._handlesAction(action)).length <= 1);
    return reducers.fold(state, (S model, TypedReducer<S> reducer) => reducer(model, action));
  }
}

class Store<S> {
  Store({
    @required this.name,
    @required S initialState,
    @required Reducer<S> reducer,
    List<Store<dynamic>> children = const [],
    List<Middleware> middlewares = const [],
  })
      : _state = initialState,
        _reducer = reducer,
        _children = new Map.fromIterable(children, key: (Store<dynamic> store) => store.name),
        _middlewares = middlewares,
        _streamController = new StreamController<S>.broadcast() {
    _children.values.forEach((Store<dynamic> child) {
      child._parent = this;
    });
  }

  final String name;

  @protected
  S _state;

  S get state => _state;

  final Reducer<S> _reducer;
  final Map<dynamic, Store<dynamic>> _children;
  final List<Middleware> _middlewares;

  Store<dynamic> _parent;

  Dispatcher _dispatcher;

  Dispatcher _createDispatcher(Store<dynamic> store, List<Middleware> middlewares, Dispatcher nextDispatcher) {
    for (Middleware nextMiddleware in middlewares.reversed) {
      final Dispatcher next = nextDispatcher;
      nextDispatcher = (Action action) {
        nextMiddleware(store, action, next);
      };
    }
    return nextDispatcher;
  }

  void _reduce(Action action) {
    _state = _reducer(_state, action);
    _broadcast();
  }

  void _dispatch(Action action) {
    if (_dispatcher == null) {
      List<List<Middleware>> middlewares = <List<Middleware>>[_middlewares];
      Store<dynamic> parent = _parent;
      while (parent != null) {
        middlewares.add(parent._middlewares);
        parent = parent._parent;
      }
      _dispatcher = _createDispatcher(this, middlewares.reversed.expand((x) => x).toList(), _reduce);
    }
    _dispatcher(action);
  }

  /// Due to limit of type system, the result store may no be a subtype of
  /// Store<S>.
  Store<S> find<S>({
    Iterable<dynamic> path,
    bool debugTypeMatcher(dynamic model),
  }) {
    Store<dynamic> current = this;
    path.forEach((dynamic key) {
      current = current._children[key];
      assert(current != null);
    });
    assert(debugTypeMatcher == null || debugTypeMatcher(current.state));
    return current as Store<S>;
  }

  void dispatch(Action action, {
    Iterable<dynamic> path = const Iterable.empty(),
  }) {
    Store<dynamic> store = this;
    path.forEach((dynamic key) {
      store = store._children[key];
      assert(store != null);
    });
    store._dispatch(action);
  }

  final StreamController<S> _streamController;
  Stream<S> get stream => _streamController.stream;

  void _broadcast() {
    _streamController.add(_state);

    Store<dynamic> parent = _parent;
    while (parent != null) {
      parent._streamController.add(parent._state);
      parent = parent._parent;
    }
  }

  void teardown() {
    _streamController.close();
    _children.values.forEach((Store<dynamic> child) {
      child.teardown();
    });
  }
}
