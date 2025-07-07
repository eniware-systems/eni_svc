import 'dart:async';

import 'package:eni_svc/eni_svc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class AbstractService {}

class ConcreteService extends AbstractService {}

class InitCallbackService with Service {
  final Future Function(ServiceRegistry services) init;

  InitCallbackService(this.init);

  @override
  Future onInit(ServiceRegistry services) => init(services);
}

class ConcreteService2 extends AbstractService with Service {
  final completionStream = StreamController();

  @override
  Future onStart(ServiceRegistry services) {
    return completionStream.stream.first;
  }
}

class ConcreteService3 with Service {
  final completionStream = StreamController();

  @override
  Future onPreInit(ServiceRegistry services) async {
    services.register(ServiceDescriptor.from(
        name: "ConcreteService", create: (_) => ConcreteService()));
  }
}

int _nthService = 0;

class ConcreteService4 {
  final int nth;

  ConcreteService4() : nth = _nthService++;
}

class TestServiceProvider extends ServiceProvider {
  Future doBootstrap(BuildContext context) => bootstrap(context);
}

void main() {
  test('service descriptors can be identified by type', () {
    final d = ServiceDescriptor.from(
        name: "ConcreteService",
        create: (_) => ConcreteService(),
        family: AbstractService);

    expect(d.isOfType<AbstractService>(), true);
    expect(d.isOfType<ConcreteService>(), true);
    expect(d.isOfType<ConcreteService2>(), false);
  });

  testWidgets('ServiceScope is bootstrapping', (tester) async {
    final svc = ConcreteService2();

    const childKey = Key("child");

    await tester.pumpWidget(ServiceScope(
      child: Container(key: childKey),
    )..provide(name: "ConcreteService", ConcreteService()));

    expect(find.byKey(childKey), findsNothing);

    svc.completionStream.add(null);
    expect(find.byKey(childKey), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byKey(childKey), findsOneWidget);
  });

  testWidgets('Can provide services while bootstrapping', (tester) async {
    await tester.pumpWidget(ServiceScope(
      child: Container(),
    )..provide(name: "ConcreteService3", ConcreteService3()));

    await tester.pumpAndSettle();
  });

  test('Cannot provide service with same name twice', () {
    final provider = ServiceProvider();
    provider.register(ServiceDescriptor(
        create: (_) => ConcreteService(),
        priority: (_) => ServiceDescriptor.defaultPriority,
        type: ConcreteService,
        name: "A"));
    expect(
        () => provider.register(ServiceDescriptor(
            create: (_) => ConcreteService2(),
            priority: (_) => ServiceDescriptor.defaultPriority,
            type: ConcreteService2,
            name: "A")),
        throwsA(isA<StateError>()));
  });

  testWidgets('State priorities are respected', (tester) async {
    final scope = ServiceScope(
      child: Container(),
    );

    const priorities = [3, 4, 65, 2, 122, 34, 10, 0, -100];

    final result = <int>[];

    for (int i = 0; i < priorities.length; ++i) {
      scope.provide(name: "P${i}_${priorities[i]}",
          InitCallbackService((_) async {
        result.add(priorities[i]);
      }), priority: priorities[i]);
    }

    await tester.pumpWidget(scope);

    expect(result.length, equals(priorities.length));

    final resultsOrdered = result.toList();
    resultsOrdered.sort((a, b) => b.compareTo(a));

    expect(result, equals(resultsOrdered));
  });

  testWidgets('Can get service by name', (tester) async {
    late ImmutableServiceRegistry registry;

    final scope = ServiceScope(
      builder: (context, bootstrapLevel) {
        registry = context.services;
        return Container();
      },
    )
      ..provide<ConcreteService>(name: "A", ConcreteService())
      ..provide<ConcreteService>(name: "B", ConcreteService());

    await tester.pumpWidget(scope);

    expect(registry.getServiceOrNull(name: "A"), isNotNull);
    expect(registry.getServiceOrNull(name: "B"), isNotNull);
    expect(registry.getServiceOrNull(name: "C"), isNull);
  });

  testWidgets('Services are propagated up to the child scope', (tester) async {
    late ImmutableServiceRegistry registry;
    late ImmutableServiceRegistry rootRegistry;

    final childScope = ServiceScope(
      builder: (context, bootstrapLevel) {
        registry = context.services;
        return Container();
      },
    );

    final rootScope = ServiceScope(builder: (context, bootstrapLevel) {
      rootRegistry = context.services;
      return childScope;
    })
      ..provide<ConcreteService>(name: "A", ConcreteService());

    await tester.pumpWidget(rootScope); // This bootstraps the root service

    expect(rootRegistry.getServiceOrNull(name: "A"), isNotNull);
    expect(registry.getServiceOrNull(name: "A"), isNotNull);
  });

  testWidgets('Can create transient services', (tester) async {
    late ImmutableServiceRegistry registry;

    final scope = ServiceScope(
      builder: (context, bootstrapLevel) {
        registry = context.services;
        return Container();
      },
    )..provide<ConcreteService4>((_) => ConcreteService4(),
        scope: ServiceScopeType.transient);

    await tester.pumpWidget(
        scope); // This bootstraps the root service/ And this obtains the registry through the builder.

    final svc1 = registry.getService<ConcreteService4>();
    final svc2 = registry.getService<ConcreteService4>();

    expect(svc2.nth, greaterThan(svc1.nth));
  });

  testWidgets('ephemeral services are removed after bootstrapping',
      (tester) async {
    late ImmutableServiceRegistry registry;

    final scope = ServiceScope(
      builder: (context, bootstrapLevel) {
        registry = context.services;
        return Container();
      },
    )..provide<ConcreteService4>((_) => ConcreteService4(), ephemeral: true);

    await tester.pumpWidget(scope); // This bootstraps the root service
    await tester.pumpWidget(
        scope); // And this obtains the registry through the builder.

    expect(registry.getServiceOrNull<ConcreteService4>(), isNull);
  });
}
