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

class SimpleService {
  void doIt() => print("doIt");
}

class MyAwesomeService with Service {
  final int index;

  MyAwesomeService(this.index);

  void doAwesomeThing() => print("MyAwesomeService $index");
}

void main() {
  runApp(
    ServiceScope(child: const MyApp())
      ..provide(SimpleService())
      ..provide<MyAwesomeService>(
            (context) => MyAwesomeService(1),
        name: "svc1",
      )
      ..provide(MyAwesomeService(2), name: "svc2")
  );
}
```

#### Accessing Services

Once registered, services can be accessed from any widget within the build tree using the `getService` method:

```dart
void build(BuildContext context) {
  context.getService<SimpleService>().doIt();
  context.getService<MyAwesomeService>(name: "svc1").doAwesomeThing();
  context.getService<MyAwesomeService>(name: "svc2").doAwesomeThing();
  final allAwesomeServices = context.getServices<MyAwesomeService>();
}
```

## Service Packages

An application can contain multiple packages. Each `Package` can have a different setup.
You can create standard packages with method `makePackage`. To create your own packages you may extend class `Package`.
A `PackageFeature` can add functionality to each registered package:

```dart
class Worker with Service {
  final String packageName;
  final int id;

  Worker(this.packageName, this.id);

  get name => "$Worker $packageName $id";
}

class WorkerHandler extends PackageFeature {
  @override
  void onApply(Package package) {
    final workerCount = package.getConfigOrNull<int>("workerCount") ?? 1;
    for (int i = 0; i < workerCount; ++i) {
      final packageName = package.name;
      package.services.register(
        ServiceDescriptor.from(
          name: "Worker_${packageName}_$i",
          create: (context) => Worker(packageName, i),
        ),
      );
    }
  }

  @override
  String get name => "WorkerHandler";
}

void main() {
  runApp(
    ServiceScope(child: const MyApp())
      ..addFeature(WorkerHandler())
      ..addPackage(makePackage("PackageA")..withConfig("workerCount", 3))
      ..addPackage(makePackage("PackageB")..withConfig("workerCount", 5)),
  );
}
```
For each registered package the package feature `WorkerHandler` creates the requested amount of workers in method `onApply`
and adds them to the current scope. Method `onApply` is called for each package during the bootstrap phase of the scope.
Later the workers are available as services:

```dart
@override
Widget build(BuildContext context) {
  final workers = context.getServices<Worker>();
  for (final worker in workers) {
    print(worker.name);
  }
}
```

## Service Configuration

You can add a configuration as parameter to method `addConfiguration`. All services with mixin `Service`
can access this configuration via method `getConfigOrNull`:

```dart
import 'package:eni_svc/eni_svc.dart';

class CustomerService with Service {
  String? getTheUrl() {
    String? url = getConfigOrNull<String>('url');
    return url;
  }
}

void main() {
  runApp(
    ServiceScope(child: const MyApp())
      ..addConfiguration({"url": "http://home.com"})
      ..provide(CustomerService())
  );
}
```
You could also provide configurations to certain services by adding the service type 
or by a service name pattern for `addConfiguration`:

```dart
@override
Widget build(BuildContext context) {
  ServiceScope(child: const MyApp())
    ..addConfiguration<CustomerService>({"url": "http://home.com"})..addConfiguration(
      {"url": "http://home.com/secret"}, serviceNamePattern: RegExp('Secret.*'));
}
```
In this example the `CustomerService` gets the public url while all services with name prefix 'Secret'
get the secret url. 

## License

This package is proprietary software owned by [Eniware Systems GmbH](https://eniware-systems.de). All rights reserved.

Unauthorized reproduction or distribution of this package, or any portion of it, may result in severe civil and criminal penalties, and will be prosecuted to the maximum extent possible under the law.

For licensing inquiries or other questions, please contact [info@eniware-systems.de](mailto:info@eniware-systems.de)
```
