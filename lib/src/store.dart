import 'dart:async';

import 'package:meta/meta.dart';

/// Base class for all actions.
@immutable
abstract class Action {
  const Action();

  /// Construct a empty action without implementing one yourself.
  factory Action.empty() {
    return const _EmptyAction();
  }
}

@immutable
class _EmptyAction extends Action {
  const _EmptyAction();
}

class _ActionResult<Response> {
  Response value;
}

/// Action that expect a result.
@immutable
abstract class RequestAction<R> extends Action {
  RequestAction();

  final _ActionResult<R> _result = new _ActionResult<R>();

  /// Get result.
  R get result => _result.value;

  /// Set result, usually by reducer.
  void set result(R result) {
    _result.value = result;
  }
}

/// A function that dispatch action to reducer in ambient store.
///
/// [Store.dispatch] should be considered as a Dispatcher with functionality to
/// locate descendant store.
///
/// Also serve as bridge among chain of middlewares, let middleware pass action,
/// possibly transformed, to next middleware in chain.
typedef void Dispatcher(Action action);

/// Middleware is a function that intercept actions before they reach reducer.
///
/// Middleware use [next] to pass action to next middleware in the middleware
/// chain, things middleware can do include but not limited to:
/// * Transform action.
/// * Dispatch another action from begin through [Store.dispatch].
/// * Conditional dispatch action based on state of store.
/// * Dispatch action at a later time.
/// * Customize dispatch behavior for particular action, such as [thunkMiddleware].
typedef void Middleware(Store<dynamic> store, Action action, Dispatcher next);

/// Signature for typed middleware which only got called for matching state and
/// action type.
///
/// Due to type system limitation, all functions with typed middleware signature
/// must be wrapped in class [ProxyTypedMiddleware] or similar to get desired
/// behavior.
typedef void TypedMiddleware<S, A extends Action>(Store<S> store, A action, Dispatcher next);

/// Proxy to filter out unmatched calls to [TypedMiddleware].
///
/// Pass control to [middleware] if types of state and action matching generic types of
/// this class, otherwise pass control to next middleware in chain.
//
// I wound like to export a static function instead of concrete class, but it won't work.
//
// Middleware createTypedMiddleware<S, A extends Action>(TypedMiddleware<S, A> typedMiddleware) {
//   return new ProxyTypedMiddleware<S, A>(typedMiddleware);
// }
//
// See: https://github.com/dart-lang/sdk/issues/31466 for more details.
class ProxyTypedMiddleware<S, A extends Action> {
  /// Create a typed middleware for store of type Store<[S]> and action of type [A].
  ///
  /// The [middleware] only got called if both types matching incoming store and
  /// action. If you specify [S] as `dynamic`, all stores are matching. Similar
  /// for action type [Action].
  ///
  /// CAUTION: Always specify type parameters [S] and [A] explicitly, as there
  /// is no type inference in Dart 1. So use:
  ///
  /// Middleware thunkMiddleware = new ProxyTypedMiddleware<dynamic, ThunkAction>(_handleThunkAction);
  ///
  /// instead of:
  ///
  /// Middleware thunkMiddleware = new ProxyTypedMiddleware(_handleThunkAction);
  ///
  /// In later case, [middleware] will be called for all pairs of stores and actions.
  ///
  /// See: https://github.com/dart-lang/sdk/issues/31466 for more details.
  ProxyTypedMiddleware(this.middleware);

  final TypedMiddleware<S, A> middleware;

  bool _handlesAction(Store<dynamic> store, Action action) {
    return store is Store<S> && action is A;
  }

  void call(Store<dynamic> store, Action action, Dispatcher next) {
    if (_handlesAction(store, action)) {
      return middleware(store, action, next);
    }
    return next(action);
  }
}

/// Reducer is a function to reduce state based on give action.
typedef S Reducer<S>(S state, Action action);

/// Function signature for [Reducer] that expect specified action type.
///
/// Wrap it with [ProxyTypedReducer] to filter out unmatched action types.
typedef S ActionReducer<S, A extends Action>(S state, A action);

/// Base functional class for [Reducer]s that filter out all unmatched actions.
abstract class TypedReducer<S> {
  bool _handlesAction(Action action);

  S call(S state, Action action);
}

/// Proxy to filter out unmatched calls to [ActionReducer].
class ProxyTypedReducer<S, A extends Action> implements TypedReducer<S> {
  /// Create a typed reducer for action of type [A]. For all other action types,
  /// it just reduce to the input state.
  ///
  /// CAUTION: In order to function correct, it is required to specify type
  /// parameters explicitly. Otherwise, [reducer] will be called with undesired
  /// actions. For example:
  ///
  /// class FooAction extends Action {
  /// };
  ///
  /// FooState _handleFooAction(FooState state, FooAction action) {
  ///   return state;
  /// }
  ///
  /// TypedReducer<FooState> reducer = new ProxyTypedReducer(_handleFooAction);
  ///
  /// The final `reducer` lost the type [A] represents for, which means [A] got
  /// `dynamic` actually, thus unmatched actions are not filtered out.
  ///
  /// Specify type parameters explicitly solves this issue:
  ///
  /// TypedReducer<FooState> reducer = new ProxyTypedReducer<FooState, FooAction>(_handleFooAction);
  ///
  /// See: https://github.com/dart-lang/sdk/issues/31466 for more details.
  const ProxyTypedReducer(this.reducer);

  final ActionReducer<S, A> reducer;

  @override
  bool _handlesAction(Action action) => action is A;

  S call(S state, Action action) {
    if (_handlesAction(action)) {
      return reducer(state, action);
    }
    return state;
  }
}

/// Merge sequence of typed reducers to one.
///
/// MergedTypedReducer act as a rendezvous for sequence of typed reducers on
/// state of same type. Only one reducer at most is allowed to accept the
/// dispatching action, otherwise an [StateError] is thrown in checked mode.
/// The result [Reducer] can be used as the sole reducer for store of the same
/// state type.
class MergedTypedReducer<S> implements TypedReducer<S> {
  /// Create a [TypedReducer] from sequence of typed reducers.
  const MergedTypedReducer(this.reducers);

  final Iterable<TypedReducer<S>> reducers;

  bool _debugAtMostOneMatchedReducer(Action action) {
    Iterable matchs = reducers.where((TypedReducer<S> reducer) => reducer._handlesAction(action));
    if (matchs.length > 1) {
      throw new StateError(
        'Only one reducer at most is allowed to accept dispatching action.' +
        'But ${matchs.length} reducers claim that they accept action of type ${action.runtimeType}'
      );
    }
    return true;
  }

  @override
  bool _handlesAction(Action action) {
    assert(_debugAtMostOneMatchedReducer(action));
    return reducers.any((TypedReducer<S> reducer) => reducer._handlesAction(action));
  }

  S call(S state, Action action) {
    assert(_debugAtMostOneMatchedReducer(action));
    return reducers.fold(state, (S model, TypedReducer<S> reducer) => reducer(model, action));
  }
}

/// Store is a storage place for state and its reducer with optional descendants.
///
/// Every store has a mandatory [name] which is used to identify itself to its
/// parent and hence should be unique among siblings.
class Store<S> {
  /// Create a store to hold a binding of state and reducer.
  ///
  /// Use [children] to build a hierarchical store structure. Parent store use
  /// child store's [name] to identify that child. Use [Store.find] to find its
  /// descendant.
  ///
  /// Use [middlewares] to intercepts action dispatched to this store and its
  /// descendants but not ancestors. Middlewares are chained from left to right,
  /// from parent to child in [Store.dispatch].
  ///
  /// It is illegal to build a hierarchical store after any [Store.dispatch] on
  /// its descendants.
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

  /// Name of this store, parent store can [find] this store using its [name].
  final String name;

  @protected
  S _state;

  /// Get current state.
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

  Store<dynamic> _find(Iterable<String> path) {
    Store<dynamic> current = this;
    path.forEach((String name) {
      current = current._children[name];
      assert(current != null);
    });
    return current;
  }

  /// Find descendant store using [path] which is a sequence of descendant
  /// store's name.
  ///
  /// Due to limit of type system, the result store may no be a subtype of
  /// Store<S>, use [debugTypeMatcher] to assert it in checked mode.
  Store<S> find<S>({
    @required Iterable<String> path,
    bool debugTypeMatcher(dynamic model),
  }) {
    Store<dynamic> store = _find(path);
    assert(debugTypeMatcher == null || debugTypeMatcher(store.state));
    return store as Store<S>;
  }

  /// Dispatch an [action] to store located at [path].
  ///
  /// Before [action] reach the reducer, a middleware chain which is constructed
  /// from all middlewares in stores from topmost one down to the target store
  /// is called. Middlewares from stores are chained from left to right, from
  /// parent to child. If the middleware chain proceed to next [Dispatcher] of
  /// last middleware, then the reducer is called, and a new state is reduced
  /// and sent as data event to [stream].
  void dispatch(Action action, {
    Iterable<String> path = const Iterable.empty(),
  }) {
    Store<dynamic> store = _find(path);
    store._dispatch(action);
  }

  final StreamController<S> _streamController;


  /// Stream of state [S].
  ///
  /// Every time the reducer is called, a new state is added to this stream as
  /// a data event.
  Stream<S> get stream => _streamController.stream;

  void _broadcast() {
    _streamController.add(_state);

    Store<dynamic> parent = _parent;
    while (parent != null) {
      parent._streamController.add(parent._state);
      parent = parent._parent;
    }
  }

  /// Teardown closes streams of this store and its descendants.
  void teardown() {
    _streamController.close();
    _children.values.forEach((Store<dynamic> child) {
      child.teardown();
    });
  }
}
