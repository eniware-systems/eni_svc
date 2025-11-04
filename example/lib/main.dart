import 'package:eni_svc/eni_svc.dart';
import 'package:eni_utils/eni_utils.dart';
import 'package:flutter/material.dart';

class CustomerService with Service {
  String? getTheUrl() {
    String? url = getConfigOrNull<String>('url');
    return url;
  }
}

class SecretService with Service {
  String? getTheUrl() {
    String? url = getConfigOrNull<String>('url');
    return url;
  }
}

class SimpleService {
  void doIt() => loggerFor("SimpleService").log(Level.info, "doIt");
}

class MyAwesomeService with Service {
  final int index;

  MyAwesomeService(this.index);

  void doAwesomeThing() =>
      loggerFor("MyAwesomeService $index").log(Level.info, "doAwesomeThing");
}

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
      ..addConfiguration<CustomerService>({"url": "http://home.com"})
      ..addConfiguration({
        "url": "http://home.com/secret",
      }, serviceNamePattern: RegExp('Secret.*'))
      ..provide(CustomerService())
      ..provide(SecretService())
      ..provide(SimpleService())
      ..provide<MyAwesomeService>(
        (context) => MyAwesomeService(1),
        name: "svc1",
      )
      ..provide(MyAwesomeService(2), name: "svc2")
      ..addFeature(WorkerHandler())
      ..addPackage(makePackage("PackageA")..withConfig("workerCount", 3))
      ..addPackage(makePackage("PackageB")..withConfig("workerCount", 5)),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final customerServiceUrl =
        context.getService<CustomerService>().getTheUrl();
    final logger = loggerFor("Result");
    logger.log(Level.info, "Customer url: $customerServiceUrl");
    final secretServiceUrl = context.getService<SecretService>().getTheUrl();
    logger.log(Level.info, "Secret url: $secretServiceUrl");
    context.getService<SimpleService>().doIt();
    context.getService<MyAwesomeService>(name: "svc1").doAwesomeThing();
    context.getService<MyAwesomeService>(name: "svc2").doAwesomeThing();
    final allAwesomeServices = context.getServices<MyAwesomeService>();
    logger.log(
        Level.info, "Number of AwesomeServices: ${allAwesomeServices.length}");
    final workers = context.getServices<Worker>();
    for (final worker in workers) {
      logger.log(Level.info, worker.name);
    }
    return MaterialApp(
      title: 'Eni service example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Urls:", style: Theme.of(context).textTheme.titleLarge),
              Text("Customer url: $customerServiceUrl"),
              Text("Secret url: $secretServiceUrl"),
              const SizedBox(height: 16),
              Text(
                "Awesome services:",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final service in allAwesomeServices)
                Text("Service ${service.index}"),
              const SizedBox(height: 16),
              Text("Workers:", style: Theme.of(context).textTheme.titleLarge),
              for (final worker in workers) Text(worker.name),
            ],
          ),
        ),
      ),
    );
  }
}
