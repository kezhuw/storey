# Changelog

## 0.2.2
- Fix test coverage

## 0.2.1
- Add factory constructor Action.empty() to construct empty action
- Throw StateError if multiple reducers accept the dispatching action

## 0.2.0
- Refactor thunk as a function that accepts a store and returns a value

## 0.1.0
- Align store a name
- Rename TypedMiddlewareBinding to ProxyTypedMiddleware
- Fix skipped typed middleware due to null state
- Add tests and CI support

## 0.0.1

- Initial version
