import 'package:eni_svc/eni_svc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class MyService with Service {}

class MyService2 with Service {}

void main() {
  testWidgets('configurations can be used globally', (tester) async {
    final svc = MyService();

    final scope = ServiceScope(
      child: Container(),
    )
      ..addConfiguration({"foo": "bar"})
      ..addConfiguration({"foo2": "baz"})
      ..provide(svc);

    await tester.pumpWidget(scope);

    expect(svc.configurations.length, equals(2));
    expect(svc.getConfigOrNull<String>("foo"), equals("bar"));
    expect(svc.getConfigOrNull<String>("foo2"), equals("baz"));
  });

  testWidgets('configurations can be used by service type', (tester) async {
    final svc = MyService();
    final svc2 = MyService2();

    final scope = ServiceScope(
      child: Container(),
    )
      ..addConfiguration<MyService>({"foo": "bar"})
      ..provide(svc)
      ..provide(svc2);

    await tester.pumpWidget(scope);

    expect(svc.configurations.length, equals(1));
    expect(svc2.configurations.length, equals(0));
  });

  testWidgets('configurations can be used by service name', (tester) async {
    final svc = MyService();
    final svc2 = MyService2();

    final scope = ServiceScope(
      child: Container(),
    )
      ..addConfiguration({"foo": "bar"}, serviceNamePattern: RegExp(r'.+2'))
      ..provide(svc)
      ..provide(svc2);

    await tester.pumpWidget(scope);

    expect(svc.configurations.length, equals(0));
    expect(svc2.configurations.length, equals(1));
  });
}
