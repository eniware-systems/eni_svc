# eni_svc - Eniware Service Management

The `eni_svc` package provides a lightweight solution for managing globally accessible services within a Flutter application.

## Features

- **No Strict Coupling**: Services can be accessed through the `BuildContext` from anywhere in the widget tree, promoting a decoupled architecture.
- **Flexible Service Definition**: Services can range from Plain Old Dart Objects (PODOs) to simple data types, offering versatility in application design.
- **Service Lifecycle Handling**: The `Service` mixin facilitates additional lifecycle management for services, enhancing control over initialization and disposal.
- **Packaged services**: Utilize `addPackage()` and `makePackage()` to create and incorporate custom packages, facilitating the integration of features such as localization or app configuration seamlessly into your application.
- **Configurations**: Register configurations at the `ServiceScope`, allowing the customization of certain services or service types, either on a per-service basis or globally.
- **Transient Services**: Register transient services that are created anew for each invocation of `getService()`, offering flexibility in service instantiation without enforcing singleton behavior.

## Getting Started

To begin using `eni_svc` in your project, simply install the package via:

```bash
dart pub add eni_svc
```

## Usage

### Services

#### Creating a `ServiceScope`

While multiple `ServiceScope` instances can be used within an app (e.g., for scoped access), it's recommended to register a global instance as follows:

```dart
import 'package:eni_svc/eni_svc.dart';

void main() {
  runApp(
    ServiceScope(child: const MyApp())
  );
}
```

#### Registering Services

To register services with the `ServiceScope`, utilize the `provide` method. For example:

```dart
import 'package:eni_svc/eni_svc.dart';

class MyAwesomeService {}

void main() {
  runApp(
    ServiceScope(child: const MyApp())
      ..provide<MyAwesomeService>(
        name: "MyAwesomeService",
        factory: (BuildContext context) => MyAwesomeService(),
      ),
  );
}
```

#### Accessing Services

Once registered, services can be accessed from any widget within the build tree using the `getService` method:

```dart
void build(BuildContext context) {
  final myAwesomeService = context.getService<MyAwesomeService>();
  final myAwesomeService1 = context.getService<MyAwesomeService>(name: "svc1");
  final allServices = context.getServices<MyAwesomeService>();
}
```

## Service Packages

[TODO]

## Service Configuration

[TODO]

## License

This package is proprietary software owned by [Eniware Systems GmbH](https://eniware-systems.de). All rights reserved.

Unauthorized reproduction or distribution of this package, or any portion of it, may result in severe civil and criminal penalties, and will be prosecuted to the maximum extent possible under the law.

For licensing inquiries or other questions, please contact [info@eniware-systems.de](mailto:info@eniware-systems.de)
```
