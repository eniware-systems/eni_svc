## 2.0.4

- Updated to Flutter 3.32.5

## 2.0.3

- Added `ServiceScope` names for better debugging.
- Fixed `ServiceScope` not detecting direct parent scope.

## 2.0.2

- Fixed a bug that prevented `ServiceScope` from accessing parent services when `getService(s)` methods were used through
`ServiceProvider` facade in bootstrap callbacks.

## 2.0.0

Initial release
